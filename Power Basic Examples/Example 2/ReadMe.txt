Generic_PB-PlugIn.zip contains a complete PlugIn Skeleton for PowerBasic.

The main code, where you realize your code is GENERIC.BAS . All other NB-related functions are put into the 2 INC files. The PBR file is only the Resource file with one icon inside.

GENERIC.BAS - main Code for your function(s)

NB_Interface.inc - contains all NB initializations and declarations. This module must NOT be modified.

NB_PlugIn.inc - contains all NB-interfacing routines, to call your routines from within the NB-Runtime. Here you can modify code, in case you do use MORE than 1 own function.

So, normally, you only have to use the GENERIC.BAS for developing your code.

Limitations: The Code does ONLY supports one Parameter. That means, inside NB, every function is called with maximum of one parameter like GFX_Function "1 Parameter"
This Parameter can contain multiple parts, which are separated by a delimiter of your own choice, e.g. a "," And you have to parse this command for "sub-commands" by yourself inside your code first.

This isn´t a serious limitation, because the parse$ function inside PB is much more easy for handling than the code-overhead inside the NB-PlugIn itself. And so, there is NO limit for the number of parameters "inside" the parameter.

Routines for GetVariable, SetVariable and PlayAction are implemented and work well.

Special thanks to Gerhard Kropf for creating this template.