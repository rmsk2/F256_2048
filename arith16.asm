; --------------------------------------------------
; load16BitImmediate loads the 16 bit value given in .val into the memory location given
; by .addr 
; --------------------------------------------------
load16BitImmediate .macro  val, addr 
    lda #<\val
    sta \addr
    lda #>\val
    sta \addr+1
.endmacro

; --------------------------------------------------
; move16Bit copies the 16 bit value stored at .memAddr1 to .memAddr2
; --------------------------------------------------
move16Bit .macro  memAddr1, memAddr2 
    ; copy lo byte
    lda \memAddr1
    sta \memAddr2
    ; copy hi byte
    lda \memAddr1+1
    sta \memAddr2+1
.endmacro

; --------------------------------------------------
; double16Bit multiplies the 16 bit value stored at .memAddr by 2
; --------------------------------------------------
double16Bit .macro  memAddr 
    asl \memAddr+1
    asl \memAddr                     
    bcc _noCarry                     ; no carry set => we are already done
    ; carry set => set least significant bit in hi byte. No add or inc is required as bit 0 
    ; of .memAddr+1 has to be zero due to previous left shift
    lda #$01
    ora \memAddr+1                   
    sta \memAddr+1
_noCarry    
.endmacro

; --------------------------------------------------
; halve16Bit divides the 16 bit value stored at .memAddr by 2
; --------------------------------------------------
halve16Bit .macro  memAddr 
    clc
    lda \memAddr+1
    ror
    sta \memAddr+1
    lda \memAddr
    ror
    sta \memAddr
.endmacro


; --------------------------------------------------
; sub16Bit subtracts the value stored at .memAddr1 from the value stored at the
; address .memAddr2. The result is stored in .memAddr2
; --------------------------------------------------
sub16Bit .macro  memAddr1, memAddr2 
    sec
    lda \memAddr2
    sbc \memAddr1
    sta \memAddr2
    lda \memAddr2+1
    sbc \memAddr1+1
    sta \memAddr2+1
.endmacro

; --------------------------------------------------
; sub16BitImmediate subtracts the value .value from the value stored at the
; address .memAddr2. The result is stored in .memAddr2
; --------------------------------------------------
sub16BitImmediate .macro value, memAddr2
    sec
    lda \memAddr2
    sbc #<\value
    sta \memAddr2
    lda \memAddr2+1
    sbc #>\value
    sta \memAddr2+1
.endmacro

; --------------------------------------------------
; add16Bit implements a 16 bit add of the values stored at memAddr1 and memAddr2 
; The result is stored in .memAddr2
; --------------------------------------------------
add16Bit .macro  memAddr1, memAddr2 
    clc
    ; add lo bytes
    lda \memAddr1
    adc \memAddr2
    sta \memAddr2
    ; add hi bytes
    lda \memAddr1+1
    adc \memAddr2+1
    sta \memAddr2+1
.endmacro

; --------------------------------------------------
; add16BitImmediate implements a 16 bit add of an immediate value to value stored at memAddr2 
; The result is stored in .memAddr2
; --------------------------------------------------
add16BitImmediate .macro  value, memAddr2 
    clc
    ; add lo bytes
    lda #<\value
    adc \memAddr2
    sta \memAddr2
    ; add hi bytes
    lda #>\value
    adc \memAddr2+1
    sta \memAddr2+1
.endmacro


; --------------------------------------------------
; inc16Bit implements a 16 bit increment of the 16 bit value stored at .memAddr 
; --------------------------------------------------
inc16Bit .macro  memAddr 
    clc
    lda #1
    adc \memAddr
    sta \memAddr
    bcc _noCarryInc
    inc \memAddr+1
_noCarryInc
.endmacro

; --------------------------------------------------
; dec16Bit implements a 16 bit decrement of the 16 bit value stored at .memAddr 
; --------------------------------------------------
dec16Bit .macro  memAddr
    lda \memAddr
    sec
    sbc #1
    sta \memAddr
    lda \memAddr+1
    sbc #0
    sta \memAddr+1
.endmacro


; --------------------------------------------------
; cmp16Bit compares the 16 bit values stored at memAddr1 and memAddr2 
; Z  flag is set in case these values are equal
; --------------------------------------------------
cmp16Bit .macro  memAddr1, memAddr2 
    lda \memAddr1+1
    cmp \memAddr2+1
    bne _unequal
    lda \memAddr1
    cmp \memAddr2
_unequal
.endmacro

; --------------------------------------------------
; cmp16BitImmediate compares the 16 bit value stored at memAddr with
; the immediate value given in .value.
; 
; Z  flag is set in case these values are equal. Carry is set
; if .value is greater or equal than the value store at .memAddr
; --------------------------------------------------
cmp16BitImmediate .macro  value, memAddr 
    lda #>\value
    cmp \memAddr+1
    bne _unequal2
    lda #<\value
    cmp \memAddr
_unequal2
.endmacro
