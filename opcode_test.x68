
*-----------------------------------------------------------
* Title      :nop
* Written by :Lucas Buckeye, Brendan Hurt, Zach Shim
* Date       :4.19.21
* Description:v1.1
*-----------------------------------------------------------

        ORG     $7000
MAIN:
    NOP    
    ;ADD.B   D1, D2

DONE:
		SIMHALT             ; halt simulator
        END		MAIN        ; last line of source

*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
