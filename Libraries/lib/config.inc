; ==============================================================================
; Project Configuration Presets - Universal Next Library
; 
; INSTRUCTIONS:
; This file contains configuration templates for various project types.
; To configure your project, UNCOMMENT exactly ONE block below corresponding
; to your desired display mode and memory architecture.
; Keep all other blocks commented out with leading semicolons (;).
; 
; PARAMETERS EXPLAINED:
;   FrontBase - Starting 16K bank for visible display buffer
;   BackBase  - Starting 16K bank for drawing (same as FrontBase for single-buf)
;   BankCnt   - Number of 16K banks (5 for 320x256 = 80K, 3 for 256x192 = 48K)
;   StackTop  - Safe stack pointer location (below $C000)
;   FillByte  - Clear color index (0 for Copper backdrop / transparent)
; 
; All symbol names strictly <= 10 characters (CamelCase).
; ==============================================================================

; ==============================================================================
; PRESET 1: Layer 2 320x256 Mode - Double-Buffered (Active Default)
; Best for: 50 FPS arcade games, smooth demos, action graphics with page flipping.
; Memory: 160 KiB total (Front: Banks 16..20, Back: Banks 21..25)
; ==============================================================================
FrontBase:  EQU 16          ; Front buffer base 16K bank (16..20)
BackBase:   EQU 21          ; Back buffer base 16K bank (21..25)
BankCnt:    EQU 5           ; 5 banks of 16K = 80 KiB total per buffer
StackTop:   EQU $BFFF       ; Safe stack pointer location
FillByte:   EQU $00         ; Background clear color (0 = Copper)

; ==============================================================================
; PRESET 2: Layer 2 320x256 Mode - Single-Buffered (Live Drawing / Low RAM)
; Best for: Generative art, Mandala, turtle graphics, progressive line plotters.
; Memory: 80 KiB total (Single buffer on Banks 16..20)
; ==============================================================================
;FrontBase:  EQU 16          ; Visible buffer base 16K bank (16..20)
;BackBase:   EQU 16          ; Draw directly to visible bank (no flip)
;BankCnt:    EQU 5           ; 5 banks of 16K = 80 KiB total
;StackTop:   EQU $BFFF       ; Safe stack pointer location
;FillByte:   EQU $00         ; Background clear color (0 = Copper)

; ==============================================================================
; PRESET 3: Layer 2 256x192 Mode - Double-Buffered (Standard Resolution)
; Best for: Classic resolution games with 256 colors & smooth 50 FPS page flip.
; Memory: 96 KiB total (Front: Banks 16..18 = 48K, Back: Banks 19..21 = 48K)
; ==============================================================================
;FrontBase:  EQU 16          ; Front buffer base 16K bank (16..18)
;BackBase:   EQU 19          ; Back buffer base 16K bank (19..21)
;BankCnt:    EQU 3           ; 3 banks of 16K = 48 KiB total per buffer
;StackTop:   EQU $BFFF       ; Safe stack pointer location
;FillByte:   EQU $00         ; Background clear color (0 = Copper)

; ==============================================================================
; PRESET 4: Layer 2 256x192 Mode - Single-Buffered (Minimal 48K Footprint)
; Best for: Lightweight tools, utilities, sprite engines saving maximum RAM.
; Memory: 48 KiB total (Single buffer on Banks 16..18)
; ==============================================================================
;FrontBase:  EQU 16          ; Visible buffer base 16K bank (16..18)
;BackBase:   EQU 16          ; Draw directly to visible bank (no flip)
;BankCnt:    EQU 3           ; 3 banks of 16K = 48 KiB total
;StackTop:   EQU $BFFF       ; Safe stack pointer location
;FillByte:   EQU $00         ; Background clear color (0 = Copper)

; ==============================================================================
; PRESET 5: Extended RAM Mode (Upper 1MB / 2MB Nexts)
; Best for: Large games reserving lower 1MB for code, music, and sprite banks.
; Memory: 160 KiB high RAM (Front: Banks 32..36, Back: Banks 37..41)
; ==============================================================================
;FrontBase:  EQU 32          ; Front buffer base in upper RAM (32..36)
;BackBase:   EQU 37          ; Back buffer base in upper RAM (37..41)
;BankCnt:    EQU 5           ; 5 banks of 16K = 80 KiB total per buffer
;StackTop:   EQU $BFFF       ; Safe stack pointer location
;FillByte:   EQU $00         ; Background clear color (0 = Copper)
