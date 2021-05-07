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

TEST_JSR_1:
        RTS

MAIN:
        ;MULS.W  #$0010, D0
        ;MULS.W   D0, D1
        ;MULS.L  $123456, D1

        LEA     $1234, A3

        JSR     DONE

        ADD.B   #3, D0
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

        SUB.B   #3, D2
        SUB.L   #$123456, D6
        SUB.W   #$1234, D6
        SUB.B   #$34, D6
        SUB.B   x, D6
        SUB.W   #z, D6
        SUB.L   D3, (A4)+
        SUB.L   (A4)+, D3
        SUB.L   -(A4), D4
        SUB.L   D4, -(A4)
        SUB.L   $ABCD, D5
        SUB.W   D5, $ABCDEF12
        SUB.B   D1, D2

        AND.L   #$0010, D0
        AND.W   $AE437B, D0
        AND.W   D1, D0
        AND.L   D1, D0

        NOT.L   D5
        NOT.L   D2

        NOP    

TEST_JSR_2:
        RTS

DONE:
		SIMHALT             ; halt simulator
        END		MAIN        ; last line of source









*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
