; ==============================================================================
; Data Variables & Glyph Matrix Table - Cosmic Swarm Demo
; All symbol names strictly <= 10 characters (CamelCase).
; ==============================================================================

; ==============================================================================
; Program Data Variables
; ==============================================================================
RndSeed:
    DW $ACE1                ; Non-zero initial seed for LFSR PRNG

TmpGridX:
    DB 0                    ; Temporary storage for grid column X
TmpGridY:
    DB 0                    ; Temporary storage for grid row Y
TmpRndY:
    DB 0                    ; High PRNG byte reused for target Y jitter
CurChr:
    DB 0                    ; Selected random ASCII character (33..122)
NumBlk:
    DB 0                    ; Number of active solid blocks in current glyph (K)
MinX:
    DB 0                    ; Leftmost active source-font column
MaxX:
    DB 0                    ; Rightmost active source-font column
MinY:
    DB 0                    ; Topmost active source-font row
MaxY:
    DB 0                    ; Bottommost active source-font row
BaseX:
    DB 0                    ; Per-glyph horizontal origin for exact centering
BaseY:
    DB 0                    ; Per-glyph vertical origin for exact centering
BlkIdx:
    DB 0                    ; Balanced active-cell assignment cursor
MovOdd:
    DB 0                    ; Alternates even and odd motion halves
SpdCnt:
    DB 0                    ; 8-bit frame divider counter for gradient speed
PalTmp:
    DB 0                    ; Temporary buffer byte for 1-step palette rotation

; Running pointers for particle array iterations
PtrX:
    DW 0                    ; Running pointer to DotX array
PtrY:
    DW 0                    ; Running pointer to DotY array
PtrTX:
    DW 0                    ; Running pointer to DotTX array
PtrTY:
    DW 0                    ; Running pointer to DotTY array

; Table of active (X, Y) block coordinates for current decoded character
GlyphBlk:
    DS 64 * 2               ; Maximum 64 active blocks (2 bytes each: col, row)
