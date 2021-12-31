'______________________________________________________________________________
'
'  NeoBook Plug-In Example for PowerBASIC
'  --------------------------------------
'
'  Please refer to the "NeoBook Plug-In DOC.rtf" file for instructions.
'
'  Converted to PowerBASIC v7.02: 26/02/2004.
'
'  Notes: NeoBook expects decorated (C\C++ style) function names with a parameter
'         byte count. ie: "_MyFunc@4" where the 4 is no. of bytes passed.
'
'         nbAddAction uses a different calling convenstion so we use a 'thunking' method
'______________________________________________________________________________

#Compile Dll
#Dim All
#Register All

%USEMACROS = 1
#Include "WIN32API.INC"


$PLUGIN_TITLE   = "COM Communication for NeoBook"
$PLUGIN_AUTHOR  = "Author"
$PLUGIN_INFO    = "Allows interaction with COM ports from within NeoBook"


#Resource "testplug.pbr"   ' <--- Edit this file with a resource editor to change this plug-in's
                           '      icon which appears in NeoBook's Action list...

'****************** NeoBook Interface Functions DO NOT MODIFY *****************
'*
'* Action Command Parameter Types...
'
 %ACTIONPARAM_NONE     = 0
 %ACTIONPARAM_ALPHA    = 1   ' May contain alpha, numeric, punctuation, etc.
 %ACTIONPARAM_ALPHASP  = 2   ' Contains aplha text that can be spell checked.
 %ACTIONPARAM_NUMERIC  = 3   ' Must be numeric value 0..9
 %ACTIONPARAM_MIXED    = 4   ' May be either numeric or alpha. May contain math expression
 %ACTIONPARAM_FILENAME = 5   ' Parameter is a file name
 %ACTIONPARAM_VARIABLE = 6   ' Parameter is a variable name
 %ACTIONPARAM_DATAFILE = 7   ' Parameter is data file - if not a variable then should be localized

 %MaxActionParams      = 10  ' Maximum number of parameters per action


Declare Sub AddActionProcType(ByVal IDNum As Long, ByRef zName As Asciiz, ByRef Hint As Asciiz, ByRef Params As Asciiz) ', ByVal NumParams As Byte)
Declare Sub AddFileProcType(ByRef s As Asciiz, ByVal AddFlag As Long)
Declare Sub GetVarProcType(ByRef VarName As Asciiz, ByRef Value As Asciiz)
Declare Sub SetVarProcType(ByRef VarName As Asciiz, ByRef Value As Asciiz)
Declare Sub PlayActionProcType(ByRef s As Asciiz)
Declare Function InterfaceProcType(ByVal InterfaceID As Long, ByRef zData As Asciiz) As Long
Declare Sub dllHandlerProcType(ByVal Reason As Long)


'   Used to free memory allocated to PChars. You must use this if you create any
'   PChars to send between NeoBook and your Plug-In DLL. Failure to use this
'   procedure may result in memory allocation errors, memory leaks, crashes, etc...

Sub FreeStr(ByRef S As Dword)
  If S <> %NULL Then GlobalFree S
  S = %NULL
End Sub

'   Used to modify PChar parameters. You must use this if you modify any
'   PChars sent between NeoBook and your Plug-In DLL. Failure to use this
'   procedure may result in memory allocation errors, crashes, etc...

Sub SetStr(ByRef Dest As Dword, ByVal Source As String)
  FreeStr Dest
  If Len(Source) Then
     Dest = GlobalAlloc(%GPTR, Len(Source) + 1)
     Poke$ Dest, Source
  End If
End Sub


Global nbGetVar     As Dword
Global nbSetVar     As Dword
Global nbPlayAction As Dword
Global nbInterface  As Dword
Global nbAddFile    As Dword
Global nbAddAction  As Dword
Global nbWinHandle  As Dword

Global gsComPort    As String


Sub xnbAddAction(ByVal IDNum As Long, zName As Asciiz, zHint As Asciiz, Params As Asciiz, ByVal NumParams As Byte)

  ' Do not edit.  This is to match Delphi's calling conventions.
  Asm push eax
  Asm xor eax,eax
  Asm mov al, NumParams
  Asm push eax
  Asm push eax

  Call Dword nbAddAction Using AddActionProcType(IDNum, zName, zHint, Params)
  Asm pop eax
End Sub


'******************** End of NeoBook Interface Functions **********************



'******************* Your Custom Plug-In Functions Go Here ********************


%IDC_PORTS = 100

'------------------------------------------------------------------------------
' Callback for the port selector dialog
'------------------------------------------------------------------------------
CallBack Function dlgPorts
  Local n As Long

  Select Case CbMsg

         Case %WM_COMMAND
              Select Case CbCtl

                     Case %IDOK
                          If (CbCtlMsg = %BN_CLICKED) Then
                             ' Return index selected...
                             Control Send CbHndl, %IDC_PORTS, %CB_GETCURSEL, 0, 0 To n
                             Dialog End CbHndl, n+1
                          End If

                     Case %IDCANCEL
                          If (CbCtlMsg = %BN_CLICKED) Then Dialog End CbHndl

              End Select

  End Select

End Function


'------------------------------------------------------------------------------
' Prompts user to choose a specific COM-port. Returns the one selected.
'------------------------------------------------------------------------------
Function SelectComPort(ByVal hParent As Dword) As String
  Local hDlg As Dword, i As Long, n As Long, lCommProp As COMMPROP, lDCB As DCB, hComPort As Dword, dummy As Dword

  For i = 1 To 16
      hComPort = CreateFile("COM" + Format$(i), %GENERIC_READ Or %GENERIC_WRITE, 0, ByVal %Null, _
                           %OPEN_EXISTING, 0, ByVal %NULL)

      If (hComPort <> %INVALID_HANDLE_VALUE) Then
         If GetCommState(hComPort, lDCB) Then
            ReDim Preserve sPorts(n) As String
            If GetCommModemStatus(hComPort, dummy) Then
               sPorts(n) = "COM" + Format$(i) + ": (Modem)"
            Else
               sPorts(n) = "COM" + Format$(i) + ": (Unknown Device)"
            End If
            Incr n
         End If
      End If
      CloseHandle hComPort
  Next i

  If n = 0 Then
     MessageBox hParent, "No installed COM ports found on system", "No ports found", %MB_ICONINFORMATION
     Exit Function
  End If

  Dialog New hParent, "Select a COM port", 261, 170, 157, 62, %WS_CAPTION Or %WS_SYSMENU Or %DS_MODALFRAME To hDlg
  Control Add Button, hDlg, %IDOK, "OK", 76, 43, 35, 14
  Control Add Button, hDlg, %IDCANCEL, "Cancel", 115, 43, 35, 14
  Control Add Label, hDlg,  -1, "Available &Ports:", 10, 8, 85, 10
  Control Add ComboBox, hDlg, %IDC_PORTS, sPorts(), 10, 20, 140, 98, %WS_CHILD Or %WS_VISIBLE Or %WS_TABSTOP Or %CBS_DROPDOWNLIST
  ComboBox Select hDlg, %IDC_PORTS, 1
  Dialog Show Modal hDlg Call dlgPorts To n

  ' Return selected port...
  If n Then Function = Parse$(sPorts(n-1), ":", 1)
End Function


'------------------------------------------------------------------------------
' Output data to the selected COM port.
'------------------------------------------------------------------------------
Sub ComPortCommunicate(ByVal hParent As Dword)
  Dim nPort As Long

  On Error GoTo PortErrorEvent:

  If Len(gsComPort) = 0 Then
     MessageBox hParent, "You must select a COM port before you can use this function.", $PLUGIN_TITLE, %MB_ICONINFORMATION
     Exit Sub
  End If

  nPort = FreeFile
  Comm Open gsComPort As #nPort

       ' [PLACEHOLDER]
       ' DO PORT STUFF HERE
       MessageBox hParent, "Port opened: " + gsComPort + ":", $PLUGIN_TITLE, %MB_ICONINFORMATION

  Close #nPort

  Exit Sub
  PortErrorEvent:
  MessageBox hParent, "There was a problem opening port " + gsComPort + ": . The error was " + $Dq + Error$ + $Dq, $PLUGIN_TITLE, %MB_ICONINFORMATION
End Sub



'********** NeoBook Plug-In Functions that Must be Customized by You **********

' nbEditAction - called by NeoBook to edit/define on of the Plug-In's commands.
' Plug-In may display a dialog box with fields for user to fill in. Return
' TRUE if successful, FALSE if not..

Function nbEditAction Alias "_nbEditAction@8" (ByVal IDNum As Long, Params As Asciiz) Export As Byte

  ' Examine the Action string to determine which Plug-In command to execute...
  Select Case IDNum

         Case 1: Function = %True
         Case 2: Function = %True
         Case Else: Function = %FALSE

  End Select

End Function



' nbExecAction - called by NeoBook to execute one of the Plug-In's commands...
Function nbExecAction Alias "_nbExecAction@8" (ByVal IDNum As Long, Params As Asciiz) Export As Byte

  ' Examine the Action string to determine which Plug-In command to execute...
  Select Case IDNum

         Case 1: gsComPort = SelectComPort(GetActiveWindow): Function = %True
         Case 2: ComPortCommunicate GetActiveWindow : Function = %True
         Case Else: Function = %FALSE

  End Select

End Function



' nbInitPlugIn - called by NeoBook To request information about the Plug-In...

Sub nbInitPlugIn Alias "_nbInitPlugIn@16" (ByVal WinHandle As Dword, _
                                           ByRef PlugInTitle As Dword, _
                                           ByRef PlugInPublisher As Dword, _
                                           ByRef PlugInHint As Dword) Export

  ' Save Handle Of Parent NeoBook App Or compiled pub Window - may be required by some Windows functions
  nbWinHandle = WinHandle

  ' Title Of this Plug-In (appears As heading In NeoBook's action list)
  SetStr PlugInTitle, $PLUGIN_TITLE

  ' Publisher Of this Plug-In
  SetStr PlugInPublisher, $PLUGIN_AUTHOR

  ' Description Of this Plug-In
  SetStr PlugInHint, $PLUGIN_INFO

End Sub



' nbRegisterScriptProcessor - called by NeoBook when registering your plug-In
' Provides Access To NeoBook's Action Script Player via nbPlayAction...
Sub nbRegisterScriptProcessor Alias "_nbRegisterScriptProcessor@4" (ByVal PlayActionProc As Dword) Export

  '***************************** Do Not MODIFY ********************************
  nbPlayAction = PlayActionProc
  '****************************************************************************

End Sub


' nbMessage - sent by NeoBook To inform plug-In Of important NeoBook activities...
Sub nbMessage Alias "_nbMessage@8" (ByVal MsgCode As Long, ByVal Reserved As Long) Export

  ' Not All types Of plug-ins will care about these messages,
  ' so they can be ignored If Not needed. This procedure must be present even If
  ' None Of the messages are used.
  '
  ' Possible MsgCode values are:
  '
  '   1  = Pub has entered run mode
  '   2  = Pub is about To Exit run mode And Return To design mode.
  '   3  = Pub window has been deactivated
  '   4  = Pub window has been activated
  '   5  = Pub window has been moved Or sized
  '   6  = Pub is about To display another page
  '   7  = Pub window has been minimized
  '   8  = Pub window has been restored
  '   9  = A pub was opened (design mode only)
  '   10 = A pub was saved (design mode only)
  '
  ' Reserved value is Not currently used
  '

  Select Case MsgCode
         Case 01:   ' Don't care
         Case 02:   ' Don't care
         Case 03:   ' Don't care
         Case 04:   ' Don't care
         Case 05:   ' Don't care
         Case 06:   ' Don't care
         Case 07:   ' Don't care
         Case 08:   ' Don't care
         Case 09:   ' Don't care
         Case 10:   ' Don't care
  End Select

End Sub


' nbRegisterInterfaceAccess - called by NeoBook when registering your plug-In
' Provides Access To some Of NeoBook's design-time interface via nbInterface...
Sub nbRegisterInterfaceAccess Alias "_nbRegisterInterfaceAccess@4" (ByVal InterfaceProc As Dword) Export

  '***************************** Do Not MODIFY ********************************
  nbInterface = InterfaceProc
  '****************************************************************************

End Sub


' nbVerifyLicense - This is an Optional Function that can be used To implement a
' registration scheme For commercial Or shareware plug-ins. It should Not be
' implemented For freeware plug-ins. Remove comment code From here And Export
' At bottom Of file To implement nbVerifyLicense. User must have NeoBook version
' 4.1.3 Of higher To Access this feature...

Function VerifyRegCode(Code As Asciiz Ptr) As Long

  ' Verify If code is valid And Return True Or False. Do Not display Any
  ' Dialog boxes Or messages...

  ' Validate for the demo...
  Function = %True

End Function


Function GetRegCode(ByRef CodeStr As Asciiz) As Long

  ' Display your Dialog box And allow User To enter registration code here.
  ' If code is valid, Return CodeStr And True. Otherwise, Return False...

  ' Validate for the demo...
  CodeStr = "ABC123"
  Function = %True

End Function


Function nbVerifyLicense(ByRef Code As Asciiz) As Byte

  Dim CodeStr As Asciiz * 256

  If Len(Code) = 0 Then ' empty parameter
      ' Code parameter is null so display your plug-in registration dialog and
      ' allow User To enter his/her registration code. This section Of code is
      ' executed when a User clicks On the "register this plug-in" Button In
      ' NeoBook's Plug-In Options screen. You can also display information on
      ' this Dialog For curious users who haven't yet purchased your plug-in.

      If GetRegCode(CodeStr) Then
          ' If User enters the correct registration code, Return it To NeoBook
          ' (As a PChar). You may encrypt the code If you like, but it must be 255
          ' characters Or less. NeoBook will also encrypt the code, so encryption
          ' is optional. Since the code is valid, you should also Switch your
          ' plug-In into registered mode.

          SetStr VarPtr(Code), CodeStr
          Function = %TRUE
      End If
  Else
      '  Code var contains a registration code that NeoBook wants you To check.
      '  You should only Verify the code And Return true If it's OK or false if
      '  it's not. Do not display dialog boxes or messages here. If you encrypted
      '  the code above, you will need To unencrypt it here. If the code is
      '  valid, you should Switch your plug-In into registered mode.
      Function = VerifyRegCode(VarPtr(Code))
  End If

End Function



' nbRegisterPlugIn - called by NeoBook when it wants you To Register your plug-In's actions...
Sub nbRegisterPlugIn Alias "_nbRegisterPlugIn@16" (ByVal AddActionProc As Dword, _
                                                   ByVal AddFileProc As Dword, _
                                                   ByVal VarGetFunc As Dword, _
                                                   ByVal VarSetFunc As Dword) Export

  '***************************** Do Not MODIFY ********************************
  nbGetVar      = VarGetFunc
  nbSetVar      = VarSetFunc
  nbAddAction   = AddActionProc
  nbAddFile     = AddFileProc
  '****************************************************************************

  ' Call the AddAction procedure For each Of Plug-In command.
  '
  ' Parameters For the ndAddAction procedure:
  '
  ' Item 1 = Action ID number - must use a unique identifier For each Of your actions.
  ' Item 2 = Action Name
  ' Item 3 = Action Description
  ' Item 4 = Array describing each Of the Action's parameters - choose from the following:
  '
  '   ACTIONPARAM_NONE     = Use If action contains no parameters.
  '   ACTIONPARAM_ALPHA    = Parameter is a string. May contain alpha, numeric, punctuation, etc.
  '   ACTIONPARAM_ALPHASP  = Parameter is a String that can be spell checked.
  '   ACTIONPARAM_NUMERIC  = Parameter is a number.
  '   ACTIONPARAM_MIXED    = May be either numeric Or alpha. May contain math expression.
  '   ACTIONPARAM_FILENAME = Parameter is a file name.
  '   ACTIONPARAM_VARIABLE = Parameter is a variable name.
  '   ACTIONPARAM_DATAFILE = Parameter is Data file - if not a variable then should be localized.
  '
  ' Item 5 = Number Of parameters required by this action
  '
  '******************* Enter your Plug-In's actions below *********************

  ' Next, If necessary, tell NeoBook what extra files are required For your plug-in.
  ' These are the files that NeoBook will collect when compiling publications that
  ' use this plug-in. If your plug-In uses Any Data files, drivers or special DLLs
  ' this is where you will tell NeoBook about it. It is Not necessary To include
  ' the Name Of the plug-In itself since NeoBook will automatically assume that
  ' it is required.


  ' Add the COM port actions...
  xnbAddAction 1, "PortSelect", "Select a COM port to output data", "0", 0
  xnbAddAction 2, "PortCommunicate", "Communicate with a selected COM port", "0", 0

End Sub


Function LibMain(ByVal hInstance As Dword, _
                 ByVal Reason    As Long, _
                 ByVal Reserved  As Long) As Long

  If (Reason = %DLL_PROCESS_DETACH) Then

     ' If this plug-In requires Any special processing before being unloaded From
     ' memory, Do that here. Leave blank If no special processing is needed.

  End If

  Function = %True
End Function
