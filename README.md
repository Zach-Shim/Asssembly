# Disassembler or DASM FOR SHORT
## Rundown:
*Zach Carrying the team <br>
*Brendan is helping Lucas Keep his sanity. <br>
*Lucas is just trying to survive and figure out how to use Github <br>

## Known Issues: 
I still have yet to test: <br>

In GET_EA_MODE <br>
opcode      -(An), <ea> <br>
opcode        (xxx).W, <ea> <br>
opcode        (xxx).L, <ea> <br>
opcode        immediate, <ea>        <--- this one is not implemented yet <br> 

I also haven't tested with loading in data from opcode_test with a starting/ending address  above a Word (right now I've been testing with $7000)<br> 

And i think that's it for now off the top of my head, let me know if theres anything else breaks and I will try to fix it. Also let me know if something is unclear so I can document it better. Don't be afraid to add helper functions or change my code cause as you guys see its not that great lol. Thanks again <br>
