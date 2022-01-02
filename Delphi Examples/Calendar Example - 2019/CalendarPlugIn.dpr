LIBRARY CalendarPlugIn;

{ This is a sample Delphi project that demonstrates how to create a simple
  Calendar plugin for NeoBook v4/5. Please refer to the "NeoBook Plug-In DOC.rtf"
  file for additional information. }

uses
  Windows,
  Messages,
  SysUtils,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Calendar,
  Edit1 in 'Edit1.pas' {EditForm1},
  PlugInUtils in 'PlugInUtils.pas';

{$E nbp}

{$R CAL.RES}   { <--- Edit this file with a resource editor to change this plug-in's
                      icon which appears in NeoBook's Action list... }


{ NOTE: NeoBook Interface Functions moved to PlugInUtils unit so they can be
  accessed from Edit1.pas. }


{******************* Your Custom Plug-In Functions Go Here ********************}

{ CalList is used to keep track of the calendar controls we create. We can use this
  list to find the controls later if we want to modify them... }
CONST CalList : TList = NIL;

{ We're going to create our own version of Delphi's TCalendar control so we can
  add some NeoBook specific functions to it...}
TYPE TNeoCalendar = CLASS( TCalendar )
     PRIVATE
       { Private declarations }
       PROCEDURE WMNotifyPlugIn( VAR Msg : TMessage ); MESSAGE WM_NOTIFYPLUGINOBJECT;
     PROTECTED
       { Protected declarations }
       PROCEDURE Change; OVERRIDE;
     PUBLIC
       { Public declarations }
       VariableName,
       RectangleName : ANSISTRING;
     PUBLISHED
       { Published declarations }
     END;

{ This procedure is called every time the value of the Calendar control changes.
  We can use this opportunity to update our NeoBook variable... }
PROCEDURE TNeoCalendar.Change;
BEGIN
  INHERITED CHANGE;
  IF VariableName > '' THEN
    nbSetVar( PAnsiChar( VariableName ), PAnsiChar( ANSISTRING(DateToStr( EncodeDate( Year, Month, Day ) ) )) );
END;

{ This procedure intercepts messages sent by NeoBook... }
PROCEDURE TNeoCalendar.WMNotifyPlugIn( VAR Msg : TMessage );
VAR R : TRect;
BEGIN
  CASE Msg.lParam OF
    1 : ; { Page Leave }
    2 : ; { Page Enter }
    3 : ; { Leaving Run mode }
    4 : BEGIN
          { Host rectangle was resized, so adjust the calendar to match... }
          Windows.GetClientRect( ParentWindow, R );
          SetWindowPos( Handle, 0, 0, 0,
            R.Right-R.Left, R.Bottom-R.Top, SWP_SHOWWINDOW );
        END;
  END;
END;

{ Checks to see if author is using NeoBook version 4.0.9 or higher... }
FUNCTION CheckVer : BOOLEAN;
VAR P : PAnsiChar;
BEGIN
  Result := FALSE;
  IF Assigned( nbInterface ) THEN
    TRY
      P := NIL;
      nbInterface( 6, P );
      { If NeoBook version of 4.0.9 or higher then P will contain a number.
        If P = NIL then this is an earlier version of NeoBook... }
      Result := P <> NIL
    FINALLY
      FreeStr( P );
    END;
END;


FUNCTION FindCalendarControl( RectangleName : ANSISTRING ) : INTEGER;
VAR I : INTEGER;
BEGIN
  { Search the CalList to see if there's one that's attached to a NeoBook
    rectangle with this name... }
  Result := -1;
  I     := 0;
  IF Assigned( CalList ) THEN
    WHILE (I < CalList.Count) AND (Result = -1) DO
      BEGIN
        IF CompareText( TNeoCalendar( CalList.Items[I] ).RectangleName, RectangleName ) = 0 THEN
          Result := I;
        Inc( I );
      END;
END;

FUNCTION RemoveCalendarControl( RectangleName : ANSISTRING; ShowErrors : BOOLEAN ) : BOOLEAN;
VAR Found : INTEGER;
BEGIN
  Result := FALSE;
  TRY
    { Search the CalList to see if there's one that's attached to a NeoBook
      rectangle with this name... }
    Found := FindCalendarControl( RectangleName );

    IF Found > -1 THEN
      BEGIN
        { We found it, so clear the variable and delete the Calendar control... }
        IF TNeoCalendar( CalList.Items[Found] ).VariableName > '' THEN
          nbSetVar( PAnsiChar( TNeoCalendar( CalList.Items[Found] ).VariableName ), '' );
        TNeoCalendar( CalList.Items[Found] ).Free;
        { Remove the control from our list too... }
        CalList.Delete( Found );
        Result := TRUE;
      END
    ELSE IF ShowErrors THEN
      nbSetVar( '[LastError]', PAnsiChar( 'There is no calendar control attached to an object named '+RectangleName+'.' ) );

  EXCEPT ON E : Exception DO
    nbSetVar( '[LastError]', PAnsiChar( E.Message ) );
  END;
END;

FUNCTION SetCalendarControl( RectangleName, NewDate : ANSISTRING ) : BOOLEAN;
VAR Found   : INTEGER;
    M, D, Y : WORD;
BEGIN
  Result := FALSE;
  TRY
    { Search the CalList to see if there's one that's attached to a NeoBook
      rectangle with this name... }
    Found := FindCalendarControl( RectangleName );

    IF Found > -1 THEN
      BEGIN
        { We found it, so change the Calendar control's value... }

        DecodeDate( StrToDate( STRING(NewDate) ), Y, M, D );

        TNeoCalendar( CalList.Items[Found] ).Year  := Y;
        TNeoCalendar( CalList.Items[Found] ).Month := M;
        TNeoCalendar( CalList.Items[Found] ).Day   := D;

        Result := TRUE;
      END
    ELSE nbSetVar( '[LastError]',
      PAnsiChar( 'There is no calendar control attached to an object named '+RectangleName+'.' ) );

  EXCEPT ON E : Exception DO
    nbSetVar( '[LastError]', PAnsiChar( E.Message ) );
  END;
END;

FUNCTION CreateCalendarControl( RectangleName, InitialDate, VariableName : ANSISTRING ) : BOOLEAN;
VAR Cal   : TNeoCalendar;
    P         : PAnsiChar;
    ObjHandle : HWND;
    R         : TRect;
    M, D, Y   : WORD;
BEGIN
  Result := FALSE;
  TRY
    { Check NeoBook version number to make sure author is using NeoBook 4.0.9 or higher... }
    IF CheckVer THEN
      BEGIN

        { We only want one Calendar control per rectangle, so make sure this
          rectangle doesn't already have one... }
        RemoveCalendarControl( RectangleName, FALSE );

        { Get the window handle of the host NeoBook rectangle object... }
        TRY
          P := NIL;
          SetStr( P, RectangleName );
          nbInterface( 7, P );
          ObjHandle := HWND( StrToInt( P ) );
        FINALLY
          FreeStr( P );
        END;

        IF ObjHandle <> 0 THEN
          BEGIN
            { We found the rectangle's window handle, so attach a Calendar control to it... }

            Cal               := TNeoCalendar.Create( NIL );

            Cal.ParentWindow  := ObjHandle;

            Cal.VariableName  := VariableName;
            Cal.RectangleName := RectangleName;

            IF InitialDate > '' THEN
              BEGIN
                DecodeDate( StrToDate( STRING(InitialDate) ), Y, M, D );
                Cal.Year  := Y;
                Cal.Month := M;
                Cal.Day   := D;
              END;

            Cal.Change;

            Cal.Visible       := TRUE;

            { Stretch the Cal to match the bounds of the rectangle... }
            Windows.GetClientRect( ObjHandle, R );
            SetWindowPos( Cal.Handle, 0, 0, 0,
              R.Right-R.Left, R.Bottom-R.Top, SWP_SHOWWINDOW );

            { Add this Calendar control to our list... }
            IF NOT Assigned( CalList ) THEN
              CalList := TList.Create;
            CalList.Add( TObject( Cal ) );

            Result := TRUE;
          END
        ELSE nbSetVar( '[LastError]', PAnsiChar( 'An object named '+RectangleName+' does not exist.' ) );

      END
    ELSE nbSetVar( '[LastError]', 'This function requires NeoBook 4.0.9 or higher.' );

  EXCEPT ON E : Exception DO
    nbSetVar( '[LastError]', PAnsiChar( E.Message ) );
  END;
END;


{********** NeoBook Plug-In Functions that Must be Customized by You **********}

{ nbEditAction - called by NeoBook to edit/define on of the Plug-In's commands.
  Plug-In may display a dialog box with fields for user to fill in. Return
  TRUE if successful, FALSE if not.. }
FUNCTION nbEditAction( IDNum      : INTEGER;
                       VAR Params : ARRAY OF PAnsiChar ) : BOOLEAN;
BEGIN
  Result := FALSE;
  { Examine the Action ANSISTRING to determine which Plug-In command to execute... }
  CASE IDNum OF
    1 : BEGIN
          { Display our edit form... }
          EditForm1 := TEditForm1.CreateParented( GetActiveWindow );
          TRY
            EditForm1.Caption := 'CalendarCreate Properties';

            { Fill out the form with the data from NeoBook's parameters... }
            EditForm1.Edit1.Text           := Params[0];

            IF StrPas( Params[1] ) > '' THEN
              EditForm1.DateTimePicker1.Date := StrToDate( StrPas( Params[1] ) );

            EditForm1.Edit2.Text           := Params[2];

            IF EditForm1.ShowModal = mrOK THEN
              BEGIN
                { The user clicked OK, so transfer the data from the form to our
                  NeoBook parameters... }
                SetStr( Params[0], EditForm1.Edit1.Text );
                SetStr( Params[1], ANSISTRING(DateToStr( EditForm1.DateTimePicker1.Date )) );
                SetStr( Params[2], EditForm1.Edit2.Text );

                Result := TRUE;
              END;
            FINALLY
              EditForm1.Free;
            END;
        END;
    2 : BEGIN
          { Display our edit form. Because I'm lazy we're going to use the same
            form as we did for the first action and just hide the controls we
            don't need... }
          EditForm1 := TEditForm1.CreateParented( GetActiveWindow );
          TRY
            EditForm1.Caption := 'CalendarDelete Properties';

            { Fill out the form with the data from NeoBook's parameters... }
            EditForm1.Edit1.Text := Params[0];

            { Hide the controls we don't need... }
            EditForm1.DateTimePicker1.Hide;
            EditForm1.Edit2.Hide;
            EditForm1.Label3.Hide;
            EditForm1.Label6.Hide;

            IF EditForm1.ShowModal = mrOK THEN
              BEGIN
                { The user clicked OK, so transfer the data from the form to our
                  NeoBook parameters... }
                SetStr( Params[0], EditForm1.Edit1.Text );

                Result := TRUE;
              END;
            FINALLY
              EditForm1.Free;
            END;
        END;
    3 : BEGIN
          { Display our edit form. Because I'm lazy we're going to use the same
            form as we did for the first action and just hide the controls we
            don't need... }
          EditForm1 := TEditForm1.CreateParented( GetActiveWindow );
          TRY
            EditForm1.Caption := 'CalendarSetDate Properties';

            { Fill out the form with the data from NeoBook's parameters... }
            EditForm1.Edit1.Text := Params[0];

            IF StrPas( Params[1] ) > '' THEN
              EditForm1.DateTimePicker1.Date := StrToDate( StrPas( Params[1] ) );

            { Hide the controls we don't need... }
            EditForm1.Edit2.Hide;
            EditForm1.Label6.Hide;

            IF EditForm1.ShowModal = mrOK THEN
              BEGIN
                { The user clicked OK, so transfer the data from the form to our
                  NeoBook parameters... }
                SetStr( Params[0], EditForm1.Edit1.Text );
                SetStr( Params[1], ANSISTRING(DateToStr( EditForm1.DateTimePicker1.Date )) );

                Result := TRUE;
              END;
            FINALLY
              EditForm1.Free;
            END;
        END;
  END;
END;


{ nbExecAction - called by NeoBook to execute one of the Plug-In's commands... }
FUNCTION nbExecAction( IDNum      : INTEGER;
                       VAR Params : ARRAY OF PAnsiChar ) : BOOLEAN;
BEGIN
  { Examine the Action ANSISTRING to determine which Plug-In command to execute... }
  CASE IDNum OF
    1 : Result := CreateCalendarControl( Params[0], Params[1], Params[2] );
    2 : Result := RemoveCalendarControl( Params[0], TRUE );
    3 : Result := SetCalendarControl( Params[0], Params[1] );
    ELSE Result := FALSE;
  END;
END;


{ nbMessage - sent by NeoBook to inform plug-in of important NeoBook activities... }
PROCEDURE nbMessage( MsgCode, Reserved : INTEGER );
VAR I : INTEGER;
BEGIN
  { Not all types of plug-ins will care about these messages,
    so they can be ignored if not needed. This procedure must be present even if
    none of the messages are used.

    Possible MsgCode values are:

      1 = Pub has entered run mode
      2 = Pub is about to exit run mode and return to design mode.
      3 = Pub window has been deactivated
      4 = Pub window has been activated
      5 = Pub window has been moved or sized
      6 = Pub is about to display another page
      7 = Pub window has been minimized
      8 = Pub window has been restored

    Reserved value is not currently used
  }

  CASE MsgCode OF
    1 : ; { Don't care }
    2 : IF Assigned( CalList ) THEN
          BEGIN
            { We're leaving run mode, so delete the CalList... }
            FOR I := 0 TO CalList.Count-1 DO
              TNeoCalendar( CalList.Items[I] ).Free;
            CalList.Free;
            CalList := NIL;
          END;
    3 : ; { Don't care }
    4 : ; { Don't care }
    5 : ; { Don't care }
    6 : ; { Don't care }
    7 : ; { Don't care }
    8 : ; { Don't care }
  END;

END;


{ nbInitPlugIn - called by NeoBook to request information about the Plug-In... }
PROCEDURE nbInitPlugIn( WinHandle : HWND; VAR PlugInTitle, PlugInPublisher, PlugInHint : PAnsiChar );
BEGIN
  { Save handle of Parent NeoBook App or compiled pub Window - may be required by some Windows functions }
  nbWinHandle := WinHandle;

  { Title of this Plug-In (appears as heading in NeoBook's action list) }
  SetStr( PlugInTitle, 'Calendar' );

  { Publisher of this Plug-In }
  SetStr( PlugInPublisher, 'NeoSoft Corp.' );

  { Description of this Plug-In }
  SetStr( PlugInHint, 'Use this plug-in to add a simple calendar control to NeoBook.' );
END;


{ nbRegisterScriptProcessor - called by NeoBook when registering your plug-in
  Provides access to NeoBook's Action Script Player via nbPlayAction... }
PROCEDURE nbRegisterScriptProcessor( PlayActionProc : POINTER );
BEGIN
  {***************************** DO NOT MODIFY ********************************}
  {*} nbPlayAction := @TPlayActionProc( PlayActionProc );
  {****************************************************************************}
END;

{ nbRegisterInterfaceAccess - called by NeoBook when registering your plug-in
  Provides access to some of NeoBook's design-time interface via nbInterface... }
PROCEDURE nbRegisterInterfaceAccess( InterfaceProc : POINTER );
BEGIN
  {***************************** DO NOT MODIFY ********************************}
  {*} nbInterface := @TInterfaceProc( InterfaceProc );
  {****************************************************************************}
END;

{ nbRegisterPlugIn - called by NeoBook when it wants you to register your plug-in's actions... }
PROCEDURE nbRegisterPlugIn( AddActionProc, AddFileProc, VarGetFunc, VarSetFunc : POINTER );
BEGIN

  {***************************** DO NOT MODIFY ********************************}
  {*} nbGetVar    := @TVarGetProc( VarGetFunc );
  {*} nbSetVar    := @TVarSetProc( VarSetFunc );
  {*} nbAddAction := @TAddActionProc( AddActionProc );
  {*} nbAddFile   := @TAddFileProc( AddFileProc );
  {****************************************************************************}

  { Call the AddAction procedure for each of Plug-In command.

    Parameters for the ndAddAction procedure:

    Item 1 = Action ID number - must use a unique identifier for each of your actions.
    Item 2 = Action Name
    Item 3 = Action Description
    Item 4 = Array describing each of the Action's parameters - choose from the following:

      ACTIONPARAM_NONE     = Use if action contains no parameters.
      ACTIONPARAM_ALPHA    = Parameter is a ANSISTRING. May contain alpha, numeric, punctuation, etc.
      ACTIONPARAM_ALPHASP  = Parameter is a ANSISTRING that can be spell checked.
      ACTIONPARAM_NUMERIC  = Parameter is a number.
      ACTIONPARAM_MIXED    = May be either numeric or alpha. May contain math expression.
      ACTIONPARAM_FILENAME = Parameter is a file name.
      ACTIONPARAM_VARIABLE = Parameter is a variable name.
      ACTIONPARAM_DATAFILE = Parameter is data file - if not a variable then should be localized.
      ACTIONPARAM_OBJNAME  = Parameter is an object name
      ACTIONPARAM_MENUID   = Parameter is a mennu item id
      ACTIONPARAM_FILENOEX = Parameter is a file name. For with files that you don't want
                             NeoBook to extract automatically. Since the files won't be
                             extracted, you will need to use ndFileToStream.

    Item 5 = Number of parameters required by this action
  }

  {******************* Enter your Plug-In's actions below *********************}



  nbAddAction( 1, 'CalendarCreate', 'Attach a calendar control to an existing NeoBook Rectangle object.',
    [ACTIONPARAM_ALPHA,ACTIONPARAM_ALPHA,ACTIONPARAM_VARIABLE], 3 );
  nbAddAction( 2, 'CalendarDelete', 'Remove an calendar control previously attached to a Rectangle object.',
    [ACTIONPARAM_ALPHA], 1 );
  nbAddAction( 3, 'CalendarSetDate', 'Change the selected date for an existing calendar control.',
    [ACTIONPARAM_ALPHA,ACTIONPARAM_ALPHA], 2 );


  { Next, if necessary, tell NeoBook what extra files are required for your plug-in.
    These are the files that NeoBook will collect when compiling publications that
    use this plug-in. If your plug-in uses any data files, drivers or special DLLs
    this is where you will tell NeoBook about it. It is NOT necessary to include
    the name of the plug-in itself since NeoBook will automatically assume that
    it is required.

    Parameters for the ndAddFile procedure:

    Item 1 = File name including correct drive and path
    Item 2 = TRUE to add the file, FALSE to remove the file

    For example:

    nbAddFile( 'c:\path\somefile.xyz', TRUE );
  }


END;


PROCEDURE DLLHandler( Reason : INTEGER );
BEGIN
  IF Reason = DLL_PROCESS_DETACH THEN
    BEGIN
      { If this plug-in requires any special processing before being unloaded from
        memory, do that here. Leave blank if no special processing is needed. }

    END;
END;


{***** Export the required functions for NeoBook interface. Do NOT modify *****}
{*}EXPORTS nbEditAction;
{*}EXPORTS nbExecAction;
{*}EXPORTS nbInitPlugIn;
{*}EXPORTS nbRegisterPlugIn;
{*}EXPORTS nbRegisterScriptProcessor;
{*}EXPORTS nbRegisterInterfaceAccess;
{*}EXPORTS nbMessage;
{******************************************************************************}

BEGIN
  DLLProc := @DLLHandler;
END.






