; ==============================================================================
; Layer 2 Graphics Driver (256x192 8bpp Mode) - Universal Library
; Row-major addressing, MMU bank caching, clipping, and fast rasterizer
; All symbol names strictly <= 10 characters (CamelCase).
; ==============================================================================

; --- Initialize Layer 2 Display Subroutine ---
; Configures NextRegs for 256x192 8bpp mode, resets clipping and scroll.
; Inputs:    None (Uses FrontBase from config.inc)
; Outputs:   None
; Clobbers:  AF, BC
InitL2:
    NEXTREG RegL2Ctl,$00    ; Set 256x192 mode, 8bpp, palette 0 offset
    NEXTREG RegClipCt,$01   ; Reset Layer 2 clip window index to X1
    NEXTREG RegL2Clip,0     ; Set X1 clip boundary to 0
    NEXTREG RegL2Clip,255   ; Set X2 clip boundary to 255
    NEXTREG RegL2Clip,0     ; Set Y1 clip boundary to 0
    NEXTREG RegL2Clip,191   ; Set Y2 clip boundary to 191
    NEXTREG RegScrXLo,0     ; Reset X scroll LSB to 0
    NEXTREG RegScrXHi,0     ; Reset X scroll MSB to 0
    NEXTREG RegScrY,0       ; Reset Y scroll to 0
    NEXTREG RegLineOf,0     ; Align Copper line 0 with top of video
    NEXTREG RegLayer,$04    ; Layer priority: Layer2 > Sprites > ULA
    NEXTREG RegL2Bank,FrontBase ; Display initial frame on front buffer bank

    LD A,$02                ; Enable Layer 2 visibility (bit 1 = 1)
    LD BC,PortL2            ; BC = Layer 2 control port ($123B)
    OUT (C),A               ; Send enable command to Layer 2 port

    LD A,FrontBase          ; Initial front buffer base 16K bank
    LD (FntBank),A          ; Store active front bank variable
    LD A,BackBase           ; Initial back buffer base 16K bank
    LD (BckBank),A          ; Point back bank to BackBase on boot
    LD A,$FF                ; Invalidate MMU bank cache token ($FF)
    LD (CurBank),A          ; Mark currently mapped bank invalid
    RET                     ; Return with Layer 2 initialized

; --- Clear Active Back Buffer using zxnDMA ---
; Loops through all consecutive 16 KiB banks defined by BankCnt (3 banks = 48K)
; Inputs:    None (Reads BckBank)
; Outputs:   None
; Clobbers:  AF, BC, DE, HL
ClrBack:
    LD A,(BckBank)          ; Load base 16 KiB bank of back buffer
    LD D,A                  ; D = running bank counter
    LD B,BankCnt            ; B = number of 16K banks to clear (3)
ClrLp:
    LD A,D                  ; Current 16 KiB bank number
    ADD A,A                 ; Multiply by 2 for MMU slot 2 (8K bank)
    NEXTREG RegMMU2,A       ; Map lower 8K of bank into $4000-$5FFF
    INC A                   ; Advance to upper 8K bank
    NEXTREG RegMMU3,A       ; Map upper 8K of bank into $6000-$7FFF
    LD A,D                  ; Current 16K bank
    LD (CurBank),A          ; Update MMU cache tracking variable

    PUSH BC                 ; Preserve outer loop counter
    CALL DmaClear           ; Fast DMA fill of $4000-$7FFF with FillVal
    POP BC                  ; Restore loop counter

    INC D                   ; Advance to next 16 KiB bank
    DJNZ ClrLp              ; Loop across all banks
    RET                     ; Return with back buffer fully cleared

; --- Swap Front and Back Buffers at VBlank ---
; Inputs:    None
; Outputs:   None
; Clobbers:  AF, B
SwapBuf:
    LD A,(BckBank)          ; Load newly completed back buffer bank
    NEXTREG RegL2Bank,A     ; Flip display output to new frame instantly

    LD A,(FntBank)          ; Exchange front and back bank variables
    LD B,A                  ; B = old front bank
    LD A,(BckBank)          ; A = old back bank
    LD (FntBank),A          ; Front bank is now old back bank
    LD A,B                  ; A = old front bank
    LD (BckBank),A          ; Back bank is now old front bank

    LD A,$FF                ; Invalidate MMU bank cache token ($FF)
    LD (CurBank),A          ; Invalidate cache for new drawing cycle
    RET                     ; Return after buffer swap

; --- Plot Single Pixel in 256x192 Row-Major Mode ---
; Inputs:    C  = X coordinate (0..255)
;            D  = Y coordinate (0..191)
;            E  = Color index (1..254)
; Outputs:   None
; Clobbers:  AF, HL
PlotPix:
    ; Range clipping check: Y must be strictly < 192
    LD A,D                  ; A = Y coordinate
    CP 192                  ; Test if Y < 192
    RET NC                  ; Reject off-screen pixel

    ; 16 KiB Bank offset = Y >> 6 (0, 1, 2)
    LD A,D                  ; A = Y (0..191)
    RLCA                    ; Shift bit 7 into Carry
    RLCA                    ; Shift bit 6 into Carry
    AND %00000011           ; A = Y >> 6 (0..2)
    LD HL,BckBank           ; Point HL to back buffer base bank
    ADD A,(HL)              ; A = BckBank + (Y >> 6)

    ; Check MMU bank cache to eliminate redundant NextReg writes
    LD HL,CurBank           ; Point to cached bank variable
    CP (HL)                 ; Compare target bank with current cache
    JP Z,PltMapped          ; If already mapped, skip NextReg updates

    ; Remap MMU2 ($4000-$5FFF) and MMU3 ($6000-$7FFF)
    LD (HL),A               ; Update cached bank variable
    ADD A,A                 ; 16K bank * 2 = first 8K slot
    NEXTREG RegMMU2,A       ; Map lower 8K into $4000
    INC A                   ; Advance to second 8K slot
    NEXTREG RegMMU3,A       ; Map upper 8K into $6000

PltMapped:
    ; 256x192 CPU Address Calculation:
    ; High byte = $40 + (Y & 63)
    ; Low byte  = X (stored in C)
    LD A,D                  ; A = Y coordinate
    AND 63                  ; Mask to line within 16K bank (0..63)
    OR $40                  ; Base address starts at $4000
    LD H,A                  ; H = High address byte ($40..$7F)
    LD L,C                  ; L = Low address byte (X: 0..255)
    LD (HL),E               ; Write pixel color byte into Layer 2 RAM
    RET                     ; Return from pixel plot

; --- Layer 2 Driver Variables ---
FntBank:    DB FrontBase    ; Active visible 16 KiB buffer bank
BckBank:    DB BackBase     ; Active off-screen 16 KiB drawing bank
CurBank:    DB $FF          ; Cached 16 KiB bank currently in MMU2/MMU3
