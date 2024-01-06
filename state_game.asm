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
    jsr printPoints

    #getTimestamp ST_2048_DATA.tsStart
    jsr showTime
    jsr setTimerClockTick
    rts

eventLoop
    jsr snes.querySnesPad    
    cmp #$FF
    beq _noteNeutral
    jsr testSnesPad
    bra _doKernelStuff
_noteNeutral
    sta LAST_SNES_VALUE
_doKernelStuff    
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
    cmp #kernel.event.timer.EXPIRED
    beq _timerEvent
    cmp #kernel.event.JOYSTICK
    bne _querySnesPad
    jsr testJoyStick
    bra eventLoop
_querySnesPad
;    jsr testSnesPad
    bra eventLoop
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
    jmp eventLoop
_testCursorRight
    cmp #6
    beq _shiftRight
    jmp eventLoop
_shiftRight
    ldx #6
    jsr performOperation
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


testJoyStick
    lda myEvent.joystick.joy0
    cmp #1    
    bne _checkDown
    ldx #0
    jsr performOperation
    bra _done    
_checkDown
    cmp #2
    bne _checkLeft
    ldx #2
    jsr performOperation
    bra _done
_checkLeft
    cmp #4
    bne _checkRight
    ldx #4
    jsr performOperation
    bra _done
_checkRight
    cmp #8
    bne _done
    ldx #6
    jsr performOperation
_done    
    rts

LAST_SNES_VALUE .byte 0

testSnesPad    
    cmp LAST_SNES_VALUE
    beq _done
    sta LAST_SNES_VALUE
    cmp #%11110111
    bne _checkDown
    ldx #0
    jsr performOperation
    bra _done
_checkDown
    cmp #%11111011
    bne _checkLeft
    ldx #2
    jsr performOperation
    bra _done
_checkLeft
    cmp #%11111101
    bne _checkRight
    ldx #4
    jsr performOperation
    bra _done
_checkRight
    cmp #%11111110
    bne _done
    ldx #6
    jsr performOperation
_done
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

; x-reg = 0 => Shift Up
; x-reg = 2 => Shift Down
; x-reg = 4 => Shift Left
; x-reg = 6 => Shift Right
performOperation
    jsr playfield.save
    jsr performShift
    jsr printPoints
    jsr playfield.compare
    bcs _invalidMove
    jsr playfield.placeNewElement
    jsr playfield.draw
    jsr playfield.anyMovesLeft
    bne _done
    jsr printGameOver
    bra _reallyOver
_done
    jsr checkWin
_reallyOver    
    rts
_invalidMove
    jsr sid.beepIllegal
    jsr sid.beepOff
    rts


TXT_POINTS .text "Points: "

printBcdByte .macro addr 
    lda \addr
    jsr splitByte
    tay
    lda HEX_CHARS, y
    jsr txtio.charOut
    lda HEX_CHARS, x
    jsr txtio.charOut
.endmacro

printPoints
    #locate 29, 13
    lda GLOBAL_STATE.globalCol
    sta CURSOR_STATE.col
    #printString TXT_POINTS, len(TXT_POINTS)
    #printBcdByte playfield.PLAY_FIELD.points
    #printBcdByte playfield.PLAY_FIELD.points+1
    #printBcdByte playfield.PLAY_FIELD.points+2
    #printBcdByte playfield.PLAY_FIELD.points+3
    rts

GAME_OVER .text "          GAME OVER!          "

printGameOver
    #locate 22, 40
    lda GLOBAL_STATE.globalCol
    sta CURSOR_STATE.col
    #printString GAME_OVER, len(GAME_OVER) 
    rts


TXT_WIN .text "YOU WIN!"

checkWin
    jsr playfield.check2048
    bcc _done
    #locate 33, 40
    lda GLOBAL_STATE.globalCol
    sta CURSOR_STATE.col
    #printString TXT_WIN, len(TXT_WIN) 
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