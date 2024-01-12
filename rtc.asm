TimeStamp_t .struct h, m, s
    seconds .byte \s
    minutes .byte \m
    hours   .byte \h
.endstruct

RTCI2C .dstruct TimeStamp_t, 0, 0, 0

; --------------------------------------------------
; This macro allows to fill the target address with a timestamp that
; holds the current time.
; --------------------------------------------------
getTimestamp .macro targetAddr
    #load16BitImmediate \targetAddr, TEMP_PTR
    jsr rtc.getTimeStampCall
.endmacro

getTimeStr .macro targetAddr, srcAddr
    #load16BitImmediate \targetAddr, TEMP_PTR
    #load16BitImmediate \srcAddr, TEMP_PTR2
    jsr rtc.formatTimeStrCall
.endmacro

diffTime .macro addr1, addr2
    #load16BitImmediate \addr1, TEMP_PTR
    #load16BitImmediate \addr2, TEMP_PTR2
    jsr rtc.diffTimeCall
.endmacro

rtc .namespace

cmpTime .macro addr1, addr2
    #load16BitImmediate \addr1, TEMP_PTR
    #load16BitImmediate \addr2, TEMP_PTR2
    jsr cmpTimeI2cCall
.endmacro

; --------------------------------------------------
; This routine compares two I2C time stamps. The addresses of the timestamps
; have to be given through TEMP_PTR and TEMP_PTR2. 
;
; Zero flag is set if the two values are equal. Carry is set if
; the value to which TEMP_PTR points is larger or equal than the one to which 
; TEMP_PTR2 points.
; --------------------------------------------------
cmpTimeI2cCall
    sed                                     ; switch to bcd mode
    ldy #2
    php                                     ; initialize loop
_cmpLoop    
    plp                                     ; throw previous comparison result away
    lda (TEMP_PTR),y 
    cmp (TEMP_PTR2), y                      ; perform comparison
    bne _cmpDone                            ; if we found a difference we are done
    php                                     ; save flags at this point as they contain potentially the end result
    dey             
    bpl _cmpLoop                            ; decrease and check looping values, if neccessary look at next values 
    plp                                     ; restore result of last comparison. It is the end result
_cmpDone
    cld                                     ; switch back to binary mode
    rts

diffTimeSimple .macro addr1, addr2
    #load16BitImmediate \addr1, TEMP_PTR
    #load16BitImmediate \addr2, TEMP_PTR2
    jsr diffTimeSimpleCall
.endmacro

addTimeSimple .macro addr1, addr2
    #load16BitImmediate \addr1, TEMP_PTR
    load16BitImmediate \addr2, TEMP_PTR2
    jsr addTimeSimpleCall
.endmacro

MOD_60 .dstruct ModN_t

; --------------------------------------------------
; This routine calculates A + X mod $60 (in BCD)
; 
; It returns the result in the accu. Carry is set if an overflow occured.
; --------------------------------------------------
addMod60Call
    #addModN2 $60, MOD_60
    rts


; --------------------------------------------------
; This macro calculates A - X mod $60 (in BCD)
; 
; It returns the result in the accu. Carry is set if an underflow occured.
; --------------------------------------------------
subMod60Call
    #subModN2 $60, MOD_60
    rts


; --------------------------------------------------
; This routine calculates A - 1 mod $60 (in BCD)
; 
; It returns result in accu. Carry is set if an underflow occured.
; --------------------------------------------------
decMod60
    ldx #1
    jsr subMod60Call
    rts
  

; --------------------------------------------------
; This routine calculates A + 1 mod $60 (in BCD)
; 
; It returns result in accu. Carry is set if an overflow occured.
; --------------------------------------------------
incMod60
    ldx #1
    jsr addMod60Call
    rts


TIME_UNDERFLOW_MINUTES
.byte 0
TIME_UNDERFLOW_HOURS
.byte 0
TIME_TEMP
.byte 0

; --------------------------------------------------
; This routine calculates the time span between two given time stamps.
; The time stamps have to be referenced by TMP_PTR and TEMP_PTR2 respectively.
;
; This routine subtracts the value of *TEMP_PTR2 from *TEMP_PTR. The
; result is stored in *TEMP_PTR2. It assumes *TEMP_PTR >= *TEMP_PTR2.
; --------------------------------------------------
diffTimeSimpleCall
    sed                                                         ; set BCD mode
    ldy #0
    stz TIME_UNDERFLOW_MINUTES
    stz TIME_UNDERFLOW_HOURS

    ; process seconds
    lda (TEMP_PTR2), y
    tax                                                         ; TEMP_PTR2 in X
    lda (TEMP_PTR), y                                           ; TEMP_PTR in A
    jsr subMod60Call                                            ; A = A - X mod 60
    sta (TEMP_PTR2), y                                          ; save new seconds in TEMP_PTR2
    bcc _noUnderflowSeconds
    inc TIME_UNDERFLOW_MINUTES                                 ; record underflow
_noUnderflowSeconds
    ; process minutes
    iny
    lda (TEMP_PTR), y                                           ; accu contains minutes of TEMP_PTR
    ldx TIME_UNDERFLOW_MINUTES
    beq _noUnderflowMinutes                                     ; was there an underflow?
    ; process underflow from seconds
;underflowSub    
    jsr decMod60                                                ; yes => subtract underflow A = A - 1 mod 60
    bcc _noUnderflowMinutes                                     ; have we generated an underflow in the hours?
    inc TIME_UNDERFLOW_HOURS                                   ; yes, we have!
_noUnderflowMinutes
    ; now process minutes
    sta TIME_TEMP                                              ; store minutes of TEMP_PTR (perhaps decremented due to underflow)
    lda (TEMP_PTR2), y                                          ; load minutes of TEMP_PTR2
    tax                                                         ; minutes of TEMP_PTR2 are in X
    lda TIME_TEMP                                              ; minutes of TEMP_PTR are in A
;regularSub
    jsr subMod60Call                                            ; A = A - X mod 60
    sta (TEMP_PTR2), y                                          ; save new minutes in TEMP_PTR2
    bcc _noHourUnderflow
    ; Either line underflowSub or line regularSub but not both can generate an underflow.
    ; Reasoning: If line underflowSub created an underflow the minutes are at 59
    ; before line regularSub. And from that value we subtract at most 59, so no 
    ; additional underflow can occur
    inc TIME_UNDERFLOW_HOURS                                   

_noHourUnderflow
    ; process hours
    iny 
    sec
    lda (TEMP_PTR), y                                          
    sbc (TEMP_PTR2), y                                          ; Hours of TEMP_PTR in A
    ldx TIME_UNDERFLOW_HOURS                                   ; Subtract TEMP_PTR2 from A
    beq _storeResult                                            ; no underflow => we are nearly done
    dea                                                         ; A = A - 1 Take underflow into account.
_storeResult
    sta (TEMP_PTR2), y                                          ; write result for hours
    cld                                                         ; set binary mode
    rts


; --------------------------------------------------
; This routine adds the given time intervals. The interval have to be 
; referenced by TMP_PTR and TEMP_PTR2 respectively. This routine add the 
; value of *TEMP_PTR to *TEMP_PTR2. The result is stored in *TEMP_PTR2.
; --------------------------------------------------
addTimeSimpleCall
    sed                                                         ; set BCD mode

    ldy #0
    stz TIME_UNDERFLOW_MINUTES
    stz TIME_UNDERFLOW_HOURS

    ; process seconds
    lda (TEMP_PTR2), y                                          
    tax                                                         ; TEMP_PTR2 => X
    lda (TEMP_PTR), y                                           ; TEMP_PTR => A
    jsr addMod60Call                                            ; A = A + X mod $60
    bcc _noOverflowSec
    inc TIME_UNDERFLOW_MINUTES                                 ; yes I know, this should be overflow not underflow ....
_noOverflowSec
    sta (TEMP_PTR2), y                                          ; store result for seconds

    ; process minutes
    iny
    lda (TEMP_PTR2),y                                           ; TEMP_PTR2 in A
    ldx TIME_UNDERFLOW_MINUTES 
    beq _noMinutesOverflow                                      ; checkForOveflow  
;overflowAdd
    jsr incMod60                                                ; Overflow occurred increment A
    bcc _noMinutesOverflow                                      ; Did this create an overflow for the hours?
    inc TIME_UNDERFLOW_HOURS                                   ; yes
_noMinutesOverflow
    tax                                                         ; TEMP_PTR2 => X
    lda (TEMP_PTR), y                                           ; TEMP_PTR => A
;normalAdd
    jsr addMod60Call                                            ; A = A + X mod $60
    sta (TEMP_PTR2), y
    bcc _noHoursOverflow                                        ; did an overflow occur?
    inc TIME_UNDERFLOW_HOURS                                   ; yes

_noHoursOverflow    
    ; process hours
    ; In an argument that mirrors subtraction only the line
    ; overflowAdd or the line normalAdd but not both can
    ; result in an overflow 

    iny
    clc
    lda (TEMP_PTR2), y                                          ; A = Hours of TEMP_PTR2
    adc (TEMP_PTR), y                                           ; A = A + Hours of TEMP_PTR
    ldx TIME_UNDERFLOW_HOURS
    beq _noAdditionalOverflow                                   ; Did we have an overflow?
    ina                                                         ; yes
_noAdditionalOverflow
    sta (TEMP_PTR2), y                                          ; store result in TEMP_PTR2

    cld                                                         ; back to binary
    rts


copyTs .macro srcAddr, targetAddr
    lda \srcAddr
    sta \targetAddr
    lda \srcAddr + 1
    sta \targetAddr + 1
    lda \srcAddr + 2
    sta \targetAddr + 2
.endmacro

copyTsIndirect .macro ptr, target
    ldy #0
    lda (\ptr), y
    sta \target

    iny
    lda (\ptr), y
    sta \target + 1

    iny
    lda (\ptr), y
    sta \target + 2
.endmacro

copyTsIndirectTarget .macro src, ptr
    ldy #0
    lda \src
    sta (\ptr),y

    iny
    lda \src + 1
    sta (\ptr),y

    iny
    lda \src + 2
    sta (\ptr),y    
.endmacro

CONST_TS_MIDNIGHT .dstruct TimeStamp_t, 0, 0, $24
HELP_INTERVAL_UNTIL_MIDNIGHT .dstruct TimeStamp_t, 0, 0, 0
HELP_TS2 .dstruct TimeStamp_t, 0, 0, 0
HELP_TS1 .dstruct TimeStamp_t, 0, 0, 0

TEMP_PTR_BKP
.byte 0,0

TEMP_PTR2_BKP
.byte 0,0

; --------------------------------------------------
; This routine calculates the time interval between two given time stamps.
; The time stamps have to be referenced by TMP_PTR and TEMP_PTR2 respectively.
; The result is stored in *TEMP_PTR2. 
; 
; It correctly handles the case where a time interval wraps around at midnight. 
; TEMP_PTR is the timestamp of the beginning of the interval and TEMP_PTR2 holds 
; a timestamp for the end of the interval.
; --------------------------------------------------
diffTimeCall
    ; save pointers
    #move16Bit TEMP_PTR, TEMP_PTR_BKP
    #move16Bit TEMP_PTR2, TEMP_PTR2_BKP

    jsr cmpTimeI2cCall                         ; Test *TEMP_PTR >= *TEMP_PTR2
    beq _noWrapAround                          ; *TEMP_PTR == *TEMP_PTR2 => no wrap around
    bcs _wrapAround                            ; *TEMP_PTR >= *TEMP_PTR2 => wrap around                                
_noWrapAround                                  ; *TEMP_PTR < *TEMP_PTR2 => no wrap around
    #copyTsIndirect TEMP_PTR, HELP_TS1
    #copyTsIndirect TEMP_PTR2, HELP_TS2    
    #diffTimeSimple HELP_TS2, HELP_TS1       ; Calculate time diff with reversed parameters to fulfill preconditon of diffTimeSimpleCall

    ; restore pointers
    #move16Bit TEMP_PTR_BKP, TEMP_PTR
    #move16Bit TEMP_PTR2_BKP, TEMP_PTR2
    ; result is in HELP_TS1 => copy to *TEMP_PTR2
    #copyTsIndirectTarget HELP_TS1, TEMP_PTR2

    rts
_wrapAround
    ; copy time stamps
    #copyTs CONST_TS_MIDNIGHT, HELP_INTERVAL_UNTIL_MIDNIGHT
    #copyTsIndirect TEMP_PTR, HELP_TS2
   
    ; HELP_TS2 = HELP_INTERVAL_UNTIL_MIDNIGHT - HELP_TS2 = 24:00:00 - *TEMP_PTR
    #diffTimeSimple HELP_INTERVAL_UNTIL_MIDNIGHT, HELP_TS2
    
    ; *TEMP_PTR2 = HELP_TS2 + *TEMP_PTR2
    #move16Bit TEMP_PTR2_BKP, TEMP_PTR2
    #load16BitImmediate HELP_TS2, TEMP_PTR
    jsr addTimeSimpleCall

    ; restore pointers
    #move16Bit TEMP_PTR_BKP, TEMP_PTR

    rts



; --------------------------------------------------
; This routine reads the current time from the built in Real Time Clock.
;
; After calling this routine the current time is stored at the three
; bytes to which TEMP_PTR points. First byte is seconds, the second is 
; minutes and the third is hors. The values are BCD. Upon return the 
; carry is set if an error occurred.
; --------------------------------------------------
getTimeStampCall
    jsr kGetTimeStamp
    #copyTsIndirectTarget RTCI2C, TEMP_PTR
    rts


BTOX_TEMP
.byte 0

HEX_NIBBLE_LO
.byte 0

HEX_NIBBLE_HI
.byte 0

; --------------------------------------------------
; This routine splits a byte into nibbles and returns the nibbles
; as hex digits in the memory locations .HEX_NIBBLE_LO/HI
; --------------------------------------------------
btox
    jsr splitByte
    stx BTOX_TEMP
    tax
    lda HEX_CHARS, X
    sta HEX_NIBBLE_HI

    ldx BTOX_TEMP
    lda HEX_CHARS, X
    sta HEX_NIBBLE_LO
    rts

; --------------------------------------------------
; This routine returns the time as read from the RTC as a string. The 
; address of the receiving string has to be specified through 
; TEMP_PTR/TEMP_PTR + 1. The string has to have room for at least 8 characters.
; The three bytes that are evaluated have to be referenced by TEMP_PTR2/
; TEMP_PTR2 + 1 and have to be BCD.
; 
; This routine does not return an error.
; --------------------------------------------------
formatTimeStrCall    
    ; process seconds
    ldy #7
    lda (TEMP_PTR2)                           ; load seconds as BCD value
    jsr btox        
    lda HEX_NIBBLE_LO
    sta (TEMP_PTR), y
    dey
    lda HEX_NIBBLE_HI
    sta (TEMP_PTR), y
    dey
    lda #58                                   ; save colon
    sta (TEMP_PTR), y

    ; process minutes
    #inc16Bit TEMP_PTR2
    dey
    lda (TEMP_PTR2)                           ; load minutes as BCD value
    jsr btox    
    lda HEX_NIBBLE_LO
    sta (TEMP_PTR), y
    dey
    lda HEX_NIBBLE_HI
    sta (TEMP_PTR), y
    dey
    lda #58                                   ; save colon
    sta (TEMP_PTR), y

    ; process hours
    #inc16Bit TEMP_PTR2
    dey 
    lda (TEMP_PTR2)                           ; load hours as BCD value
    jsr btox    
    lda HEX_NIBBLE_LO
    sta (TEMP_PTR), y
    dey
    lda HEX_NIBBLE_HI
    sta (TEMP_PTR), y

    rts

.endnamespace