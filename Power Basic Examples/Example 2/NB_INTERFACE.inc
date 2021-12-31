#INCLUDE "WIN32API.INC"

' ****************** NeoBook Interface Functions DO NOT MODIFY *****************
' * Action Command Parameter Types...

    %ACTIONPARAM_NONE     = 0
    %ACTIONPARAM_ALPHA    = 1   '  May contain alpha, numeric, punctuation, etc.
    %ACTIONPARAM_ALPHASP  = 2   '  Contains aplha text that can be spell checked.
    %ACTIONPARAM_NUMERIC  = 3   '  Must be numeric value 0..9
    %ACTIONPARAM_MIXED    = 4   '  May be either numeric or alpha. May contain math expression
    %ACTIONPARAM_FILENAME = 5   '  Parameter is a file name
    %ACTIONPARAM_VARIABLE = 6   '  Parameter is a variable name
    %ACTIONPARAM_DATAFILE = 7   '  Parameter is data file - if not a variable then should be localized

    %MaxActionParams      = 10  '  Maximum number of parameters per action


    DECLARE SUB AddActionProcType(BYVAL IDNum AS LONG, BYREF zName AS ASCIIZ, BYREF Hint AS ASCIIZ, BYREF Params AS ASCIIZ) ' , ByVal NumParams As Byte)
    DECLARE SUB AddFileProcType(BYREF s AS ASCIIZ, BYVAL AddFlag AS LONG)
    DECLARE SUB GetVarProcType(BYREF VarName AS ASCIIZ, BYREF Value AS ASCIIZ)
    DECLARE SUB SetVarProcType(BYREF VarName AS ASCIIZ, BYREF Value AS ASCIIZ)
    DECLARE SUB PlayActionProcType(BYREF s AS ASCIIZ)
    DECLARE FUNCTION InterfaceProcType(BYVAL InterfaceID AS LONG, BYREF zData AS ASCIIZ) AS LONG
    DECLARE SUB dllHandlerProcType(BYVAL Reason AS LONG)


'    Used to free memory allocated to PChars. You must use this if you create any
'    PChars to send between NeoBook and your Plug-In DLL. Failure to use this
'    procedure may result in memory allocation errors, memory leaks, crashes, etc...

    SUB FreeStr(BYREF S AS DWORD)
      IF S <> %NULL THEN GlobalFree S
      S = %NULL
    END SUB

'    Used to modify PChar parameters. You must use this if you modify any
'    PChars sent between NeoBook and your Plug-In DLL. Failure to use this
'    procedure may result in memory allocation errors, crashes, etc...

    SUB SetStr(BYREF Dest AS DWORD, BYVAL Source AS STRING)
      FreeStr Dest
      IF LEN(Source) THEN
         Dest = GlobalAlloc(%GPTR, LEN(Source) + 1)
         POKE$ Dest, Source
      END IF
    END SUB


    GLOBAL nbGetVar     AS DWORD
    GLOBAL nbSetVar     AS DWORD
    GLOBAL nbPlayAction AS DWORD
    GLOBAL nbInterface  AS DWORD
    GLOBAL nbAddFile    AS DWORD
    GLOBAL nbAddAction  AS DWORD
    GLOBAL nbWinHandle  AS DWORD
    GLOBAL RetValue$


    SUB xnbAddAction(BYVAL IDNum AS LONG, zName AS ASCIIZ, zHint AS ASCIIZ, Params AS ASCIIZ, BYVAL NumParams AS BYTE)

      ASM push eax
      ASM xor eax,eax
      ASM mov al, NumParams
      ASM push eax
      ASM push eax
      CALL DWORD nbAddAction USING AddActionProcType(IDNum, zName, zHint, Params)
      ASM pop eax

    END SUB

    SUB SetVariable(BYVAL Variable$,BYVAL Wert$)
        CALL DWORD nbSetVar USING SetVarProcType(BYCOPY Variable$,BYCOPY Wert$)
    END SUB

    SUB PlayScript(BYVAL Script$)
        CALL DWORD nbPlayAction USING PlayActionProcType(BYCOPY Script$)
    END SUB

    FUNCTION GetVariable(par$) AS STRING
        RetValue$=""
        PlayScript $FUNKTIONS_NAME1+CHR$(32,34)+"<#["+par$+"]#>"+CHR$(34)
        FUNCTION=RetValue$
    END FUNCTION


' ******************** End of NeoBook Interface Functions **********************
