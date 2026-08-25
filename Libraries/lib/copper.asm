; ==============================================================================
; Copper Coprocessor Engine - Universal Library
; Dynamic Backdrop Controller, Program Streamer, and Coprocessor Manager
; All symbol names strictly <= 10 characters (CamelCase).
; ==============================================================================

; --- Initialize Copper Instruction List in RAM ---
; Sets up a solid background color on Layer 2 / ULA palette 0, index 0
; Inputs:    None
; Outputs:   None
; Clobbers:  AF, HL
InitCop:
    LD HL,CopBuf            ; HL points to Copper RAM buffer
    LD (HL),$43             ; MOVE RegPalCtl ($43): Select palette control
    INC HL                  ; Advance pointer to data byte
    LD (HL),$00             ; Value $00: Target ULA Palette 0
    INC HL                  ; Advance pointer to next opcode
    LD (HL),$40             ; MOVE RegPalIdx ($40): Select palette index
    INC HL                  ; Advance pointer to data byte
    LD (HL),$00             ; Value $00: Target background index 0
    INC HL                  ; Advance pointer to next opcode
    LD (HL),$41             ; MOVE RegPalVal ($41): Set color value
    INC HL                  ; Advance pointer to data byte
    LD (HL),$00             ; Value $00: Initial black background
    INC HL                  ; Advance pointer to next opcode
    LD (HL),$43             ; MOVE RegPalCtl ($43): Restore palette control
    INC HL                  ; Advance pointer to data byte
    LD (HL),$18             ; Value $18: Layer 2 Pal 0, auto-inc OFF
    INC HL                  ; Advance pointer to next opcode
    LD (HL),$FF             ; HALT opcode MSB ($FF)
    INC HL                  ; Advance pointer to next opcode
    LD (HL),$FF             ; HALT opcode LSB ($FF)
    RET                     ; Return with initialized Copper buffer

; --- Set Solid Background Color in Copper List ---
; Inputs:    A = 8-bit RRRGGGBB background color
; Outputs:   CopBuf updated with new background color
; Clobbers:  None (preserves registers)
SetCopBg:
    LD (CopBuf+5),A         ; Store new color byte into MOVE RegPalVal
    RET                     ; Return with updated buffer

; --- Upload Copper List to Hardware and Start at VBlank ---
; Inputs:    None (Reads from CopBuf in RAM)
; Outputs:   None
; Clobbers:  AF, B, HL
SendCop:
    NEXTREG RegCopLo,0      ; Reset Copper write address LSB to 0
    NEXTREG RegCopHi,0      ; Stop Copper and reset address MSB
    LD HL,CopBuf            ; HL points to RAM Copper instruction list
    LD B,10                 ; B = 10 bytes in standard Copper list
SendLp:
    LD A,(HL)               ; Read instruction byte from RAM
    NEXTREG RegCopDat,A     ; Stream byte directly into Copper RAM
    INC HL                  ; Advance pointer to next byte
    DJNZ SendLp             ; Loop for all 10 bytes
    NEXTREG RegCopLo,0      ; Reset Copper PC to start instruction 0
    NEXTREG RegCopHi,$C0    ; Mode %11: Restart Copper automatically on VBlank
    RET                     ; Return with active Copper program

; --- Safely Stop Copper Execution ---
; Inputs:    None
; Outputs:   None
; Clobbers:  None
StopCop:
    NEXTREG RegCopHi,$00    ; Write 0 to RegCopHi to halt execution
    RET                     ; Return with Copper stopped

; --- Copper Variables and Storage ---

CopBuf:
    DS 10                   ; 10-byte RAM buffer for Copper instructions
