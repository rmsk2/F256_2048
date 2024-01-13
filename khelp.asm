; value of event buffer at program start (likely set by `superbasic`)
oldEvent .byte 0, 0
; the new event buffer
myEvent .dstruct kernel.event.event_t


; --------------------------------------------------
; This routine saves the current value of the pointer to the kernel event 
; buffer and sets that pointer to the address of myEvent. This in essence
; disconnects superbasic from the kernel event stream.
;--------------------------------------------------
initEvents
    #move16Bit kernel.args.events, oldEvent
    #load16BitImmediate myEvent, kernel.args.events
    rts


; --------------------------------------------------
; This routine restores the pointer to the kernel event buffer to the value
; encountered at program start. This reconnects superbasic to the kernel
; event stream.
;--------------------------------------------------
restoreEvents
    #move16Bit oldEvent, kernel.args.events
    rts


; --------------------------------------------------
; This macro prints a string to the screen at a given x and y coordinate. The 
; macro has the following parameters
;
; 1. x coordinate
; 2. y coordinate
; 3. address of text to print
; 4. length of text to print
; 5. address of color information
;--------------------------------------------------
kprint .macro x, y, txtPtr, len, colPtr
     lda #\x                                     ; set x coordinate
     sta kernel.args.display.x
     lda #\y                                     ; set y coordinate
     sta kernel.args.display.y
     #load16BitImmediate \txtPtr, kernel.args.display.text
     lda #\len                                   ; set text length
     sta kernel.args.display.buflen
     #load16BitImmediate \colPtr, kernel.args.display.color
     jsr kernel.Display.DrawRow                  ; print to the screen
     .endmacro


kprintAddr .macro x, y, txtPtr, len, colPtr
     lda #\x                                     ; set x coordinate
     sta kernel.args.display.x
     lda #\y                                     ; set y coordinate
     sta kernel.args.display.y
     #move16Bit \txtPtr, kernel.args.display.text
     lda \len                                   ; set text length
     sta kernel.args.display.buflen
     #load16BitImmediate \colPtr, kernel.args.display.color
     jsr kernel.Display.DrawRow                  ; print to the screen
     .endmacro


; waiting for a key press event from the kernel
waitForKey
    ; Peek at the queue to see if anything is pending
    lda kernel.args.events.pending ; Negated count
    bpl waitForKey
    ; Get the next event.
    jsr kernel.NextEvent
    bcs waitForKey
    ; Handle the event
    lda myEvent.type    
    cmp #kernel.event.key.PRESSED
    beq _done
    bra waitForKey
_done
    lda myEvent.key.flags 
    and #myEvent.key.META
    bne waitForKey
    lda myEvent.key.ascii
    rts

TIMER_COOKIE_START .byte 0
TIMER_COOKIE_GAME .byte 1

setTimerHelp .macro type, interval, cookieSrc
    ; get current value of timer
    lda #\type | kernel.args.timer.QUERY
    sta kernel.args.timer.units
    jsr kernel.Clock.SetTimer
    ; carry should be clear here as previous jsr clears it, when no error occurred
    ; make a timer which fires interval units from now
    adc #\interval
    sta kernel.args.timer.absolute
    lda #\type
    sta kernel.args.timer.units
    lda \cookieSrc
    sta kernel.args.timer.cookie
    ; Create timer
    jsr kernel.Clock.SetTimer
.endmacro

setTimerStartScreen 
    #setTimerHelp kernel.args.timer.FRAMES, 30, TIMER_COOKIE_START
    rts

setTimerClockTick
    #setTimerHelp kernel.args.timer.SECONDS, 1, TIMER_COOKIE_GAME
    rts


RTC_BUFFER .dstruct kernel.time_t

kGetTimeStamp
    #load16BitImmediate RTC_BUFFER, kernel.args.buf
    lda #size(kernel.time_t)
    sta kernel.args.buflen
    jsr kernel.Clock.GetTime
    lda RTC_BUFFER.seconds
    sta RTCI2C.seconds
    lda RTC_BUFFER.minutes
    sta RTCI2C.minutes
    lda RTC_BUFFER.hours
    sta RTCI2C.hours
    rts

CONV_TEMP
.byte 0
; --------------------------------------------------
; This routine splits the value in accu its nibbles. The lower nibble 
; is returned in x and its upper nibble in the accu
; --------------------------------------------------
splitByte
    sta CONV_TEMP
    and #$0F
    tax
    lda CONV_TEMP
    and #$F0
    lsr
    lsr 
    lsr 
    lsr
    rts

sys64738
    lda #$DE
    sta $D6A2
    lda #$AD
    sta $D6A3
    lda #$80
    sta $D6A0
    lda #00
    sta $D6A0
    rts