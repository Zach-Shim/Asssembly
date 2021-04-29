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

startMsg:   DC.B    'Please enter a starting address ', CR, LF, 0
endMsg:     DC.B    'Please enter an ending address ', CR, LF, 0
doneMsg:    DC.B    'exiting...', CR, LF, 0
badInput:   DC.B    'Invalid Input', CR, LF, 0
newline:    DC.B    '', CR, LF, 0

userAddr:   DS.L    1
startAddr:  DS.L    1
endAddr:    DS.L    1

opOutput:   DS.L    2

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

CLR_A_REG:  MACRO
            CLR.L   \1
            MOVE.L  \1, \2
            ENDM              

*-----------------------------------------------------------
* Description:  Get User Input
*-----------------------------------------------------------

*-------------------------MAIN------------------------------
MAIN:
            BSR     GET_INPUT
            BRA     LOAD_ADDRESSES
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
            PRINT_MSG   newline
            
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
            PRINT_MSG   newline

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
*   D7 = holds addresses (word in length)
*   A1 = used for task 14 (printing out strings to screen) and trap #15
*   A2 = current address (given by user)
*   A3 = ending address (given by user)
*-----------------------------------------------------------


*---------------------LOAD ADDRESSES------------------------
* stores initial values into registers
*-----------------------------------------------------------
LOAD_ADDRESSES: 
            * Clear all registers and output register
            CLR_D_REGS
            CLR_A_REG       D0, A1


            * load start and end registers
            MOVEA.L startAddr, A2
            MOVEA.L endAddr, A3

            BSR     GRAB_NEXT_WORD
            MOVE.W  D7, opcode

            BSR     GRAB_FIRST_FOUR_BITS     ; grabs that opcode's ID (first four bits)

            * Push current registers onto the stack (so we can have fresh registers)
            MOVEM.L D0-D7,-(SP)              ; move the old registers onto the stack
            BRA     FIND_OPCODE

*-------------------IDENTIFY OPCODES------------------------
* evaluates an opcode based on first four bits (aka opTag)
*-----------------------------------------------------------
IDENTIFY_OPCODE:
            CMPA.L  A2, A3
            BGE     DONE

            ;BSR     RESTORE_REGS           need to fix
            BRA     PRINT_INSTRUCTION

            BSR     GRAB_NEXT_WORD
            BSR     GRAB_FIRST_FOUR_BITS    ; grabs that opcode's ID (first four bits)
            BRA     FIND_OPCODE

RESTORE_REGS:
            MOVEM.L (SP)+, D0-D7            ; move the old registers onto the stack
            RTS

PRINT_INSTRUCTION:    
            * null terminator
            MOVE.B    #00,(A1)              

            * reset A1 to beginning of string
            CLR.L     D0
            CLR_A_REG D0, A1

            * print out string
            MOVE.B    #14, D0
            TRAP      #15

            PRINT_MSG newline

BAD_OPCODE:
            JMP      DONE

GRAB_NEXT_WORD:
            * load current word of bits into D7
            MOVE.W (A2)+, D7

            * load into A1 register for printing
            RTS

GRAB_FIRST_FOUR_BITS:
            * find first four bits of opcode
            MOVE.W  opcode, D2
            MOVE.B  #12, D1
            LSR.L   D1, D2
            MOVE.B  D2, D0
            MOVE.B  D0, opTag
            RTS



*----------------------FIND OPCODE--------------------------
FIND_OPCODE:
            CMP.B   #%0000100, D0 
            BEQ     opc_0100

            CMP.B   #%00001101, D0
            BEQ     opc_1101

            * error, bad opcode
            BRA      BAD_OPCODE

*-----------------------------------------------------------




*-----------------------------------------------------------
* First four bits = 0100
* (NOP, NOT, MOVEM, JSR, RTS, LEA) 
*-----------------------------------------------------------
opc_0100:
            
*-----------------------------------------------------------




*-----------------------------------------------------------
* First four bits = 1101
* (ADD)
*-----------------------------------------------------------
opc_1101:
            * fill in A1 register
            MOVE.B  #'A',(A1)+          * Put ADD into Buff
            MOVE.B  #'D',(A1)+
            MOVE.B  #'D',(A1)+
            MOVE.B  #'.',(A1)+

            JSR     GET_SIZE  
            JSR     SIZE_TO_BUFFER
            JSR     OPERATION_TYPE      ; boolean value (either <ea> -> Dn or Dn -> <ea>)  
            JSR     GET_EA

            MOVE.B  #',',(A1)+
            MOVE.B  #' ',(A1)+
            JSR     GET_REGISTER_NUMBER

            BRA     IDENTIFY_OPCODE
            

GET_SIZE:
            CLR.L   D2
            MOVE.W  opcode ,D2          ; copy current instruction to shift
            
            * shift left to get rid of opTag
            MOVE.B  #8, D1
            LSL.W   D1, D2

            * shift right to get rid of opmode, mode, and register bits
            MOVE.B  #14, D1
            LSR.W   D1, D2

            * store in appropriate register
            ;ADD.B   #$30,D2                   * convert data register # to hex digit
            MOVE.B  D2, D3
            
            RTS

OPERATION_TYPE:
            * D3 should hold the size of the opcode operation
            CLR.L   D2
            MOVE.W  D3, D2  

            * shift left to identify
            MOVE.B  #7, D1
            LSL.W   D1, D2
            
            * shift left to identify
            MOVE.B  #15, D1
            LSR.W   D1, D2

            * store in appropriate register
            ;ADD.B   #$30,D2                   * convert data register # to hex digit
            ;MOVE.B  D2,(A1)+                  * register # to buffer    
            MOVE.B  D2, D4

            RTS

GET_REGISTER_NUMBER:
            * D3 should hold the size of the opcode operation
            CLR.L   D2
            MOVE.W  opcode, D2  

            * shift left to identify
            MOVE.B  #4, D1
            LSL.W   D1, D2
            
            * shift right to isolate high register bits
            MOVE.B  #13, D1
            LSR.W   D1, D2

            * store in appropriate register
            MOVE.B  #'D',(A1)+              * add "D" to buffer
            ADD.B   #$30,D2                   * convert data register # to hex digit
            MOVE.B  D2,(A1)+                * register # to buffer             
            MOVE.B  D2, D6

            RTS
*-----------------------------------------------------------


*----------------------------GET_EA------------------------
* evaluates the size of an opcode and adds it to A1 to be printed out
* prints out the effective address mode and register
* Registers:
*   D2 = destination for shifts
*   D3 = size of opcode
*   D5 = addressing mode
*-----------------------------------------------------------
GET_EA:
            * move size of opcode to be manipulated
            CLR.L   D2
            MOVE.B  D3, D2                     

            * shift left to identify
            MOVE.B  #10, D1
            LSL.W   D1, D2
            
            * shift right to isolate mode bits for EA 
            MOVE.B  #13, D1
            LSR.W   D1, D2

            * store in appropriate register
            MOVE.B  D2, D5
            
            BRA     GET_EA_MODE

*----------------------------GET_EA_MODE------------------------
GET_EA_MODE:                              * table holds the different EA modes

            CMP.B   #%00000000, D5        * Direct Data Register
            BEQ     ea_000

            CMP.B   #%00000001, D5        * Direct Address Register
            BEQ     ea_001

            CMP.B   #%00000010, D5        * Indirect Address Register
            BEQ     ea_010

            CMP.B   #%00000011, D5        * Post Increment
            BEQ     ea_011

            CMP.B   #%00000100, D5        * Pre Decrement
            BEQ     ea_100

            CMP.B   #%00000101, D5        * Not necessary, go to bad ea
            BEQ     ea_101

            CMP.B   #%00000111, D5        * Not necessary, go to bad ea
            BEQ     ea_110

            CMP.B   #%00000111, D5        * Absolute or immediate address
            BEQ     ea_111

*----------------------------Direct Data Register------------------------
ea_000:
            MOVE.W      opcode, D2              * move current working word into temp storage
            MOVE.B      #'D',(A1)+              * add "D" to buffer
            
            MOVE.B      #13, D1
            LSL.W       D1,D2                   * isolate register bits (last 3)
            LSR.W       D1,D2                   * isolate register bits (last 3)
            ADD.B       #$30,D2                 * convert data register # to hex digit

            MOVE.B      D2,(A1)+                * register # to buffer                  
            
            RTS                                 * Return

*----------------------------Direct Address Register------------------------
ea_001:
            MOVE.W      opcode, D2              * move current working word into temp storage
            MOVE.B      #'A',(A1)+              * add "A" to buffer
            
            MOVE.B      #13, D1
            LSL.W       D1,D2                   * isolate register bits (last 3)
            LSR.W       D1,D2                   * isolate register bits (last 3)
            ADD.B       #$30,D2                 * convert data register # to hex digit

            MOVE.B      D2,(A1)+                * register # to buffer               
              
            RTS                                 * Return

*----------------------------Indirect Address Register------------------------
ea_010:
            MOVE.W      opcode, D2              * move current working word into temp storage
            MOVE.B      #'(',(A1)+              * add "(" to buffer
            MOVE.B      #'A',(A1)+              * add "A" to buffer

            MOVE.B      #13, D1
            LSL.W       D1,D2                   * isolate register bits (last 3)
            LSR.W       D1,D2                   * isolate register bits (last 3)
            ADD.B       #$30,D2                 * convert data register # to hex digit
            MOVE.B      D2,(A1)+                * register # to buffer     

            MOVE.B      #')',(A1)+              * add ")" to buffer
             
            RTS                                 * Return

*----------------------------Post Increment------------------------
ea_011:
            MOVE.W      opcode, D2              * move current working word into temp storage

            MOVE.B      #'(',(A1)+              * add "D" to buffer
            MOVE.B      #'A',(A1)+              * add "D" to buffer
            
            MOVE.B      #13, D1
            LSL.W       D1,D2                   * isolate register bits (last 3)
            LSR.W       D1,D2                   * isolate register bits (last 3)
            ADD.B       #$30,D2                 * convert data register # to hex digit
            MOVE.B      D2,(A1)+                * register # to buffer     

            MOVE.B      #')',(A1)+              * add "D" to buffer
            MOVE.B      #'+',(A1)+              * add "D" to buffer
                 
            RTS                                 * Return

*----------------------------Pre Decrement------------------------
ea_100:
            MOVE.W      opcode, D2              * move current working word into temp storage

            MOVE.B      #'-',(A1)+              * add "D" to buffer
            MOVE.B      #'(',(A1)+              * add "D" to buffer
            MOVE.B      #'A',(A1)+              * add "D" to buffer
            
            MOVE.B      #13, D1
            LSL.W       D1,D2                   * isolate register bits (last 3)
            LSR.W       D1,D2                   * isolate register bits (last 3)
            ADD.B       #$30,D2                 * convert data register # to hex digit
            MOVE.B      D2,(A1)+                * register # to buffer     

            MOVE.B      #')',(A1)+              * add "D" to buffer
            
            RTS                                     * Return

*----------------------------Not necessary, go to bad ea------------------------
ea_101:
            JMP         INVALID_EA             * set bad instruction flag


*----------------------------Not necessary, go to bad ea------------------------
ea_110:
            JMP         INVALID_EA             * set bad instruction flag



*----------------------------Absolute or immediate address------------------------
ea_111:
            JSR      GET_SIZE            * Get Register bits

            CMP.B    #$0,D6              * compare to determine if it's a word
            BEQ      EA_TO_BUFFER        * put word address in buffer

            CMP.B    #$1,D6              * compare to determine if it's a long
            BEQ      EA_TO_BUFFER        * put long address in buffer
            
            CMP.B    #$2,D6
            BEQ      EA_TO_BUFFER

            * NEED TO WORK ON IMMEDIATE
           
            RTS

*----------------------------Invalid Effective Address------------------------
INVALID_EA:
            JMP      DONE
*-----------------------------------------------------------


*---------------------SIZE TO BUFFER------------------------
* evaluates the size of an opcode and adds it to A1 to be printed out
*-----------------------------------------------------------
SIZE_TO_BUFFER: 
            CMP.B   #%0000,D3            
            BEQ     BYTE_TO_BUFFER              

            CMP.B   #%0001,D3             * is this a word?
            BEQ     WORD_TO_BUFFER

            CMP.B   #%0010,D3             * is this a long?
            BEQ     LONG_TO_BUFFER             
      
            
            JMP     BAD_OPCODE  
            
BYTE_TO_BUFFER:
            MOVE.B  #'B', (A1)+           * add B to buffer
            BRA     STB_END             
            
WORD_TO_BUFFER:
            MOVE.B  #'W', (A1)+          * add W to buffer
            BRA     STB_END             

LONG_TO_BUFFER:
            MOVE.B  #'L',(A1)+          * add L to buffer
            BRA     STB_END             

STB_END:
            MOVE.B  #' ',(A1)+          * add L to buffer
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