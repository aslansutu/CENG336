PROCESSOR 18F8722

#include <xc.inc>

; CONFIGURATION (DO NOT EDIT)
; CONFIG1H
CONFIG OSC = HSPLL      ; Oscillator Selection bits (HS oscillator, PLL enabled (Clock Frequency = 4 x FOSC1))
CONFIG FCMEN = OFF      ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
CONFIG IESO = OFF       ; Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)
; CONFIG2L
CONFIG PWRT = OFF       ; Power-up Timer Enable bit (PWRT disabled)
CONFIG BOREN = OFF      ; Brown-out Reset Enable bits (Brown-out Reset disabled in hardware and software)
; CONFIG2H
CONFIG WDT = OFF        ; Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit))
; CONFIG3H
CONFIG LPT1OSC = OFF    ; Low-Power Timer1 Oscillator Enable bit (Timer1 configured for higher power operation)
CONFIG MCLRE = ON       ; MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled)
; CONFIG4L
CONFIG LVP = OFF        ; Single-Supply ICSP Enable bit (Single-Supply ICSP disabled)
CONFIG XINST = OFF      ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))
CONFIG DEBUG = OFF      ; Disable In-Circuit Debugger


GLOBAL busy_wait_var
GLOBAL busy_wait_helper_var
GLOBAL busy_wait_helper_var2
GLOBAL counter1
GLOBAL counter2

GLOBAL re0_pressed
GLOBAL re0_released
GLOBAL portc_enabled

GLOBAL re1_pressed
GLOBAL re1_released
GLOBAL portb_enabled
    
GLOBAL tmp



; Define space for the variables in RAM
PSECT udata_acs
busy_wait_var:
    DS 1 ; Allocate 1 byte for busy_wait_var
busy_wait_helper_var:
    DS 1 
busy_wait_helper_var2:
    DS 1
counter1:
    DS 1
counter2:
    DS 1
re0_pressed:
    DS 1
re0_released:
    DS 1
portc_enabled:
    DS 1
re1_pressed:
    DS 1
re1_released:
    DS 1
portb_enabled:
    DS 1
tmp:
    DS 1
    
    
    
PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto main

PSECT CODE
main:
    call init
    
    loop:
	call check_buttons	; Check button presses
	call counter_function	; Begin counter
	goto loop		; Restart loop
    

busy_wait:  ; busy_wait_var = 1 => 100ms
    movlw 131
    movwf busy_wait_helper_var
    busy_wait_middle:
	setf busy_wait_helper_var2
	busy_wait_inner:
	    decf busy_wait_helper_var2
	    bnz busy_wait_inner
	decf busy_wait_helper_var
	bnz busy_wait_middle
    decf busy_wait_var
    bnz busy_wait
    return

init:
    ; Init variables
    clrf busy_wait_var
    clrf busy_wait_helper_var
    clrf busy_wait_helper_var2
    movlw 197
    movwf counter1
    movlw 196
    movwf counter2
    
    clrf re0_pressed
    clrf re0_released
    clrf portc_enabled

    clrf re1_pressed
    clrf re1_released
    clrf portb_enabled
    
    clrf tmp
    
    ; Init Ports
    clrf TRISB	; Output
    clrf TRISC	; Output
    clrf TRISD	; Output
    setf TRISE	; Input

    ; Light up all pins
    setf PORTB
    setf PORTC
    setf PORTD
    
    ; Busy wait 1000ms +/- 50ms
    movlw 10
    movwf busy_wait_var
    call busy_wait

    ; Turn off all pins
    clrf PORTB
    clrf PORTC
    clrf PORTD
    
    return
    
enable_portc:
    comf portc_enabled	    ; PORTC display will be enabled
    clrf re0_pressed	    ; Button press variable reset
    return
re0_btn_press:
    setf re0_pressed	    ; BTN is pressed
    return
re0_btn_release:
    btfsc re0_pressed, 0    ; Skip if RE0 has not been pressed yet
    goto enable_portc	    ; Button has been pressed and released (clicked)
    return
    
enable_portb:
    comf portb_enabled	    ; PORTB display will be enabled
    clrf re1_pressed	    ; Button press variable reset
    return
re1_btn_press:
    setf re1_pressed	    ; BTN is pressed
    return
re1_btn_release:
    btfsc re1_pressed, 0    ; Skip if RE1 has not been pressed yet
    goto enable_portb	    ; Button has been pressed and released (clicked)
    return

check_buttons:
    btfsc PORTE, 0	    ; Skip next line if RE0 not pressed
    call re0_btn_press	    ; BTN is high
    btfss PORTE, 0	    ; Skip next line if RE0 is not released
    call re0_btn_release    ; BTN is low
    
    btfsc PORTE, 1	    ; Skip next line if RE1 not pressed
    call re1_btn_press	    ; BTN is high
    btfss PORTE, 1	    ; Skip next line if RE1 is not pressed
    call re1_btn_release    ; BTN is low
    return

    
light_up_portc:
    btfsc PORTC, 0
    goto portc_edge_case
    setf STATUS, C
    rrcf PORTC
    return
portc_edge_case:
    clrf PORTC
    return
light_up_portb:
    movf PORTB, W
    incf WREG
    addwfc PORTB, F
    return
clear_portc:
    clrf PORTC
    return
clear_portb:
    clrf PORTB
    return
update_displays:
    btfss portc_enabled, 0	; Skip if enabled
    call clear_portc			; Clear display
    btfsc portc_enabled, 0	; Skip if disabled
    call light_up_portc		; Light up sequence
    
    btfss portb_enabled, 0
    call clear_portb
    btfsc portb_enabled, 0
    call light_up_portb
    
    btg PORTD, 0		; Toggle the lowest bit on PORTD
    return
counter_function:
    incfsz counter1		; Increment and return till zero
    return
    overflowed_counter:
	incfsz counter2		; Increment and return till zero
	return
	call update_displays	; Update displays (has been about 500ms)
	; Reset counter variables
	movlw 197
	movwf counter1
	movlw 196
	movwf counter2
	return    
end resetVec