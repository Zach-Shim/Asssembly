# Disassembler or DASM FOR SHORT

## TODO List for this week:
TBD

## Current Opcode You Are Working On:
Zach:    TBD    
Brendan: MULS   
Lucas:   LEA    

## Updates:
<p>
JSR and RTS are done. All tests seem to be passing for now.
There were a couple bugs with ADD and SUB, so I added a few more subroutines that require calling ADDI, SUBI, ADDQ, and SUBQ. All tests seem to be passing for now.
Tested immediate data for MULS and it doesn't seem to be working. The current routine that it is performing is that it will always print out a longword for immediate data. Also sill need to test DIVS.
</p>

## Known Issues: 
<p>
Tested immediate data for MULS and it doesn't seem to be working.        
It calls a subroutine which in the end, will basically print out a longword every time there is an immediate data addressing mode called, which causes problems with parsing.     
Also sill need to test DIVS.   

Haven't tested with loading in data from opcode_test with a starting/ending address above a Word (right now I've been testing with $7000)  
</p>


## Features:
<p>
Current Supported Opcodes  
<ul>
  <li> ADD </li>  
  <li> AND </li>  
  <li> NOP </li>  
  <li> NOT </li>  
  <li> SUB </li>  
  <li> RTS </li>  
  <li> JSR </li>  
</ul>

<p>
Need Further Testing
<ul>
  <li> MULS </li>  
  <li> DIVU </li>  
</ul>

Opcdoes that will be supported in the future:
<ul>
  <li> MOVE, MOVEM
  <li> MULS, DIVU
  <li> LEA
  <li> NOT
  <li> LSL, LSR, ASL, ASR
  <li> Bcc (BLT, BGE, BEQ) 
  <li> JSR, RTS
  <li> BRA
 </ul>
</p>
