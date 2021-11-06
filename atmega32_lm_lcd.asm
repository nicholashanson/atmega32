;LCD connected to port B
;basically all we are doing here is taking the three registers in
;the avr architecture related to port B and assigning them aliases
;to make the code more readable and maitainable
;this register is used to write data to the pins of port b
.EQU			LCD_PRT = PORTB
;DDRB is the data direction register for port B
;setting a bit configures the pin for output
;clearing a bit configures the pin for input
.EQU			LCD_DDR = DDRB
;this register is used to read the input on the pins of portB; 
.EQU			LCD_PIN = PINB

;these are the three control lines for the LCD
;here we are not assigning values to the control lines, rather
;we are aliasing numbers that can be used when accessing the pins
;to which the control lines are connected
;RS stands for register select
;the LCD can recieve two kinds of data: commands and actual data
;clearing RS selects the command register
;setting RS selects the data register
.EQU			LCD_RS = 0
;read/write control line
;setting reads
;clearing writes
.EQU			LCD_RW = 1
.EQU			LCD_EN = 2

;in this section we are assigning aliases 
;to certain registers
;hexidecimal to decimal conversion
;HEX_NUM is now an alias for register R25
;this is where the hexidecminal number, the target for
;conversion, is stored
.def			HEX_NUM = R25
;these registers are used to store intermediate variables
;that are used in the conversion process
.def			RMND_L = R19
.def			RMND_M = R20
.def			RMND_H = R21
.def			NUM = R22
.def			DENOMINATOR = R23
.def			QUOTIENT = R24

;in this section we initialize the stack pointer
;in the avr architecture it is necessary to initialize
;the stack if you are going to use function calls
LDI			R21, HIGH(RAMEND)
OUT			SPH, R21
LDI			R21, LOW(RAMEND)
OUT			SPL, R21

;port configuration
;here we set all the pins of the port connected to the LCD
;to output mode
LDI			R21, 0xFF
OUT			LCD_DDR, R21

;LCD initialization
;here we send a set of commands to initilaize the LCD
;during intialization we need to send a set of commands to the LCD
;that follow a certain procedure
LDI			R16, 0x33
CALL			CMDWRT
;we need to wait 2 ms after writing the previous command before writing
;the next one, as stated in the LCD datasheet
CALL			DELAY_2ms
LDI			R16, 0x32
CALL			CMDWRT
CALL			DELAY_2ms
;this command sets the LCD to four-bit mode
LDI			R16, 0x28
CALL			CMDWRT
LDI			R16, 0x0E
CALL			CMDWRT
;this command clears the display
LDI			R16, 0x01
CALL			CMDWRT
;auto-increment cursor and diable shift mode
LDI			R16, 0x06
CALL			CMDWRT

;initialization of the port used for input from the ADC module
;write to the data direction register of port A
;to set port pins to input mode
LDI			R16, 0x00
OUT			DDRA, R16				;set Port A as input for ADC
LDI			R16, 0x87  		         	;enable ADC and select ck/128
OUT			ADCSRA, R16
LDI			R16, 0xE0				;2.56 Vref, ADC0 single-ended
OUT			ADMUX, R16				;left-justified data

READ_ADC:
SBI			ADCSRA, ADSC				;start conversion
;we are not sure when the analog to digital conversion will be completed,
;so we need to keep polling the corresponding flag to check for completion

;this is an inner-loop inside the main loop READ_ADC that waits for the
;AD conversion to complete
KEEP_POLING:
  SBIS			ADCSRA, ADIF				;end of conversion?
;if conversion has not been completed then jump to the beginning of the loop
  RJMP			KEEP_POLING

;conversion has been completed, so clear the flag that indicates completion
;this needs to be done before the next conversion
SBI			ADCSRA, ADIF				;write 1 to clear ADIF flag
;we left-justified the data, so reading the eight most significant bits 
;corresponds to a certain number of shift operations that corresponds to
;a certain numerical scaling
;we move this data from the temperature sensor into a general purpose
;register that is then accessed by the conversion function (CONVERT) to
;convert the hexidecimal value to a decimal one
;we want a decimnal value because numbers in decimal can be easily converted
;to characters that can be displated on the LCD
IN			R16, ADCH				;read ADCH for 8 MSB
CALL			CONVERT
LDI			R16, 0x01
CALL			CMDWRT
MOV			R16, RMND_H
CALL			DATAWRT
MOV			R16, RMND_M
CALL			DATAWRT
MOV			R16, RMND_L
CALL			DATAWRT
;after displaying the temperature on the LCD we now need to jump to the sub-routine
;that reads the signal from the temperature sensor to start the process all over again
RJMP			READ_ADC

CMDWRT:				
MOV			R27, R16
ANDI			R27, 0xF0
IN			R26, LCD_PRT
ANDI			R26, 0x0F
OR			R26, R27
OUT			LCD_PRT, R26
CBI			LCD_PRT, LCD_RS
CBI			LCD_PRT, LCD_RW
SBI			LCD_PRT, LCD_EN
CALL			SDELAY
CBI			LCD_PRT, LCD_EN

CALL			DELAY_100us

MOV			R27, R16
SWAP			R27
ANDI			R27, 0xF0
IN			R26, LCD_PRT
ANDI			R26, 0x0F
OR			R26, R27
OUT			LCD_PRT, R26
SBI			LCD_PRT, LCD_EN
CALL			SDELAY
CBI			LCD_PRT, LCD_EN

CALL			DELAY_100us

RET

DATAWRT:
MOV			R27, R16
ANDI			R27, 0xF0
IN			R26, LCD_PRT
ANDI			R26, 0x0F
OR			R26, R27
OUT			LCD_PRT, R26
SBI			LCD_PRT, LCD_RS
CBI			LCD_PRT, LCD_RW
SBI			LCD_PRT, LCD_EN
CALL			SDELAY
CBI			LCD_PRT, LCD_EN

CALL			DELAY_100us

MOV			R27, R16
SWAP			R27
ANDI			R27, 0xF0
IN			R26, LCD_PRT
ANDI			R26, 0x0F
OR			R26, R27
OUT			LCD_PRT, R26
SBI			LCD_PRT, LCD_EN
CALL			SDELAY
CBI			LCD_PRT, LCD_EN

CALL			DELAY_100us
RET
SDELAY:				
NOP
NOP
RET
DELAY_100us:			
PUSH			R17
LDI			R17, 60
DR0:				
CALL			SDELAY
DEC			R17
BRNE			DR0
POP			R17
RET
DELAY_2ms:			
PUSH			R17
LDI			R17, 20
LDR0:				
CALL			DELAY_100us
DEC			R17
BRNE			LDR0
POP			R17
RET
CONVERT:			
MOV			NUM, R16
LDI			DENOMINATOR, 10
L1:				
INC			QUOTIENT
SUB			NUM, DENOMINATOR
BRCC			L1

DEC			QUOTIENT
ADD			NUM, DENOMINATOR
MOV			RMND_L, NUM

MOV			NUM, QUOTIENT
LDI			QUOTIENT, 0

L2:				
INC			QUOTIENT
SUB			NUM, DENOMINATOR
BRCC			L2

DEC			QUOTIENT
ADD			NUM, DENOMINATOR
MOV			RMND_M, NUM

MOV			RMND_H, QUOTIENT

LDI			R31, 0x30
OR			RMND_L, R31
OR			RMND_M, R31
OR			RMND_H, R31
RET


