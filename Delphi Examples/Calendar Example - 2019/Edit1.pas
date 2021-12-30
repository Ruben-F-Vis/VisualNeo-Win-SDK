unit Edit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, PlugInUtils, ComCtrls;

type
  TEditForm1 = class(TForm)
    Image1: TImage;
    Label2: TLabel;
    SpeedButton1: TSpeedButton;
    Edit1: TEdit;
    OKBtn: TButton;
    CancelBtn: TButton;
    Label1: TLabel;
    Label3: TLabel;
    Label6: TLabel;
    Edit2: TEdit;
    Image2: TImage;
    DateTimePicker1: TDateTimePicker;
    procedure SpeedButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EditForm1: TEditForm1;

implementation

{$R *.DFM}

procedure TEditForm1.SpeedButton1Click(Sender: TObject);
VAR Data : PANSICHAR;
begin
  { Load the current pub's subroutine names into combobox... }
  IF Assigned( nbInterface ) THEN
    TRY
      Data := NIL;
      SetStr( Data, Edit1.Text );
      IF nbInterface( 8, Data ) THEN
        Edit1.Text := StrPas( Data );
    FINALLY    
      FreeStr( Data );
    END;
end;

end.
