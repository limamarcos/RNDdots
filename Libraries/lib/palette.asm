; ==============================================================================
; Layer 2 Palette Generator - Universal Library
; 254-color continuous natural spectral rainbow and 16 deep velvet backdrops
; All symbol names strictly <= 10 characters (CamelCase).
; ==============================================================================

; --- Generate Complete 256-Color Natural Spectrum Palette in RAM ---
; Inputs:    BgRec selects deep velvet background hue (0..15)
; Outputs:   PalBuf filled with 256 bytes (0..255)
; Clobbers:  AF, BC, DE, HL, IX
GenPal:
    LD HL,PalBuf            ; HL points to RAM palette buffer

    ; Set Entry 0 to selected deep velvet background color
    LD A,(BgRec)            ; Load background recipe index (0..15)
    AND 15                  ; Constrain to 0..15
    LD E,A                  ; E = index offset
    LD D,0                  ; D = 0
    LD IX,BgTable           ; IX points to table of 16 background colors
    ADD IX,DE               ; Index into background table
    LD A,(IX+0)             ; Load 8-bit RRRGGGBB background color byte
    LD (HL),A               ; Set palette entry 0
    INC HL                  ; Advance pointer to stroke entries 1..255

    ; --- Generate 254-Color Continuous Natural Spectral Light Rainbow ---
    ; Sector 0 (42 entries): Red -> Yellow (R=7, G: 0..7, B=0)
    LD B,42                 ; B = 42 entries in sector 0
    LD C,0                  ; C = step counter
LpSec0:
    LD A,C                  ; A = index 0..41
    LD D,A                  ; D = index
    LD E,7                  ; E = 7
    MUL D,E                 ; DE = index * 7 (0..287)
    LD A,D                  ; Approximate G = (index * 7) / 41
    SRL A                   ; Shift right by 1
    SRL A                   ; Shift right to bring G into 0..7
    LD A,C                  ; A = step index
    SRL A                   ; Linear slope division
    SRL A                   ; Shift right
    SRL A                   ; Shift right
    RLCA                    ; Shift G left to bit 3
    RLCA                    ; Shift G left to bits 4..2
    OR %11100000            ; Set max Red (%111 in bits 7..5)
    LD (HL),A               ; Store generated color byte
    INC HL                  ; Advance palette pointer
    INC C                   ; Increment step counter
    DJNZ LpSec0             ; Loop for all 42 entries

    ; Sector 1 (43 entries): Yellow -> Green (R: 7..0, G=7, B=0)
    LD B,43                 ; B = 43 entries in sector 1
    LD C,0                  ; C = step counter
LpSec1:
    LD A,C                  ; A = index 0..42
    SRL A                   ; Shift right
    SRL A                   ; Shift right
    SRL A                   ; A in 0..7
    LD D,A                  ; D = offset
    LD A,7                  ; Max Red value (7)
    SUB D                   ; R = 7 - offset
    RLCA                    ; Shift R left
    RLCA                    ; Shift R left
    RLCA                    ; Shift R left
    RLCA                    ; Shift R left
    RLCA                    ; Shift R into bits 7..5
    OR %00011100            ; Set max Green (%111 in bits 4..2)
    LD (HL),A               ; Store generated color byte
    INC HL                  ; Advance palette pointer
    INC C                   ; Increment step counter
    DJNZ LpSec1             ; Loop for all 43 entries

    ; Sector 2 (42 entries): Green -> Cyan (R=0, G=7, B: 0..3)
    LD B,42                 ; B = 42 entries in sector 2
    LD C,0                  ; C = step counter
LpSec2:
    LD A,C                  ; A = index 0..41
    SRL A                   ; Shift right
    SRL A                   ; Shift right
    SRL A                   ; Shift right
    SRL A                   ; A in 0..3
    AND %00000011           ; Mask to Blue bits (0..3)
    OR %00011100            ; Set max Green (%111 in bits 4..2)
    LD (HL),A               ; Store generated color byte
    INC HL                  ; Advance palette pointer
    INC C                   ; Increment step counter
    DJNZ LpSec2             ; Loop for all 42 entries

    ; Sector 3 (43 entries): Cyan -> Blue (R=0, G: 7..0, B=3)
    LD B,43                 ; B = 43 entries in sector 3
    LD C,0                  ; C = step counter
LpSec3:
    LD A,C                  ; A = index 0..42
    SRL A                   ; Shift right
    SRL A                   ; Shift right
    SRL A                   ; A in 0..7
    LD D,A                  ; D = offset
    LD A,7                  ; Max Green value (7)
    SUB D                   ; G = 7 - offset
    RLCA                    ; Shift G left
    RLCA                    ; Shift G into bits 4..2
    OR %00000011            ; Set max Blue (%11 in bits 1..0)
    LD (HL),A               ; Store generated color byte
    INC HL                  ; Advance palette pointer
    INC C                   ; Increment step counter
    DJNZ LpSec3             ; Loop for all 43 entries

    ; Sector 4 (42 entries): Blue -> Magenta (R: 0..7, G=0, B=3)
    LD B,42                 ; B = 42 entries in sector 4
    LD C,0                  ; C = step counter
LpSec4:
    LD A,C                  ; A = index 0..41
    SRL A                   ; Shift right
    SRL A                   ; Shift right
    SRL A                   ; A in 0..7
    RLCA                    ; Shift R left
    RLCA                    ; Shift R left
    RLCA                    ; Shift R left
    RLCA                    ; Shift R left
    RLCA                    ; Shift R into bits 7..5
    OR %00000011            ; Set max Blue (%11 in bits 1..0)
    LD (HL),A               ; Store generated color byte
    INC HL                  ; Advance palette pointer
    INC C                   ; Increment step counter
    DJNZ LpSec4             ; Loop for all 42 entries

    ; Sector 5 (43 entries): Magenta -> Red (R=7, G=0, B: 3..0)
    LD B,43                 ; B = 43 entries in sector 5
    LD C,0                  ; C = step counter
LpSec5:
    LD A,C                  ; A = index 0..42
    SRL A                   ; Shift right
    SRL A                   ; Shift right
    SRL A                   ; Shift right
    SRL A                   ; A in 0..3
    LD D,A                  ; D = offset
    LD A,3                  ; Max Blue value (3)
    SUB D                   ; B = 3 - offset
    AND %00000011           ; Mask to Blue bits (0..3)
    OR %11100000            ; Set max Red (%111 in bits 7..5)
    LD (HL),A               ; Store generated color byte
    INC HL                  ; Advance palette pointer
    INC C                   ; Increment step counter
    DJNZ LpSec5             ; Loop for all 43 entries
    RET                     ; Return with natural spectrum ready

; --- Upload RAM Palette to Hardware ---
; Must be called during vertical blank
; Inputs:    PalBuf ready in RAM
; Outputs:   None
; Clobbers:  AF, B, HL
SetPal:
    NEXTREG RegPalCtl,$10   ; Layer 2 Pal 0, auto-inc ON
    NEXTREG RegPalIdx,0     ; Start at palette index 0
    LD HL,PalBuf            ; Point HL to RAM palette buffer
    LD B,0                  ; B = 0 (256 bytes in DJNZ loop)
SetPalLp:
    LD A,(HL)               ; Read color byte from RAM
    NEXTREG RegPalVal,A     ; Write to NextReg $41 (auto-increments)
    INC HL                  ; Advance RAM pointer
    DJNZ SetPalLp           ; Upload all 256 palette entries

    NEXTREG RegPalCtl,$18   ; Layer 2 Pal 0, auto-inc OFF
    NEXTREG RegPalIdx,0     ; Reset index to 0 for Copper access
    RET                     ; Return with active hardware palette

; --- Shimmer Palette Rotation Subroutine ---
; Rotates palette entries 1..254 left by 1 step at 50 FPS
; Preserves entry 0 (background) and entry 255 (highlight)
; Inputs:    PalBuf in RAM
; Outputs:   PalBuf rotated and uploaded to hardware
; Clobbers:  AF, BC, DE, HL
ShimPal:
    LD A,(PalBuf+1)         ; Save entry 1 color byte
    LD (ShimTmp),A          ; Store in temporary variable
    LD HL,PalBuf+2          ; Source: entries 2..254
    LD DE,PalBuf+1          ; Destination: entries 1..253
    LD BC,253               ; BC = 253 bytes to shift
    LDIR                    ; Shift color block left by 1
    LD A,(ShimTmp)          ; Load saved entry 1
    LD (PalBuf+254),A       ; Store wrapped color at entry 254
    CALL SetPal             ; Upload rotated palette to hardware
    RET                     ; Return after shimmer update

; --- Curated Table of 16 Deep Dark Velvet Background Hues ---
; 8-bit RRRGGGBB format: R:bits 7..5, G:bits 4..2, B:bits 1..0
BgTable:
    DB %00000000            ; 0:  Pure Velvet Obsidian (#000000)
    DB %00000001            ; 1:  Deep Midnight Navy (#000014)
    DB %00100000            ; 2:  Deep Burgundy Wine (#140000)
    DB %00000100            ; 3:  Deep Emerald Forest (#001400)
    DB %00100001            ; 4:  Royal Midnight Plum (#140014)
    DB %00000101            ; 5:  Deep Twilight Teal (#001414)
    DB %00100100            ; 6:  Roasted Dark Espresso (#141400)
    DB %00000001            ; 7:  Deep Celestial Indigo (#000014)
    DB %01000001            ; 8:  Deep Imperial Violet (#240014)
    DB %00100101            ; 9:  Dark Slate Graphite (#141414)
    DB %00001001            ; 10: Deep Ocean Abyss (#002414)
    DB %01000000            ; 11: Deep Ruby Maroon (#240000)
    DB %00000110            ; 12: Deep Arctic Twilight (#001428)
    DB %01000100            ; 13: Dark Amber Bronze (#241400)
    DB %00100010            ; 14: Deep Amethyst Night (#140028)
    DB %00000000            ; 15: Pitch Black Carbon (#000000)

; --- Palette Storage Variables ---

BgRec:
    DB 0                    ; Active background hue index (0..15)
ShimTmp:
    DB 0                    ; Shimmer rotation temporary byte
PalBuf:
    DS 256                  ; 256-byte RAM buffer for Layer 2 palette
