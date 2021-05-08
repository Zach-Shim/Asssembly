# Disassembler or DASM FOR SHORT

## TODO List for this week:
TBD

## Current Opcode You Are Working On:
Zach:    MOVE   
Brendan: MULS   
Lucas:   Bcc   

## Updates:
<p>
JSR and RTS are done. All tests seem to be passing for now.   
Implemented ADDI, SUBI, ADDQ, and SUBQ. All tests seem to be passing for now.   
MULS and DIVS are fixed.   
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
</ul>

Opcdoes that will be supported in the future:
<ul>
  <li> MOVE, MOVEM
  <li> LSL, LSR, ASL, ASR
  <li> Bcc (BLT, BGE, BEQ) 
  <li> BRA
 </ul>
</p>
