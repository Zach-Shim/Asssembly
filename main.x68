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
* \3 should be D4
* SHIFT    #11, #9, D0
* this will return bits 11 to 9 into D0
*
* Registers:
*   D4 = holds opcode
*   D5 = highest bit in range 
*   D6 = lowest bit in range 
*   D7 = number of bits we want
*-----------------------------------------------------------
GET_BITS:   
            * Subtract value to find amount to shift by 
            ADD.B   #11, D7          
            SUB.B   #9, D7 
            ADD.B   #1, D7  * add 1 because we start our count from 0

            * Get high bit offset
            ADD.B   #15, D5
            SUB.B   #11, D5
            
            * shift out high bits
            MOVE.W  #$D401, D4
            LSL.W   D5, D4
            
            *get low bit offset
            *16 - NUMBER OF BITS WE WANT
            ADD.B   #16, D6         * 16 total bits
            SUB.L   D7, D6          * subtract numBits from 16
            
            * shift out low bits
            LSR.W   D6, D4          * isolate bits
            RTS


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
            JSR     INSERT_SPACE

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
*   D7 = holds address (word in length)
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

            * check to see if we are done (start address >= end address)
            CMPA.L  A3, A2
            BGE     DONE
            
            * print next address
            BSR     PRINT_ADDRESS
            JSR     INSERT_SPACE
            
            ;BSR     RESTORE_REGS           need to fix

            CLR_D_REGS
            BSR     GRAB_NEXT_WORD          * grab opcode
            BSR     GRAB_FIRST_FOUR_BITS    * grabs that opcode's ID (first four bits)
           
            BRA     FIND_OPCODE
*-----------------------------------------------------------

*----------------------RESTORE_REGS--------------------------
* Description:
* Move the old registers onto the stack
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
            CMP.B   #%0100, opTag 
            BEQ     OPC_0100

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

*------------------------OPC_0100---------------------------
* First four bits = 0100
* (NOP, NOT, MOVEM, JSR, RTS, LEA) 
*-----------------------------------------------------------
OPC_0100:

            ;Check if the opcode is NOP
            MOVE.W  opcode, D2          ;Copy opcode to D2
            CMP.W   #$4E71, D2          ;Check if D2 is equal to NOP (0x4E71 in hex)
            BEQ     OPC_NOP             ;If equal branch to label to handle the opcode NOP
            
            ;Check if the opcode is NOT
            ASR.L   #8, D2 ;Shift bits to compare
            CMP.B   #%01000110, D2
            BEQ     OPC_NOT
            
            CLR.L   D2                  ;If instruction is not equal to NOP clear register and continue checks

OPC_NOP:
            * Put NOP into A1 buffer for printing
            MOVE.B  #'N',(A1)+      
            MOVE.B  #'O',(A1)+ 
            MOVE.B  #'P',(A1)+ 
            
            BRA     IDENTIFY_OPCODE


OPC_NOT:
            * Put NOT into A1 buffer for printing
            MOVE.B  #'N',(A1)+ 
            MOVE.B  #'O',(A1)+
            MOVE.B  #'T',(A1)+
            MOVE.B  #'.',(A1)+
            
            * Calculate Size (.b,.w.l)
            JSR     GET_NOT_SIZE
            JSR     SIZE_TO_BUFFER 
            JSR     GET_EA_MODE
            BRA     IDENTIFY_OPCODE
            
GET_NOT_SIZE:
            CLR.L   D2
            MOVE.W  opcode, D2

            * shift left to get rid of opTag
            MOVE.B  #8, D1
            LSL.W   D1, D2

            * shift right to get rid of opmode, mode, and register bits
            MOVE.B  #14, D1
            LSR.W   D1, D2

            * store in appropriate register
            MOVE.B  D2, D3
            RTS
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
            MOVE.B  #'.',(A1)+
            BRA     PROCESS_ROEA
*-----------------------------------------------------------

*-----------------------OPC_1100----------------------------
* First four bits = 1100
* (AND, MULS)
*-----------------------------------------------------------
OPC_1100:   ; AND opcode subroutine
            
            ; check to see if bits 8-6 are 111
            ; if they are, then branch to PARSE_MULS
            ; else, keep going to parse AND

OPC_AND:
            ; fill A1 with the opcode name
            MOVE.B  #'A',(A1)+
            MOVE.B  #'N',(A1)+
            MOVE.B  #'D',(A1)+
            MOVE.B  #'.',(A1)+
            BRA     PROCESS_ROEA

OPC_MULS:
            ; load the command name into the output
            MOVE.B  #'M',(A1)+
            MOVE.B  #'U',(A1)+
            MOVE.B  #'L',(A1)+
            MOVE.B  #'S',(A1)+
            MOVE.B  #'.',(A1)+


*---------------------------opc_1101------------------------
* First four bits = 1101
* (ADD)
*-----------------------------------------------------------
OPC_1101:
            * fill in A1 register
            MOVE.B  #'A',(A1)+          * Put ADD into Buff
            MOVE.B  #'D',(A1)+
            MOVE.B  #'D',(A1)+
            MOVE.B  #'.',(A1)+
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
            JSR     GET_SIZE
            JSR     SIZE_TO_BUFFER
            JSR     OPMODE_TYPE         * 0 or 1 value (either <ea> -> Dn or Dn -> <ea>)  
            CMP.B   #1, D4              * is this Dn + <ea> -> <ea>?
            BEQ     D_TO_EA
            BNE     EA_TO_D

D_TO_EA:
            JSR     GET_DATA_REG_NUM
            MOVE.B  #',',(A1)+
            JSR     GET_EA_MODE
            BRA     ROEA_DONE

EA_TO_D:
            JSR     GET_EA_MODE
            MOVE.B  #',',(A1)+
            JSR     GET_DATA_REG_NUM
            BRA     ROEA_DONE

ROEA_DONE:
            MOVE.B  #' ',(A1)+
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
            MOVE.B  D2, D3
            
            RTS

OPMODE_TYPE:
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
            MOVE.B  D2, D4

            RTS

GET_DATA_REG_NUM:
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









*----------------------------GET_EA_MODE------------------------
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
GET_EA_MODE:
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

            MOVE.B      #'$', (A1)+
            MOVE.W      opcode, D2
            MOVE.B      #15, D1
            LSL.W       D1, D2                   * isolate register bits (last 3)
            LSR.W       D1, D2                   * isolate register bits (last 3)
            ;ADD.B       #$30, D2                 * convert data register # to ASCII digit

            CMP.B       #%0000, D2               * compare to determine if it's a word
            BEQ         EA_WORD                 * put word address in buffer

            CMP.B       #%0001, D2               * compare to determine if it's a long
            BEQ         EA_LONG                 * put long address in buffer
            
            CMP.B       #%0100, D2
            BEQ         EA_IMMEDIATE

            * NEED TO WORK ON IMMEDIATE

EA_WORD:
            CLR.L       D1
            MOVE.B      #1, D1
            MOVE.W      (A2)+, D7
            BSR         HEX_TO_ASCII
            BRA         GET_EA_DONE

EA_LONG:
            CLR.L       D1
            MOVE.B      #3, D1
            MOVE.L      (A2)+, D7   
            BSR         HEX_TO_ASCII
            BRA         GET_EA_DONE

EA_IMMEDIATE:
            * NEED TO WRITE


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
* Parameters (if calling NUMBER_OR_LETTER (usually done in opcode sections)):
*   D2 = should hold value (in hex) you want to push to the buffer
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

INSERT_SPACE:
            MOVE.B  #' ',(A1)+          * add blank space to buffer
            RTS









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
            MOVE.B  #' ',(A1)+          * add blank space to buffer
            RTS                         









*-------------------------DONE-------------------------------
DONE:
            CLR.L     D0
            MOVE.B    #14, D0
            LEA.L     doneMsg, A1
            TRAP      #15
            CLR_A_REG D0, A1

            END       MAIN              ; last line of source


*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
