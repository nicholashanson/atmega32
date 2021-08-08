              .EQU			SUM = 0x300
              .ORG			00
              LDI				R16, 0x25
              LDI				R17, $34
              LDI				R18, 0b00110001
              ADD				R16, R17
              LDI				R17, 11
              ADD				R16, R18
              STS				SUM, R16
HERE:			    JMP				HERE
