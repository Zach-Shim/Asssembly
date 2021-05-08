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
* \1 should be highest bit in range
* \2 should be lowest bit in range
* Result will be returned in D4
* Example: #11, #9
*
* Return Value:
*   D4 = value held within bits \1 and \2
*
* Registers:
*   D4 = holds opcode
*   D5 = highest bit in range 
*   D6 = lowest bit in range 
*   D7 = number of bits we want
*-----------------------------------------------------------
GET_BITS:   MACRO

            CLR_D_REGS

            * Subtract value to find amount to shift by 
            ADD.B   \1, D7          
            SUB.B   \2, D7 
            ADD.B   #1, D7  * add 1 because we start our count from 0

            * Get high bit offset
            ADD.B   #15, D5
            SUB.B   \1, D5
            
            * shift out high bits
            MOVE.W  opcode, D4
            LSL.W   D5, D4
            
            *get low bit offset
            *16 - NUMBER OF BITS WE WANT
            ADD.B   #16, D6         * 16 total bits
            SUB.L   D7, D6          * subtract numBits from 16
            
            * shift out low bits
            LSR.W   D6, D4          * isolate bits
            ENDM

*----------------------Value To Buffer----------------------
* Description:
* Converts a Hex numbered address (1-9 or A-F) back to an
* ASCII value and pushes it to the buffer for printing
*
* Parameters:
*   \1 = should hold value (in hex) you want to push to the buffer
*
*-----------------------------------------------------------
VALUE_TO_BUFFER:  MACRO
                  MOVE.L  \1, D2  
                  JSR     NUMBER_OR_LETTER
                  ENDM
*-----------------------------------------------------------

*----------------------Size To Buffer-----------------------
* Description:
* Converts a binary size (Byte = 00, Word = 01, or Long = 10) 
* to a letter (B, W, L) and pushes it to the buffer
*
* Parameters:
*   \1 = should hold size (in binary) of the size you want
*        to push to the buffer
*
*-----------------------------------------------------------
SIZE_TO_BUFFER:   MACRO
                  MOVE.L  \1, D3
                  JSR     FIND_SIZE
                  ENDM
*-----------------------------------------------------------

*----------------------Buffer Macros------------------------
* Description:
* Pushes commonly used single characters to the buffer
*-----------------------------------------------------------
INSERT_SPACE:   MACRO
                MOVE.B  #' ',(A1)+          * add blank space to buffer
                ENDM

INSERT_COMMA:   MACRO
                MOVE.B  #',',(A1)+          * add blank space to buffer
                ENDM

INSERT_PERIOD:  MACRO
                MOVE.B  #'.',(A1)+          * add blank space to buffer
                ENDM

INSERT_POUND:   MACRO
                MOVE.B  #'#',(A1)+          * add blank space to buffer
                ENDM

INSERT_DOLLAR:  MACRO
                MOVE.B  #'$',(A1)+          * add blank space to buffer
                ENDM
*-----------------------------------------------------------








*-----------------------------------------------------------
* Description:  
* Main routine
*-----------------------------------------------------------

*-------------------------MAIN------------------------------
MAIN:
            BSR     GET_INPUT
            BRA     LOAD_ADDRESSES
*-----------------------------------------------------------








*-----------------------------------------------------------
* Description:  
* Get User Input
*
* Registers Used:
*   D0 = task values
*   D1 = stores of size of ascii string in A1 from user input
*   D4 = bool check (0 = starting address, 1 = ending address, 2 = done)
*   A1 = stores an ascii string from user input
*-----------------------------------------------------------
*-------------------------Get Input-------------------------
GET_INPUT:
            CMP      #0, D4
            BEQ      GET_START_ADDRESS
               
            MOVE.L   D6, startAddr
            MOVE.L   D7, endAddr
            RTS 
*-----------------------------------------------------------

*----------------------Get Starting Address-----------------
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

*----------------------Get Ending Address-------------------
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
*
* Registers Used:
*   D0 = task values
*   D1 = stores of size of ascii string in A1 from user input
*   D4 = bool check (0 = starting address, 1 = ending address, 2 = done)
*   A1 = stores an ascii string from user input
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
            
            CLR         D3
            BRA         VALIDATE_INPUT

STORE_END:
            MOVE.L     D3, D7
            ADD.B      #1, D4               ; value to indicate if we are done parsing

            CLR         D3
            BRA         VALIDATE_INPUT
*-----------------------------------------------------------











*--------------------------PRINT----------------------------
* Description:
* Prints hex addresses according to where we are in the .S file
* and source/destination effective addresses
*
* No Parameters
*
* Registers:
*   D0 = used for tasks and trap #15
*   D1 = size of comparison
*   D2 = destination for comparisons, holds an address
*   D3 = iterator
*   A1 = used for task 14 (printing out strings to screen) and trap #15
*   A2 = current address (given by user)
*-----------------------------------------------------------

*----------------------PRINT_ADDRESS------------------------
PRINT_ADDRESS:
            * reset A1 to beginning of string
            CLR_D_REGS
            CLR_A_REG D0, A1
            
            * move current address to D2
            MOVE.L    A2, D2

            * if absolute short, print word. Range $0000 - $7FFF and $FFFF8000 - $FFFFFFFF
            MOVE.L    #$8000, D1
            CMP.L     D1, D2
            BLT       PRINT_WORD
            
            * if absolute long, print long. Range $8000 - $FFFF7FFF
            MOVE.L    #$FFFF8000, D1
            CMP.L     D1, D2
            BGE       PRINT_LONG                 

PRINT_WORD:
            CLR_D_REGS
            MOVE.B    #1, D1            * passing 1 means we are passing word as a parameter to HEX_TO_ASCII
            MOVE.W    A2, D7            * passing current parsing position means we are passing an address as a parameter in D7 to HEX_TO_ASCII
            JSR       HEX_TO_ASCII
            BRA       FINISH_PRINT

PRINT_LONG:
            CLR_D_REGS
            MOVE.B    #3, D1            * passing 1 means we are passing long as a parameter to HEX_TO_ASCII
            MOVE.L    A2, D7
            JSR       HEX_TO_ASCII
            BRA       FINISH_PRINT

FINISH_PRINT:
            * print out string
            MOVE.B    #00,(A1)
            CLR_D_REGS
            CLR_A_REG D0, A1
            MOVE.B    #14, D0
            TRAP      #15
            RTS
*-----------------------------------------------------------

*-------------------PRINT_INSTRUCTION-----------------------
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
            RTS
*-----------------------------------------------------------




















*---------------------LOAD ADDRESSES------------------------
* Description:
* Stores INITIAL values into appropriate address registers 
* which is necessary to complete before starting identify opcodes loop
* Also pushes reigsters onto the stack
*
* No Parameters
*
* Registers:
*   A2 = current address (given by user)
*   A3 = ending address (given by user)
*-----------------------------------------------------------
LOAD_ADDRESSES: 
            * reset A1 to beginning of string
            CLR.L     D0
            CLR_A_REG D0, A1

            * load start and end registers and print starting address
            MOVEA.L startAddr, A2
            MOVEA.L endAddr, A3
            BSR     PRINT_ADDRESS
            INSERT_SPACE

            BSR     GRAB_NEXT_WORD
            BSR     GRAB_FIRST_FOUR_BITS     ; grabs that opcode's ID (first four bits)

            * Push current registers onto the stack (so we can have fresh registers)
            MOVEM.L D0-D7,-(SP)              ; move the old registers onto the stack
            BRA     FIND_OPCODE
*-----------------------------------------------------------

*-----------------------------------------------------------
* Description:  IDENTIFY OPCODES LOOP
* Registers:
*   D0 = used for tasks and trap #15
*   D1 = size of shifting bits
*   D2 = destination for shifts
*   D3 = size of opcode
*   D4 = used to hold bits returned from SHIFT macro
*   A1 = used for task 14 (printing out strings to screen) and trap #15
*   A2 = current address (given by user)
*   A3 = ending address (given by user)
*-----------------------------------------------------------
*-------------------IDENTIFY OPCODES------------------------
* evaluates an opcode based on first four bits (aka opTag)
* for now only works with one instruction
*-----------------------------------------------------------
IDENTIFY_OPCODE:

            * print opcode
            BSR     PRINT_INSTRUCTION

            * check if starting address >= ending address
            CMPA.L  A3, A2
            BGE     DONE
            
            * print next address
            BSR     PRINT_ADDRESS
            INSERT_SPACE
            
            ;BSR     RESTORE_REGS           need to fix

            CLR_D_REGS
            BSR     GRAB_NEXT_WORD          * grab opcode
            BSR     GRAB_FIRST_FOUR_BITS    * grabs that opcode's ID (first four bits)
           
            BRA     FIND_OPCODE
*------------------------------------------------------------

*----------------------RESTORE_REGS--------------------------
* Description:
* Move the old registers onto the stack
*------------------------------------------------------------
RESTORE_REGS:
            MOVEM.L (SP)+, D0-D7            
            RTS
*-----------------------------------------------------------

*---------Useful Subroutines For Identifying Opcodes--------
GRAB_NEXT_WORD:
            * load current word of bits into D7
            MOVE.W (A2)+, opcode
            RTS

GRAB_FIRST_FOUR_BITS:
            * find first four bits of opcode
            MOVE.W  opcode, D2
            MOVE.B  #12, D1
            LSR.L   D1, D2
            MOVE.B  D2, D0
            MOVE.B  D0, opTag
            RTS
*-----------------------------------------------------------









*----------------------FIND OPCODE--------------------------
* Description:
* Finds a matching opTag (first four bits of opcode) and 
* jumps to that opcode's encoding subroutine
*
* For example:
*               ADD's first four bits = 1101, so I put
*               CMP.B #%1101, D0
*
* No Parameters
*
* No Registers Used
*-----------------------------------------------------------        
FIND_OPCODE:
            CMP.B   #%0000, opTag 
            BEQ     OPC_0000

            CMP.B   #%0100, opTag 
            BEQ     OPC_0100

            CMP.B   #%0101, opTag 
            BEQ     OPC_0101

            CMP.B   #%1000, opTag
            BEQ     OPC_1000

            CMP.B   #%1001, opTag
            BEQ     OPC_1001

            CMP.B   #%1100, opTag
            BEQ     OPC_1100

            CMP.B   #%1101, opTag
            BEQ     OPC_1101

            * error, bad opcode
            BRA      BAD_OPCODE

*-----------------------------------------------------------

*-----------------------BAD OPCODE--------------------------
BAD_OPCODE:
            JMP      DONE
*-----------------------------------------------------------

*------------------------OPC_0000---------------------------
* First four bits = 0000
* (ADDI, SUBI)
*-----------------------------------------------------------
OPC_0000:
            GET_BITS  #11, #8
            
            * is the opcode ADDI?
            CMP.B     #%0110, D4
            BEQ       OPC_ADDI

            * is the opcode SUBI?
            CMP.B     #%0100, D4
            BEQ       OPC_SUBI

            JMP       BAD_OPCODE

*------------------------OPC_ADDI---------------------------
OPC_ADDI:
            MOVE.B  #'A',(A1)+          * Put ADD into Buff
            MOVE.B  #'D',(A1)+
            MOVE.B  #'D',(A1)+
            MOVE.B  #'I',(A1)+
            INSERT_PERIOD

            BSR     DECODE_IMMEDIATE

*------------------------OPC_SUBI---------------------------
OPC_SUBI:            
            MOVE.B  #'S',(A1)+          * Put ADD into Buff
            MOVE.B  #'U',(A1)+
            MOVE.B  #'B',(A1)+
            MOVE.B  #'I',(A1)+
            INSERT_PERIOD

            BSR     DECODE_IMMEDIATE

*--------------Subroutines for OPC_0000---------------------  
DECODE_IMMEDIATE:
            * push size to buffer
            GET_BITS        #7, #6              * get size bits (gets returned to D4)
            SIZE_TO_BUFFER  D4                  * put operation size in buffer

            * push #<data> to buffer
            JSR     CHECK_IMMEDIATE

            INSERT_COMMA
            INSERT_SPACE

            * push <ea> to buffer
            JSR     DECODE_BITS_6_TO_0
            BRA     IDENTIFY_OPCODE
 
CHECK_IMMEDIATE:
            INSERT_POUND

            CMP     #1, D3
            BLE     IMMEDIATE_WORD

            CMP     #2, D3
            BRA     IMMEDIATE_LONG

IMMEDIATE_WORD:
            JSR     EA_WORD
            RTS

IMMEDIATE_LONG:
            JSR     EA_LONG      
            RTS
*-----------------------------------------------------------


*------------------------OPC_0100---------------------------
* First four bits = 0100
* (NOP, NOT, MOVEM, JSR, RTS, LEA) 
*-----------------------------------------------------------
OPC_0100:

            * Check if the opcode is NOP
            MOVE.W  opcode, D2              * Copy opcode to D2
            CMP.W   #$4E71, D2              * Check if D2 is equal to NOP (0x4E71 in hex)
            BEQ     OPC_NOP                 * If equal branch to label to handle the opcode NOP
            
            * Check if the opcode is NOT
            ASR.L   #8, D2                  * Shift bits to compare
            CMP.B   #%01000110, D2
            BEQ     OPC_NOT
            CLR.L   D2
            
            * Check if the opcode is LEA
            MOVE.W   opcode, D4             * Put opcode in D4 to use the macro get bits
            GET_BITS #8, #6 
            CMP.B   #%0111, D4              * if bits 6-8 are equal to 111, then the opocde is LEA
            BEQ     OPC_LEA

            * Check if the opcode is JSR
            CMP.B   #%0010, D4              * if bits 6-8 are equal to 010, then the opocde is LEA
            BEQ     OPC_JSR

            * Check if the opcode is RTS
            CMP.B   #%0001, D4              * if bits 6-8 are equal to 001, then the opocde is LEA
            BEQ     OPC_RTS

*---------------------------OPC_NOP--------------------------------

OPC_NOP:
            * Put NOP into A1 buffer for printing
            MOVE.B  #'N',(A1)+      
            MOVE.B  #'O',(A1)+ 
            MOVE.B  #'P',(A1)+ 
            
            BRA     IDENTIFY_OPCODE


*-----------------------------OPC_NOT------------------------------

OPC_NOT:
            * Put NOT into A1 buffer for printing
            MOVE.B  #'N',(A1)+ 
            MOVE.B  #'O',(A1)+
            MOVE.B  #'T',(A1)+
            INSERT_PERIOD
            
            * Calculate Size (.b,.w.l)
            GET_BITS        #7, #6
            SIZE_TO_BUFFER  D4                  * put operation size in buffer
            JSR             DECODE_BITS_6_TO_0
            BRA             IDENTIFY_OPCODE

*-----------------------------OPC_LEA------------------------------
OPC_LEA:
            * Put LEA into A1 buffer for printing
            MOVE.B  #'L',(A1)+      
            MOVE.B  #'E',(A1)+ 
            MOVE.B  #'A',(A1)+
            INSERT_PERIOD
            MOVE.B  #'L',(A1)+ 
            INSERT_SPACE
                    
            JSR     DECODE_BITS_6_TO_0
            INSERT_COMMA
            INSERT_SPACE
            JSR GET_DATA_REG_NUM

            BRA IDENTIFY_OPCODE    


*-----------------------------------------------------------

*-----------------------------OPC_JSR------------------------------
OPC_JSR:
            * Put LEA into A1 buffer for printing
            MOVE.B  #'J',(A1)+      
            MOVE.B  #'S',(A1)+ 
            MOVE.B  #'R',(A1)+
            INSERT_SPACE
            
            JSR     DECODE_BITS_6_TO_0
            BRA     IDENTIFY_OPCODE  

*-----------------------------OPC_RTS------------------------------
OPC_RTS:
            * Put LEA into A1 buffer for printing
            MOVE.B  #'R',(A1)+      
            MOVE.B  #'T',(A1)+ 
            MOVE.B  #'S',(A1)+
        
            BRA IDENTIFY_OPCODE

*-----------------------------------------------------------

*---------------------------OPC_1000------------------------
* First four bits = 1001
* (DIVU)
*-----------------------------------------------------------
OPC_1000:   * keeping this in case there's more that start with 1000
            BRA     OPC_DIVU
            
OPC_DIVU:
            MOVE.B  #'D',(A1)+
            MOVE.B  #'I',(A1)+
            MOVE.B  #'V',(A1)+
            MOVE.B  #'U',(A1)+
            INSERT_PERIOD
            MOVE.B  #'W',(A1)+  * always size word
            INSERT_SPACE
            
            * set the valid bits (since there's only one adressing mode)
            MOVE.B  #%10111111, valid
            
            JMP     EA_TO_D

*-----------------------------------------------------------



*-----------------------OPC_0101----------------------------
* First four bits = 0101
* (ADDQ, SUBQ)
*-----------------------------------------------------------
OPC_0101:
            GET_BITS  #8, #8
            
            * is the opcode ADDQ?
            CMP.B     #%0000, D4
            BEQ       OPC_ADDQ

            * is the opcode SUBI?
            CMP.B     #%0001, D4
            BEQ       OPC_SUBQ

            JMP       BAD_OPCODE

*------------------------OPC_ADDQ---------------------------
OPC_ADDQ:
            MOVE.B  #'A',(A1)+          * Put ADD into Buff
            MOVE.B  #'D',(A1)+
            MOVE.B  #'D',(A1)+
            MOVE.B  #'Q',(A1)+
            INSERT_PERIOD

            BSR     DECODE_QUICK

*------------------------OPC_SUBI---------------------------
OPC_SUBQ:            
            MOVE.B  #'S',(A1)+          * Put ADD into Buff
            MOVE.B  #'U',(A1)+
            MOVE.B  #'B',(A1)+
            MOVE.B  #'Q',(A1)+
            INSERT_PERIOD

            BSR     DECODE_QUICK

*------------------Subroutines for OPC_0101-----------------
DECODE_QUICK:            
            * Get size of operation and push to buffer
            CLR.L           D4
            GET_BITS        #7, #6
            SIZE_TO_BUFFER  D4                  * put operation size in buffer

            * push value of #<data> to buffer
            CLR.L            D4
            GET_BITS         #11, #9
            INSERT_POUND
            VALUE_TO_BUFFER  D4

            INSERT_COMMA
            INSERT_SPACE

            * push <ea> to buffer
            JSR     DECODE_BITS_6_TO_0
            BRA     IDENTIFY_OPCODE
*-----------------------------------------------------------



*-----------------------OPC_1001----------------------------
* First four bits = 1001
* (SUB)
*-----------------------------------------------------------
OPC_1001:
            * fill in A1 register
            MOVE.B  #'S',(A1)+          * Put ADD into Buff
            MOVE.B  #'U',(A1)+
            MOVE.B  #'B',(A1)+
            INSERT_PERIOD
            BRA     PROCESS_ROEA
*-----------------------------------------------------------



*-----------------------OPC_1100----------------------------
* First four bits = 1100
* (AND, MULS)
*-----------------------------------------------------------
OPC_1100:   
            ; check to see if bits 8-6 are 111
            ; if they are, then branch to PARSE_MULS
            ; else, keep going to parse AND

            GET_BITS #8, #6
            CMP.B   #%00000111, D4
            BEQ     OPC_MULS
            BNE     OPC_AND

*---------------------------OPC_AND------------------------
OPC_AND:    ; AND opcode subroutine

            ;-----------------------------
            ; fill A1 with the opcode name
            MOVE.B  #'A',(A1)+
            MOVE.B  #'N',(A1)+
            MOVE.B  #'D',(A1)+
            INSERT_PERIOD
            BRA     PROCESS_ROEA

*---------------------------OPC_MULS------------------------
OPC_MULS:  * MULS opcode subroutine

            * load the command name into the output
            MOVE.B  #'M',(A1)+
            MOVE.B  #'U',(A1)+
            MOVE.B  #'L',(A1)+
            MOVE.B  #'S',(A1)+
            INSERT_PERIOD
            MOVE.B  #'W',(A1)+ * always size word
            INSERT_SPACE
            
            MOVE.B  #%10111111, valid   * set the valid mode bits (to be used later)
            
            JMP     EA_TO_D
*-----------------------------------------------------------


*---------------------------opc_1101------------------------
* First four bits = 1101
* (ADD)
*-----------------------------------------------------------
OPC_1101:
            * fill in A1 register
            MOVE.B  #'A',(A1)+          * Put ADD into Buff
            MOVE.B  #'D',(A1)+
            MOVE.B  #'D',(A1)+
            INSERT_PERIOD
            BRA     PROCESS_ROEA        * subroutine processes everything for ADD

*-----------------------------------------------------------











*--------------Process Register->Opmode->EA-----------------
* Description:
* Parses bits for opcodes that share bit placements:
* ROEA stands for Register, Opmode, and Effective Address,
* because the opcodes below share this bit order.
*
* Used by: (ADD, SUB, MULS)
*
*-----------------------------------------------------------
PROCESS_ROEA:
            GET_BITS        #7, #6              * retrieve size
            SIZE_TO_BUFFER  D4                  * put operation size in buffer

            GET_BITS        #8, #8              * retrieve type  
            CMP.B           #1, D4              * is this Dn + <ea> -> <ea>?
            BEQ             D_TO_EA
            CMP.B           #0, D4              * is this <ea> + Dn -> <ea>?
            BEQ             EA_TO_D

D_TO_EA:
            JSR     GET_DATA_REG_NUM
            INSERT_COMMA
            INSERT_SPACE
            JSR     DECODE_BITS_6_TO_0
            BRA     ROEA_DONE

EA_TO_D:
            JSR     DECODE_BITS_6_TO_0
            INSERT_COMMA
            INSERT_SPACE
            JSR     GET_DATA_REG_NUM
            BRA     ROEA_DONE

ROEA_DONE:
            INSERT_SPACE
            BRA     IDENTIFY_OPCODE

GET_DATA_REG_NUM:
            CLR.L    D4
            GET_BITS #11, #9                     * retrieve high data register number

            * store in appropriate register
            MOVE.B            #'D',(A1)+                  * add "D" to buffer
            VALUE_TO_BUFFER   D4          
            RTS
*-----------------------------------------------------------












*----------------------DECODE_BITS_6_TO_0------------------
* Description:
* Evaluates the ea mode and register of an opcode 
* (usually last 6 bits of instruction format),
* and adds it to A1 to be printed out
*
* No Parameters
*
* Registers Used:
*   D1 = amount to shift the opcode
*   D2 = destination for shifts
*   D5 = addressing mode
*-----------------------------------------------------------
DECODE_BITS_6_TO_0:
            CLR_D_REGS
            * move size of opcode to be manipulated
            CLR.L   D2
            MOVE.W  opcode, D2     

            * shift left to identify
            MOVE.B  #10, D1
            LSL.W   D1, D2
            
            * shift right to isolate mode bits for EA 
            MOVE.B  #13, D1
            LSR.W   D1, D2

            * store in appropriate register
            MOVE.B  D2, D5
            
            BRA     FIND_MODE

*----------------------------FIND_MODE------------------------
FIND_MODE:                            
            CMP.B   #%0000, D5        * Direct Data Register
            BEQ     ea_000

            CMP.B   #%0001, D5        * Direct Address Register
            BEQ     ea_001

            CMP.B   #%0010, D5        * Indirect Address Register
            BEQ     ea_010

            CMP.B   #%0011, D5        * Post Increment
            BEQ     ea_011

            CMP.B   #%0100, D5        * Pre Decrement
            BEQ     ea_100

            CMP.B   #%0101, D5        * Not necessary, go to bad ea
            BEQ     ea_101

            CMP.B   #%0110, D5        * Not necessary, go to bad ea
            BEQ     ea_110

            CMP.B   #%0111, D5        * Absolute or immediate address
            BEQ     ea_111

            BRA    INVALID_EA

*----------------------------Direct Data Register------------------------
ea_000:
            MOVE.W      opcode, D2              * move current working word into temp storage
            MOVE.B      #'D',(A1)+              * add "D" to buffer
            
            MOVE.B      #13, D1
            LSL.W       D1,D2                   * isolate register bits (last 3)
            LSR.W       D1,D2                   * D2 now holds the mode of the opcode
            ADD.B       #$30,D2                 * convert data register # to ASCII digit

            MOVE.B      D2,(A1)+                * register # to buffer                  
            
            RTS                                

*----------------------------Direct Address Register------------------------
ea_001:
            MOVE.W      opcode, D2              * move current working word into temp storage
            MOVE.B      #'A',(A1)+              * add "A" to buffer
            
            MOVE.B      #13, D1
            LSL.W       D1,D2                   * isolate register bits (last 3)
            LSR.W       D1,D2                   * D2 now holds the mode of the opcode
            ADD.B       #$30,D2                 * convert data register # to ASCII digit

            MOVE.B      D2,(A1)+                * register # to buffer               
              
            RTS                            

*----------------------------Indirect Address Register------------------------
ea_010:
            MOVE.W      opcode, D2              * move current working word into temp storage
            MOVE.B      #'(',(A1)+              * add "(" to buffer
            MOVE.B      #'A',(A1)+              * add "A" to buffer

            MOVE.B      #13, D1
            LSL.W       D1,D2                   * isolate register bits (last 3)
            LSR.W       D1,D2                   * D2 now holds the mode of the opcode
            ADD.B       #$30,D2                 * convert data register # to ASCII digit
            MOVE.B      D2,(A1)+                * register # to buffer     

            MOVE.B      #')',(A1)+              * add ")" to buffer
             
            RTS                            

*----------------------------Post Increment------------------------
ea_011:
            MOVE.W      opcode, D2              * move current working word into temp storage

            MOVE.B      #'(',(A1)+              * add "(" to buffer
            MOVE.B      #'A',(A1)+              * add "A" to buffer
            
            MOVE.B      #13, D1
            LSL.W       D1,D2                   * isolate register bits (last 3)
            LSR.W       D1,D2                  
            ADD.B       #$30,D2                 * convert data register # to ASCII digit
            MOVE.B      D2,(A1)+                * register # to buffer     

            MOVE.B      #')',(A1)+              * add ")" to buffer
            MOVE.B      #'+',(A1)+              * add "+" to buffer
                 
            RTS                              

*----------------------------Pre Decrement------------------------
ea_100:
            MOVE.W      opcode, D2              * move current working word into temp storage

            MOVE.B      #'-',(A1)+              * add "-" to buffer
            MOVE.B      #'(',(A1)+              * add "(" to buffer
            MOVE.B      #'A',(A1)+              * add "A" to buffer
            
            MOVE.B      #13, D1
            LSL.W       D1, D2                   * isolate register bits (last 3)
            LSR.W       D1, D2                   * D2 now holds the mode of the opcode
            ADD.B       #$30, D2                 * convert data register # to ASCII digit
            MOVE.B      D2, (A1)+                * register # to buffer     

            MOVE.B      #')',(A1)+               * add ")" to buffer
            
            RTS

*----------------------------Not necessary, go to bad ea------------------------
ea_101:
            BRA         INVALID_EA        


*----------------------------Not necessary, go to bad ea------------------------
ea_110:
            BRA         INVALID_EA        


*----------------------------Absolute or immediate address------------------------
ea_111:
            * D405      0 0003456  23345245
            * ADD.L     $1234, D0

            * 8 bit value
            * 11111111

            * 11111011 - Direct data register would be Invalid
            * 00000100
            * 00000000 -> invalid code

            * and.b     #$F, Dn        ---->  10000000
            * cmp.b     #%10000000, Dn  

            * check against valid bits
                * if invalid, branch to invalid opcode subroutine
                    * if the mode is 111, then go back and print out addresses

            MOVE.W      opcode, D2
            MOVE.B      #13, D1
            LSL.W       D1, D2                   * isolate register bits (last 3)
            LSR.W       D1, D2                   * isolate register bits (last 3)

            CMP.B       #%000, D2                * compare to determine if it's a word
            BEQ         EA_WORD                  * put word address in buffer

            CMP.B       #%001, D2                * compare to determine if it's a long
            BEQ         EA_LONG                  * put long address in buffer
            
            CMP.B       #%100, D2
            BEQ         EA_IMMEDIATE             * always print a long if it's immediate data

            * Invalid EA mode/register
            BRA         INVALID_EA

EA_WORD:
            MOVE.B      #'$', (A1)+
            CLR.L       D1
            MOVE.B      #1, D1
            MOVE.W      (A2)+, D7
            BSR         HEX_TO_ASCII
            BRA         GET_EA_DONE

EA_LONG:
            MOVE.B      #'$', (A1)+
            CLR.L       D1
            MOVE.B      #3, D1
            MOVE.L      (A2)+, D7   
            BSR         HEX_TO_ASCII
            BRA         GET_EA_DONE

EA_IMMEDIATE:
            MOVE.B      #'#', (A1)+

            * if MULS or DIVU, fetch Word from memory
            CLR.L       D1
            MOVE.B      opcode, D1          * load first four bits of opcode

            CMP.B       #%1100, D1          * is this MULS?
            BEQ         TEST_1100           * there are multiple opcodes with this tag

            CMP.B       #%1000, D1          * is this DIVU?
            BEQ         EA_WORD          

            BRA         EA_LONG             * else, print longword worth of data

TEST_1100:
            GET_BITS #8, #6                 
            CMP.B    #%0111, D4
            BEQ      EA_WORD
            BRA      EA_LONG

GET_EA_DONE:
            RTS

*------------------Invalid Effective Address----------------
INVALID_EA:
            JMP      DONE
*-----------------------------------------------------------









*----------------------HEX TO ASCII-------------------------
* Description:
* Converts a Hex numbered address (1-9 or A-F) back to an
* ASCII value for printing
*
* Parameters (if calling HEX_TO_ASCII (always used by print subroutine)):
*   D1 = pass in 1 if the address is a word, pass in 3 if address is a long
*   D7 = holds the original address to parse (either word or long, for example: $7000)
*
*
* Registers Used:
*   D0 = number of bits to remove
*   D2 = holds either top four bits or bottom four bits of each byte in D6
*   D3 = holds temp data
*   D6 = holds part of address (used as temp variable)
*   A1 = used for buffer
*-----------------------------------------------------------
HEX_TO_ASCII:
            MOVE.B   D1, D0             * current number of bytes to remove
            MULS.W   #8, D0             * number of bits to remove

            MOVE.L   D7, D6             * load original address to parse
            LSR.L    D0, D6             * remove lowest byte(s)

            * isolate first four bits
            MOVE.B   D6, D2
            LSR.B    #4, D2 
            BSR      NUMBER_OR_LETTER

            * isolate second set of four bits
            MOVE.B   D6, D2
            LSL.B    #4, D2 
            LSR.B    #4, D2 
            BSR      NUMBER_OR_LETTER

            SUB.B    #1, D1             * iterate
            CMP.B    #0, D1             * done if equal
            BLT      ATH_DONE

            BRA      HEX_TO_ASCII

NUMBER_OR_LETTER:
            MOVE.B   D2, D3
            ADD.B    #$30, D3           
            CMP.B    #$39, D3           * is byte in D2 a number?
            BLE      NUMBER_TO_ASCII
            
            MOVE.B   D2, D3
            ADD.B    #$37, D3           
            CMP.B    #$39, D3           * is byte in D2 a letter?
            BGE      LETTER_TO_ASCII

            BRA      INVALID_EA

NUMBER_TO_ASCII:
            ADD.B    #$30, D2           * Get the hex range from '0-9'
            BRA      ADD_TO_BUFFER

LETTER_TO_ASCII:
            ADD.B    #$37, D2           * Get the hex range from 'A-F'
            BRA      ADD_TO_BUFFER

ADD_TO_BUFFER:
            MOVE.B   D3, (A1)+          * add part of address to buffer    
            RTS

ATH_DONE:
            CLR_D_REGS
            RTS
*-----------------------------------------------------------









*---------------------SIZE TO BUFFER------------------------
* Description:
* Evaluates the size of an opcode and adds it to A1 to be printed out
*
* Parameters:
*   D3 = size of opcode
*
* Registers Used:
*   A1: adding words/numbers to buffer
*-----------------------------------------------------------
FIND_SIZE: 
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
            MOVE.B  #' ',(A1)+          * add blank space to buffer
            RTS                         
*-----------------------------------------------------------






*-------------------------DONE-------------------------------
DONE:
            CLR_A_REG D0, A1

            * add 'SIMHAULT' to buffer
            MOVE.B  #'S',(A1)+      
            MOVE.B  #'I',(A1)+         
            MOVE.B  #'M',(A1)+         
            MOVE.B  #'H',(A1)+        
            MOVE.B  #'A',(A1)+         
            MOVE.B  #'U',(A1)+         
            MOVE.B  #'L',(A1)+          
            MOVE.B  #'T',(A1)+         
            MOVE.B  #00,(A1)+         

            CLR_A_REG D0, A1
            
            * print out string
            MOVE.B    #14, D0
            TRAP      #15
            
            CLR_A_REG D0, A1


            END       MAIN              ; last line of source
*-----------------------------------------------------------
