; ==============================================================================
; zxnDMA Hardware Controller (Port $6B) - Universal Library
; High-speed memory fill, block transfer, and memory-to-I/O palette streamer
; All symbol names strictly <= 10 characters (CamelCase).
; ==============================================================================

; --- DMA Clear Subroutine ---
; Fills mapped 16 KiB bank at $4000-$7FFF with FillVal byte
; Inputs:    None (Bank mapped in $4000-$7FFF, FillVal set)
; Outputs:   None
; Clobbers:  AF, BC, HL
DmaClear:
    LD HL,DmaClrDsc         ; HL points to 14-byte DMA clear descriptor
    LD B,14                 ; B = 14 command bytes in DMA sequence
    LD C,$6B                ; C = Target native zxnDMA port ($6B)
    OTIR                    ; Upload descriptor sequence to DMA port
    RET                     ; Return after DMA finishes block fill

; --- DMA Palette Stream Subroutine ---
; Transfers 256 bytes from PalBuf in RAM to NextReg $41 via port $253B
; Inputs:    NextReg $41 already selected via port $243B
; Outputs:   None
; Clobbers:  AF, BC, HL
DmaPal:
    LD HL,DmaPalDsc         ; HL points to 14-byte palette descriptor
    LD B,14                 ; B = 14 command bytes in DMA sequence
    LD C,$6B                ; C = Target native zxnDMA port ($6B)
    OTIR                    ; Upload descriptor sequence to DMA port
    RET                     ; Return after DMA finishes palette stream

; --- DMA 16 KiB Block Copy Subroutine ---
; Transfers 16384 bytes from DmaSrc to DmaDst
; Inputs:    DmaSrc (source address DW), DmaDst (dest address DW)
; Outputs:   None
; Clobbers:  AF, BC, HL
DmaCopy:
    LD HL,DmaCpyDsc         ; HL points to 14-byte copy descriptor
    LD B,14                 ; B = 14 command bytes in DMA sequence
    LD C,$6B                ; C = Target native zxnDMA port ($6B)
    OTIR                    ; Upload descriptor sequence to DMA port
    RET                     ; Return after DMA finishes block transfer

; --- DMA Control Descriptors and Storage ---

FillVal:
    DB 0                    ; Fixed fill source byte (e.g. 0 for clear)

DmaClrDsc:
    DB $83                  ; WR6: Reset and disable DMA controller
    DB $7D                  ; WR0: A->B transfer with address & length
    DW FillVal              ; Port A starting source address in RAM
    DW $4000                ; Transfer length: 16384 bytes ($4000)
    DB $24                  ; WR1: Port A is fixed memory address
    DB $10                  ; WR2: Port B is incrementing memory dest
    DB $AD                  ; WR4: Continuous mode, dest address loaded
    DW $4000                ; Port B destination start address ($4000)
    DB $82                  ; WR5: Stop on end of block, CE only
    DB $CF                  ; WR6: Load addresses into DMA counters
    DB $87                  ; WR6: Enable DMA execution immediately

DmaPalDsc:
    DB $83                  ; WR6: Reset and disable DMA controller
    DB $7D                  ; WR0: A->B transfer with address & length
    DW PalBuf               ; Port A starting source (PalBuf in RAM)
    DW $0100                ; Transfer length: 256 bytes ($0100)
    DB $14                  ; WR1: Port A is incrementing memory
    DB $28                  ; WR2: Port B is fixed I/O destination
    DB $AD                  ; WR4: Continuous mode, dest address loaded
    DW PortData             ; Port B destination I/O port ($253B)
    DB $82                  ; WR5: Stop on end of block, CE only
    DB $CF                  ; WR6: Load addresses into DMA counters
    DB $87                  ; WR6: Enable DMA execution immediately

DmaCpyDsc:
    DB $83                  ; WR6: Reset and disable DMA controller
    DB $7D                  ; WR0: A->B transfer with address & length
DmaSrc:
    DW $4000                ; Port A source memory address
    DW $4000                ; Transfer length: 16384 bytes ($4000)
    DB $14                  ; WR1: Port A is incrementing memory
    DB $10                  ; WR2: Port B is incrementing memory
    DB $AD                  ; WR4: Continuous mode, dest address loaded
DmaDst:
    DW $8000                ; Port B destination memory address
    DB $82                  ; WR5: Stop on end of block, CE only
    DB $CF                  ; WR6: Load addresses into DMA counters
    DB $87                  ; WR6: Enable DMA execution immediately
