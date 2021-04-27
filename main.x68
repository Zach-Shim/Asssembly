*-----------------------------------------------------------
* Title      :DASM
* Written by :Lucas Buckeye, Brendan Hurt, Zach Shim
* Date       :4.19.21
* Description:v1.0
*-----------------------------------------------------------

*-----------------------------------------------------------
* Directives:
*-----------------------------------------------------------
            ORG     $1000

CR          EQU     $0D             ; Define Carriage Return and Line Feed
LF          EQU     $0A 

startMsg:   DC.B    'Please enter a starting address ', 0, CR, LF
endMsg:     DC.B    'Please enter an ending address ', 0, CR, LF
doneMsg:    DC.B    'exiting...', 0, CR, LF
badInput:   DC.B    'Invalid Input', 0, CR, LF

userAddr:   DS.L    1
startAddr:  DS.L    1
endAddr:    DS.L    1

opOutput:   DS.L    5

opcode:     DS.W    1   
opTag:      DS.B    1               ; a four bit identifier for opcodes (first four bits of an instruction, ex. 1011 = ADD)
valid:      DS.B    1

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
            LEA.L   startMsg, A1      
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
            LEA.L   endMsg, A1      
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
* Registers:
*   D0 = used for tasks and trap #15
*   D1 = size of shifting bits
*   D2 = destination for shifts
*   D3 = size of opcode
*   D4 = <ea> vs Dn (0 = <ea>, 1 = Dn)
*   D5 = addressing mode
*   D6 = register number
*   D7 = used as bool flag
*   A1 = used for task 14 (printing out strings to screen) and trap #15
*   A2 = current address (given by user)
*   A3 = ending address (given by user)
*   A4 = used to add to the buffer to print ()

*-----------------------------------------------------------


*---------------------LOAD ADDRESSES------------------------
* stores initial values into registers
*-----------------------------------------------------------
LOAD_ADDRESSES: 
            * clear all registers and push current registers onto the stack (so we can have fresh registers)
            CLR_D_REGS
            CLR_A_REG       D0, A1

            * load start and end registers
            MOVEA.L startAddr, A2
            MOVEA.L endAddr, A3

            BSR     GRAB_NEXT_WORD
            BSR     GRAB_FIRST_FOUR_BITS    ; grabs that opcode's ID (first four bits)

            MOVEM.L D0-D7/A0-A6,-(SP)       ; move the old registers onto the stack
            BRA     FIND_OPCODE

*-------------------IDENTIFY OPCODES------------------------
* evaluates an opcode based on first four bits (aka opTag)
*-----------------------------------------------------------
IDENTIFY_OPCODE:
            CMPA.L  A2, A3
            BEQ     DONE

            BSR     RESTORE_REGS
            BSR     PRINT_OPCODE

            BSR     GRAB_NEXT_WORD
            BSR     GRAB_FIRST_FOUR_BITS    ; grabs that opcode's ID (first four bits)
            BRA     FIND_OPCODE

RESTORE_REGS:
            MOVEM.L (SP)+, D0-D7/A0-A6      ; move the old registers onto the stack
            RTS

PRINT_OPCODE:
            CLR.L     D0
            MOVE.B    #14, D0
            TRAP      #15
            CLR_A_REG D0, A1

FIND_OPCODE:
            CMP.B   #%0000100, D0 
            JMP     opc_0100

            CMP.B   #%00001101, D0
            JMP     opc_1101

            * error, bad opcode
            BRA      BAD_OPCODE

BAD_OPCODE:
            JMP      DONE

GRAB_NEXT_WORD:
            * load current word of bits into opcode
            MOVE.W (A2)+, opcode

            * load into A4 register for printing
            MOVE.L   opcode, (A4)+
            MOVE.B  #' ', (A4)+
            MOVE.L   opcode, (A4)+

GRAB_FIRST_FOUR_BITS:
            * find first four bits of opcode
            MOVE.B  opcode, D2
            MOVE.B  #12, D1
            LSR.L   D1, D2
            MOVE.B  D2, opTag
            RTS

*-----------------------------------------------------------



*-----------------------------------------------------------
* First four bits = 0100
* (NOP, NOT, MOVEM, JSR, RTS, LEA) 
*-----------------------------------------------------------
opc_0100:
            
*-----------------------------------------------------------




*-----------------------------------------------------------
* First four bits = 1101
* (ADD,ADDA)
*-----------------------------------------------------------
opc_1101:
            * fill in A1 register
            MOVE.B  #'A',(A4)+          * Put ADD into Buff
            MOVE.B  #'D',(A4)+
            MOVE.B  #'D',(A4)+
            MOVE.B  #'.',(A4)+

            BSR     GET_SIZE  
            JSR     SIZE_TO_BUFFER
            BSR     EA_TO_DN            ; boolean value (either <ea> -> Dn or Dn -> <ea>)  
            JSR     EA_TO_BUFFER

            BSR     LOAD_ADDRESSES
            

GET_SIZE:
            CLR.L   D2
            MOVE.W  opcode ,D2          ; copy current instruction to shift
            
            * shift left to get rid of opTag
            MOVE.B  #7, D1
            LSL.W   D1, D2

            * shift right to get rid of opmode, mode, and register bits
            MOVE.B  #13, D1
            LSR.W   D1, D2

            * store in appropriate register
            MOVE.B  D2, D3
            RTS

EA_TO_DN:
            * D3 should hold the size of the opcode operation
            CLR.L   D2
            MOVE.W  D3, D2  

            * shift left to identify
            MOVE.B  #2, D1
            LSR.W   D1, D2
            
            * store in appropriate register
            MOVE.B  D2, D4
            RTS
*-----------------------------------------------------------


*---------------------SIZE TO BUFFER------------------------
* evaluates the size of an opcode and adds it to A1 to be printed out
*-----------------------------------------------------------
SIZE_TO_BUFFER: 
            CMP.B   #%00,D3            
            BEQ     BYTE_TO_BUFFER              

            CMP.B   #%01,D6             * is this a word?
            BEQ     WORD_TO_BUFFER

            CMP.B   #%10,D6             * is this a long?
            BEQ     LONG_TO_BUFFER             
      
            
            JMP     BAD_OPCODE  
            
BYTE_TO_BUFFER:
            MOVE.B  #'B', (A1)           * add B to buffer
            BRA     STB_END             
            
WORD_TO_BUFFER:
            MOVE.B  #'W', (A1)          * add W to buffer
            BRA     STB_END             

LONG_TO_BUFFER:
            MOVE.B  #'L',(A2)+          * add L to buffer
            BRA     STB_END             

STB_END:
            RTS                         

*-----------------------EA TO BUFFER------------------------
* evaluates the size of an opcode and adds it to A1 to be printed out
* Registers:
*   D2 = destination for shifts
*   D3 = size of opcode
*-----------------------------------------------------------
EA_TO_BUFFER:
            CLR.L   D2
            MOVE.B  D3, D2               ; move size of opcode to be manipulated
            BSR     EA_TO_BUFFER_LOOP

EA_TO_BUFFER_LOOP:
            CMP.B   #0, D2
            BEQ     EA_TO_BUFFER_END
            JSR     GRAB_NEXT_WORD
            SUB.B   #1, D2

EA_TO_BUFFER_END:
            RTS


*-------------------------DONE-------------------------------
DONE:
            CLR.L     D0
            MOVE.B    #14, D0
            LEA.L     doneMsg, A1
            TRAP      #15
            CLR_A_REG D0, A1

            END       MAIN              ; last line of source