; ==============================================================================
; 256-Entry Signed Sine Table (-127 to +127) - Universal Library
; Angles: 0 to 255 representing 0 to 360 degrees.
; Cosine: Read with an index offset of +64: AngleCos = (AngleSin + 64) & 255
; Astrum & Sjasmplus compatible format (8-bit two's complement bytes).
; To align table to page boundary ($xx00), place at known boundary or use DS.
; Astrum / 8-Bit Lookup Pattern:
;   LD HL,SineTab           ; HL = table base ($xx00)
;   LD L,Angle              ; L = angle (0..255)
;   LD A,(HL)               ; A = Sin(Angle)
; ==============================================================================

SineTab:
    DB    0,   3,   6,   9,  12,  16,  19,  22  ; Angles   0..  7 (Quadrant 1)
    DB   25,  28,  31,  34,  37,  40,  43,  46  ; Angles   8.. 15 (Quadrant 1)
    DB   49,  51,  54,  57,  60,  63,  65,  68  ; Angles  16.. 23 (Quadrant 1)
    DB   71,  73,  76,  78,  81,  83,  85,  88  ; Angles  24.. 31 (Quadrant 1)
    DB   90,  92,  94,  96,  98, 100, 102, 104  ; Angles  32.. 39 (Quadrant 1)
    DB  106, 107, 109, 111, 112, 113, 115, 116  ; Angles  40.. 47 (Quadrant 1)
    DB  117, 118, 120, 121, 122, 122, 123, 124  ; Angles  48.. 55 (Quadrant 1)
    DB  125, 125, 126, 126, 126, 127, 127, 127  ; Angles  56.. 63 (Peak +127)
    DB  127, 127, 127, 127, 126, 126, 126, 125  ; Angles  64.. 71 (Quadrant 2)
    DB  125, 124, 123, 122, 122, 121, 120, 118  ; Angles  72.. 79 (Quadrant 2)
    DB  117, 116, 115, 113, 112, 111, 109, 107  ; Angles  80.. 87 (Quadrant 2)
    DB  106, 104, 102, 100,  98,  96,  94,  92  ; Angles  88.. 95 (Quadrant 2)
    DB   90,  88,  85,  83,  81,  78,  76,  73  ; Angles  96..103 (Quadrant 2)
    DB   71,  68,  65,  63,  60,  57,  54,  51  ; Angles 104..111 (Quadrant 2)
    DB   49,  46,  43,  40,  37,  34,  31,  28  ; Angles 112..119 (Quadrant 2)
    DB   25,  22,  19,  16,  12,   9,   6,   3  ; Angles 120..127 (Quadrant 2)
    DB    0, 253, 250, 247, 244, 240, 237, 234  ; Angles 128..135 (Quadrant 3, -3..-22)
    DB  231, 228, 225, 222, 219, 216, 213, 210  ; Angles 136..143 (Quadrant 3, -25..-46)
    DB  207, 205, 202, 199, 196, 193, 191, 188  ; Angles 144..151 (Quadrant 3, -49..-68)
    DB  185, 183, 180, 178, 175, 173, 171, 168  ; Angles 152..159 (Quadrant 3, -71..-88)
    DB  166, 164, 162, 160, 158, 156, 154, 152  ; Angles 160..167 (Quadrant 3, -90..-104)
    DB  150, 149, 147, 145, 144, 143, 141, 140  ; Angles 168..175 (Quadrant 3, -106..-116)
    DB  139, 138, 136, 135, 134, 134, 133, 132  ; Angles 176..183 (Quadrant 3, -117..-124)
    DB  131, 131, 130, 130, 130, 129, 129, 129  ; Angles 184..191 (Trough -127)
    DB  129, 129, 129, 129, 130, 130, 130, 131  ; Angles 192..199 (Quadrant 4, -127..-125)
    DB  131, 132, 133, 134, 134, 135, 136, 138  ; Angles 200..207 (Quadrant 4, -125..-118)
    DB  139, 140, 141, 143, 144, 145, 147, 149  ; Angles 208..215 (Quadrant 4, -117..-107)
    DB  150, 152, 154, 156, 158, 160, 162, 164  ; Angles 216..223 (Quadrant 4, -106..-92)
    DB  166, 168, 171, 173, 175, 178, 180, 183  ; Angles 224..231 (Quadrant 4, -90..-73)
    DB  185, 188, 191, 193, 196, 199, 202, 205  ; Angles 232..239 (Quadrant 4, -71..-51)
    DB  207, 210, 213, 216, 219, 222, 225, 228  ; Angles 240..247 (Quadrant 4, -49..-28)
    DB  231, 234, 237, 240, 244, 247, 250, 253  ; Angles 248..255 (Quadrant 4, -25..-3)
