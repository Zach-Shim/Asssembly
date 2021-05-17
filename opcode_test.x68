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
        ; immediate shifts
        ASL.B   #5, D2
        ASR.W   #8, D1
        LSL.L   #2, D4
        
        ; register shifts
        ASR.B   D4, D2
        ASL.W   D3, D5
        LSR.W   D1, D7
        LSL.L   D3, D6
        
        ; addressing modes for memory shift
        ; always word sized
        ASR.W   (A3)
        LSL.W   (A5)+
        ASR.W   -(A7)
        LSR.W   $1234
        ASL.W   $0000FFFF
        
        ; MOVEQ
        MOVE.B  #1, D0
        MOVE.B  #$AC, D3
        MOVE.B  #$FF, D5
        
        ; MOVEM
        MOVEM.L D0, -(SP)
        MOVEM.L (SP)+, D0

        MOVEM.L D1, -(SP)
        MOVEM.L (SP)+, D1

        MOVEM.L D0-D2, -(SP)
        MOVEM.L (SP)+, D0-D2

        MOVEM.L D0-D7, -(SP)
        MOVEM.L (SP)+, D0-D7 

        MOVEM.L A0, -(SP)
        MOVEM.L (SP)+, A0

        MOVEM.L A1, -(SP)
        MOVEM.L (SP)+, A1

        MOVEM.L A0-A2, -(SP)
        MOVEM.L (SP)+, A0-A2

        MOVEM.L A0-A6, -(SP)
        MOVEM.L (SP)+, A0-A6 

        MOVEM.L D2-D5/A1-A3, -(SP)
        MOVEM.L (SP)+, D2-D5/A1-A3

        MOVEM.L D0-D7/A0-A6, -(SP)
        MOVEM.L (SP)+, D0-D7/A0-A6
        
        ; MOVE
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

        MULS.W  #$0010, D0
        MULS.W   D0, D1
        MULS.W  $123456, D1

        LEA     $1234, A3

        JSR     DONE

        ADD.B   #3, D0
        ADD.L   #$123456, D6
        ADD.W   #$1234, D6
        ADD.B   #$34, D6
        ADD.B   x, D6
        ADD.W   #z, D6

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
