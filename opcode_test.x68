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
        MOVE.B  D0,         D1
        MOVE.W  D2,         D3
        MOVE.L  D4,         D5

        MOVE.B  (A1),       D1
        MOVE.W  D2,         (A2)

        MOVE.L  -(A3),      D3
        MOVE.B  D4,         -(A4)

        MOVE.W  (A5)+,      D5
        MOVE.L  D6,         (A6)+

        MOVE.B  $1234,      D1
        MOVE.W  D2,         $5678910
        MOVE.L  $7842,      $C01EABD

        MOVE.W  #$3478,     D0
        MOVE.W  #$BED0,     $5678910
        MOVE.L  #$EC478256, D1
        MOVE.L  #$FACAA456, $78236

        ADD.L   #5, D0
        MULS.W  #$0010, D0
        MULS.W  D0, D1
        MULS.W  $123456,   D1
        MULS.W  (A0),      D1
        
        ADD.L   #54327830, D2
        DIVU.W  #$FCE,     D2
        DIVU.W  D2,        D1
        DIVU.W  $123456,   D2
        DIVU.W  (A3),      D2

        LEA     $1234,     A3

        JSR     DONE

        ADD.B   #3,        D0
        ADD.L   #$123456,  D6
        ADD.W   #$1234,    D6
        ADD.B   #$34,      D6
        ADD.B   x,         D6
        ADD.W   #z,        D6
        ADD.L   D3,        (A4)+
        ADD.L   (A4)+,     D3
        ADD.L   -(A4),     D4
        ADD.L   D4,        -(A4)
        ADD.L   $ABCD,     D5
        ADD.W   D5,        $ABCDEF12
        ADD.B   D1,        D2

        ADD.B  D0,         D2
        ADD.B  (A1),       D2
        ADD.B  (A1)+,      D2
        ADD.B  -(A1),      D2
        ADD.B  $1234,      D2
        ADD.B  $12345678,  D2
        ADD.B  #$12,       D2
        ADD.B  D1,         (A3)
        ADD.B  #$12,       (A3)
        ADD.B  D1,         (A3)+
        ADD.B  #$12,       (A3)+
        ADD.B  D1,         -(A3)
        ADD.B  #$12,       -(A3)
        ADD.B  D1,         $1234
        ADD.B  #$12,       $1234
        ADD.B  D1,         $12345678
        ADD.B  #$12,       $12345678

        SUB.B   #3,        D2
        SUB.L   #$123456,  D6
        SUB.W   #$1234,    D6
        SUB.B   #$34,      D6
        SUB.B   x,         D6
        SUB.W   #z,        D6
        SUB.L   D3,        (A4)+
        SUB.L   (A4)+,     D3
        SUB.L   -(A4),     D4
        SUB.L   D4,        -(A4)
        SUB.L   $ABCD,     D5
        SUB.W   D5,        $ABCDEF12
        SUB.B   D1,        D2

        AND.L   #$0010,    D0
        AND.W   $AE437B,   D0
        AND.W   D1,        D0
        AND.L   D1,        D0
        
        BRA     TEST_JSR_1
        BRA     TEST_JSR_2
        
        BLT    TEST_JSR_1
        BLT    TEST_JSR_2  

        BGE    TEST_JSR_1
        BGE    TEST_JSR_2   
        
        BEQ    TEST_JSR_1
        BEQ    TEST_JSR_2 
        
        LEA     $1234,     A3

        NOT.L              D5
        NOT.L              D2

        NOP    

TEST_JSR_2:
        RTS

DONE:
	SIMHALT             ; halt simulator
        END     MAIN        ; last line of source

*~Font name~Courier New~
*~Font size~12~
*~Tab type~0~
*~Tab size~4~
