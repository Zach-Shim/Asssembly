*-----------------------------------------------------------
* Title      :DASM
* Written by :Lucas Buckeye, Brendan Hurt, Zach Shim
* Date       :4.19.21
* Description:v1.0
*-----------------------------------------------------------

*-----------------------------------------------------------
* Directives:
*-----------------------------------------------------------
            ORG     $100

CR          EQU     $0D             ; Define Carriage Return and Line Feed
LF          EQU     $0A 

startMsg:   DC.B    'Please enter a starting address ', 0, CR, LF
endMsg:     DC.B    'Please enter an ending address ', 0, CR, LF
testMsg:    DC.B    'value: ', 0, CR, LF

badInput    DC.B    'Invalid Input', 0, CR, LF

userAddr    DS.L    1
startAddr   DS.L    1
;startSize   DS.B    1
endAddr     DS.L    1
;endSize     DS.B    1

*-----------------------------------------------------------
* Macros:
*-----------------------------------------------------------

PRINT_MSG:  MACRO 
            CLR.L   D0
            LEA     \1, A1      ; \1 acts as a parameter
            MOVE.B  #14, D0     
            TRAP    #15
            ENDM

CLR_D_REGS: MACRO
            CLR.L   D0
            CLR.L   D1
            CLR.L   D2
            CLR.L   D3
            CLR.L   D4
            CLR.L   D5
            CLR.L   D6
            CLR.L   D7
            ENDM

CLR_A_REG: MACRO
            CLR.L   \1
            MOVE.L  \1, \2
            ENDM  


*-----------------------------------------------------------
* Description:  Get User Input
*-----------------------------------------------------------

*-------------------------MAIN------------------------------
MAIN:
            BSR     GET_INPUT
            JMP     IDENTIFY_OPCODE
*-----------------------------------------------------------

TEST:




*-------------------------Get Input-------------------------
GET_INPUT:
            CMP      #0, D4
            BEQ      GET_START_ADDRESS
               
            MOVE.L   D6, startAddr
            MOVE.L   D7, endAddr
            RTS 
*-----------------------------------------------------------

*----------------------Get Starting Address----------------------
GET_START_ADDRESS:
            CLR.L   D0
            LEA     startMsg, A1      
            MOVE.B  #14, D0     
            TRAP    #15

            LEA.L   userAddr, A1
            MOVE.B  #2, D0
            TRAP    #15
            ;MOVE.B  D1, startSize
            BRA     VALIDATE_INPUT
*-----------------------------------------------------------

*----------------------Get Ending Address----------------------
GET_END_ADDRESS:
            CLR.L   D0
            LEA     endMsg, A1      
            MOVE.B  #14, D0     
            TRAP    #15

            LEA.L   userAddr, A1
            MOVE.B  #2, D0
            TRAP    #15
            ;MOVE.B  D1, endSize
            BRA     CHECK_LENGTH
*-----------------------------------------------------------





*-----------------------------------------------------------
* Description:  Validate User Input
* Constraints:  
*   User input must be:
*   Length 4 or Length 8
*   ASCII character 0-9 or A-F
*   Starting and ending address with value < $00FFFFFF 
*   Starting address is before ending address
*-----------------------------------------------------------

*----------------------VALIDATE INPUT---------------------------      

VALIDATE_INPUT:        
            CMP.B      #0, D4               ; D4 = 0 if start and end address have not been parsed
            BEQ        CHECK_LENGTH         ; if equal, parse START address 
            CMP.B      #1, D4               ; D4 = 1 if start has been parsed but not end address
            BEQ        GET_END_ADDRESS      ; if equal, parse ENDING address  
            BRA        GET_INPUT            ; done parsing, D4 = 2

CHECK_LENGTH:
            CMP.B      #4, D1               ; for task 2, length of string is in D1                
            BEQ        CONVERT_TO_HEX 
            CMP.B      #8, D1               ; address can either be 4 or 8 bits in length  
            BEQ        CONVERT_TO_HEX
            BRA        INVALID_INPUT

INVALID_INPUT:  
            CLR.L      D3
            PRINT_MSG  badInput
            CMP.B      #0, D4 
            BEQ        GET_START_ADDRESS  
            CMP.B      #1, D4               ; D4 = 1 if start has been parsed but not end address
            BEQ        GET_END_ADDRESS      ; if equal, parse ENDING address  
            BRA        MAIN
*-----------------------------------------------------------

*----------------CONVERT FROM ASCII TO HEX------------------
CONVERT_TO_HEX:
            CMP.B      #$30, (A1)           ; check if input is a number (lower range) - check ascii table for reference
            BLT        INVALID_INPUT        

            CMP.B      #$3A,(A1)            ; check if input is a number (upper range)
            BLT        NUM_TO_HEX      

            CMP.B      #$41, (A1)           ; check if input is a letter (lower range)
            BLT        INVALID_INPUT             

            CMP.B      #$47,(A1)            ; check if input is a number (upper range)
            BLT        LETTER_TO_HEX

            BRA        INVALID_INPUT    

NUM_TO_HEX:      
            SUB.B      #$30, (A1)          ; subtract 30 to get a number 
            BRA        STORE_CHAR   

LETTER_TO_HEX:     
            SUB.B      #$37, (A1)          ; subtract 37 to get a letter
            BRA        STORE_CHAR

STORE_CHAR:       
            ADD.B     (A1)+, D3            ; keep hex stored in D3           
            BRA        ITERATE                 

ITERATE:
            SUB.B      #$1, D1
            CMP.B      #0, D1
            BEQ        STORE_INPUT

            LSL.L      #4, D3               ; shift D3 contents left by 4 to receive next input
            BRA        CONVERT_TO_HEX

STORE_INPUT:
            CMP.B      #0, D4               ; D4 = 0 if start and end address have not been parsed
            BEQ        STORE_START          ; if equal, parse START address 
            
            CMP.B      #1, D4               ; D4 = 1 if start has been parsed but not end address
            BEQ        STORE_END         

STORE_START:
            MOVE.L     D3, D6
            ADD.B      #1, D4               ; value to indicate if we are done parsing
            ;CLR        D3
            ;BRA       VALIDATE_INPUT       ; UNCOMMENT WHEN TAKING OUT TEST CODE BELOW

            ; USED FOR TESTING - MAKE SURE OUTPUT IS CORRECT
            CLR.L       D1
            MOVE.L      D3, D1   
            MOVE.B      #3, D0     
            TRAP        #15

            CLR         D3
            BRA         VALIDATE_INPUT

STORE_END:
            MOVE.L     D3, D7
            ADD.B      #1, D4               ; value to indicate if we are done parsing
            ;CLR        D3
            ;BRA       VALIDATE_INPUT       ; UNCOMMENT WHEN TAKING OUT TEST CODE BELOW

            ; USED FOR TESTING - MAKE SURE OUTPUT IS CORRECT
            CLR.L       D1
            MOVE.L      D3, D1   
            MOVE.B      #3, D0     
            TRAP        #15

            CLR         D3
            BRA         VALIDATE_INPUT
*-----------------------------------------------------------





*-----------------------------------------------------------
* Description:  IDENTIFY OPCODES LOOP
* Constraints:  

*-----------------------------------------------------------

*-------------------IDENTIFY OPCODES------------------------

IDENTIFY_OPCODE:
            CLR_D_REGS
            CLR_A_REG   D0, A1
            MOVEM.L     D0-D7/A0-A6,-(SP)    ; move the old registers onto the stack

            MOVEA.L     startAddr, A1
            MOVEA.L     endAddr, A2

            MOVE.W      (A1), D1
            MOVE.B      #12, D0
            LSR.L       D0, D1 

FIND_OPCODE:
            CMP.B       D0, %0100
            JMP         opc_0100
            CMP.B       D0, %1101
            JMP         opc_1101
*-----------------------------------------------------------

*-----------------------------------------------------------
* First four bits = 0100
* (CLR,NEG,NOT,MOVEM,SWAP,JMP,JSR,NOP,RTS,LEA) 
*-----------------------------------------------------------
opc_0100:
            
*-----------------------------------------------------------

*-----------------------------------------------------------
* First four bits = 1101
* (ADD,ADDA)
*-----------------------------------------------------------
opc_1101:
            MOVE.L      
            JSR     getSize             * return size  in 6 & 7 into D6
            
getSize     
            MOVE.W      D7,D6               * copy current instruction to shift
            LSR.W       #6,D6               * move the size bits in 6-7 to LSB
            ANDI.W      #$0003,D6           * remove other non-size bits and store result into D6
            RTS
*-----------------------------------------------------------



*----------------CONVERT FROM ASCII TO HEX------------------
DONE:
            END        MAIN        ; last line of source