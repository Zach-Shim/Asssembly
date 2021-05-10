# Disassembler or DASM FOR SHORT

## TODO List for this week:
TBD

## Current Opcode You Are Working On:
Zach:    MOVE   
Brendan: MULS   
Lucas:   Bcc   

## Updates:
<p>
Had to abstract DECODE_6_TO_0 to accommodate for MOVE.  
Now call DECODE_EA as a macro. Pass in two params. See API doc for details.  
If your opcode uses immediate addressing, it is necessary to put the size of the opcode operation into opSize. This is so immediate data will print correctly. opSize recognizes a operations of sizes: byte = 0, word = 1, and long = 2. Note that these values may differ depending on the opcode, so you may need to convert in your opc decoding subroutine.   
I updated the initial GET_INPUT subroutine to simplify the code and put in more error handling.   
MOVE is implemented.   
</p>

## Known Issues: 
<p>
Haven't tested with loading in data from opcode_test with a starting/ending address above a Word (right now I've been testing with $7000)  
I think he mentioned we don't have to worry about this though ^^^   
</p>


## Features:
<p>
Current Supported Opcodes  
<ul>
  <li> ADD </li>  
  <li> ADDI </li>  
  <li> ADDQ </li>  
  <li> AND </li>  
  <li> NOP </li>  
  <li> NOT </li>  
  <li> SUB </li>  
  <li> SUBI </li>  
  <li> SUBQ </li>  
  <li> MULS </li>  
  <li> DIVU </li>  
  <li> RTS </li>  
  <li> JSR </li>  
  <li> MOVE </li>
</ul>

Opcdoes that will be supported in the future:
<ul>
  <li> MOVEM
  <li> LSL, LSR, ASL, ASR
  <li> Bcc (BLT, BGE, BEQ) 
  <li> BRA
 </ul>
</p>
