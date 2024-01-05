
st_start .namespace

printBigAt .macro x, y, colAddr, addr
    ldx #\x
    ldy #\y    
    #load16BitImmediate \addr, TXT_PTR5
    lda \colAddr
    jsr printBigChar
.endmacro

printBigAtImpl .macro x, y, addr
    ldx #\x
    ldy #\y    
    #load16BitImmediate \addr, TXT_PTR5
    jsr printBigCharImplicitColor
.endmacro

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
    bne eventLoop
    lda myEvent.key.ascii
    cmp #KEY_F1
    beq _startGame
    cmp #KEY_F3
    bne _timerExp
    #setState S_END
    bra _endEvent
_startGame
    #setstate S_GAME
    bra _endEvent
_timerExp
    cmp #kernel.event.timer.EXPIRED
    bne eventLoop
    lda myEvent.timer.cookie
    cmp TIMER_COOKIE
    bne eventLoop
    jsr colorCycle
    jsr setTimerStartScreen
    bra eventLoop
_endEvent
    rts

enterState
    lda #1
    sta ST_START_DATA.cycleCount
    jsr txtio.cursorOff
    lda GLOBAL_STATE.globalCol    
    sta ST_START_DATA.logoCol
    sta CURSOR_STATE.col
    jsr txtio.clear
    #printBigAt 4*8 + 1, 2*8, ST_START_DATA.logoCol, BIG_ONE
    #printBigAt 5*8 - 1, 2*8, ST_START_DATA.logoCol, BIG_ONE
    #printBigAt 3*8 + 2, 3*8, ST_START_DATA.logoCol, BIG_TWO

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

    jsr setTimerStartScreen
    rts

leaveState
    rts

MSG_START_1 .text "Zwei hoch 11, a puzzle game for the Foenix 256K and 256 Jr.", $0d
MSG_START_2 .text "Written by Martin Grap in 2024", $0d
MSG_START_3 .text "To start game press F1", $0d
MSG_START_4 .text "To quit game press  F3", $0d

ST_START_DATA .dstruct StartState_t

BIG_TWO
.byte $20, $20, $20, $20, $20, $20, $20, $20 ; ________
.byte $20, $A0, $A0, $A0, $A0, $A0, $A0, $20 ; _******_
.byte $20, $20, $20, $20, $20, $A0, $A0, $20 ; _____**_
.byte $20, $20, $20, $20, $20, $A0, $A0, $20 ; _____**_
.byte $20, $A0, $A0, $A0, $A0, $A0, $A0, $20 ; _******_
.byte $20, $A0, $A0, $20, $20, $20, $20, $20 ; _**_____
.byte $20, $A0, $A0, $20, $20, $20, $20, $20 ; _**_____
.byte $20, $A0, $A0, $A0, $A0, $A0, $A0, $20 ; _******_

BIG_ONE
.byte $20, $20, $20, $20, $20, $20, $20, $20 ; ________
.byte $20, $20, $20, $A0, $A0, $20, $20, $20 ; ___**___
.byte $20, $20, $A0, $A0, $A0, $20, $20, $20 ; __***___
.byte $20, $20, $20, $A0, $A0, $20, $20, $20 ; ___**___
.byte $20, $20, $20, $A0, $A0, $20, $20, $20 ; ___**___
.byte $20, $20, $20, $A0, $A0, $20, $20, $20 ; ___**___
.byte $20, $20, $20, $A0, $A0, $20, $20, $20 ; ___***__
.byte $20, $20, $A0, $A0, $A0, $A0, $20, $20 ; __****__

BigCharState_t .struct 
    xCoord .byte 0
    yCoord .byte 0
    lineCount .byte 0
    col .byte 0
    revCol .byte 0
    fgCol .byte 0
    bgCol .byte 0
    temp .byte 0
.ends

BIG_CHAR_STATE .dstruct BigCharState_t

colorCycle
    jsr incForegroundCol
    #printBigAtImpl 4*8 + 1, 2*8, BIG_ONE
    #printBigAtImpl 5*8 - 1, 2*8, BIG_ONE
    #printBigAtImpl 3*8 + 2, 3*8, BIG_TWO
    rts

incForegroundCol
    lda BIG_CHAR_STATE.fgCol
    ina
    and #$0F
    sta BIG_CHAR_STATE.fgCol
    asl
    asl
    asl
    asl
    ora BIG_CHAR_STATE.bgCol
    sta BIG_CHAR_STATE.col
    lda BIG_CHAR_STATE.bgCol
    asl
    asl
    asl
    asl
    ora BIG_CHAR_STATE.fgCol
    sta BIG_CHAR_STATE.revCol
    rts

; accu => Color value
setBigCharCol
    sta BIG_CHAR_STATE.col
    and #$0F
    sta BIG_CHAR_STATE.bgCol
    asl
    asl
    asl
    asl
    sta BIG_CHAR_STATE.temp    
    lda BIG_CHAR_STATE.col
    lsr
    lsr
    lsr
    lsr
    sta BIG_CHAR_STATE.fgCol
    ora BIG_CHAR_STATE.temp
    sta BIG_CHAR_STATE.revCol
    rts

; x => x coord
; y => y coord
printBigCharImplicitColor
    stx BIG_CHAR_STATE.xCoord
    sty BIG_CHAR_STATE.yCoord
    stz BIG_CHAR_STATE.lineCount
    jmp cycleBigChar    

; x => x coord
; y => y coord
; accu => color code
; char data in address in TXT_PTR5
printBigChar
    stx BIG_CHAR_STATE.xCoord
    sty BIG_CHAR_STATE.yCoord
    stz BIG_CHAR_STATE.lineCount
    jsr setBigCharCol
cycleBigChar
    ldy #0
_lineDone
    lda BIG_CHAR_STATE.xCoord
    sta CURSOR_STATE.xPos
    lda BIG_CHAR_STATE.yCoord
    sta CURSOR_STATE.yPos
    jsr txtio.cursorSet
    ldx #0
_lineLoop
    lda (TXT_PTR5), y
    cmp #$A0
    beq _normal
    lda BIG_CHAR_STATE.col
    bra _outChar
_normal
    lda BIG_CHAR_STATE.revCol
_outChar    
    sta CURSOR_STATE.col
    lda #32
    jsr txtio.charOut
    iny
    inx
    cpx #08
    bne _lineLoop
    inc BIG_CHAR_STATE.yCoord
    inc BIG_CHAR_STATE.lineCount
    lda BIG_CHAR_STATE.lineCount
    cmp #8
    bne _lineDone
    rts

.endn