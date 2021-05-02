# Disassembler or DASM FOR SHORT
## Rundown:
<p>
 <ul>
<li>Zach Carrying the team </li>
<li>Brendan is helping Lucas Keep his sanity. </li> 
<li>Lucas is just trying to survive and figure out how to use Github </li>
</ul>
</p>

## Known Issues: 
<p>
I still have yet to test: <br>

In GET_EA_MODE <br>
opcode      -(An), <ea>  
opcode        (xxx).W, <ea>   
opcode        (xxx).L, <ea>  
opcode        immediate, <ea>        <--- this one is not implemented yet   

I also haven't tested with loading in data from opcode_test with a starting/ending address  above a Word (right now I've been testing with $7000)  

And i think that's it for now off the top of my head, let me know if theres anything else breaks and I will try to fix it. Also let me know if something is unclear so I can document it better. Don't be afraid to add helper functions or change my code cause as you guys see its not that great lol. Thanks again <br>
</p>

## Idea:
Having subroutines dedicated to finding specific bits. Will help modularize/abstract retrieving different bits for different routines.    
For example:  
GET_BITS_11_TO_9:
Would retrieve bits 7-9 in an opcode. For the ADD instruction (and some other instructions), this would help get the register operator bits. Will look further into and discuss at next meeting

Something similar has already been done in GET_EA_MODE, which is a subroutine that parses the last six bits of an opcode for the mode and register of an effective address. I believe most if not all opcodes share those bits in common (in terms of bit order), so that is useful function that we can share.

## Features:
<p>
Current Supported Opcodes 
<ul>
  <li> ADD </li>
  <li> NOP </li>
  <li> NOT </li>
</ul>
</p>
