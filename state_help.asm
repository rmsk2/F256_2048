st_help .namespace

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
    bra eventLoop
_keyPress
    lda myEvent.key.flags 
    and #myEvent.key.META
    bne eventLoop
    lda myEvent.key.ascii
    cmp #KEY_F1
    beq _backToStart
    bra eventLoop
_backToStart
    #setstate S_START
    rts

LOGO_COL .byte $30
TXT_Y_START = 26

enterState
    jsr txtio.cursorOff
    lda GLOBAL_STATE.globalCol    
    sta CURSOR_STATE.col
    jsr txtio.clear

    #printBigAt 4*8 + 1, 1*8, LOGO_COL, bigchar.BIG_ONE
    #printBigAt 5*8 - 1, 1*8, LOGO_COL, bigchar.BIG_ONE
    #printBigAt 3*8 + 2, 2*8, LOGO_COL, bigchar.BIG_TWO

    lda GLOBAL_STATE.globalCol
    sta CURSOR_STATE.col


    #locate 0, TXT_Y_START
    #printString M1, len(M1)
    #locate 0, TXT_Y_START+2
    #printString M2, len(M2)
    #locate 0, TXT_Y_START+4
    #printString M3, len(M3)
    #locate 0, TXT_Y_START+6
    #printString M4, len(M4)
    #locate 0, TXT_Y_START+8
    #printString M5, len(M5)
    #locate 0, TXT_Y_START+10
    #printString M6, len(M6)
    #locate 0, TXT_Y_START+12
    #printString M7, len(M7)
    #locate 0, TXT_Y_START+14
    #printString M8, len(M8)
    #locate 0, TXT_Y_START+16
    #printString M10, len(M10)
    #locate 0, TXT_Y_START+18
    #printString M11, len(M11)


    #locate 7, TXT_Y_START+22
    #printString M9, len(M9)

    rts

leaveState
    rts

M1  .text "This is an implementation of a well known puzzle game in which the player has", $0d
M2  .text "to create a tile with the value two to the power of eleven or 2048 on a", $0d
M3  .text "playing field of four by four cells. Use the cursor keys, the joystick in", $0d
M4  .text "port 1 or an SNES pad in the first socket to move the tiles of all cells", $0d
M5  .text "up, down, left or right. When two equal tiles 'collide' during that movement", $0d
M6  .text "they merge into a tile with a value twice that of the original tiles. The", $0d
M7  .text "game is won if a tile with the value two to the power of eleven is created", $0d
M8  .text "on the playfield. Invalid moves are signalled by a beep. After a valid move", $0d
M10 .text "a new tile with a value two is placed on the playing field. The game ends", $0d
M11 .text "when no valid moves are left.", $0d
M9  .text "Press F1 now or during the game to return to the start screen", $0d

.endnamespace