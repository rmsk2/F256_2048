.include "points.asm"

PlayField_t .struct 
    playField .fill 16
    points .dstruct PointsBCD_t              ; uses big endian!
.ends

movePlayfieldAddr .macro src, target
    #move16Bit \src, PLAYFIELD_PTR1
    #move16Bit \target, PLAYFIELD_PTR2
    jsr playField.copy
.endmacro

MOVE_VERT_LEFT = %00000001
MOVE_HOR_LEFT =  %00000010

playfield .namespace

PLAY_FIELD .dstruct PlayField_t
FIELD_CHECK .dstruct PlayField_t

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
    stz PLAY_FIELD.points.hh
    stz PLAY_FIELD.points.hl
    stz PLAY_FIELD.points.lh
    stz PLAY_FIELD.points.ll
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

; set carry, if a 2048 cell is on the playing field
check2048
    lda #11
    jsr findValue
    cpx #16
    beq _notWon
    sec
    rts
_notWon
    clc
    rts

check8192
    ; no moves are left, when an 8192 tile appears on the
    ; playing field. We are simply running out of sprites to 
    ; display ;-)
    phx
    lda #13
    jsr findValue
    cpx #16
    plx
    rts

; if carry is set the two fields are equal
compare
    #load16BitImmediate PLAY_FIELD.playField, PLAYFIELD_PTR1
    #load16BitImmediate FIELD_CHECK.playField, PLAYFIELD_PTR2
    ldy #0
_loop
    lda (PLAYFIELD_PTR1), y
    cmp (PLAYFIELD_PTR2), y
    bne _notEqual                          
    iny
    cpy #16
    bne _loop
    sec
    rts
_notEqual
    clc
    rts


save
    #load16BitImmediate PLAY_FIELD, PLAYFIELD_PTR1
    #load16BitImmediate FIELD_CHECK, PLAYFIELD_PTR2
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


;--------------------------------------------------
; calcPlayFieldOffsetTransposed calculates the offset of the position y,x 
; 
; INPUT:  x-pos (0-3) in register X, y-pos (0-3) in accu
;         X and A are not changed by this call
; OUTPUT: offset in register Y
; --------------------------------------------------
calcPlayFieldOffsetTransposed
    sta SCRATCH    ; save y-pos
    phx            ; save x-pos
    txa            ; calc x-pos * 4
    asl            ; * 2
    asl            ; * 2
    clc
    adc SCRATCH    ; add y-pos to row base address
    tay            ; move result to y
    plx            ; restore x register
    lda SCRATCH

    rts


TRANSPOSE_BUFFER .fill 16

XCOUNT .byte ?
YCOUNT .byte ?
CELL_VAL .byte ?

transpose
    stz YCOUNT
_loopY
    stz XCOUNT
_loopX
    ldx XCOUNT
    lda YCOUNT
    jsr calcPlayFieldOffset                  ; calc offset for x, y
    lda PLAY_FIELD.playField, y              ; load untransposed cell
    sta CELL_VAL                             ; save cell value
    lda YCOUNT                               ; reload y value
    jsr calcPlayFieldOffsetTransposed        ; calc transposed offest
    lda CELL_VAL                             ; reload cell value
    sta TRANSPOSE_BUFFER, y                  ; store at transposed location
    inc XCOUNT                               
    lda XCOUNT
    cmp #4                                   ; loop over x value
    bne _loopX
    inc YCOUNT
    lda YCOUNT
    cmp #4
    bne _loopY                               ; loop over y value
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


draw
    lda #18
    sta RECT_PARAMS.xpos
    lda #9
    sta RECT_PARAMS.ypos
    lda #4*9
    sta RECT_PARAMS.lenx
    lda #4*9
    sta RECT_PARAMS.leny
    lda #DRAW_FALSE
    sta RECT_PARAMS.overwrite
    lda GLOBAL_STATE.globalCol
    sta RECT_PARAMS.col
    jsr txtrect.drawRect

    ldy #0
_nextCell
    tya
    jsr sprites.callSetSpritePointer
    lda PLAY_FIELD.playField, y    
    jsr sprites.setBitmapAddr
    iny
    cpy #16
    bne _nextCell

    rts

; PLAYFIELD_PTR1 => address of buffer to check
; carry set means a move is possible
checkBufferMoves
    ldy #0
_checkRow
    ldx #0
_nextCheck
    lda (PLAYFIELD_PTR1), y
    iny
    cmp (PLAYFIELD_PTR1), y
    beq _done                                         ; carry is set when equal
    inx
    cpx #3
    bne _nextCheck
    iny
    cpy #16
    bne _checkRow
    clc
_done
    rts

CHECK_MOVE_RESULT .byte ?
; Upon return the accu contains two flags which indicates a move is possible 
; vertically or horizontally
anyMovesLeft
    lda #MOVE_HOR_LEFT | MOVE_VERT_LEFT             ; if there is a free cell there is at least a move left
    sta CHECK_MOVE_RESULT
    lda #0
    jsr findValue
    cpx #16
    bcc _movesLeft
    ; here we know that all cells are occupied
    ; check whether move is possible in horizontal direction (left/right)
    #load16BitImmediate PLAY_FIELD.playField, PLAYFIELD_PTR1
    jsr checkBufferMoves
    bcs _checkVert
    lda CHECK_MOVE_RESULT
    and #~MOVE_HOR_LEFT
    sta CHECK_MOVE_RESULT
_checkVert
    jsr transpose
    #load16BitImmediate TRANSPOSE_BUFFER, PLAYFIELD_PTR1
    ; check whether move is possible in vertical direction (up/down)
    jsr checkBufferMoves
    bcs _movesLeft
    lda CHECK_MOVE_RESULT
    and #~MOVE_VERT_LEFT
    sta CHECK_MOVE_RESULT
_movesLeft
    lda CHECK_MOVE_RESULT
    rts

evalHighScore
    #pointsCompare GLOBAL_STATE.highScore, PLAY_FIELD.points
    bcs _done
    #pointsMove PLAY_FIELD.points, GLOBAL_STATE.highScore
_done
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
    lda PLAY_FIELD.points.ll
    adc POWERS_TABLE_BCD,X
    sta PLAY_FIELD.points.ll
    dex                    ; x now contains offset of the most significant digits of the point value
    ; add point value to "medium" significant digits of result counter
    lda PLAY_FIELD.points.lh
    adc POWERS_TABLE_BCD,X
    sta PLAY_FIELD.points.lh
    ; add carry to most significant digits of result counter
    lda PLAY_FIELD.points.hl
    adc #00
    sta PLAY_FIELD.points.hl
    lda PLAY_FIELD.points.hh
    adc #00
    sta PLAY_FIELD.points.hh

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