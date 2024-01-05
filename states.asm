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
    .word restoreScreen
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
    #callStateFunc 1

callEnterFunc
    #callStateFunc 3

callLeaveFunc
    #callStateFunc 5
