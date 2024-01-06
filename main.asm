.include "api.asm"
.cpu "w65c02"
* = $2500

jmp main

KEY_F1 = 129
KEY_F3 = 131

HEX_CHARS
.text "0123456789ABCDEF"

.include "zeropage.asm"
.include "arith16.asm"
.include "khelp.asm"
.include "txtio.asm"
.include "rtc.asm"
.include "beep.asm"
.include "random.asm"
.include "playfield.asm"
.include "undo.asm"
.include "states.asm"
.include "state_start.asm"
.include "state_game.asm"

S_START .dstruct GameState_t, st_start.eventLoop, st_start.enterState, st_start.leaveState, st_start.ST_START_DATA
S_GAME  .dstruct GameState_t, st_2048.eventLoop, st_2048.enterState, st_2048.leaveState, st_2048.ST_2048_DATA
S_END   .dstruct EndState_t

GlobalState_t .struct 
    globalCol .byte $F0
    highScore .byte 4
.ends

GLOBAL_STATE .dstruct GlobalState_t

main
    jsr txtio.init
    jsr random.init
    jsr sid.init
    ; create a new event queue and save pointer to event queue of superbasic
    jsr initEvents
    #setStartState S_START
mainLoop
    jsr isStateEnd    
    beq _done
    jsr stateEventLoop
    bra mainLoop
_done
    ; restore event queue of superbasic
    jsr restoreEvents

    rts

