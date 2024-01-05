.include "txtrect.asm"

st_2048 .namespace

NO_STOP = 0
DO_STOP = 1

State2048_t .struct
    tsStart .dstruct TimeStamp_t, 0, 0, 0
    doStop .byte 0
.ends

ST_2048_DATA .dstruct State2048_t


enterState
    lda GLOBAL_STATE.globalCol
    sta CURSOR_STATE.col
    lda #NO_STOP 
    sta ST_2048_DATA.doStop
    jsr txtio.clear

    jsr playfield.init
    jsr playField.placeNewElement
    jsr playfield.placeNewElement
    jsr playfield.draw

    #getTimestamp ST_2048_DATA.tsStart
    jsr showTime
    jsr setTimerClockTick
    rts


eventLoop
    lda ST_2048_DATA.doStop
    beq _noStop
    #setstate S_START
    jmp _endEvent
_noStop
    ; Peek at the queue to see if anything is pending
    lda kernel.args.events.pending ; Negated count
    bpl eventLoop
    ; Get the next event.
    jsr kernel.NextEvent
    bcs eventLoop
    ; Handle the event
    lda myEvent.type    
    cmp #kernel.event.key.PRESSED
    beq _keyPress
    bra _timerExp
_keyPress
    lda myEvent.key.flags 
    and #myEvent.key.META
    bne eventLoop
    lda myEvent.key.ascii
    cmp #KEY_F1
    bne _testF3
    #setstate S_START
    bra _endEvent
_testF3
    cmp #KEY_F3
    bne _testCursorUp
    #setState S_END
    bra _endEvent
_testCursorUp
    cmp #16
    bne _testCursorDown
    ldx #0
    jsr performOperation
    bra eventLoop
_testCursorDown
    cmp #14
    bne _testCursorLeft
    ldx #2
    jsr performOperation
    bra eventLoop
_testCursorLeft
    cmp #2
    bne _testCursorRight
    ldx #4
    jsr performOperation
    bra eventLoop
_testCursorRight
    cmp #6
    bne _timerExp
    ldx #6
    jsr performOperation
    jmp eventLoop
_timerExp
    cmp #kernel.event.timer.EXPIRED
    beq _timerEvent
    jmp eventLoop
_timerEvent
    lda myEvent.timer.cookie
    cmp TIMER_COOKIE
    beq _cookieMatches
    jmp eventLoop
_cookieMatches
    jsr showTime
    jsr setTimerClockTick
    jmp eventLoop
_endEvent
    rts


leaveState
    rts

JUMP_TAB
.word playfield.shiftUp
.word playfield.shiftDown
.word playfield.shiftLeft
.word playfield.shiftRight

performShift
    jmp (JUMP_TAB, x)


performOperation
    jsr performShift
    jsr playfield.placeNewElement
    jsr playfield.draw
    jsr playfield.anyMovesLeft
    bcc _done
    lda #DO_STOP
    sta ST_2048_DATA.doStop
_done
    rts


TIME_STR .fill 8
CURRENT_TIME .dstruct TimeStamp_t

TEXT_ELAPSED_TIME .text "Elapsed time: "

showTime
    #getTimestamp CURRENT_TIME
    #diffTime ST_2048_DATA.tsStart, CURRENT_TIME
    #getTimeStr TIME_STR, CURRENT_TIME
    #locate 1,1
    lda GLOBAL_STATE.globalCol
    sta CURSOR_STATE.col
    #printString TEXT_ELAPSED_TIME, 14
    #printString TIME_STR, 8
    rts

.endn