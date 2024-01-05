PlayField_t .struct 
    playField .fill 16
    points .fill 4                ; uses big endian!
.ends

playfield .namespace

PLAY_FIELD .dstruct PlayField_t

POWERS_TABLE_BCD
.byte $00, $02
.byte $00, $04
.byte $00, $08
.byte $00, $16
.byte $00, $32
.byte $00, $64
.byte $01, $28
.byte $02, $56
.byte $05, $12
.byte $10, $24
.byte $20, $48
.byte $40, $96
.byte $81, $92

init
    jsr clear
    lda #0
    sta PLAY_FIELD.points
    sta PLAY_FIELD.points + 1
    sta PLAY_FIELD.points + 2
    sta PLAY_FIELD.points + 3
    rts

; set all values in playing field to zero
clear
    ldx #0
    lda #0
_loop
    sta PLAY_FIELD.playField,x
    inx
    cpx #16
    bne _loop
    rts

TEMP .byte ?

; search value given in accu in playfield
; Return first found position in x register or 16 if not found
findValue
    ldx #0
    sta TEMP
_loop
    lda PLAY_FIELD.playField,x
    cmp TEMP
    beq _done
    inx
    cpx #16
    bne _loop
_done
    rts

movePlayfield .macro src, target
    #load16BitImmediate \src, PLAYFIELD_PTR1
    #load16BitImmediate \target, PLAYFIELD_PTR2
    jsr copy
.endmacro

movePlayfieldAddr .macro src, target
    #move16Bit \src, PLAYFIELD_PTR1
    #move16Bit \target, PLAYFIELD_PTR2
    jsr copy
.endmacro


copy
    ldy #0
_loop
    lda (PLAYFIELD_PTR1), y
    sta (PLAYFIELD_PTR2), y
    iny
    cpy #size(PlayField_t)
    bne _loop
    rts


SCRATCH .byte $00
;--------------------------------------------------
; calcPlayFieldOffset calculates the offset of the position x,y 
; 
; INPUT:  x-pos (0-3) in register X, y-pos (0-3) in accu
;         X and A are not changed by this call
; OUTPUT: offset in register Y
; --------------------------------------------------
calcPlayFieldOffset
    pha            ; save accu
    asl            ; * 2
    asl            ; * 2
    stx SCRATCH    ; x-pos in temp memory
    clc
    adc SCRATCH    ; add x-pos to row base address
    tay            ; move result to y
    pla            ; restore accu
     
    rts


; places new "2" on the playing field. Carry is set upon an error
placeNewElement
    ; is there a free spot?
    lda #0
    jsr findValue
    cpx #16
    bcs _done
    ; yes. We had to check that in order to prevent an infinite loop
_retry
    jsr random.get
    ldx #0
_nextNibble
    ldy random.RAND_NIBBLES, x
    lda PLAY_FIELD.playField, y
    beq _spotFound
    inx 
    cpx #4
    bne _nextNibble
    bra _retry
_spotFound
    lda #1
    sta PLAY_FIELD.playField, y
    clc
_done
    rts


DrawParam_t .struct x, y
    xpos .byte \x
    ypos .byte \y
.endstruct

CELL_WIDTH = 7
CELL_HEIGHT = 6
UPPER_LEFT_X = 22 + 1
UPPER_LEFT_Y = 14 + 1


TAB0 .dstruct DrawParam_t, UPPER_LEFT_X, UPPER_LEFT_Y
TAB1 .dstruct DrawParam_t, UPPER_LEFT_X + CELL_WIDTH, UPPER_LEFT_Y
TAB2 .dstruct DrawParam_t, UPPER_LEFT_X + 2 * CELL_WIDTH, UPPER_LEFT_Y
TAB3 .dstruct DrawParam_t, UPPER_LEFT_X + 3 * CELL_WIDTH, UPPER_LEFT_Y

TAB4 .dstruct DrawParam_t, UPPER_LEFT_X, UPPER_LEFT_Y + CELL_HEIGHT
TAB5 .dstruct DrawParam_t, UPPER_LEFT_X + CELL_WIDTH, UPPER_LEFT_Y + CELL_HEIGHT
TAB6 .dstruct DrawParam_t, UPPER_LEFT_X + 2 * CELL_WIDTH, UPPER_LEFT_Y + CELL_HEIGHT
TAB7 .dstruct DrawParam_t, UPPER_LEFT_X + 3 * CELL_WIDTH, UPPER_LEFT_Y + CELL_HEIGHT

TAB8 .dstruct DrawParam_t, UPPER_LEFT_X, UPPER_LEFT_Y + 2 * CELL_HEIGHT
TAB9 .dstruct DrawParam_t, UPPER_LEFT_X + CELL_WIDTH, UPPER_LEFT_Y + 2 * CELL_HEIGHT
TAB10 .dstruct DrawParam_t, UPPER_LEFT_X + 2 * CELL_WIDTH, UPPER_LEFT_Y + 2 * CELL_HEIGHT
TAB11 .dstruct DrawParam_t, UPPER_LEFT_X + 3 * CELL_WIDTH, UPPER_LEFT_Y + 2 * CELL_HEIGHT

TAB12 .dstruct DrawParam_t, UPPER_LEFT_X, UPPER_LEFT_Y + 3 * CELL_HEIGHT
TAB13 .dstruct DrawParam_t, UPPER_LEFT_X + CELL_WIDTH, UPPER_LEFT_Y + 3 * CELL_HEIGHT
TAB14 .dstruct DrawParam_t, UPPER_LEFT_X + 2 * CELL_WIDTH, UPPER_LEFT_Y + 3 * CELL_HEIGHT
TAB15 .dstruct DrawParam_t, UPPER_LEFT_X + 3 * CELL_WIDTH, UPPER_LEFT_Y + 3 * CELL_HEIGHT

TextParams_t .struct x, y, txt
    xpos .byte \x
    ypos .byte \y
.endstruct

TEXT_TAB
.text "    "
.text "  2 "
.text "  4 "
.text "  8 "
.text " 16 "
.text " 32 "
.text " 64 "
.text "128 "
.text "256 "
.text "512 "
.text "1024"
.text "2048"
.text "8192"

ADDR_HELP .byte 0, 0

draw
    lda #22
    sta RECT_PARAMS.xpos
    lda #14
    sta RECT_PARAMS.ypos
    lda #4*7-1
    sta RECT_PARAMS.lenx
    lda #4*6-1
    sta RECT_PARAMS.leny
    lda #DRAW_FALSE
    sta RECT_PARAMS.overwrite
    lda GLOBAL_STATE.globalCol
    sta RECT_PARAMS.col
    jsr txtrect.drawRect

    ldy #0
_nextCell
    tya
    asl
    tax
    lda TAB0, x
    sta RECT_PARAMS.xpos
    inx
    lda TAB0,x
    sta RECT_PARAMS.ypos
    lda #CELL_WIDTH-3
    sta RECT_PARAMS.lenx
    lda #CELL_HEIGHT-3
    sta RECT_PARAMS.leny
    lda #DRAW_TRUE
    sta RECT_PARAMS.overwrite
    lda PLAY_FIELD.playField, y
    sta RECT_PARAMS.col
    phy
    jsr txtrect.clearRect    
    ply

    
    lda RECT_PARAMS.xpos 
    ina
    sta CURSOR_STATE.xPos

    lda RECT_PARAMS.ypos
    ina
    ina
    sta CURSOR_STATE.yPos

    jsr txtio.cursorSet

    lda RECT_PARAMS.col
    sta CURSOR_STATE.col

    lda PLAY_FIELD.playField, y
    beq _skipText
    asl
    asl
    sta ADDR_HELP
    stz ADDR_HELP + 1
    #add16BitImmediate TEXT_TAB, ADDR_HELP
    #move16Bit ADDR_HELP, TXT_PTR3
    lda #4
    phy
    jsr txtio.printStr
    ply
_skipText
    iny
    cpy #16
    bne _nextCell

    rts

; carry clear => There are moves left. Else carry set
anyMovesLeft
    lda #0
    jsr findValue
    cpx #16
    bcc _movesLeft
    ; here we know that all cells are occupied

    sec
_movesLeft
    rts

;--------------------------------------------------
; addPoints adds a new value to the current result using big endian and BCD!
; 
; INPUT:  Value to add to current points as log_2 value 1-13 in accu
; OUTPUT: None
; --------------------------------------------------
addPoints
    ; transform 1-13 to 0-12
    dea
    ; calc offset of 2**(contents of accu)            
    asl                    ; *2
    tax 
    inx                    ; x now contains 2*accu + 1
    sed                    ; use BCD mode. This saves us from doing a hex => dec conversion when rendering the score

    clc
    ; add least significant digits of point value to result counter
    lda PLAY_FIELD.points + 3
    adc POWERS_TABLE_BCD,X
    sta PLAY_FIELD.points + 3
    dex                    ; x now contains offset of the most significant digits of the point value
    ; add point value to "medium" significant digits of result counter
    lda PLAY_FIELD.points + 2
    adc POWERS_TABLE_BCD,X
    sta PLAY_FIELD.points + 2
    ; add carry to most significant digits of result counter
    lda PLAY_FIELD.points + 1
    adc #00
    sta PLAY_FIELD.points + 1
    lda PLAY_FIELD.points
    adc #00
    sta PLAY_FIELD.points

    cld 
    rts


BUFFERIN   .byte $00, $00, $00, $00
BUFFERTEMP .byte $00, $00, $00, $00
TEMPLEN .byte $00

compressBuffer .macro source, target 
    ; Clear target buffer
    ; This macro copies all nonzero bytes from soure to target 
    ; at the end x contains the number of bytes copied
    lda #0             
    sta \target
    sta \target+1
    sta \target+2
    sta \target+3    
    ; remove all zero elements and write result to target
    ldy #0             ; read index
    ldx #0             ; write index
_loop                 
    lda \source, Y     ; load input data
    cmp #0             ; Is it zero?
    beq _next          ; yes, write nothing
    sta \target, X     ; write nonzero value in target buffer
    inx                ; increment write offset
_next
    iny                ; increment read offset
    cpy #4             ; end reached?
    bne _loop         ; no?
.endmacro


;--------------------------------------------------
; shiftRowLeft implements a left shift of a row. All other shifts of rows and 
; columns can be mapped to this. Input and output in BUFFERIN 
; 
; INPUT:  None
; OUTPUT: None
; --------------------------------------------------
shiftRowLeft
    #compressBuffer BUFFERIN, BUFFERTEMP 

    ; X holds number of bytes copied
    cpx #0
    beq _done            ; no bytes were transferred => Input data was all zero. Nothing else to do
    cpx #1               
    beq _doCopy          ; Only one byte was copied, no merging necessary, only copy data back to BUFFERIN

    ; Here BUFFERTEMP contains at least two nonzero elements
    ; perform merging of equal elements
    ; we have a sliding window of length two, that is moved over the conpressed buffer from left to right
    dex                  
    stx TEMPLEN          ; now x contains the last nonzero position in BUFFERTEMP
    ldx #0               ; Begin of sliding window at pos 0
    ldy #1               ; End of sliding window at pos 1
_mergeLoop
    lda BUFFERTEMP, X    ; load frist and second element of window
    cmp BUFFERTEMP, Y
    bne _skip            ; Elements not equal. Move window one position
    lda #0               ; Elements in window are equal, merge them
    sta BUFFERTEMP, y    ; clear second element of window
    inc BUFFERTEMP, X    ; increment first window element

    ; save registers
    phx
    phy

    ; add points
    lda BUFFERTEMP, X
    jsr addPoints
    ; restore registers
    
    ply
    plx

    inx                  ; move window two elements
    inx
    iny
    iny
    cpx TEMPLEN
    bcc _mergeLoop       ; start of window < last pos with nonzero element
    bcs _doCopy          ; start of window >= last pos with zero element
_skip
    inx
    iny
    cpx TEMPLEN         ; has window reached last position?
    bne _mergeLoop      ; no, process next element
    ; x is at last nonzero position, therefore there is no more element to merge with

_doCopy
    #compressBuffer BUFFERTEMP, BUFFERIN
_done
    rts


reverse .macro buffer
    lda \buffer
    ldy \buffer+3
    sta \buffer+3
    sty \buffer
    lda \buffer+1
    ldy \buffer+2
    sta \buffer+2
    sty \buffer+1    
.endmacro


;--------------------------------------------------
; shiftRowRight implements a right shift of a row.
; Input and output in BUFFERIN 
; 
; INPUT:  None
; OUTPUT: None
; --------------------------------------------------
shiftRowRight
    #reverse BUFFERIN
    jsr shiftRowLeft
    #reverse BUFFERIN

    rts


ROWCOUNT .byte $00
COLCOUNT .byte $00
;--------------------------------------------------
; shiftPlayingField implements shifting the playing field. If .slow is equal to ROWCOUNT then
; the shift is horizontal. If .slow is set to COLCOUNT a vertical shift is performed. The parameter
; shiftCall then determines whether the shift is left/right or up/down. 
; 
; INPUT:  None
; OUTPUT: None
; --------------------------------------------------
shiftPlayingField .macro slow, fast, shiftCall
    lda #0
    sta \slow                    ; .slow is the slow counter
    sta \fast                    ; .fast is the fast counter

_count1CopyLoop
    ; Copy data into BUFFERIN
    lda ROWCOUNT
    ldx COLCOUNT
    jsr calcPlayFieldOffset           ; returns playing field offset in y
    lda PLAY_FIELD.playField, y
    ldx \fast
    sta BUFFERIN, X
    inc \fast
    lda \fast
    cmp #04
    bne _count1CopyLoop

    ; perform shift
    jsr \shiftCall

    ; reset fast counter
    lda #00
    sta \fast

    ; copy data back
_count1CopyBack
    lda ROWCOUNT
    ldx COLCOUNT
    jsr calcPlayFieldOffset           ; returns playing field offset in y
    ldx \fast
    lda BUFFERIN, x
    sta PLAY_FIELD.playField, Y
    inc \fast
    lda \fast
    cmp #04
    bne _count1CopyBack

    ; reset fast counter
    lda #00
    sta \fast

    ; increment and test slow counter
    inc \slow
    lda \slow
    cmp #04
    bne _count1CopyLoop
.endmacro

shiftLeft
    #shiftPlayingField ROWCOUNT, COLCOUNT, shiftRowLeft
    rts

shiftRight
    #shiftPlayingField ROWCOUNT, COLCOUNT, shiftRowRight
    rts

shiftUp
    #shiftPlayingField COLCOUNT, ROWCOUNT, shiftRowLeft
    rts

shiftDown
    #shiftPlayingField COLCOUNT, ROWCOUNT, shiftRowRight
    rts

.endnamespace