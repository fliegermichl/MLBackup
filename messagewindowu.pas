unit messagewindowu;

{$i mlbackupsettings.inc}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons;

type

  { TMessageWindow }

  TMessageWindow = class(TForm)
    btnAbort: TBitBtn;
    lbMessage: TLabel;
    procedure btnAbortClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    fAborted : boolean;
  public
    function  OnProgress(const Msg : string) : boolean;
    procedure OnProcessDir(const Msg : string);
  end;

var
  MessageWindow: TMessageWindow;

implementation

{$R *.lfm}

{ TMessageWindow }

procedure TMessageWindow.btnAbortClick(Sender: TObject);
begin
  fAborted := True;
  Application.ProcessMessages();
end;

procedure TMessageWindow.FormCreate(Sender: TObject);
begin
  lbMessage.Caption := 'Bitte warten...';
  fAborted := False;
end;

function TMessageWindow.OnProgress(const Msg: string): boolean;
begin
  lbMessage.Caption := Msg;
  Result := not fAborted;
  Application.ProcessMessages();
end;

procedure TMessageWindow.OnProcessDir(const Msg: string);
begin
  btnAbort.Visible := False;
  lbMessage.Caption := Msg;
  Application.ProcessMessages();
end;

end.

