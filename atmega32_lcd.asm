					.EQU			LCD_DELAY = 5
					.EQU			LCD_START_UP = 15
					.EQU			LCD_CLEAR = 0x01
					.EQU			LCD_HOME = 0x02
					.EQU			LCD_CURSOR_BACK = 0x10
					.EQU			LCD_CURSOR_FWD = 0x14
					.EQU			LCD_PAN_LEFT = 0x18
					.EQU			LCD_PAN_RIGHT = 0x1C
					.EQU			LCD_CURSOR_OFF = 0x0C
					.EQU			LCD_CURSOR_ON = 0x0E
					.EQU			LCD_CURSOR_BLINK = 0x0F
					.EQU			LCD_CURSOR_LINE2 = 0xC0

					.EQU			FUNCTION_SET = 0x28
					.EQU			ENTRY_MODE = 0x06 
					.EQU			DISPLAY_SETUP = 0x0C 

					.EQU			INSTR = 0x00
					.EQU			DATA = 0x10	

					.EQU    		LCD_PORT = PORTD
					.EQU			LCD_DDR = DDRD
					.EQU			LCD_PWR = 7
					.EQU			LCD_EN = 6
					.EQU			LCD_RW = 5
					.EQU			LCD_RS = 4
					
					.EQU			NB_LINES = 2
					.EQU			NB_COL = 16

					;initialize stack
					LDI			R21, HIGH(RAMEND)
					OUT			SPH, R21
					LDI			R21, LOW(RAMEND)
					OUT			SPL, R21

          				;initialize LCD to 0
					LDI			R21, 0x00
					OUT			LCD_PORT, R21

					;set LCD port as ouput
					LDI			R21, 0xFF
					OUT			LCD_DDR, R21
          
					;power on
					SBI			LCD_PORT, LCD_PWR
          
					;start-up delay
					LDI			R17, LCD_START_UP
					CALL			DELAY
          
					;cmd code 0x32
					LDI			R21, 0x32
				 	CALL			PUT_CMD
          
					;move FUNCTION_SET into R21
					LDI			R21, FUNCTION_SET
					CALL			PUT_CMD
          
					;move DISPLAY_SETUP into R21
					LDI			R21, DISPLAY_SETUP
					CALL			PUT_CMD
          
					;move LCD_CLEAR into R21
					LDI			R21, LCD_CLEAR
					CALL			PUT_CMD
          
					;move ENTRY_MODE into R21
					LDI			R21, ENTRY_MODE
					CALL			PUT_CMD

					;write message
					LDI			R21, 'H'
					CALL			PUT_CHAR
					LDI			R21, 'i'
					CALL			PUT_CHAR
					
					
HERE:					RJMP			HERE

PUT_CMD:				LDI			R17, LCD_DELAY
					CALL			DELAY
					LDI			R22, INSTR
					CALL			WRITE_NIBBLE					
					LSL			R21
					LSL			R21
					LSL			R21
					LSL			R21
					LDI			R17, 1
					CALL			DELAY
					CALL			WRITE_NIBBLE
					RET
PUT_CHAR:				LDI			R17, LCD_DELAY
					CALL			DELAY
					LDI			R22, DATA
					CALL			WRITE_NIBBLE
					LSL			R21
					LSL			R21
					LSL			R21
					LSL			R21
					CALL			WRITE_NIBBLE
					RET
WRITE_NIBBLE:		
          				;right shift R21 (cmd) four times
					PUSH			R21
					LSR			R21
					LSR			R21
					LSR			R21
					LSR			R21
          
					;bitwise & R21 with 0x0F
					LDI			R23, 0x0F
					AND			R21, R23
          
					;bitwise & LCD_PORT with 0xF0
					LDI			R23, 0xF0
					IN			R24, LCD_PORT
					AND			R24, R23
          
					;bitwise OR LCD_PORT with R21
					OR			R24, R21
          
					;set LCD_RS to INSTR
					OR			R24, R22
					OUT			LCD_PORT, R24
          
					;clear LCD_RW
					CBI			LCD_PORT, LCD_RW
          
					;set LCD_EN
					SBI			LCD_PORT, LCD_EN
          
					;clear LCD_EN
					CBI			LCD_PORT, LCD_EN
					POP			R21
					RET
SDELAY:					NOP
					NOP
					RET
DELAY_100us:		
         	 			LDI			R19, 60
DR0:					CALL			SDELAY
					DEC			R19
					BRNE			DR0
					RET
DELAY:					LDI			R18, 10				
LDR0:					CALL			DELAY_100us	
					DEC			R18
					BRNE			LDR0
					DEC			R17
					BRNE			DELAY
					RET
