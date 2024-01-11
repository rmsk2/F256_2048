Undo_t .struct 
    playfield .dstruct Playfield_t
    hiscore .dstruct PointsBCD_t
.endstruct

LAST_STATE .dstruct Undo_t

saveState .macro plfAddr, undoAddr
    #load16BitImmediate \plfAddr, UNDO_PTR1
    #load16BitImmediate \undoAddr, UNDO_PTR3
    jsr undo.saveStateCall
.endmacro 

restoreState .macro undoAddr, plfAddr
    #load16BitImmediate \plfAddr, UNDO_PTR3
    #load16BitImmediate \undoAddr, UNDO_PTR1
    jsr undo.restoreStateCall
.endmacro

undo .namespace

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

.endnamespace