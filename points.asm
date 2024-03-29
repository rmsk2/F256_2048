PointsBCD_t .struct 
    hh .byte 0                ; high high byte
    hl .byte 0                ; high lo byte
    lh .byte 0                ; lo high byte
    ll .byte 0                ; lo lo byte
.endstruct

pointsCompare .macro addr1, addr2
    #load16BitImmediate \addr1, PLAYFIELD_PTR1
    #load16BitImmediate \addr2, PLAYFIELD_PTR2
    jsr points.compare
.endmacro

pointsMove .macro addr1, addr2
    #load16BitImmediate \addr1, PLAYFIELD_PTR1
    #load16BitImmediate \addr2, PLAYFIELD_PTR2
    jsr points.move
.endmacro


points .namespace

clear
    ldy #size(PointsBCD_t)-1
    lda #0
_loop
    sta (PLAYFIELD_PTR1), y
    dey
    bpl _loop
    rts

; Move data to which PLAYFIELD_PTR1 points to the loaction to
; which PLAYFIELD_PTR2 points
move 
    ldy #0
    lda (PLAYFIELD_PTR1), y
    sta (PLAYFIELD_PTR2), y
    iny ; 1
    lda (PLAYFIELD_PTR1), y
    sta (PLAYFIELD_PTR2), y
    iny ; 2
    lda (PLAYFIELD_PTR1), y
    sta (PLAYFIELD_PTR2), y
    iny ; 3
    lda (PLAYFIELD_PTR1), y
    sta (PLAYFIELD_PTR2), y
    rts

; Compare the value to which PLAYFIELD_PTR1 points to the value
; to which PLAYFIELD_PTR2 points.
; Carry is clear if *PLAYFIELD_PTR1 < *PLAYFIELD_PTR2
; Carry is set if *PLAYFIELD_PTR1 >= *PLAYFIELD_PTR2
; Zero flag is set if *PLAYFIELD_PTR1 == *PLAYFIELD_PTR2
compare
    ldy #0
    lda (PLAYFIELD_PTR1), y
    cmp (PLAYFIELD_PTR2), y
    bne _done
    iny ; 1
    lda (PLAYFIELD_PTR1), y
    cmp (PLAYFIELD_PTR2), y
    bne _done
    iny ; 2
    lda (PLAYFIELD_PTR1), y
    cmp (PLAYFIELD_PTR2), y
    bne _done
    iny ; 3
    lda (PLAYFIELD_PTR1), y
    cmp (PLAYFIELD_PTR2), y
_done
    rts

.endnamespace