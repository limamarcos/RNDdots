; ==============================================================================
; Test Harness for Universal ZX Spectrum Next Graphics Library Suite
; Verifies clean assembly, symbol resolution, and label validity.
; ==============================================================================

    DEVICE ZXSPECTRUMNEXT
    OPT --zxnext=on

    ORG $C000

    INCLUDE "../lib/hw.inc"
    INCLUDE "../inc/config.inc"
    INCLUDE "../lib/sine.asm"
    INCLUDE "../lib/palette.asm"
    INCLUDE "../lib/dma.asm"
    INCLUDE "../lib/copper.asm"
    INCLUDE "../lib/layer2.asm"

Start:
    DI
    LD SP,StackTop
    NEXTREG RegSpeed,3
    CALL InitCop
    CALL InitL2
    CALL GenPal
    CALL SetPal
    CALL ClrBack
    CALL SendCop
    CALL SwapBuf
    CALL StopCop

    ; Test PlotPix
    LD C,128                ; X (0..255)
    LD D,96                 ; Y (0..191)
    LD E,255                ; Color
    CALL PlotPix

    RET

    SAVENEX OPEN "libtest.nex", Start, StackTop
    SAVENEX CORE 3, 1, 2
    SAVENEX CFG 0, 0, 0, 0
    SAVENEX AUTO
    SAVENEX CLOSE
