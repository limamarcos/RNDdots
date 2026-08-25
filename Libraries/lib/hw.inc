; ==============================================================================
; Hardware Definitions for ZX Spectrum Next (Z80N) - Universal Library
; All symbol names strictly <= 10 characters (CamelCase)
; ==============================================================================

; --- I/O Ports ---
PortNext:   EQU $243B       ; NextReg select port (write reg number here)
PortData:   EQU $253B       ; NextReg data I/O port (read/write data)
PortL2:     EQU $123B       ; Layer 2 control / visible toggle port
PortDma:    EQU $006B       ; Native zxnDMA port (C=$6B with B=$00)
PortUla:    EQU $00FE       ; Classic ULA port (border bits 0..2)
PortKey:    EQU $7FFE       ; Keyboard half-row (Space=bit0, N=bit3)

; --- Core & CPU Registers ---
RegReset:   EQU $02         ; Soft reset register (write 1 to reset)
RegSpeed:   EQU $07         ; CPU speed register (0=3.5, 1=7, 2=14, 3=28MHz)

; --- Layer 2 & Video Control Registers ---
RegL2Bank:  EQU $12         ; Layer 2 active display 16K bank register
RegL2Shad:  EQU $13         ; Layer 2 shadow/write 16K bank register
RegLayer:   EQU $15         ; Layer priority and sprite system register
RegScrXLo:  EQU $16         ; Layer 2 X scroll LSB register
RegScrY:    EQU $17         ; Layer 2 Y scroll register
RegL2Clip:  EQU $18         ; Layer 2 clip window definition register
RegClipCt:  EQU $1C         ; Clip window control register
RegLineHi:  EQU $1E         ; Active video raster line MSB register
RegLineLo:  EQU $1F         ; Active video raster line LSB register
RegLineOf:  EQU $64         ; Vertical line-count offset register
RegDisp:    EQU $69         ; Layer 2 visibility and legacy display mirror
RegL2Ctl:   EQU $70         ; Layer 2 control register (resolution/palette)
RegScrXHi:  EQU $71         ; Layer 2 X scroll MSB register

; --- Palette Registers ---
RegPalIdx:  EQU $40         ; Palette index register (0..255)
RegPalVal:  EQU $41         ; Palette 8-bit RRRGGGBB data register
RegPalCtl:  EQU $43         ; Palette control register

; --- MMU Slot Paging Registers (8K Banks) ---
RegMMU0:    EQU $50         ; MMU slot 0 register ($0000-$1FFF, 8K bank)
RegMMU1:    EQU $51         ; MMU slot 1 register ($2000-$3FFF, 8K bank)
RegMMU2:    EQU $52         ; MMU slot 2 register ($4000-$5FFF, 8K bank)
RegMMU3:    EQU $53         ; MMU slot 3 register ($6000-$7FFF, 8K bank)
RegMMU4:    EQU $54         ; MMU slot 4 register ($8000-$9FFF, 8K bank)
RegMMU5:    EQU $55         ; MMU slot 5 register ($A000-$BFFF, 8K bank)
RegMMU6:    EQU $56         ; MMU slot 6 register ($C000-$DFFF, 8K bank)
RegMMU7:    EQU $57         ; MMU slot 7 register ($E000-$FFFF, 8K bank)

; --- Copper Coprocessor Registers ---
RegCopLo:   EQU $61         ; Copper write address LSB register
RegCopHi:   EQU $62         ; Copper write address MSB & control register
RegCopDat:  EQU $63         ; Copper 16-bit data upload register
