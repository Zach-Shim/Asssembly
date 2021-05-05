*-----------------------------------------------------------
* Title      :Testing File
* Written by :Lucas Buckeye, Brendan Hurt, Zach Shim
* Date       :4.19.21
* Description:v1.2
*-----------------------------------------------------------

        ORG     $7000

x:      DC.B    1
y:      DC.B    5
z:      EQU     $A8C0


MAIN:
        LEA     $1234, A3
        ADD.L   #$123456, D6
        ADD.W   #$1234, D6
        ADD.B   #$34, D6
        ADD.B   x, D6
        ADD.W   #z, D6

        ADD.L   D3, (A4)+
        ADD.L   (A4)+, D3
        ADD.L   -(A4), D4
        ADD.L   D4, -(A4)
        ADD.L   $ABCD, D5
        ADD.W   D5, $ABCDEF12
        ADD.B   D1, D2

        SUB.W   D4, D6
        SUB.L   D3, D6

        AND.L   #$0010, D0
        AND.W   $AE437B, D0

        NOT.L   D5
        NOP    
        NOT.L   D2
DONE:
		SIMHALT             ; halt simulator
        END		MAIN        ; last line of source


