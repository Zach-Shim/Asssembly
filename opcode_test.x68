
*-----------------------------------------------------------
* Title      :Testing File
* Written by :Lucas Buckeye, Brendan Hurt, Zach Shim
* Date       :4.19.21
* Description:v1.2
*-----------------------------------------------------------

        ORG     $7000
MAIN:
        LEA $12345,A1
        ;AND.W   #$0010, D0
        ;ADD.L   (A4)+, D6
        ;SUB.W   D4, D6
        ;SUB.L   D3, D6
 
        ;NOT.L   D5
        ;NOP    
        ;ADD.B   D1, D2
        ;NOT.L   D2
DONE:
		SIMHALT             ; halt simulator
        END		MAIN        ; last line of source


*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
