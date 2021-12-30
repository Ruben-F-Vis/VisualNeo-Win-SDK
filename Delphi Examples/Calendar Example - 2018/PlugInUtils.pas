unit PlugInUtils;

interface

{****************** NeoBook Interface Functions DO NOT MODIFY *****************}
{************************** Moved here from main unit *************************}

USES Windows, Messages, SysUtils, Classes, Graphics, Controls;

CONST { Action Command Parameter Types... }
      ACTIONPARAM_NONE     = 0;
      ACTIONPARAM_ALPHA    = 1;  { May contain alpha, numeric, punctuation, etc. }
      ACTIONPARAM_ALPHASP  = 2;  { Contains aplha text that can be spell checked. }
      ACTIONPARAM_NUMERIC  = 3;  { Must be numeric value 0..9 }
      ACTIONPARAM_MIXED    = 4;  { May be either numeric or alpha. May contain math expression }
      ACTIONPARAM_FILENAME = 5;  { Parameter is a file name }
      ACTIONPARAM_VARIABLE = 6;  { Parameter is a variable name }
      ACTIONPARAM_DATAFILE = 7;  { Parameter is data file - if not a variable then should be localized }
      ACTIONPARAM_OBJNAME  = 8;  { Parameter is an object name }
      ACTIONPARAM_MENUID   = 9;  { Parameter is a mennu item id }
      ACTIONPARAM_FILENOEX = 10; { Parameter is a file name that will not be extracted }

      MaxActionParams      = 10; { Maximum number of parameters per action }

      WM_NOTIFYPLUGINOBJECT  = WM_USER + 250;  { Used to send messages to child windows attached to
                                                 NeoBook Rectangle objects via plug-ins.

                                                 WParam is handle of sending rect object

                                                 lParam can be one of these:

                                                 1 = Page Leave
                                                 2 = Page Enter
                                                 3 = Leaving Run Mode }

TYPE TAddActionProc = PROCEDURE( IDNum      : INTEGER;
                                 Name, Hint : PChar;
                                 Params     : ARRAY OF BYTE;
                                 NumParams  : BYTE );
     TAddFileProc    = PROCEDURE( FileName : PChar; AddFlag : BOOLEAN );
     TVarGetProc     = PROCEDURE( VarName : PChar; VAR Value : PChar );
     TVarSetProc     = PROCEDURE( VarName, Value : PChar );
     TPlayActionProc = PROCEDURE( Action : PChar );
     TInterfaceProc  = FUNCTION( InterfaceID : INTEGER; VAR Data : PChar ) : BOOLEAN;

VAR nbGetVar     : TVarGetProc;
    nbSetVar     : TVarSetProc;
    nbPlayAction : TPlayActionProc;
    nbInterface  : TInterfaceProc;
    nbAddFile    : TAddFileProc;
    nbAddAction  : TAddActionProc;
    nbWinHandle  : HWND;

PROCEDURE FreeStr( VAR S : PChar );
PROCEDURE SetStr( VAR Dest : PChar; CONST Source : STRING );


implementation

{ Used to free memory allocated to PChars. You must use this if you create any
  PChars to send between NeoBook and your Plug-In DLL. Failure to use this
  procedure may result in memory allocation errors, memory leaks, crashes, etc... }
PROCEDURE FreeStr( VAR S : PChar );
BEGIN
  IF S <> NIL THEN GlobalFree( HGLOBAL( S ) );
  S := NIL;
END;

{ Used to modify PChar parameteres. You must use this if you modify any
  PChars sent between NeoBook and your Plug-In DLL. Failure to use this
  procedure may result in memory allocation errors, crashes, etc... }
PROCEDURE SetStr( VAR Dest : PChar; CONST Source : STRING );
BEGIN
  IF Dest <> NIL THEN GlobalFree( HGLOBAL( Dest ) );
  Dest := Pointer( GlobalAlloc( GMEM_FIXED, Length( Source )+1 ) );
  StrCopy( Dest, PChar( Source ) );
END;

end.
