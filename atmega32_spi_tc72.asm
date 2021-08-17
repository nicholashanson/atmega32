				.equ				MOSI = 5
				.equ				SCK = 7
				.equ				SS = 4

				LDI				R17, HIGH(RAMEND)
				OUT				SPH, R17
				LDI				R17, LOW(RAMEND)
				OUT				SPL, R17

				LDI				R17, 0xFF
				OUT				DDRA, R17

				LDI				R17, (1<<MOSI)|(1<<SCK)|(1<<SS)
				OUT				DDRB, R17							;set MOSI, SCK and SS as output

				;enable SPI
				LDI				R17, (1<<SPE)|(1<<MSTR)|(1<<SPR0)|(1<<SPR1)|(1<<CPHA)	
				OUT				SPCR, R17							;master, CLK = fck/16

				SBI				PORTB, SS							;enable slave device
				LDI				R17, 0x80
				OUT				SPDR, R17
Reg_sel:		
        			SBIS				SPSR, SPIF
				RJMP				Reg_sel
				LDI				R17, 0x04
				OUT				SPDR, R17
Mode:				SBIS				SPSR, SPIF
				RJMP				Mode
				CBI				PORTB, SS

Read_temp:

				SBI				PORTB, SS							;enable slave device
				LDI				R17, 0x02
				OUT				SPDR, R17
Wait1:
				SBIS				SPSR, SPIF
				RJMP				Wait1
				LDI				R17, 0x00
				OUT				SPDR, R17
Wait2:
				SBIS				SPSR, SPIF
				RJMP				Wait2
				CBI				PORTB, SS

Wait3:				SBIS				SPSR, SPIF
				RJMP				Wait3

				IN				R18, SPDR

				SBI				PORTB, SS
				LDI				R17, 0x01
				OUT				SPDR, R17
Wait4:
				SBIS				SPSR, SPIF
				RJMP				Wait4
				LDI				R17, 0x00
				OUT				SPDR, R17
Wait5:				SBIS				SPSR, SPIF
				RJMP				Wait5

Wait6:				SBIS				SPSR, SPIF
				RJMP				Wait6

				IN				R19, SPDR				
				CBI				PORTB, SS

				RJMP				Read_temp
