; ==============================================================================
; Project Configuration Presets - Universal Next Library
; Layer 2 256x192 Mode - Double-Buffered
; ==============================================================================

FrontBase:  EQU 16          ; Front buffer base 16K bank (16..18 = 48K)
BackBase:   EQU 19          ; Back buffer base 16K bank (19..21 = 48K)
BankCnt:    EQU 3           ; 3 banks of 16K = 48 KiB total per buffer
StackTop:   EQU $BFFF       ; Safe stack pointer location below user code
FillByte:   EQU $00         ; Background clear color (0 = velvet black)
