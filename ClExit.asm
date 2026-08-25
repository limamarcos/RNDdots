; ==============================================================================
; Clean Host Entry and Exit - Astrum, NextZXOS, and NextBASIC Compatible
; Include after hw.inc so all port and NextReg symbols are already available.
; The parent source must provide ClReady as the first application instruction.
; All labels remain at most ten characters for native 8-bit assemblers.
; ==============================================================================

; --- Capture Caller State Before the Application Changes Any Registers ---
ClStart:
    PUSH AF                 ; Preserve the caller's accumulator and flags
    LD A,I                  ; Copy entry IFF2 into the parity flag
    JP PO,ClIffOff          ; Choose DI when entry interrupts were disabled
    LD A,$FB                ; Opcode $FB restores an enabled interrupt state
    JR ClIffSav             ; Skip the disabled-state opcode selection
ClIffOff:
    LD A,$F3                ; Opcode $F3 restores a disabled interrupt state
ClIffSav:
    LD (ClIffSet),A         ; Patch the final register-safe EI or DI opcode
    DI                      ; Protect register-bank and paging transitions

    PUSH BC                 ; Preserve the caller's primary BC pair
    PUSH DE                 ; Preserve the caller's primary DE pair
    PUSH HL                 ; Preserve the caller's primary HL pair
    PUSH IX                 ; Preserve the caller's IX workspace state
    PUSH IY                 ; Preserve BASIC/Astrum system-variable state
    EXX                     ; Select the caller's shadow register bank
    PUSH BC                 ; Preserve the caller's shadow BC pair
    PUSH DE                 ; Preserve the caller's shadow DE pair
    PUSH HL                 ; Preserve the caller's shadow HL pair
    EXX                     ; Return to the primary register bank
    EX AF,AF'               ; Select the caller's shadow accumulator pair
    PUSH AF                 ; Preserve the caller's shadow AF pair
    EX AF,AF'               ; Return to the primary accumulator pair
    LD (ClSaveSP),SP        ; Save the complete caller-frame stack pointer

    LD A,RegMMU2            ; Select the host's MMU slot 2 register
    CALL ClRead             ; Read its entry value without changing paging
    LD (ClMmu2),A           ; Preserve host memory at $4000-$5FFF
    LD A,RegMMU3            ; Select the host's MMU slot 3 register
    CALL ClRead             ; Read its entry value without changing paging
    LD (ClMmu3),A           ; Preserve host memory at $6000-$7FFF
    LD A,RegMMU4            ; Select the host's MMU slot 4 register
    CALL ClRead             ; Read its entry value without changing paging
    LD (ClMmu4),A           ; Preserve host memory at $8000-$9FFF
    LD A,RegMMU5            ; Select the host's MMU slot 5 register
    CALL ClRead             ; Read the bank containing the return frame
    LD (ClMmu5),A           ; Preserve the host stack's physical bank
    LD A,RegSpeed           ; Select the host's CPU-speed register
    CALL ClRead             ; Read the speed selected by the caller
    LD (ClSpeed),A          ; Preserve the exact host CPU speed
    LD A,RegLayer           ; Select the layer-priority register
    CALL ClRead             ; Read the caller's layer ordering
    LD (ClLayer),A          ; Preserve the exact host layer priority
    LD A,RegL2Ctl           ; Select the Layer 2 mode register
    CALL ClRead             ; Read the caller's Layer 2 mode
    LD (ClL2Ctl),A          ; Preserve the exact host graphics mode
    LD A,RegPalCtl          ; Select the palette-control register
    CALL ClRead             ; Read the caller's palette selection
    LD (ClPalCt),A          ; Preserve palette selection and auto-step
    LD A,RegPalIdx          ; Select the shared palette-index register
    CALL ClRead             ; Read the caller's palette cursor
    LD (ClPalIx),A          ; Preserve the host palette cursor
    LD A,RegL2Bank          ; Select the visible Layer 2 bank register
    CALL ClRead             ; Read the caller's visible Layer 2 bank
    LD (ClL2Bnk),A          ; Preserve the host's visible bank
    LD A,RegL2Shad          ; Select the shadow Layer 2 bank register
    CALL ClRead             ; Read the caller's Layer 2 write bank
    LD (ClL2Shd),A          ; Preserve the host's shadow bank
    LD A,RegScrXLo          ; Select Layer 2 X-scroll low register
    CALL ClRead             ; Read the caller's X-scroll low byte
    LD (ClScrXL),A          ; Preserve the host's horizontal position
    LD A,RegScrXHi          ; Select Layer 2 X-scroll high register
    CALL ClRead             ; Read the caller's X-scroll high bit
    LD (ClScrXH),A          ; Preserve the full horizontal position
    LD A,RegScrY            ; Select the Layer 2 Y-scroll register
    CALL ClRead             ; Read the caller's vertical position
    LD (ClScrY),A           ; Preserve the host's vertical position
    LD A,RegLineOf          ; Select the raster-line offset register
    CALL ClRead             ; Read the caller's raster numbering offset
    LD (ClLineOf),A         ; Preserve host raster timing coordinates
    LD A,RegDisp            ; Select the legacy display-state mirror
    CALL ClRead             ; Read visibility and legacy video state
    LD (ClDisp),A           ; Preserve the complete host display state
    JP ClReady              ; Continue at the application's clean entry

; --- Read One NextReg Selected in A ---
; Inputs: A = NextReg number; Outputs: A = register value; Clobbers: BC
ClRead:
    LD BC,PortNext          ; BC = NextReg select port $243B
    OUT (C),A               ; Select the requested hardware register
    INC B                   ; Advance to NextReg data port $253B
    IN A,(C)                ; Return the selected register value in A
    RET                     ; Resume the caller-state capture sequence

; --- Restore Caller State and Return Through Its Original Stack Frame ---
QuitPrg:
    LD BC,PortL2            ; BC = Layer 2 control port $123B
    XOR A                   ; A = no display, read, or write paging
    OUT (C),A               ; Remove all Layer 2 paging before MMU restore

    LD BC,PortDma           ; BC = native zxnDMA command port
    LD A,$83                ; WR6 reset command also disables the DMA engine
    OUT (C),A               ; Leave no pending DMA operation for the host
    LD A,(ClLayer)          ; Recover the caller's layer priority
    NEXTREG RegLayer,A      ; Restore the caller's layer ordering
    LD A,(ClL2Ctl)          ; Recover the caller's Layer 2 mode
    NEXTREG RegL2Ctl,A      ; Restore the caller's graphics mode
    LD A,(ClPalCt)          ; Recover the caller's palette control
    NEXTREG RegPalCtl,A     ; Restore palette selection and auto-step
    LD A,(ClPalIx)          ; Recover the caller's palette cursor
    NEXTREG RegPalIdx,A     ; Restore the shared palette index
    LD A,(ClL2Bnk)          ; Recover the caller's visible Layer 2 bank
    NEXTREG RegL2Bank,A     ; Restore the visible bank selection
    LD A,(ClL2Shd)          ; Recover the caller's Layer 2 write bank
    NEXTREG RegL2Shad,A     ; Restore the shadow bank selection
    LD A,(ClScrXL)          ; Recover Layer 2 X-scroll low byte
    NEXTREG RegScrXLo,A     ; Restore the horizontal position
    LD A,(ClScrXH)          ; Recover Layer 2 X-scroll high bit
    NEXTREG RegScrXHi,A     ; Restore the full horizontal position
    LD A,(ClScrY)           ; Recover the caller's Layer 2 Y-scroll
    NEXTREG RegScrY,A       ; Restore the vertical position
    LD A,(ClLineOf)         ; Recover the caller's raster-line offset
    NEXTREG RegLineOf,A     ; Restore host raster timing coordinates
    LD A,(ClDisp)           ; Recover host visibility and legacy state
    NEXTREG RegDisp,A       ; Restore the caller's display configuration
    LD A,(ClSpeed)          ; Recover the caller's original CPU speed
    NEXTREG RegSpeed,A      ; Restore the exact entry CPU speed

    LD A,(ClMmu2)           ; Recover original MMU slot 2 mapping
    NEXTREG RegMMU2,A       ; Restore host memory at $4000-$5FFF
    LD A,(ClMmu3)           ; Recover original MMU slot 3 mapping
    NEXTREG RegMMU3,A       ; Restore host memory at $6000-$7FFF
    LD A,(ClMmu4)           ; Recover original MMU slot 4 mapping
    NEXTREG RegMMU4,A       ; Restore host memory at $8000-$9FFF
    LD A,(ClMmu5)           ; Recover the bank holding the return frame
    NEXTREG RegMMU5,A       ; Make the original host stack visible again

    LD SP,(ClSaveSP)        ; Reattach the complete caller register frame
    EX AF,AF'               ; Select the polluted shadow accumulator pair
    POP AF                  ; Restore the caller's shadow AF pair
    EX AF,AF'               ; Return to the primary accumulator pair
    EXX                     ; Select the polluted shadow register bank
    POP HL                  ; Restore the caller's shadow HL pair
    POP DE                  ; Restore the caller's shadow DE pair
    POP BC                  ; Restore the caller's shadow BC pair
    EXX                     ; Return to the primary register bank
    POP IY                  ; Restore the caller's original IY state
    POP IX                  ; Restore the caller's original IX state
    POP HL                  ; Restore the caller's primary HL pair
    POP DE                  ; Restore the caller's primary DE pair
    POP BC                  ; Restore the caller's primary BC pair
    POP AF                  ; Restore accumulator and original flags
ClIffSet:
    DB $F3                  ; Patched to entry DI/EI without clobbering AF
    RET                     ; Return through the original caller frame

; --- Private Host-State Snapshot ---
ClSaveSP:
    DW 0                    ; Stack pointer below the saved register frame
ClMmu2:
    DB 0                    ; Entry MMU slot 2 bank
ClMmu3:
    DB 0                    ; Entry MMU slot 3 bank
ClMmu4:
    DB 0                    ; Entry MMU slot 4 bank
ClMmu5:
    DB 0                    ; Entry MMU slot 5 bank holding the stack
ClSpeed:
    DB 0                    ; Entry CPU-speed register
ClLayer:
    DB 0                    ; Entry layer-priority register
ClL2Ctl:
    DB 0                    ; Entry Layer 2 mode register
ClPalCt:
    DB 0                    ; Entry palette-control register
ClPalIx:
    DB 0                    ; Entry palette-index cursor
ClL2Bnk:
    DB 0                    ; Entry visible Layer 2 bank
ClL2Shd:
    DB 0                    ; Entry shadow Layer 2 bank
ClScrXL:
    DB 0                    ; Entry Layer 2 X-scroll low byte
ClScrXH:
    DB 0                    ; Entry Layer 2 X-scroll high bit
ClScrY:
    DB 0                    ; Entry Layer 2 Y-scroll byte
ClLineOf:
    DB 0                    ; Entry raster-line offset
ClDisp:
    DB 0                    ; Entry Layer 2 and legacy display state
