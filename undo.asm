UNDO_CAPACITY = 20

Undo_t .struct 
    playfield .dstruct Playfield_t
    hiscore .dstruct PointsBCD_t
.endstruct

RingBuffer_t .struct addr
    data .word \addr
    topElem .word ?
    len .byte 0
    top .byte 0
.endstruct

LAST_STATE .dstruct Undo_t

saveState .macro plfAddr, undoAddr
    #load16BitImmediate \plfAddr, UNDO_PTR1
    #load16BitImmediate \undoAddr, UNDO_PTR3
    jsr undo.saveStateCall
.endmacro 

undo .namespace

RING_BUFFER .dstruct RingBuffer_t, UNDO_DATA

UNDO_DATA .fill UNDO_CAPACITY * size(Undo_t)

init
    stz RING_BUFFER.len
    stz RING_BUFFER.top
    rts


; UNDO_PTR1 => address of playfield to save
; UNDO_PTR3 => address of target Undo_t
saveStateCall
    #movePlayfieldAddr UNDO_PTR1, UNDO_PTR3
    #load16BitImmediate GLOBAL_STATE.highScore, PLAYFIELD_PTR1
    clc
    lda UNDO_PTR3
    adc #<size(PlayField_t)
    sta PLAYFIELD_PTR2
    lda UNDO_PTR3+1
    adc #>size(PlayField_t)
    sta PLAYFIELD_PTR2+1
    jsr points.move
    rts


; UNDO_PTR1 => address of saved state as Undo_t
; UNDO_PTR3 => address of Playfield_t to restore to
restoreStateCall
    #movePlayfieldAddr UNDO_PTR1, UNDO_PTR3
    #load16BitImmediate GLOBAL_STATE.highScore, PLAYFIELD_PTR2
    clc
    lda UNDO_PTR1
    adc #<size(PlayField_t)
    sta PLAYFIELD_PTR1
    lda UNDO_PTR1+1
    adc #>size(PlayField_t)
    sta PLAYFIELD_PTR1+1
    jsr points.move

    rts

MOD_HELP .dstruct ModN_t

; --------------------------------------------------
; This macro calculates A++ mod N. We have to use 16 bit arithmetic
; 
; It returns the result in the accu. Carry is set if an overflow occured.
; --------------------------------------------------
incModCap
    ldx #1
    #addModN2 UNDO_CAPACITY, MOD_HELP
    rts

; --------------------------------------------------
; This macro calculates A-- mod N. We have to use 16 bit arithmetic
; 
; It returns the result in the accu. Carry is set if an overflow occured.
; --------------------------------------------------
decModCap
    ldx #1
    #subModN2 UNDO_CAPACITY, MOD_HELP
    rts


moveLastState
    ldy #size(Undo_t)
_copy
    lda LAST_STATE, y
    sta (UNDO_PTR1), y
    dey
    bpl _copy
    rts 


calcDataAddress
    #load16BitImmediate size(Undo_t), $DE00
    lda RING_BUFFER.top
    sta $DE02
    stz $DE03
    clc
    lda $DE10
    adc RING_BUFFER.data
    sta RING_BUFFER.topElem
    lda $DE11
    adc RING_BUFFER.data + 1
    sta RING_BUFFER.topElem + 1
    rts


pushState
    jsr calcDataAddress
    #move16Bit RING_BUFFER.topElem, UNDO_PTR1
    jsr moveLastState
    lda RING_BUFFER.top
    jsr incModCap
    sta RING_BUFFER.top
    lda RING_BUFFER.len
    cmp #UNDO_CAPACITY
    bne _stillRoom
    bra _done
_stillRoom
    inc RING_BUFFER.len
_done
    rts


; carry set on return if ring buffer is empty
popState
    lda RING_BUFFER.len
    beq _errEnd
    lda RING_BUFFER.top
    jsr decModCap
    sta RING_BUFFER.top
    jsr calcDataAddress
    #load16BitImmediate playfield.PLAY_FIELD, UNDO_PTR3
    #move16Bit RING_BUFFER.topElem, UNDO_PTR1
    jsr restoreStateCall
    dec RING_BUFFER.len
    clc
    rts
_errEnd
    sec
    rts

.endnamespace