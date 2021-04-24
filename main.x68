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

startAddr   DS.L    1
endAddr     DS.L    1

*-----------------------------------------------------------
* Macros:
*-----------------------------------------------------------

PRINT_MSG:      MACRO 
                CLR.L   D0
                LEA     \1, A1      ; \1 acts as a parameter
                MOVE.B  #14, D0     
                TRAP    #15
                ENDM

GET_INPUT:      MACRO
                CLR D0
                MOVE.B      #2, D0
                TRAP        #15
                ENDM

*----------------------Get Starting Address-------------------
MAIN:
            BRA     GET_START_ADDRESS

GET_START_ADDRESS:
            CLR.L   D0
            LEA     startMsg, A1      
            MOVE.B  #14, D0     
            TRAP    #15

            LEA.L   startAddr, A1
            MOVE.B  #2, D0
            TRAP    #15
            BRA     VALIDATE_INPUT

*----------------------Get Ending Address----------------------
GET_END_ADDRESS:
            CLR.L   D0
            LEA     endMsg, A1      
            MOVE.B  #14, D0     
            TRAP    #15

            LEA.L   endAddr, A1
            MOVE.B  #2, D0
            TRAP    #15
            BRA     CHECK_LENGTH


*----------------------VALIDATE INPUT---------------------------      

VALIDATE_INPUT:        
            CMP.B      #0, D4               ; D4 = 0 if start and end address have not been parsed
            BEQ        CHECK_LENGTH         ; if equal, parse START address 
            CMP.B      #1, D4               ; D4 = 1 if start has been parsed but not end address
            BEQ        GET_END_ADDRESS      ; if equal, parse ENDING address  
            BRA        IDENTIFY_OPCODE      ; done parsing, D4 = 2

CHECK_LENGTH:
            CMP.B      #4, D1               ; for task 2, length of string is in D1                
            BEQ        CONVERT_TO_HEX 
            CMP.B      #8, D1               ; address can either be 4 or 8 bits in length  
            BEQ        CONVERT_TO_HEX
            BRA        INVALID_INPUT

INVALID_INPUT:  
            PRINT_MSG  badInput
            BRA        MAIN


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
            BNE        STORE_END         

STORE_START:
            MOVE.L     D3, startAddr
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
            MOVE.L     D3, endAddr
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


*-------------------IDENTIFY OPCODES--------------------

IDENTIFY_OPCODE:


*----------------CONVERT FROM ASCII TO HEX------------------
DONE:
            END        MAIN        ; last line of source