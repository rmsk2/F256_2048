
st_start .namespace

StartState_t .struct 
    logoCol .byte 0
    cycleCount .byte 0
.ends

eventLoop
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
    beq _checkAscii
    lda myEvent.key.ascii
    jsr testForFKey
    bcc eventLoop
_checkAscii
    lda myEvent.key.ascii
    cmp #KEY_F1
    beq _startGame
    cmp #KEY_F5
    beq _gotoHelp
    cmp #KEY_F3
    bne _timerExp
    #setState S_END
    bra _endEvent
_gotoHelp
    #setState S_HELP
    bra _endEvent
_startGame
    #setstate S_GAME
    bra _endEvent
_timerExp
    cmp #kernel.event.timer.EXPIRED
    bne eventLoop
    lda myEvent.timer.cookie
    cmp TIMER_COOKIE_START
    bne eventLoop
    jsr colorCycle
    jsr setTimerStartScreen
    ; ToDo: Handle error when carry set
    bra eventLoop
_endEvent
    rts

enterState
    lda #1
    sta ST_START_DATA.cycleCount
    jsr txtio.cursorOff
    lda #$20    
    sta ST_START_DATA.logoCol
    lda GLOBAL_STATE.globalCol
    sta CURSOR_STATE.col
    jsr txtio.clear
    #printBigAt 4*8 + 1, 2*8, ST_START_DATA.logoCol, bigchar.BIG_ONE
    #printBigAt 5*8 - 1, 2*8, ST_START_DATA.logoCol, bigchar.BIG_ONE
    #printBigAt 3*8 + 2, 3*8, ST_START_DATA.logoCol, bigchar.BIG_TWO

    lda GLOBAL_STATE.globalCol
    sta CURSOR_STATE.col
    #locate 9, 35
    #printString MSG_START_1, len(MSG_START_1)

    #locate 19, 38
    #printString MSG_START_2, len(MSG_START_2)

    #locate 25, 44
    #printString MSG_START_3, len(MSG_START_3)

    #locate 25, 45
    #printString MSG_START_4, len(MSG_START_4)

    #locate 25, 46
    #printString MSG_START_5, len(MSG_START_5)

    #locate 9, 52
    #printString MSG_START_6, len(MSG_START_6)

    jsr setTimerStartScreen
    rts

leaveState
    rts

MSG_START_1 .text "Zwei hoch 11, a puzzle game for the Foenix 256K and 256 Jr.", $0d
MSG_START_2 .text "Written by Martin Grap in 2024", $0d
MSG_START_3 .text "To start game press F1", $0d
MSG_START_4 .text "Reset to BASIC      F3", $0d
MSG_START_5 .text "Learn how to play   F5", $0d
MSG_START_6 .text "Find the source code at https://github.com/rmsk2/F256_2048", $0d

ST_START_DATA .dstruct StartState_t

colorCycle
    jsr bigchar.incForegroundCol
    #printBigAtImpl 4*8 + 1, 2*8, bigchar.BIG_ONE
    #printBigAtImpl 5*8 - 1, 2*8, bigchar.BIG_ONE
    #printBigAtImpl 3*8 + 2, 3*8, bigchar.BIG_TWO
    rts

.endn