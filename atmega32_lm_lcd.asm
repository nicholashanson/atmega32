;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;LCD PORT DEFINTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;the LCD is connected to port B
;basically all we are doing here is taking the three registers in
;the avr architecture related to port B and assigning them aliases
;to make the code more readable and maitainable

;this register is used to write data to the pins of port b
    .EQU            LCD_PRT = PORTB

;DDRB is the data direction register for port B
;setting a bit configures the pin for output
;clearing a bit configures the pin for input
    .EQU            LCD_DDR = DDRB

;this register is used to read the input on the pins of portB
    .EQU            LCD_PIN = PINB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;LCD COMMAND LINES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;these are the three control lines for the LCD
;here we are not assigning values to the control lines, rather
;we are aliasing numbers that can be used when accessing the pins
;to which the control lines are connected
;RS stands for register select
;the LCD can recieve two kinds of data: commands and actual data
;clearing RS selects the command register
;setting RS selects the data register
    .EQU            LCD_RS = 0
;read/write control line
;setting reads
;clearing writes
    .EQU            LCD_RW = 1
;setting the enable line begins an operation
;clearing the enable line ends an operation 
    .EQU            LCD_EN = 2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;REGISTER DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;in this section we are assigning aliases to certain registers

;HEX_NUM is now an alias for register R25
;this is where the hexidecminal number, the target for hexidecimal to 
;decimal conversion, is stored
    .def			HEX_NUM = R25
;these registers are used to store intermediate variables
;that are used in the conversion process
    .def			RMND_L = R19
    .def			RMND_M = R20
    .def			RMND_H = R21
    .def			NUM = R22
    .def			DENOMINATOR = R23
    .def			QUOTIENT = R24

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INITIALIZATIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;STACK INITIALIZATION;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;in this section we initialize the stack pointer
;in the avr architecture it is necessary to initialize
;the stack if you are going to use function calls
    LDI             R21, HIGH(RAMEND)
    OUT             SPH, R21
    LDI             R21, LOW(RAMEND)
    OUT             SPL, R21

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;LCD PORT CONFIGURATION;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;here we set all the pins of the port connected to the LCD
;to output mode
    LDI                         R21, 0xFF
    OUT                         LCD_DDR, R21

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;LCD INITIALIZATION;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;here we send a set of commands to initilaize the LCD
;during intialization we need to send a set of commands to the LCD
;that follow a certain procedure
    LDI			        R16, 0x33
    CALL			CMDWRT
;we need to wait 2 ms after writing the previous command before writing
;the next one, as stated in the LCD datasheet
    CALL			DELAY_2ms
    LDI			        R16, 0x32
    CALL			CMDWRT
    CALL			DELAY_2ms
;this command sets the LCD to four-bit mode
    LDI			        R16, 0x28
    CALL			CMDWRT
    LDI			        R16, 0x0E
    CALL			CMDWRT
;this command clears the display
    LDI			        R16, 0x01
    CALL			CMDWRT
;auto-increment cursor and diable shift mode
    LDI			        R16, 0x06
    CALL			CMDWRT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;ADC INITIALIZATION;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;initialization of the port used for input from the ADC module
;write to the data-direction-register of port A to set port pins to input mode
    LDI			        R16, 0x00
    OUT			        DDRA, R16				;set Port A as input for ADC
    LDI			        R16, 0x87  		        ;enable ADC and select ck/128
    OUT			        ADCSRA, R16
    LDI			        R16, 0xE0				;2.56 Vref, ADC0 single-ended
    OUT			        ADMUX, R16				;left-justified data

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MAIN PROGRAM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;MAIN LOOP;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;this is the main loop of the program
;we want to read the temperature from the sensor, convert it from analog to digital,
;convert that hexidecimal value to decimal, then write that number to the LCD
;to do this we set up a main loop that reads from the ADC, waits for a result,
;calls convert, displays, and then repeats
READ_ADC:
    SBI                 ADCSRA, ADSC				;start conversion
;we are not sure when the analog to digital conversion will be completed,
;so we need to keep polling the corresponding flag to check for completion

;this is an inner-loop inside the main loop that waits for the
;AD conversion to complete
KEEP_POLING:
    SBIS                ADCSRA, ADIF				;end of conversion?
;if conversion has not been completed then jump to the beginning of the loop
    RJMP                KEEP_POLING
;conversion has been completed, so clear the flag that indicates completion
;this needs to be done before the next conversion
    SBI                 ADCSRA, ADIF				;write 1 to clear ADIF flag
;we left-justified the data, so reading the eight most significant bits 
;corresponds to a certain number of shift operations that corresponds to
;a certain numerical scaling, meaning that we no longer need to the least significant bits
;we move this data from the temperature sensor into a general purpose register that is then 
;accessed by the conversion function (CONVERT) to convert the hexidecimal value to a decimal one
;we want a decimnal value because numbers in decimal can be easily converted to 
;characters that can be displated on the LCD
    IN                  R16, ADCH				;read ADCH for 8 MSB
    CALL                CONVERT
    LDI                 R16, 0x01
    CALL                CMDWRT
    MOV                 R16, RMND_H
    CALL                DATAWRT
    MOV                 R16, RMND_M
    CALL                DATAWRT
    MOV                 R16, RMND_L
    CALL                DATAWRT
;after displaying the temperature on the LCD we now need to jump to the
;start of the main loop to start the process all over again
    RJMP			READ_ADC
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;FUNCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;LCD COMMAND WRITE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;this function writes a command to the LCD
;we are using the LCD in four-bit mode, so we want to split the command into two nibbles
;in the first half of the function we write the first nibble
;and in the second half of the function we write the second nibble
;we use a combination of logic operations that allows us to write the nibble while leaving
;the other four bits of the port unchanged (these other bits are used for the command lines)
CMDWRT:
    ;the command we need to write was passed to the function in R16
    ;we want to move it to an intermediate register so we can modify it's contents but
    ;still get back the original value later
    MOV             R27, R16
    ;we perform a logical AND on the command with 0xF0 to get the high nibble of the command
    ANDI            R27, 0xF0
    ;we read in whatever the current values are on the LCD port
    ;it is important we do this before writing to the point so that the previous values are not lost
    IN              R26, LCD_PRT
    ;we AND whatever values where just read in with 0x0F to get the lower nibble
    ANDI            R26, 0x0F
    ;we OR the high nibble of the command and the low nibble of the command to get a combination of the two
    OR              R26, R27
    ;we then write this value to the LCD port
    OUT             LCD_PRT, R26
    ;to do this, we need clear the register select pin to set the LCD for recieving commands instead of data
    CBI             LCD_PRT, LCD_RS
    ;we clear the LCD read/write pin to indicate to the LCD that this is a write operation
    CBI             LCD_PRT, LCD_RW
    ;we set the enable command line to begin the operation
    SBI             LCD_PRT, LCD_EN
    ;and after a delay
    CALL            SDELAY
    ;clear the enable command line to end the operation
    CBI             LCD_PRT, LCD_EN
    CALL            DELAY_100us
    ;we now need to repeat the above process with the low nibbe of the command
    ;so we move the command into our intermediate register again
    MOV             R27, R16
    ;swap the nibble, so low is now high and high is now low
    SWAP            R27
    ;as above, AND to get the high nibble
    ANDI            R27, 0xF0
    ;read
    IN              R26, LCD_PRT
    ;get low nibble
    ANDI            R26, 0x0F
    ;combine
    OR              R26, R27
    ;write
    OUT             LCD_PRT, R26
    SBI             LCD_PRT, LCD_EN
    CALL            SDELAY
    CBI             LCD_PRT, LCD_EN
    CALL            DELAY_100us
    ;return to caller
    RET
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;LCD DATA WRITE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;here we have two delay functions
;these are necessary to allow for proper functioning of the LCD
;here we follow a pretty similar pattern as we did for the command-write function above
DATAWRT:
    ;move data into the intermediate register
    MOV             R27, R16
    ANDI            R27, 0xF0
    IN              R26, LCD_PRT
    ANDI            R26, 0x0F
    OR              R26, R27
    OUT             LCD_PRT, R26
    ;here we are writing data and not a command, so we want to set the register select control line
    SBI             LCD_PRT, LCD_RS
    ;clear read/write control line to perform a write
    CBI             LCD_PRT, LCD_RW
    ;begin write
    SBI             LCD_PRT, LCD_EN
    CALL            SDELAY
    ;end write
    CB              LCD_PRT, LCD_EN
    CALL            DELAY_100us
    MOV             R27, R16
    SWAP            R27
    ANDI            R27, 0xF0
    IN              R26, LCD_PRT
    ANDI            R26, 0x0F
    OR              R26, R27
    OUT             LCD_PRT, R26
    SBI             LCD_PRT, LCD_EN
    CALL            SDELAY
    CBI             LCD_PRT, LCD_EN
    CALL            DELAY_100us
    RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;DELAY FUNCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;here we have two delay functions
;these are necessary to allow for proper functioning of the LCD
SDELAY:				
    NOP
    NOP
    RET

DELAY_100us:			
    PUSH            R17
    LDI             R17, 60
DR0:				
    CALL            SDELAY
    DEC             R17
    BRNE            DR0
    POP             R17
    RET

DELAY_2ms:			
    PUSH            R17
    LDI             R17, 20
LDR0:				
    CALL            DELAY_100us
    DEC             R17
    BRNE            LDR0
    POP             R17
    RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;HEX TO DEC CONVERSION;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CONVERT:			
    MOV             NUM, R16
    LDI             DENOMINATOR, 10
L1:				
    INC             QUOTIENT
    SUB             NUM, DENOMINATOR
    BRCC            L1
    DEC             QUOTIENT
    ADD             NUM, DENOMINATOR
    MOV             RMND_L, NUM
    MOV             NUM, QUOTIENT
    LDI             QUOTIENT, 0
L2:				
    INC             QUOTIENT
    SUB             NUM, DENOMINATOR
    BRCC            L2
    DEC             QUOTIENT
    ADD             NUM, DENOMINATOR
    MOV             RMND_M, NUM
    MOV             RMND_H, QUOTIENT
    LDI             R31, 0x30
    OR              RMND_L, R31
    OR              RMND_M, R31
    OR              RMND_H, R31
    RET


