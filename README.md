# Disassembler or DASM FOR SHORT
## Rundown:
<p>
Combined ADD, SUB, and AND subroutines into one function, since all of them share the same bit placements. So those are all done (haven't tested all addressing modes though).
</p>

## Known Issues: 
<p>
I still have yet to test: <br>

In GET_EA_MODE <br>
opcode        -(An), <ea>            <--- still not tested   
opcode        (xxx).W, <ea>          <--- have been lightly tested and should work with current test file   
opcode        (xxx).L, <ea>          <--- have been lightly tested and should work with current test file  
opcode        immediate, <ea>        <--- this one is not implemented yet    

I also haven't tested with loading in data from opcode_test with a starting/ending address above a Word (right now I've been testing with $7000)  
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
</ul>
</p>
