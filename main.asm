.include "api.asm"
.cpu "w65c02"
* = $0300

jmp main

USE_SNES_PAD=1

KEY_F1 = 129
KEY_F3 = 131
KEY_F5 = 133
KEY_UNDO = 117
GLOBAL_COL = $10

HEX_CHARS
.text "0123456789ABCDEF"

.include "zeropage.asm"
.include "clut.asm"
.include "arith16.asm"
.include "khelp.asm"
.include "txtio.asm"
.include "rtc.asm"
.include "beep.asm"
.include "snes_pad.asm"
.include "random.asm"
.include "spritecontrol.asm"
.include "playfield.asm"
.include "undo.asm"
.include "bigchar.asm"
.include "diskio.asm"
.include "states.asm"
.include "state_start.asm"
.include "state_game.asm"
.include "state_help.asm"

S_START .dstruct GameState_t, st_start.eventLoop, st_start.enterState, st_start.leaveState, st_start.ST_START_DATA
S_HELP  .dstruct GameState_t, st_help.eventLoop, st_help.enterState, st_help.leaveState, 0
S_GAME  .dstruct GameState_t, st_2048.eventLoop, st_2048.enterState, st_2048.leaveState, st_2048.ST_2048_DATA
S_END   .dstruct EndState_t

GlobalState_t .struct 
    globalCol .byte GLOBAL_COL
    highScore .dstruct PointsBCD_t
    highScoreAtLoad .dstruct PointsBCD_t
.ends

GLOBAL_STATE .dstruct GlobalState_t

main
    ; setup MMU, this seems to be neccessary when running as a PGX
    lda #%10110011                         ; set active and edit LUT to three and allow editing
    sta 0
    lda #%00000000                         ; enable io pages and set active page to 0
    sta 1

    ; map BASIC ROM out and RAM in
    lda #4
    sta 8+4
    lda #5
    sta 8+5

    jsr clut.init

    lda #GLOBAL_COL
    sta GLOBAL_STATE.globalCol
    jsr txtio.init
    jsr random.init
    jsr sid.init
    jsr undo.init
    jsr disk.init
    ; create a new event queue and save pointer to event queue of superbasic
    jsr initEvents
.if USE_SNES_PAD != 0
    jsr snes.init
.endif
    jsr disk.loadHiScore
    bcc _hiscoreRead
    #load16BitImmediate GLOBAL_STATE.highScore, PLAYFIELD_PTR1
    jsr points.clear
_hiscoreRead
    #pointsMove GLOBAL_STATE.highScore, GLOBAL_STATE.highScoreAtLoad
    #setStartState S_START
mainLoop
    jsr isStateEnd    
    beq _done
    jsr stateEventLoop
    bra mainLoop
_done
    
    ; restart to BASIC
    lda #65
    sta kernel.args.run.block_id
    jsr kernel.RunBlock
    ; we should never get here
    jsr sys64738

    rts
