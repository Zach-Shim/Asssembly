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

intro:      DC.B    '************************************************************************', CR, LF
            DC.B    '                    _____    _______    _____ ', CR, LF
            DC.B    '                   |  __ \  |__   __|  / ____|', CR, LF
            DC.B    '                   | |__) |    | |    | (___  ', CR, LF
            DC.B    '                   |  _  /     | |     \___ \ ', CR, LF
            DC.B    '                   | | \ \     | |     ____) |', CR, LF
            DC.B    '                   |_|  \_\    |_|    |_____/ ', CR, LF
            DC.B    '                                ', CR, LF
            DC.B    '************************************************************************',CR, LF, CR, LF, 0

teamName:   DC.B    'Team RTS Disassembler', CR, LF, 0
rules:      DC.B    'Rules For Input:', CR, LF
            DC.B    '1. Addresses must be in the range $999 > x > $100 or $FFFFFF > x > $6FFF', CR, LF
            DC.B    '   where x is your given address.', CR, LF
            DC.B    '2. If you use any letters (A-F), make sure they are upper case.', CR, LF
            DC.B    '3. If you use constants (DC), make sure you give a start address that', CR, LF
            DC.B    '   does not include that part of memory (only want to parse instructions).', CR, LF, CR, LF, 0

startMsg:   DC.B    'Please enter a starting address. ', CR, LF, 0
endMsg:     DC.B    'Please enter an ending address. ', CR, LF, 0

doneMsg:    DC.B    'Disassembly complete, saved to file "TestDisAsm.txt"', CR, LF, 0
badInput:   DC.B    'Invalid Input', CR, LF, 0
newline:    DC.B    '', CR, LF, 0
fileName:   DC.B    'TestDisAsm.txt',0

printAddrEnd     DS.L    0
printAddrStart   DS.L    0

userAddr:   DS.L    1
            DC.L    0               * Null termination for userAddr
startAddr:  DS.L    1
endAddr:    DS.L    1

opcode:     DS.W    1   
opTag:      DS.B    1               * a four bit identifier for opcodes (first four bits of an instruction, ex. 1011 = ADD)
opSize:     DS.B    1
valid:      DS.B    1

ea_mode     DS.B    1
ea_register DS.B    1
ea_valid    DS.B    1
list_mask   DS.W    1







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
* Parameters:
*   \1 should be highest bit in range
*   \2 should be lowest bit in range
* 
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
VALUE_TO_BUFFER:   MACRO
                   MOVE.L  \1, D2
                   JSR     ISOLATE_LAST_FOUR_BITS
                   ENDM

WORD_ADDRESS_TO_BUFFER: MACRO
                   MOVE.B  #1, D1
                   MOVE.L  \1, D7
                   JSR     HEX_TO_ASCII
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
SIZE_TO_BUFFER: MACRO
                MOVE.L  \1, D0
                BSR     CHECK_SIZE
                MOVE.L  \1, D3
                JSR     FIND_SIZE
                ENDM

CHECK_SIZE:
                CMP.B   #2, D0
                BGT     BAD_OPCODE
                CMP.B   #0, D0
                BLT     BAD_OPCODE
                RTS
*-----------------------------------------------------------






*----------------------CHECK_REGISTER----------------------
* Description:
* Checks that a register number is valid. 
* Valid sizes are 0-7 in decimal
*
* Parameters:
*   \1 = holds regsiter number. 
*
*-----------------------------------------------------------
CHECK_REGISTER: MACRO  
                MOVE.B  \1, D0
                CMP.B   #7, D0
                BGT     BAD_OPCODE
                CMP     #0, D0
                BLT     BAD_OPCODE
                ENDM
*-----------------------------------------------------------







*----------------Decoding EA Mode and Register--------------
* Description:
* Decodes EA mode and register and pushes to buffer
* 
* Parameters:
*   \1 = high bit of ea
*   \2 = low bit of ea
*
* Registers Used:
*   D1 = temp variable
*
* For Example (most common): 
*   DECODE_EA    #5, #0
*
*-----------------------------------------------------------
DECODE_EA:  MACRO
            CLR_D_REGS
            MOVE.B      \1, D1
            JSR         DECODE_EA_HELP
            JSR         EA_TO_BUFFER
            ENDM

GET_EA_MODE: MACRO
             GET_BITS        \1, \2
             MOVE.B          D4, ea_mode
             ENDM

GET_EA_REG:  MACRO
             GET_BITS        \1, \2
             MOVE.B          D4, ea_register
             ENDM
*-----------------------------------------------------------

*-----------------------------------------------------------
DECODE_EA_HELP:
        
            CMP.B       #5, D1               * is this bits 5-0?
            BEQ         DECODE_6_TO_0

            CMP.B       #11, D1              * is this bits 11-6? 
            BEQ         DECODE_11_TO_6

DECODE_6_TO_0:
            GET_EA_MODE #5, #3               * get ea mode
            GET_EA_REG  #2, #0               * get ea register
            BRA         EA_END

DECODE_11_TO_6:
            GET_EA_MODE #8, #6               * get ea mode
            GET_EA_REG  #11, #9              * get ea register

EA_END:
            RTS

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
            MOVE.B #50,D0 *Use this at the start of any program with file handling
            TRAP   #15
            
            LEA    fileName, A1 *Load the name of the file
            MOVE.B #52, D0 *Create file or overwrite existing
            TRAP   #15
            
            CLR.L  D0
            
            PRINT_MSG    teamName
            PRINT_MSG    intro
            PRINT_MSG    rules
            BSR          GET_INPUT
            BRA          LOAD_ADDRESSES
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
            CLR.L        D3
            CLR.L        D4
            PRINT_MSG    startMsg
            BSR          GET_ADDRESS   
            CMP          #1, D4
            BEQ          RESTART_INPUT
            MOVE.L       D7, startAddr


            CLR.L        D3
            CLR.L        D4
            PRINT_MSG    endMsg
            BSR          GET_ADDRESS   
            CMP          #1, D4
            BEQ          RESTART_INPUT
            MOVE.L       D7, endAddr

            BSR          CHECK_ADDRESS
            CMP          #1, D4
            BEQ          RESTART_INPUT

            RTS

RESTART_INPUT:
            BRA        GET_INPUT
*-----------------------------------------------------------

*------------------------Get Address------------------------
GET_ADDRESS:
            * ask for input
            LEA.L   userAddr, A1
            MOVE.B  #2, D0
            TRAP    #15

            * error checking - length
            BSR     CHECK_LENGTH
            CMP     #1, D4
            BEQ     RETURN_TO_INPUT

            * error checking - valid characters
            BSR     CONVERT_TO_HEX
            CMP     #1, D4
            BEQ     RETURN_TO_INPUT

            CLR.L   D4
            RTS

RETURN_TO_INPUT:
            RTS
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
*   D4 = bool check (1 = FALSE, 0 = TRUE)
*   A1 = stores an ascii string from user input
*-----------------------------------------------------------

*----------------------VALIDATE INPUT---------------------------      
CHECK_LENGTH:
            CLR.L      D4

            CMP.B      #1, D1               ; for task 2, length of string is in D1                
            BLT        INVALID_INPUT 

            CMP.B      #6, D1               ; address can either be 4 or 8 bits in length  
            BGT        INVALID_INPUT

            RTS

INVALID_INPUT:  
            PRINT_MSG  badInput
            MOVE.B     #1, D4
            RTS
*-----------------------------------------------------------

*----------------------CHECK ADDRESS------------------------      
CHECK_ADDRESS:
            MOVE.L     startAddr, D5
            CMP.L      endAddr, D5          ; starting address >= ending address?
            BGE        INVALID_ADDRESS

            CMP.L      #$100, D5
            BLT        INVALID_INPUT 
            
            CMP.L      #$FFFFFF, endAddr
            BGT        INVALID_INPUT
            RTS

INVALID_ADDRESS:  
            PRINT_MSG  badInput
            MOVE.B     #1, D4
            RTS
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
            ADD.B      (A1)+, D3           ; keep hex stored in D3           
            BRA        ITERATE                 

ITERATE:
            SUB.B      #$1, D1
            CMP.B      #0, D1
            BEQ        STORE_INPUT

            LSL.L      #4, D3               ; shift D3 contents left by 4 to receive next input
            BRA        CONVERT_TO_HEX

STORE_INPUT:
            MOVE.L     D3, D7
            RTS
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

            *Copy end adress to data register, used for calculating # of bytes to write to file
            *MOVE.L  A1,printAddrEnd
            *MOVE.L  A1,d1 

            * reset A1 to beginning of string
            CLR_A_REG D0, A1
            
            *Copy start address
            *MOVE.L  A1,printAddrStart 
            *MOVE.L  A1,d2 
            
            * move current address to D2
            MOVE.L    A2, D2
            MOVE.B    #3, D1            * passing 1 means we are passing long as a parameter to HEX_TO_ASCII
            MOVE.L    A2, D7
            BRA       FINISH_PRINT

FINISH_PRINT:
            * convert hex values back to ASCII
            JSR       HEX_TO_ASCII
            
            * print out string
            MOVE.B    #00,(A1)
            CLR_A_REG D0, A1
            MOVE.B    #14, D0
            TRAP      #15
            
            CLR.L     D2                    
            BRA       FIND_NUM_OF_CHARS

FIND_NUM_OF_CHARS:
            MOVE.B    (A1),D5
            CMP.B     #00, D5
            BEQ       FIND_NUMS_DONE
            ADD.B     #1, D2
            MOVE.B    (A1)+, D5
            BRA       FIND_NUM_OF_CHARS

FIND_NUMS_DONE:
            CLR_A_REG D0, A1
            MOVE.B #54,D0 *Write to file
            TRAP   #15
            RTS
*-----------------------------------------------------------

*-------------------PRINT_INSTRUCTION-----------------------
PRINT_INSTRUCTION:            
            MOVE.L    A1,D2 *Load end address into d2, this will be used to later calculated # of bytes to write to file 
            MOVE.B    #00,(A1) * null terminator             

            * reset A1 to beginning of string
            CLR.L     D0
            CLR_A_REG D0, A1

            * print out string
            MOVE.B    #14, D0
            TRAP      #15
            
            *Print to File
            SUB.L   A1,D2 *Subtract start address from end address to determine number of bytes to read
            MOVE.B  #54,D0 *Trap task to write to file
            TRAP    #15
            
            LEA newline,A1 *Create new line on file
            
            MOVE.L #1,D2
            MOVE.B #54,D0 *Trap task to write to file
            TRAP   #15

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
            CLR.L       D0
            CLR_A_REG   D0, A1

            * load start and end registers and print starting address
            MOVEA.L     startAddr, A2
            MOVEA.L     endAddr, A3
            BSR         PRINT_ADDRESS
            INSERT_SPACE

            BSR         GRAB_NEXT_WORD
            BSR         GRAB_FIRST_FOUR_BITS     ; grabs that opcode's ID (first four bits)

            * Push current registers onto the stack (so we can have fresh registers)
            MOVEM.L D0-D7,-(SP)                  ; move the old registers onto the stack
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

            CLR_D_REGS
            BSR     GRAB_NEXT_WORD          * grab opcode
            BSR     GRAB_FIRST_FOUR_BITS    * grabs that opcode's ID (first four bits)
           
            BRA     FIND_OPCODE
*------------------------------------------------------------

*---------Useful Subroutines For Identifying Opcodes--------
GRAB_NEXT_WORD:
            * load current word of bits into D7
            MOVE.W (A2)+, opcode
            RTS

GRAB_FIRST_FOUR_BITS:
            * find first four bits of opcode
            GET_BITS  #15, #12
            MOVE.B    D4, opTag
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

            CMP.B   #%0001, opTag 
            BEQ     OPC_0001

            CMP.B   #%0010, opTag 
            BEQ     OPC_0010

            CMP.B   #%0011, opTag 
            BEQ     OPC_0011

            CMP.B   #%0100, opTag 
            BEQ     OPC_0100
            
            CMP.B   #%0110, opTag
            BEQ     OPC_0110

            CMP.B   #%0101, opTag 
            BEQ     OPC_0101
            
            CMP.B   #%0111, opTag 
            BEQ     OPC_0111

            CMP.B   #%1000, opTag
            BEQ     OPC_1000

            CMP.B   #%1001, opTag
            BEQ     OPC_1001

            CMP.B   #%1100, opTag
            BEQ     OPC_1100

            CMP.B   #%1101, opTag
            BEQ     OPC_1101
            
            CMP.B   #%1110, opTag
            BEQ     OPC_1110

            CMP.B   #%1111, opTag
            BEQ     OPC_1111

            * error, bad opcode
            BRA      BAD_OPCODE

*-----------------------------------------------------------

*-----------------------BAD OPCODE--------------------------
BAD_OPCODE:
            CLR_D_REGS
            CLR_A_REG  D0, A1

            INSERT_SPACE
            MOVE.B   #'D', (A1)+
            MOVE.B   #'A', (A1)+
            MOVE.B   #'T', (A1)+
            MOVE.B   #'A', (A1)+
            INSERT_SPACE

            MOVE.B    #1, D1                  * passing 1 means we are passing word as a parameter to HEX_TO_ASCII
            MOVE.W    opcode, D7              * passing current parsing position means we are passing an address as a parameter in D7 to HEX_TO_ASCII
            BSR       FINISH_PRINT
            BRA       IDENTIFY_OPCODE
*-----------------------------------------------------------

*------------------------OPC_0000---------------------------
* First four bits = 0000
* (ADDI, SUBI)
*-----------------------------------------------------------
OPC_0000:
            GET_BITS  #11, #8
            
            * is the opcode ANDI?
            CMP.B     #%0010, D4
            BEQ       OPC_ANDI

            * is the opcode ADDI?
            CMP.B     #%0110, D4
            BEQ       OPC_ADDI

            * is the opcode SUBI?
            CMP.B     #%0100, D4
            BEQ       OPC_SUBI

            JMP       BAD_OPCODE

*------------------------OPC_ANDI---------------------------
OPC_ANDI:
            MOVE.B  #'A',(A1)+          * Put AND into Buff
            MOVE.B  #'N',(A1)+
            MOVE.B  #'D',(A1)+
            MOVE.B  #'I',(A1)+
            INSERT_PERIOD

            BSR     DECODE_IMMEDIATE

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
            MOVE.B          D4, opSize
            SIZE_TO_BUFFER  D4                  * put operation size in buffer

            * push #<data> to buffer
            JSR             CHECK_IMMEDIATE

            INSERT_COMMA
            INSERT_SPACE

            * push <ea> to buffer
            DECODE_EA       #5, #0
            BRA             IDENTIFY_OPCODE
 
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

*------------------------OPC_0001---------------------------
* First four bits = 0001
* (MOVE.B)
*-----------------------------------------------------------
OPC_0001:
            MOVE.B   #'M',(A1)+          * Put ADD into Buff
            MOVE.B   #'O',(A1)+
            MOVE.B   #'V',(A1)+
            MOVE.B   #'E',(A1)+
            MOVE.B   #'.',(A1)+
            MOVE.B   #'B',(A1)+
            INSERT_SPACE

            MOVE.B   #0, opSize

            BSR      DECODE_MOVE
            BRA      IDENTIFY_OPCODE
*-----------------------------------------------------------

*------------------------OPC_0010---------------------------
* First four bits = 0010
* (MOVE.L)
*-----------------------------------------------------------
OPC_0010:
            MOVE.B  #'M',(A1)+          * Put ADD into Buff
            MOVE.B  #'O',(A1)+
            MOVE.B  #'V',(A1)+
            MOVE.B  #'E',(A1)+
            MOVE.B  #'.',(A1)+
            MOVE.B  #'L',(A1)+
            INSERT_SPACE

            MOVE.B   #2, opSize

            BSR      DECODE_MOVE
            BRA      IDENTIFY_OPCODE
*-----------------------------------------------------------

*------------------------OPC_0011---------------------------
* First four bits = 0011
* (MOVE.W)
*-----------------------------------------------------------
OPC_0011:
            MOVE.B  #'M',(A1)+          * Put ADD into Buff
            MOVE.B  #'O',(A1)+
            MOVE.B  #'V',(A1)+
            MOVE.B  #'E',(A1)+
            MOVE.B  #'.',(A1)+
            MOVE.B  #'W',(A1)+
            INSERT_SPACE

            MOVE.B   #1, opSize

            BSR      DECODE_MOVE
            BRA      IDENTIFY_OPCODE
*-----------------------------------------------------------

*---------------------Decode Move---------------------------
DECODE_MOVE:
            DECODE_EA       #5, #0
            
            INSERT_COMMA
            INSERT_SPACE

            DECODE_EA       #11, #6
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
            CMP.B    #%111, D4              * if bits 8-6 are equal to 111, then the opocde is LEA
            BEQ      OPC_LEA

            * Check if the opcode is JSR
            MOVE.W   opcode, D4             * Put opcode in D4 to use the macro get bits
            GET_BITS #9, #7 
            CMP.B    #%101, D4              * if bits 9-7 are equal to 010, then the opocde is LEA
            BEQ      OPC_JSR

            * Check if the opcode is RTS
            CMP.B    #%100, D4              
            BEQ      OPC_RTS

            * Check if the opcode is MOVEM
            CMP.B    #%001, D4              
            BEQ      OPC_MOVEM

            JMP      BAD_OPCODE

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
            MOVE.B          D4, opSize
            SIZE_TO_BUFFER  D4                  * put operation size in buffer
            DECODE_EA       #5, #0
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

            MOVE.B          #2, opSize      * required to always be long operation
                    
            DECODE_EA       #5, #0
            INSERT_COMMA
            INSERT_SPACE
            JSR GET_DATA_REG_NUM

            BRA IDENTIFY_OPCODE    

*-----------------------------OPC_JSR-----------------------------
OPC_JSR:
            * Put LEA into A1 buffer for printing
            MOVE.B  #'J',(A1)+      
            MOVE.B  #'S',(A1)+ 
            MOVE.B  #'R',(A1)+
            INSERT_SPACE
            
            DECODE_EA       #5, #0
            BRA             IDENTIFY_OPCODE  

*-----------------------------OPC_RTS------------------------------
OPC_RTS:
            * Put LEA into A1 buffer for printing
            MOVE.B  #'R',(A1)+      
            MOVE.B  #'T',(A1)+ 
            MOVE.B  #'S',(A1)+
        
            BRA IDENTIFY_OPCODE

*-------------------------OPC_MOVEM--------------------------------
OPC_MOVEM:
            MOVE.B  #'M',(A1)+      
            MOVE.B  #'O',(A1)+ 
            MOVE.B  #'V',(A1)+
            MOVE.B  #'E',(A1)+      
            MOVE.B  #'M',(A1)+ 
            INSERT_PERIOD

            JSR     DECODE_MOVEM
            BRA     IDENTIFY_OPCODE

*------------------------------------------------------------------

*---------------------------OPC_0111------------------------
* First four bits = 0111
* (MOVEQ)
*-----------------------------------------------------------
OPC_0111:
            MOVE.B  #'M',(A1)+      
            MOVE.B  #'O',(A1)+ 
            MOVE.B  #'V',(A1)+
            MOVE.B  #'E',(A1)+      
            MOVE.B  #'Q',(A1)+ 
            INSERT_PERIOD
            MOVE.B  #'L',(A1)+
            INSERT_SPACE

            * error checking
            GET_BITS        #8, #8
            CMP.B           #0, D4
            BNE             BAD_OPCODE

            * push immediate byte value to buffer
            INSERT_POUND
            INSERT_DOLLAR
            GET_BITS        #7, #0
            WORD_ADDRESS_TO_BUFFER D4 

            INSERT_COMMA
            INSERT_SPACE

            * push register to buffer
            MOVE.B          #'D',(A1)+
            GET_BITS        #11, #9 
            CHECK_REGISTER  D4
            VALUE_TO_BUFFER D4
            BRA             IDENTIFY_OPCODE
*-----------------------------------------------------------

*---------------------------OPC_1000------------------------
 * First four bits = 1000
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

            MOVE.B  #1, opSize
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
            MOVE.B          D4, opSize
            SIZE_TO_BUFFER  D4                  * put operation size in buffer

            * push value of #<data> to buffer
            CLR.L            D4
            GET_BITS         #11, #9
            INSERT_POUND
            WORD_ADDRESS_TO_BUFFER  D4

            INSERT_COMMA
            INSERT_SPACE

            * push <ea> to buffer
            DECODE_EA       #5, #0
            BRA             IDENTIFY_OPCODE
*-----------------------------------------------------------

*-----------------------OPC_0110----------------------------
* First four bits = 0110
* BRA or Bcc condtions
*-----------------------------------------------------------
OPC_0110:
            GET_BITS #12, #8
            CMP.B   #0,D4 *Check if opcode is BRA
            BEQ     OPC_BRA
            
            GET_BITS #11, #8 *Check if opcode is a Bcc condition
            
            CMP.B   #%1101, D4 *Check if opcode is BLT
            BEQ     BLT
            
            CMP.B   #%1100, D4 *Check if opcode is BGE
            BEQ     BGE
            
            CMP.B   #%0111, D4 *Check if opcode is BEQ
            BEQ     BEQ
            
            JMP     BAD_OPCODE *If no match if found, we have an error
            
BLT:
            MOVE.B  #'B',(A1)+          * Put BLT into Buff
            MOVE.B  #'L',(A1)+
            MOVE.B  #'T',(A1)+
            MOVE.B  #'.',(A1)+
            BRA     BCC_DISPLACEMENT

BGE:
            MOVE.B  #'B',(A1)+          * Put BGE into Buff
            MOVE.B  #'G',(A1)+
            MOVE.B  #'E',(A1)+
            MOVE.B  #'.',(A1)+
            BRA     BCC_DISPLACEMENT

BEQ:
            MOVE.B  #'B',(A1)+          * Put BEQ into Buff
            MOVE.B  #'E',(A1)+
            MOVE.B  #'Q',(A1)+
            MOVE.B  #'.',(A1)+
            BRA     BCC_DISPLACEMENT

BCC_DISPLACEMENT:
            GET_BITS #7,#0 *Get displacement bits
            
            CMP.B   #0,D4 *Check if we have 16 bit dispalcement, branch if true
            BEQ     SIXTEEN_BIT_DISPLACEMENT
            
            MOVE.B  #'B',(A1)+
            INSERT_SPACE 
            MOVE.B  #'$',(A1)+
            
            MOVE.L  A2,D7  *Get the current address
            
            EXT.W   D4 *Sign extend to long for addition
            EXT.L   D4 *Sign extend again, must extend from byte to word and then word to long
            ADD.L   D4,D7  *Add the displacement

            MOVE.B  #3,D1  *Move a 3 to print long address - it's a parameter of HEX_TO_ASCII
            JSR     HEX_TO_ASCII ;Convert the address to ascii, and add to buffer for printing
            
            BRA IDENTIFY_OPCODE   
                       
OPC_BRA:
            MOVE.B  #'B',(A1)+          * Put BRA into Buff
            MOVE.B  #'R',(A1)+
            MOVE.B  #'A',(A1)+
            MOVE.B  #'.',(A1)+
            
            GET_BITS #7,#0 *Get displacement bits
            
            CMP.B   #0,D4 *Check if we have 16 bit dispalcement, branch if true
            BEQ     SIXTEEN_BIT_DISPLACEMENT
           
            MOVE.B  #'B',(A1)+
            INSERT_SPACE 
            MOVE.B  #'$',(A1)+
            
            MOVE.L  A2,D7  *Get the current address
            
            EXT.W   D4 *Sign extend to long for addition
            EXT.L   D4 *Sign extend again, must extend from byte to word and then word to long
            ADD.L   D4,D7  *Add the displacement

            MOVE.B  #3,D1  *Move a 3 to print long address - it's a parameter of HEX_TO_ASCII
            JSR     HEX_TO_ASCII ;Convert the address to ascii, and add to buffer for printing
            
            BRA IDENTIFY_OPCODE   
            
SIXTEEN_BIT_DISPLACEMENT: 
            MOVE.B  #'W',(A1)+
            INSERT_SPACE 
            MOVE.B  #'$',(A1)+
            
            MOVE.L  A2,D7  *Get the current address
            
            CLR.L D4 *Clear the contents of D4
            MOVE.W  (A2)+,D4 *Increment A2 to get 16 bit displacement value
            
            EXT.L   D4  *Sign extend to long for addition
            ADD.L   D4,D7  *Add the displacement 
                      
            MOVE.B  #3,D1  *Move a 3 to print long address - it's a parameter of HEX_TO_ASCII
            JSR     HEX_TO_ASCII ;Convert the address to ascii, and add to buffer for printing
            
            BRA     IDENTIFY_OPCODE 
            

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
            CMP.B    #%111, D4
            BEQ      OPC_MULS
            BNE      OPC_AND

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

            MOVE.B   #1, opSize
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
            
*---------------------------opc_1110------------------------
* First four bits = 1110
* (LSL, LSR, ASL, ASR)
*-----------------------------------------------------------
OPC_1110:
            GET_BITS #7, #6
            CMP.B    #%11, D4
            BEQ      SHIFT_MEMORY
            BRA      SHIFT_REGISTER

SHIFT_MEMORY:
            BSR      CHECK_MEM_TYPE
            CMP.B    #1, D3
            BEQ      BAD_OPCODE
            JMP      SHIFT_MEM_MODE
            

SHIFT_REGISTER:
            BSR      CHECK_REG_TYPE
            CMP.B    #1, D3
            BEQ      BAD_OPCODE
            JMP      SHIFT_REG_OR_IMM

*-----------------------------------------------------------
CHECK_REG_TYPE:
            ; check for LSL/LSR vs ASL/ASR
            GET_BITS  #4, #3
            CMP.B     #0, D4
            BEQ       A_SHIFT     ; if bits 4-3 are 00, ASL/ASR
            CMP.B     #1, D4
            BEQ       L_SHIFT     ; if bits 4-3 are 01, LSL/LSR
            
            MOVE.B    #1, D3
            RTS

CHECK_MEM_TYPE:
            GET_BITS #10, #9
            CMP.B    #0, D4
            BEQ      A_SHIFT
            CMP.B    #1, D4
            BEQ      L_SHIFT

            MOVE.B   #1, D3
            RTS
*--------------------get opcode name------------------------
A_SHIFT:
            MOVE.B   #'A', (A1)+
            MOVE.B   #'S', (A1)+ 
            BRA      CHECK_DIRECTION

L_SHIFT:
            MOVE.B   #'L', (A1)+
            MOVE.B   #'S', (A1)+
            BRA      CHECK_DIRECTION

*------------------determine which way to shift---------------
CHECK_DIRECTION:
            GET_BITS #8, #8      ; check for shifting left or right
            CMP.B    #1, D4
            BEQ      L_TO_BUFF
            CMP.B    #0, D4
            BEQ      R_TO_BUFF
            
            MOVE.B   #1, D3
            RTS
            
L_TO_BUFF:
            MOVE.B  #'L',(A1)+
            MOVE.B  #'.',(A1)+
            RTS

R_TO_BUFF:
            MOVE.B  #'R',(A1)+
            MOVE.B  #'.',(A1)+
            RTS

*-----------------------------------------------------------
SHIFT_REG_OR_IMM: ; register and immediate shifts
            ; get the size
            GET_BITS       #7, #6
            SIZE_TO_BUFFER D4
            
            ; get the i/r bit to determine immediate/register
            GET_BITS #5,#5

            ; if i/r is 0, it's an immediate shift
            CMP.B   #0, D4
            BEQ     SHIFT_IMMEDIATE_MODE
            ; if i/r is 1, it's a register shift
            CMP.B   #1, D4
            BEQ     SHIFT_REGISTER_MODE

            ; else, bad opcode
            JMP     BAD_OPCODE

*-----------------------------------------------------------
; shifting modes (immediate data, from a register, from memory)
SHIFT_IMMEDIATE_MODE:
            MOVE.B  #'#',(A1)+
            
            JSR     SHIFT_COUNT
            
            MOVE.B  #',',(A1)+
            MOVE.B  #' ',(A1)+
            
            BRA     SHIFT_DEST_REG   ; get the destination register

SHIFT_COUNT: ; moves the size to the buffer
            GET_BITS   #11,#9
            
            CMP.B      #0, D4   ; shift bits = 0, shifting 8 bits
            BEQ        EIGHT_TO_BUFF
            
            VALUE_TO_BUFFER  D4
            RTS
            
EIGHT_TO_BUFF:
            MOVE.B  #'8',(A1)+
            RTS
            
            
SHIFT_REGISTER_MODE:
            MOVE.B  #'D',(A1)+
            
            GET_BITS #7, #6
            
            ADD.B   #$30,D4         ; push the register to the buffer
            MOVE.B  D4,(A1)+
            MOVE.B  #',',(A1)+
            MOVE.B  #' ',(A1)+
            
            BRA     SHIFT_DEST_REG   ; get the destination register

SHIFT_DEST_REG:
            MOVE.B          #'D', (A1)+
            GET_BITS        #2, #0
            VALUE_TO_BUFFER D4
            
            BRA     IDENTIFY_OPCODE
            
            
SHIFT_MEM_MODE: ; memory shifts
            MOVE.B  #'W', (A1)+      ; always word sized
            MOVE.B  #' ', (A1)+
            
            DECODE_EA #5, #0
            BRA           IDENTIFY_OPCODE
*-----------------------------------------------------------

*-----------------------opc_1111----------------------------
* First four bits = 1111
* (SIMAULT)
*-----------------------------------------------------------
OPC_1111:
            CMP.W  #$FFFF, opcode
            BEQ    DONE
            BRA    BAD_OPCODE
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
            MOVE.B          D4, opSize
            SIZE_TO_BUFFER  D4                  * put operation size in buffer

            GET_BITS        #8, #8              * retrieve type  
            CMP.B           #1, D4              * is this Dn + <ea> -> <ea>?
            BEQ             D_TO_EA
            CMP.B           #0, D4              * is this <ea> + Dn -> <ea>?
            BEQ             EA_TO_D

D_TO_EA:
            JSR             GET_DATA_REG_NUM
            INSERT_COMMA
            INSERT_SPACE
            DECODE_EA       #5, #0
            BRA             ROEA_DONE

EA_TO_D:
            DECODE_EA       #5, #0
            INSERT_COMMA
            INSERT_SPACE
            JSR             GET_DATA_REG_NUM
            BRA             ROEA_DONE

ROEA_DONE:
            INSERT_SPACE
            BRA     IDENTIFY_OPCODE

GET_DATA_REG_NUM:
            CLR.L    D4
            GET_BITS #11, #9                     * retrieve high data register number

            * store in appropriate register
            MOVE.B            #'D',(A1)+                  * add "D" to buffer
            CHECK_REGISTER    D4
            VALUE_TO_BUFFER   D4          
            RTS
*-----------------------------------------------------------











*----------------------DECODE_MOVEM-------------------------
* Description:
* Parses bits for MOVEM 
*
* Parameters:
*   None
*
* Registers Used:
*   D1 = holds next word from memory (word represents register list mask)
*   D2 = temp variable to hold iteration values in LOOP_LIST
*   D3 = determines if we are currrently parsing data regs or address regs
*   D4 = holds returned value from GET_BITS
*   D5 = holds type field (direction of transfer)
*   D7 = temp data
*-----------------------------------------------------------
DECODE_MOVEM:
            CLR_D_REGS
            BSR       MOVEM_SIZE
            BRA       MOVEM_TYPE

MOVEM_TYPE:
            BSR       MOVEM_BR
            CMP.B     #0, D4            * register -> memory
            BEQ       REG_TO_MEM
            CMP.B     #1, D4            * memory -> register
            BEQ       MEM_TO_REG

*-----------------------------------------------------------
MOVEM_SIZE:
            * move size of operation to opSize
            GET_BITS  #6, #6

            CMP.B     #0, D4
            BEQ       MOVEM_PUSH_WORD

            CMP.B     #1, D4
            BEQ       MOVEM_PUSH_LONG

MOVEM_PUSH_WORD:
            MOVE.B    #1, D4
            BRA       MOVEM_SIZE_DONE

MOVEM_PUSH_LONG:
            MOVE.B    #2, D4
            BRA       MOVEM_SIZE_DONE

MOVEM_SIZE_DONE:
            MOVE.B          D4, opSize
            SIZE_TO_BUFFER  D4
            INSERT_SPACE
            RTS
*-----------------------------------------------------------
MOVEM_BR:
            * move dr of operation to D5
            GET_BITS  #10, #10
            CMP.B     #2, D4
            BGE       BAD_OPCODE
            RTS
*-----------------------------------------------------------
MOVEM_MODE:
            * move dr of operation to D5
            GET_BITS  #5, #3
            RTS
*-----------------------------------------------------------
REG_TO_MEM:
            * bring in the next word from memory, which represents the register list mask
            MOVE.W    (A2)+, list_mask
            BSR       IDENTIFY_REGS
            CLR_D_REGS
            INSERT_COMMA
            INSERT_SPACE
            DECODE_EA #5, #0
            BRA       DONE_MOVEM

MEM_TO_REG:
            * bring in the next word from memory, which represents the register list mask
            MOVE.W    (A2)+, list_mask
            DECODE_EA #5, #0
            CLR_D_REGS
            INSERT_COMMA
            INSERT_SPACE
            BSR       IDENTIFY_REGS
            BRA       DONE_MOVEM

DONE_MOVEM:
            RTS
*-----------------------------------------------------------
IDENTIFY_REGS:
            * load registers with appropriate memory
            BSR       LOAD_CHECKS
            MOVE.L    #0, D3
            BSR       FIND_HIGH_TO_LOW_BITS   

            * find address registers   
            BSR       LOAD_CHECKS
            MOVE.L    #1, D3
            BSR       FIND_HIGH_TO_LOW_BITS

            BSR       REMOVE_FINAL_SLASH 
            RTS

LOAD_CHECKS:
            * is this memory -> register?
            BSR       MOVEM_BR
            CMP.B     #1, D4
            BEQ       LOAD_DONE

            * is this register -> address?
            BSR       MOVEM_MODE
            CMP.B     #%111, D4
            BEQ       LOAD_DONE
            CMP.B     #%010, D4
            BEQ       LOAD_DONE
            
            * is this register -> memory?
            MOVE.B    #0, D4
            BRA       LOAD_DONE

LOAD_DONE:
            MOVE.B    D4, D5
            MOVE.B    #-1, D2
            MOVE.W    list_mask, D1
            RTS

REMOVE_FINAL_SLASH:
            MOVE.B    #0, -(A1)
            RTS 

*-----------------------------------------------------------  
FIND_HIGH_TO_LOW_BITS:
            * only parse 8 (0 based) data registers or address registers at a time
            ADD.B     #1, D2            
            CMP.B     #7, D2  
            BGT       NO_MORE_BITS

            * is this memory -> register?
            CMP.B     #1, D5 
            BEQ       SHIFT_LIST_RIGHT        

            * is this register -> (xxx).W/(xxx).L?
            CMP.B     #%111, D5 
            BEQ       SHIFT_LIST_RIGHT

            * is this register -> (An)?
            CMP.B     #%010, D5 
            BEQ       SHIFT_LIST_RIGHT

            * is this register -> memory?
            CMP.B     #0, D5 
            BEQ       SHIFT_LIST_LEFT

            BRA       FIND_HIGH_TO_LOW_BITS


SHIFT_LIST_LEFT:
            * shift left to detect carry. If 1 is carried out, that means there is a register there
            ASL.W     #1, D1
            BCS       STORE_BIT    
            BRA       FIND_HIGH_TO_LOW_BITS

SHIFT_LIST_RIGHT:
            * shift left to detect carry. If 1 is carried out, that means there is a register there
            ASR.W     #1, D1
            BCS       STORE_BIT         
            BRA       FIND_HIGH_TO_LOW_BITS

STORE_BIT:
            * are we dealing with data registers?
            CMP.B     #0, D3
            BEQ       STORE_DATA_REG_BIT

            * are we dealing with address registers?
            CMP.B     #1, D3
            BEQ       STORE_ADDR_REG_BIT

STORE_DATA_REG_BIT:
            MOVE.B    #'D', (A1)+
            BRA       LOOP_BACK

STORE_ADDR_REG_BIT:
            MOVE.B    #'A', (A1)+
            BRA       LOOP_BACK

LOOP_BACK:
            * push register number to buffer
            MOVE.B    D2, D7
            ADD.B     #$30, D7
            MOVE.B    D7, (A1)+
            MOVE.B    #'/', (A1)+       
            BRA       FIND_HIGH_TO_LOW_BITS

NO_MORE_BITS:
            MOVE.W    D1, list_mask
            RTS
*-----------------------------------------------------------












*----------------------EA_TO_BUFFER------------------
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
*-----------------------------------------------------------
EA_TO_BUFFER:              
            CHECK_REGISTER  ea_register              
            CMP.B   #%0000, ea_mode        * Direct Data Register
            BEQ     EA_000

            CMP.B   #%0001, ea_mode        * Direct Address Register
            BEQ     EA_001

            CMP.B   #%0010, ea_mode        * Indirect Address Register
            BEQ     EA_010

            CMP.B   #%0011, ea_mode        * Post Increment
            BEQ     EA_011

            CMP.B   #%0100, ea_mode        * Pre Decrement
            BEQ     EA_100

            CMP.B   #%0101, ea_mode        * Not necessary, go to bad EA
            BEQ     EA_101

            CMP.B   #%0110, ea_mode        * Not necessary, go to bad EA
            BEQ     EA_110

            CMP.B   #%0111, ea_mode        * Absolute or immediate address
            BEQ     EA_111

            BRA     BAD_OPCODE

*----------------------------Direct Data Register------------------------
EA_000:
            MOVE.B      #'D',(A1)+              * add "D" to buffer
            ADD.B       #$30, ea_register       * convert data register # to ASCII digit
            MOVE.B      ea_register, (A1)+      * register # to buffer                  
            RTS                                

*----------------------------Direct Address Register------------------------
EA_001:
            MOVE.B      #'A',(A1)+              * add "A" to buffer
            ADD.B       #$30, ea_register       * convert data register # to ASCII digit
            MOVE.B      ea_register, (A1)+      * register # to buffer               
            RTS                            

*----------------------------Indirect Address Register------------------------
EA_010:
            MOVE.B      #'(',(A1)+              * add "(" to buffer
            MOVE.B      #'A',(A1)+              * add "A" to buffer
            ADD.B       #$30, ea_register       * convert data register # to ASCII digit
            MOVE.B      ea_register, (A1)+      * register # to buffer     
            MOVE.B      #')',(A1)+              * add ")" to buffer
            RTS                            

*----------------------------Post Increment------------------------
EA_011:
            MOVE.B      #'(',(A1)+              * add "(" to buffer
            MOVE.B      #'A',(A1)+              * add "A" to buffer
            ADD.B       #$30, ea_register       * convert data register # to ASCII digit
            MOVE.B      ea_register, (A1)+      * register # to buffer 
            MOVE.B      #')',(A1)+              * add ")" to buffer
            MOVE.B      #'+',(A1)+              * add "+" to buffer 
            RTS                              

*----------------------------Pre Decrement------------------------
EA_100:
            MOVE.B      #'-',(A1)+              * add "-" to buffer
            MOVE.B      #'(',(A1)+              * add "(" to buffer
            MOVE.B      #'A',(A1)+              * add "A" to buffer
            ADD.B       #$30, ea_register       * convert data register # to ASCII digit
            MOVE.B      ea_register, (A1)+      * register # to buffer 
            MOVE.B      #')',(A1)+              * add ")" to buffer
            RTS

*----------------------------Not necessary, go to bad EA------------------------
EA_101:
            BRA         BAD_OPCODE        

*----------------------------Not necessary, go to bad EA------------------------
EA_110:
            BRA         BAD_OPCODE        

*----------------------------Absolute or immediate address------------------------
EA_111:
            CMP.B       #%000, ea_register                  * compare to determine if it's a word
            BEQ         EA_WORD                             * put word address in buffer

            CMP.B       #%001, ea_register                  * compare to determine if it's a long
            BEQ         EA_LONG                             * put long address in buffer
            
            CMP.B       #%100, ea_register
            BEQ         EA_IMMEDIATE                        * always print a long if it's immediate data

            * Invalid EA mode/register
            BRA         BAD_OPCODE

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

            CMP.B       #0, opSize          
            BEQ         EA_WORD

            CMP.B       #1, opSize          
            BEQ         EA_WORD          
            
            CMP.B       #2, opSize
            BRA         EA_LONG             

GET_EA_DONE:
            RTS
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
            BSR      ISOLATE_FIRST_FOUR_BITS

            * isolate second set of four bits
            MOVE.B   D6, D2
            BSR      ISOLATE_LAST_FOUR_BITS

            BRA      ITERATE_BITS

ISOLATE_FIRST_FOUR_BITS:
            LSR.B    #4, D2 
            BSR      NUMBER_OR_LETTER
            RTS

ISOLATE_LAST_FOUR_BITS:
            LSL.B    #4, D2 
            LSR.B    #4, D2 
            BSR      NUMBER_OR_LETTER
            RTS

ITERATE_BITS:
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

            BRA      BAD_OPCODE

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
            CLR.L     D0
            CLR_A_REG D0, A1

            * add 'SIMHAULT' to buffer
            MOVE.B  #' ',(A1)+ 
            MOVE.B  #'S',(A1)+      
            MOVE.B  #'I',(A1)+         
            MOVE.B  #'M',(A1)+         
            MOVE.B  #'H',(A1)+        
            MOVE.B  #'A',(A1)+                 
            MOVE.B  #'L',(A1)+          
            MOVE.B  #'T',(A1)+                 
            MOVE.B  #00,(A1)+         

            CLR_A_REG D0, A1
            
            * print out string
            MOVE.B    #14, D0
            TRAP      #15
            
            MOVE.B    #8, D2
            MOVE.B    #54, D0
            TRAP      #15
            PRINT_MSG    newLine
            PRINT_MSG    doneMsg
            
            CLR_A_REG D0, A1
            
            *Write Pending data to file
            MOVE.B #56,D0 
            TRAP   #15
            

            END       MAIN              ; last line of source
*-----------------------------------------------------------