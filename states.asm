DO_STOP = 0
DO_NOT_STOP = 1

GameState_t .struct mainLoopVector, enterState, leaveState, dataPtr
    stopFlag  .byte DO_NOT_STOP
    funcMain  .word \mainLoopVector
    funcEnter .word \enterState
    funcLeave .word \leaveState
    stateData .word \dataPtr
.ends

EndState_t .struct
    .byte DO_STOP
    .word dummyFunc
    .word cleanUpFunc
    .word dummyFunc
    .word 0
.ends

setState .macro stateAddr
    jsr callLeaveFunc
    #load16BitImmediate \stateAddr, ZP_STATE_PTR
    jsr callEnterFunc
.endmacro

setStartState .macro stateAddr
    #load16BitImmediate \stateAddr, ZP_STATE_PTR
    jsr callEnterFunc
.endmacro

cleanUpFunc
    jsr restoreScreen
    #pointsCompare GLOBAL_STATE.highScore, GLOBAL_STATE.highScoreAtLoad
    beq _doneNoSave                                         ; highscore unchanged => no save
    ; if the two values are different this means that a new highsore was reached => save
    jsr disk.saveHiScore
    bcc _done
    jsr sid.beepIllegal
    jsr sid.beepOff
    #locate 20, 29
    #printString MSG_SAVE_ERR, len(MSG_SAVE_ERR)
    jsr waitForKey
    rts
_done
    ; wait for 1/10 of a second to give SD card time to write **all** data.
    ; I do not know whether this is necessary, but it does not do any damage
    ; either. And: I am doing this for a reason ;-).
    lda #6
    jsr delay60thSeconds
_doneNoSave
    rts

dummyFunc
    rts

restoreScreen
    lda #$92
    sta CURSOR_STATE.col
    jsr txtio.clear
    jsr txtio.cursorOn
    rts

JMP_VECTOR .word 0

isStateEnd
    ldy #0
    lda (ZP_STATE_PTR), y
    rts

callStateFunc .macro startIndex
    ldy #\startIndex
    lda (ZP_STATE_PTR), y
    sta JMP_VECTOR
    iny
    lda (ZP_STATE_PTR), y
    sta JMP_VECTOR+1
    jmp (JMP_VECTOR)

.endmacro

stateEventLoop
    #callStateFunc GameState_t.funcMain

callEnterFunc
    #callStateFunc GameState_t.funcEnter

callLeaveFunc
    #callStateFunc GameState_t.funcLeave


MSG_SAVE_ERR .text "Unable to save hiscore file. Press <Return>."