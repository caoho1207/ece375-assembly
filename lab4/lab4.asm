;***********************************************************
;*
;*  Lab 4
;*
;*  Calculates the 6-byte result of (A + B)^2, where A and B are 2-byte numbers
;*
;*  This is the skeleton file Lab 4 of ECE 375
;*
;***********************************************************
;*
;*   Author: Sean Rettig
;*     Date: 2015-01-28
;*
;***********************************************************

.include "m128def.inc"          ; Include definition file

;***********************************************************
;*  Internal Register Definitions and Constants
;***********************************************************
.def    mpr = r16               ; Multipurpose register 
.def    rlo = r0                ; Low byte of MUL result
.def    rhi = r1                ; High byte of MUL result
.def    zero = r2               ; Zero register, set to zero in INIT, useful for calculations
.def    A = r3                  ; An operand
.def    B = r4                  ; Another operand

.def    oloop = r17             ; Outer Loop Counter
.def    iloop = r18             ; Inner Loop Counter

.equ    addrA = $0100           ; Beginning Address of Operand A data (input to ADD16)
.equ    addrB = $0102           ; Beginning Address of Operand B data (input to ADD16)
.equ    addrC = $011D           ; Beginning Address of Operand C data (input to MUL24)
.equ    addrD = $011D           ; Beginning Address of Operand D data (input to MUL24)
.equ    LAddrP = $0104          ; Beginning Address of Product Result
.equ    HAddrP = $0109          ; End Address of Product Result



;***********************************************************
;*  Start of Code Segment
;***********************************************************
.cseg                           ; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org    $0000                   ; Beginning of IVs
        rjmp    INIT            ; Reset interrupt

.org    $0046                   ; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:                           ; The initialization routine
        ; Initialize Stack Pointer
        LDI R16, LOW(RAMEND) ; Low Byte of End SRAM Address
        OUT SPL, R16 ; Write byte to SPL
        LDI R16, HIGH(RAMEND) ; High Byte of End SRAM Address
        OUT SPH, R16 ; Write byte to SPH

        clr     zero            ; Set the zero register to zero, maintain
                                ; these semantics, meaning, don't load anything
                                ; to it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:                           ; The Main program
        ; Set up the add function
        ; Add the two 16-bit numbers
        rcall   ADD16           ; Call the add function

        ; Set up the multiply function
        sts     $0104, zero
        sts     $0105, zero
        sts     $0106, zero
        sts     $0107, zero
        sts     $0108, zero
        sts     $0109, zero

        ; Multiply two 24-bit numbers
        rcall   MUL24           ; Call the multiply function


DONE:   rjmp    MAIN            ; Create an infinite while loop to signify the 
                                ; end of the program.

;***********************************************************
;*  Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;       where the high byte of the result contains the carry
;       out bit.
;-----------------------------------------------------------
ADD16:
        ; Save variables by pushing them to the stack
        push    A               ; Save A register
        push    B               ; Save B register
        push    rhi             ; Save rhi register
        push    rlo             ; Save rlo register
        push    zero            ; Save zero register
        push    XH              ; Save X-ptr
        push    XL
        push    YH              ; Save Y-ptr
        push    YL              
        push    ZH              ; Save Z-ptr
        push    ZL
        push    oloop           ; Save counters
        push    iloop               

        clr     zero            ; Maintain zero semantics

        ; Execute the function here
        lds r0, $0100
        lds r1, $0101
        lds r2, $0102
        lds r3, $0103

        add r0, r2
        adc r1, r3
        clr r2
        clr r3
        adc r2, r3

        sts $011D, r0
        sts $011E, r1
        sts $011F, r2
        
        ; Restore variables by popping them from the stack in reverse order
        pop     iloop
        pop     oloop
        pop     ZL              
        pop     ZH
        pop     YL
        pop     YH
        pop     XL
        pop     XH
        pop     zero
        pop     rlo
        pop     rhi
        pop     B
        pop     A

        ret                     ; End a function with RET

;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit 
;       result.
;-----------------------------------------------------------
MUL24:
        push    A               ; Save A register
        push    B               ; Save B register
        push    rhi             ; Save rhi register
        push    rlo             ; Save rlo register
        push    zero            ; Save zero register
        push    XH              ; Save X-ptr
        push    XL
        push    YH              ; Save Y-ptr
        push    YL              
        push    ZH              ; Save Z-ptr
        push    ZL
        push    oloop           ; Save counters
        push    iloop               

        clr     zero            ; Maintain zero semantics

        ; Set Y to beginning address of D
        ldi     YL, low(addrD)  ; Load low byte
        ldi     YH, high(addrD) ; Load high byte

        ; Set Z to begginning address of resulting Product
        ldi     ZL, low(LAddrP) ; Load low byte
        ldi     ZH, high(LAddrP); Load high byte

        ; Begin outer for loop
        ldi     oloop, 3        ; Load counter
MUL24_OLOOP:
        ; Set X to beginning address of C
        ldi     XL, low(addrC)  ; Load low byte
        ldi     XH, high(addrC) ; Load high byte

        ; Begin inner for loop
        ldi     iloop, 3        ; Load counter
MUL24_ILOOP:
        ld      A, X+           ; Get byte of A operand
        ld      B, Y            ; Get byte of B operand
        mul     A,B             ; Multiply A and B
        ld      A, Z+           ; Get a result byte from memory
        ld      B, Z+           ; Get the next result byte from memory
        add     rlo, A          ; rlo <= rlo + A
        adc     rhi, B          ; rhi <= rhi + B + carry
        ld      A, Z            ; Get a third byte from the result
        adc     A, zero         ; Add carry to A
        st      Z, A            ; Store third byte to memory
        st      -Z, rhi         ; Store second byte to memory
        st      -Z, rlo         ; Store third byte to memory
        adiw    ZH:ZL, 1        ; Z <= Z + 1            
        dec     iloop           ; Decrement counter
        brne    MUL24_ILOOP     ; Loop if iLoop != 0
        ; End inner for loop

        sbiw    ZH:ZL, 2        ; Z <= Z - 1
        adiw    YH:YL, 1        ; Y <= Y + 1
        dec     oloop           ; Decrement counter
        brne    MUL24_OLOOP     ; Loop if oLoop != 0
        ; End outer for loop
                
        pop     iloop           ; Restore all registers in reverse order
        pop     oloop
        pop     ZL              
        pop     ZH
        pop     YL
        pop     YH
        pop     XL
        pop     XH
        pop     zero
        pop     rlo
        pop     rhi
        pop     B
        pop     A
        ret                     ; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;           A - Operand A is gathered from address $0101:$0100
;           B - Operand B is gathered from address $0103:$0102
;           Res - Result is stored in address 
;                   $0107:$0106:$0105:$0104
;       You will need to make sure that Res is cleared before
;       calling this function.
;-----------------------------------------------------------
MUL16:
        push    A               ; Save A register
        push    B               ; Save B register
        push    rhi             ; Save rhi register
        push    rlo             ; Save rlo register
        push    zero            ; Save zero register
        push    XH              ; Save X-ptr
        push    XL
        push    YH              ; Save Y-ptr
        push    YL              
        push    ZH              ; Save Z-ptr
        push    ZL
        push    oloop           ; Save counters
        push    iloop               

        clr     zero            ; Maintain zero semantics

        ; Set Y to beginning address of B
        ldi     YL, low(addrB)  ; Load low byte
        ldi     YH, high(addrB) ; Load high byte

        ; Set Z to begginning address of resulting Product
        ldi     ZL, low(LAddrP) ; Load low byte
        ldi     ZH, high(LAddrP); Load high byte

        ; Begin outer for loop
        ldi     oloop, 2        ; Load counter
MUL16_OLOOP:
        ; Set X to beginning address of A
        ldi     XL, low(addrA)  ; Load low byte
        ldi     XH, high(addrA) ; Load high byte

        ; Begin inner for loop
        ldi     iloop, 2        ; Load counter
MUL16_ILOOP:
        ld      A, X+           ; Get byte of A operand
        ld      B, Y            ; Get byte of B operand
        mul     A,B             ; Multiply A and B
        ld      A, Z+           ; Get a result byte from memory
        ld      B, Z+           ; Get the next result byte from memory
        add     rlo, A          ; rlo <= rlo + A
        adc     rhi, B          ; rhi <= rhi + B + carry
        ld      A, Z            ; Get a third byte from the result
        adc     A, zero         ; Add carry to A
        st      Z, A            ; Store third byte to memory
        st      -Z, rhi         ; Store second byte to memory
        st      -Z, rlo         ; Store third byte to memory
        adiw    ZH:ZL, 1        ; Z <= Z + 1            
        dec     iloop           ; Decrement counter
        brne    MUL16_ILOOP     ; Loop if iLoop != 0
        ; End inner for loop

        sbiw    ZH:ZL, 1        ; Z <= Z - 1
        adiw    YH:YL, 1        ; Y <= Y + 1
        dec     oloop           ; Decrement counter
        brne    MUL16_OLOOP     ; Loop if oLoop != 0
        ; End outer for loop
                
        pop     iloop           ; Restore all registers in reverse order
        pop     oloop
        pop     ZL              
        pop     ZH
        pop     YL
        pop     YH
        pop     XL
        pop     XH
        pop     zero
        pop     rlo
        pop     rhi
        pop     B
        pop     A
        ret                     ; End a function with RET

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;       beginning of your functions
;-----------------------------------------------------------
FUNC:                           ; Begin a function with a label
        ; Save variable by pushing them to the stack

        ; Execute the function here
        
        ; Restore variable by popping them from the stack in reverse order\
        ret                     ; End a function with RET


;***********************************************************
;*  Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*  Additional Program Includes
;***********************************************************
; There are no additional file includes for this program

