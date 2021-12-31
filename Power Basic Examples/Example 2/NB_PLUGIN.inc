' ********** NeoBook Plug-In Functions that Must be Customized by You **********


'  nbExecAction - called by NeoBook to execute one of the Plug-In' s commands...

    FUNCTION nbExecAction ALIAS "_nbExecAction@8" (BYVAL IDNum AS LONG,BYREF Par$) EXPORT AS BYTE

        DIM x AS ASCIIZ PTR
        x = STRPTR(Par$)
        GK_Par$ = @x
        IF LEFT$(GK_Par$,2)="<#" AND RIGHT$(GK_Par$,2)="#>" THEN RetValue$=MID$(GK_Par$,3,LEN(GK_Par$)-4) : FUNCTION=%True : EXIT FUNCTION

      '  Examine the Action string to determine which Plug-In command to execute...

        SELECT CASE IDNum

                 CASE 1 : MainFunction BYCOPY GK_Par$ : FUNCTION = %True

                 CASE ELSE: FUNCTION = %False

        END SELECT

    END FUNCTION


'  nbEditAction - called by NeoBook to edit/define on of the Plug-In' s commands.
'  Plug-In may display a dialog box with fields for user to fill in. Return
'  TRUE if successful, FALSE if not..

    FUNCTION nbEditAction ALIAS "_nbEditAction@8" (BYVAL IDNum AS LONG, Params AS ASCIIZ) EXPORT AS BYTE

    '  Examine the Action string to determine which Plug-In command to execute...

      SELECT CASE IDNum

             CASE 1: FUNCTION = %True

             CASE ELSE: FUNCTION = %FALSE

      END SELECT

    END FUNCTION


'  nbInitPlugIn - called by NeoBook To request information about the Plug-In...

    SUB nbInitPlugIn ALIAS "_nbInitPlugIn@16" (BYVAL WinHandle AS DWORD, _
                                               BYREF PlugInTitle AS DWORD, _
                                               BYREF PlugInPublisher AS DWORD, _
                                               BYREF PlugInHint AS DWORD) EXPORT

      '  Save Handle Of Parent NeoBook App Or compiled pub Window - may be required by some Windows functions
      nbWinHandle = WinHandle

      '  Title Of this Plug-In (appears As heading In NeoBook' s action list)
      SetStr PlugInTitle, $PLUGIN_TITLE

      '  Publisher Of this Plug-In
      SetStr PlugInPublisher, $PLUGIN_AUTHOR

      '  Description Of this Plug-In
      SetStr PlugInHint, $PLUGIN_INFO

    END SUB



'  nbRegisterScriptProcessor - called by NeoBook when registering your plug-In
'  Provides Access To NeoBook' s Action Script Player via nbPlayAction...

    SUB nbRegisterScriptProcessor ALIAS "_nbRegisterScriptProcessor@4" (BYVAL PlayActionProc AS DWORD) EXPORT

      ' ***************************** Do Not MODIFY ********************************
      nbPlayAction = PlayActionProc
      ' ****************************************************************************

    END SUB


'  nbMessage - sent by NeoBook To inform plug-In Of important NeoBook activities...

    SUB nbMessage ALIAS "_nbMessage@8" (BYVAL MsgCode AS LONG, BYVAL Reserved AS LONG) EXPORT

      '  Not All types Of plug-ins will care about these messages,
      '  so they can be ignored If Not needed. This procedure must be present even If
      '  None Of the messages are used.
      '
      '  Possible MsgCode values are:
      '
      '    1  = Pub has entered run mode
      '    2  = Pub is about To Exit run mode And Return To design mode.
      '    3  = Pub window has been deactivated
      '    4  = Pub window has been activated
      '    5  = Pub window has been moved Or sized
      '    6  = Pub is about To display another page
      '    7  = Pub window has been minimized
      '    8  = Pub window has been restored
      '    9  = A pub was opened (design mode only)
      '    10 = A pub was saved (design mode only)
      '
      '  Reserved value is Not currently used
      '

      SELECT CASE MsgCode
             CASE 01:   '  Don' t care
             CASE 02:   '  Don' t care
             CASE 03:   '  Don' t care
             CASE 04:   '  Don' t care
             CASE 05:   '  Don' t care
             CASE 06:   '  Don' t care
             CASE 07:   '  Don' t care
             CASE 08:   '  Don' t care
             CASE 09:   '  Don' t care
             CASE 10:   '  Don' t care
      END SELECT

    END SUB


'  nbRegisterInterfaceAccess - called by NeoBook when registering your plug-In
'  Provides Access To some Of NeoBook' s design-time interface via nbInterface...

    SUB nbRegisterInterfaceAccess ALIAS "_nbRegisterInterfaceAccess@4" (BYVAL InterfaceProc AS DWORD) EXPORT

      ' ***************************** Do Not MODIFY ********************************
      nbInterface = InterfaceProc
      ' ****************************************************************************

    END SUB


'  nbVerifyLicense - This is an Optional Function that can be used To implement a
'  registration scheme For commercial Or shareware plug-ins. It should Not be
'  implemented For freeware plug-ins. ' ove comment code From here And Export
'  At bottom Of file To implement nbVerifyLicense. User must have NeoBook version
'  4.1.3 Of higher To Access this feature...

    FUNCTION VerifyRegCode(Code AS ASCIIZ PTR) AS LONG

      '  Verify If code is valid And Return True Or False. Do Not display Any
      '  Dialog boxes Or messages...

      '  Validate for the demo...
      FUNCTION = %True

    END FUNCTION


    FUNCTION GetRegCode(BYREF CodeStr AS ASCIIZ) AS LONG

      '  Display your Dialog box And allow User To enter registration code here.
      '  If code is valid, Return CodeStr And True. Otherwise, Return False...

      '  Validate for the demo...
      CodeStr = "ABC123"
      FUNCTION = %True

    END FUNCTION


    FUNCTION nbVerifyLicense(BYREF Code AS ASCIIZ) AS BYTE

      DIM CodeStr AS ASCIIZ * 256

      IF LEN(Code) = 0 THEN '  empty parameter
          '  Code parameter is null so display your plug-in registration dialog and
          '  allow User To enter his/her registration code. This section Of code is
          '  executed when a User clicks On the "register this plug-in" Button In
          '  NeoBook' s Plug-In Options screen. You can also display information on
          '  this Dialog For curious users who haven' t yet purchased your plug-in.

          IF GetRegCode(CodeStr) THEN
              '  If User enters the correct registration code, Return it To NeoBook
              '  (As a PChar). You may encrypt the code If you like, but it must be 255
              '  characters Or less. NeoBook will also encrypt the code, so encryption
              '  is optional. Since the code is valid, you should also Switch your
              '  plug-In into registered mode.

              SetStr VARPTR(Code), CodeStr
              FUNCTION = %TRUE
          END IF
      ELSE
          '   Code var contains a registration code that NeoBook wants you To check.
          '   You should only Verify the code And Return true If it' s OK or false if
          '   it' s not. Do not display dialog boxes or messages here. If you encrypted
          '   the code above, you will need To unencrypt it here. If the code is
          '   valid, you should Switch your plug-In into registered mode.
          FUNCTION = VerifyRegCode(VARPTR(Code))
      END IF

    END FUNCTION



'  nbRegisterPlugIn - called by NeoBook when it wants you To Register your plug-In' s actions...

    SUB nbRegisterPlugIn ALIAS "_nbRegisterPlugIn@16" (BYVAL AddActionProc AS DWORD, _
                                                       BYVAL AddFileProc AS DWORD, _
                                                       BYVAL VarGetFunc AS DWORD, _
                                                       BYVAL VarSetFunc AS DWORD) EXPORT

      ' ***************************** Do Not MODIFY ********************************
      nbGetVar      = VarGetFunc
      nbSetVar      = VarSetFunc
      nbAddAction   = AddActionProc
      nbAddFile     = AddFileProc
      ' ****************************************************************************

      '  Call the AddAction procedure For each Of Plug-In command.
      '
      '  Parameters For the ndAddAction procedure:
      '
      '  Item 1 = Action ID number - must use a unique identifier For each Of your actions.
      '  Item 2 = Action Name
      '  Item 3 = Action Description
      '  Item 4 = Array describing each Of the Action' s parameters - choose from the following:
      '
      '    ACTIONPARAM_NONE     = Use If action contains no parameters.
      '    ACTIONPARAM_ALPHA    = Parameter is a string. May contain alpha, numeric, punctuation, etc.
      '    ACTIONPARAM_ALPHASP  = Parameter is a String that can be spell checked.
      '    ACTIONPARAM_NUMERIC  = Parameter is a number.
      '    ACTIONPARAM_MIXED    = May be either numeric Or alpha. May contain math expression.
      '    ACTIONPARAM_FILENAME = Parameter is a file name.
      '    ACTIONPARAM_VARIABLE = Parameter is a variable name.
      '    ACTIONPARAM_DATAFILE = Parameter is Data file - if not a variable then should be localized.
      '
      '  Item 5 = Number Of parameters required by this action
      '
      ' ******************* Enter your Plug-In' s actions below *********************

      '  Next, If necessary, tell NeoBook what extra files are required For your plug-in.
      '  These are the files that NeoBook will collect when compiling publications that
      '  use this plug-in. If your plug-In uses Any Data files, drivers or special DLLs
      '  this is where you will tell NeoBook about it. It is Not necessary To include
      '  the Name Of the plug-In itself since NeoBook will automatically assume that
      '  it is required.


      xnbAddAction 1, $FUNKTIONS_NAME1, $PLUGIN_INFO, "ACTIONPARAM_ALPHA", 1

      ' CALL DWORD nbAddFile USING AddFileProcType("YourDLL.DLL",%True)


    END SUB


    FUNCTION LIBMAIN(BYVAL hInstance AS DWORD, _
                     BYVAL Reason    AS LONG, _
                     BYVAL Reserved  AS LONG) AS LONG


      IF (Reason = %DLL_PROCESS_DETACH) THEN

         '  If this plug-In requires Any special processing before being unloaded From
         '  memory, Do that here. Leave blank If no special processing is needed.

      END IF

      FUNCTION = %True
    END FUNCTION
