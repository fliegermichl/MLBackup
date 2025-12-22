unit progressformu;

{$i mlbackupsettings.inc}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  Buttons;

type

  { TProgressForm }

  TProgressForm = class(TForm)
    btnAbort: TBitBtn;
    btnError: TButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    gbError: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lbFile: TLabel;
    lbAll: TLabel;
    lbSrc: TLabel;
    lbDst: TLabel;
    lbWhatsGoingOn: TLabel;
    ErrorMemo: TMemo;
    pbFile: TProgressBar;
    pbAll: TProgressBar;
    procedure btnAbortClick(Sender: TObject);
    procedure btnErrorClick(Sender: TObject);
  private
    fEntireStartTick,
    fStartTick : Int64;
    fEntireSize : Int64;
    fEntireDone : Int64;
    fSrc, fDst : string;
    fAbortClicked : boolean;
    fCallCount : integer;
  public
    // Wird zum Beginn einmal aufgerufen
    procedure BeginJob(const Msg : string; aEntireSize : Int64);
    // Wird bei jeder zu kopierenden Datei aufgerufen
    procedure NewFile(const src, dst : string; Size : Int64);
    // Wird während dem kopieren aufgerufen
    function  Progress(BytesDone, BytesLeft : Int64) : boolean;
    // Wird am Ende aufgerufen
    procedure FileDone;
    procedure BeginPrepare(const Msg : string);
    procedure ProcessDir(const Msg : string);
    procedure Error(src, dst, ErrorMessage : string);
  end;

var
  ProgressForm: TProgressForm;

implementation
uses mlbackuptypes;

{$R *.lfm}

{ TProgressForm }

procedure TProgressForm.btnAbortClick(Sender: TObject);
begin
  fAbortClicked := True;
  Application.ProcessMessages();
end;

procedure TProgressForm.btnErrorClick(Sender: TObject);
begin
  Height := gbError.Top + gbError.Height + 5;
  btnAbort.Kind := bkClose;
end;

procedure TProgressForm.BeginJob(const Msg: string; aEntireSize : Int64);
begin
  lbWhatsGoingOn.Caption := Msg;
  fEntireSize := aEntireSize;
  fEntireDone := 0;
  fEntireStartTick := GetTickCount64();
  pbFile.Position := 0;
  pbAll.Position  := 0;
  lbSrc.Caption := '';
  lbDst.Caption := '';
  lbFile.Caption := '';
  lbAll.Caption := '';
  Application.ProcessMessages();
end;

procedure TProgressForm.NewFile(const src, dst: string; Size: Int64);
begin
  fsrc := src;
  fdst := dst;
  fStartTick := GetTickCount64();
  lbSrc.Caption := src;
  lbDst.Caption := dst;
  fCallCount := 0;
  Application.ProcessMessages();
end;

function TProgressForm.Progress(BytesDone, BytesLeft: Int64): boolean;
var PctF, PctG : integer;
    ges : Int64;
    ThisTick, TicksDone, EntireTicksDone : Int64;
    TicksLeft, EntireTicksLeft : Int64;
    TickFStr, TickEStr,
    TickDFStr, TickDEStr : string;

    function TicksToStr(Ticks : Int64) : string;
    var s, m, h : int64;
    begin
      s := Ticks div 1000;
      m := s div 60;
      h := m div 60;
      if (h > 0) then
      begin
        m -= h * 60;
        s -= h * 60 * 60;
      end;

      if (m > 0) then
      begin
        s -= m * 60;
      end;
      Result := Format('%.2dh %.2dm %.2ds', [h, m, s]);
    end;

begin
  if (fCallCount = 0) or (BytesLeft = 0) then
  begin
    if (BytesDone = 0) and (BytesLeft = 0) then
    begin
      pbFile.Position := 100;
      exit;
    end;
    Ges := fEntireDone + BytesDone;
    if BytesLeft = 0 then
      fEntireDone += BytesDone;
    PctF := 100 * BytesDone div (BytesDone + BytesLeft);
    PctG := 100 * Ges div (fEntireSize);
    if BytesLeft > 0 then
      pbFile.Position := PctF
    else
      pbFile.Position := 100;
    pbAll.Position := PctG;

    // Zeiten berechnen
    ThisTick := GetTickCount64();
    TicksDone := ThisTick - fStartTick;
    EntireTicksDone := ThisTick - fEntireStartTick;

    (* Zeitberechnung

    Die verbleibende Zeit berechnet sich aus dem Verhältnis der bereits kopierten
    Daten zu den verbleibenden Daten.

    Dabei gilt:

    BytesDone     BytesLeft               TicksDone     TicksLeft                                TicksDone * BytesLeft
    ---------  =  ---------  -> Reziprok  ---------  =  ---------  -> Umsetellen nach TicksLeft  ---------------------  =  TicksLeft
    TicksDone     TicksLeft               BytesDone     BytesLeft                                      BytesDone

    *)

    TicksLeft := TicksDone * BytesLeft div BytesDone;                 // aktuelle Datei
    EntireTicksLeft := EntireTicksDone * (fEntireSize - Ges) div Ges; // gesamt

    TickDFStr := TicksToStr(TicksDone);
    TickDEStr := TicksToStr(EntireTicksDone);
    TickFStr  := TicksToStr(TicksLeft);
    TickEStr  := TicksToStr(EntireTicksLeft);

    lbFile.Caption := Format('%s kopiert (%s), %s verbleibend (%s)', [FormatSize(BytesDone), TickDFStr, FormatSize(BytesLeft), TickFStr]);
    lbAll.Caption := Format('%s kopiert (%s), %s verbleibend (%s)', [FormatSize(Ges), TickDEStr, FormatSize(fEntireSize-Ges), TickEStr]);
    Application.ProcessMessages();
  end;
  Inc(fCallCount);
  if fCallCount = 1000 then fCallCount := 0;
  Result := not fAbortClicked;
end;

procedure TProgressForm.FileDone;
begin
  Application.ProcessMessages();
end;

procedure TProgressForm.BeginPrepare(const Msg: string);
begin
  lbWhatsGoingOn.Caption := Msg;
  lbFile.Caption := '';
  lbAll.Caption := '';
  Application.ProcessMessages();
end;

procedure TProgressForm.ProcessDir(const Msg: string);
begin
 lbSrc.Caption := Msg;
 lbDst.Caption := '';
 Application.ProcessMessages();
end;

procedure TProgressForm.Error(src, dst, ErrorMessage: string);
begin
  ErrorMemo.Lines.Add(Format('Quelle: %s, Ziel: %s' + LineEnding + 'Fehler: %s', [src, dst, ErrorMessage]));
  btnError.Visible := true;
end;

end.

