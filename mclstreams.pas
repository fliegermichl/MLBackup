unit mclstreams;
{$i mlbackupsettings.inc}
interface

uses
  sysutils, classes;

type
  TMCLPersistent  = class;
  TMCLWriteReader = class;
  TMCLClassType   = class of TMCLPersistent;

  TForEachOtherFunction = function(myItem, OtherItem : TMCLPersistent) : boolean is nested;
  TForEachProcedure = procedure(Item : TMCLPersistent) is nested;
  TForEachProcedure2 = procedure(Item : TMCLPersistent; Idx : Integer) is nested;
  TForEachEachProcedure = procedure(Item1, Item2 : TMCLPersistent) is nested;
  TTestFunction     = function(Item : TMCLPersistent) : boolean is nested;                 // lokale Testfunktion für FirstThat
  TTestFunction2    = function(Item : TMCLPersistent; Idx : Integer) : boolean is nested;  // lokale Testfunktion für FirstThat
  TLocateFunction   = function(Item : TMCLPersistent) : integer is nested;                 // lokale Testfunktion für Locate
  TLocateFunction2  = function(Item : TMCLPersistent; Idx : integer) : integer is nested;  // lokale Testfunktion für Locate
  TCompareFunction  = function(Item1, Item2 : TMCLPersistent) : integer is Nested;

  TClassListItem = class
   Item : TMCLClassType;
   Num, UpNum : cardinal;
   constructor Create(AClass : TMCLClassType);
  end;

  { TMCLPersistent }

  TMCLPersistent = class ( TList )
  protected
    fVersionen : array of Byte;
  public
    class function GetClassNum : cardinal; virtual;                                     // Liefert die 32 Bit CRC des Klassennamens
    class function GetClassNumUpper : cardinal; virtual;                                // Liefert die 32 Bit CRC des KLASSENNAMENS
    constructor Create;                                                                 // Erzeugt das Objekt und initialisiert das VersionsArray
    constructor CreateFromStream (St: TMCLWriteReader);  virtual;                       // Liest die Klasse aus dem Stream
    destructor destroy; override;                                                       // Gibt das Objekt frei und löscht auch alle Unterobjekte
    procedure WriteStream (St: TMCLWriteReader); virtual;                               // Speichert das Objekt im Strema
    procedure Foreach (Action: TForEachProcedure; Forward : boolean = True); overload;  // Führt "Action" für jeden Eintrag der Liste aus
    procedure Foreach (Action: TForEachProcedure2; Forward : boolean = True); overload; // Führt "Action" für jeden Eintrag der Liste aus
    procedure ForeachOther(OtherList : TMCLPersistent; Action: TForEachOtherFunction);  // Führt "Action" für jeden Eintrag der Liste mit jedem Eintrag der anderen
                                                                                        // Liste aus solange Action True zurückgibt.
    procedure ForeachDeleteIf (test : TTestFunction); overload;                         // Löscht jeden Eintrag aus der Liste, für den Test True liefert
    procedure ForeachDeleteIf (test : TTestFunction2); overload;                        // Löscht jeden Eintrag aus der Liste, für den Test True liefert
    procedure ForeachFreeIf (test : TTestFunction);                                     // Wie ForEachDeleteIf, ruft aber TObject(Item).Free auf
    procedure ForeachFreeIf (test : TTestFunction2);                                    // Wie ForEachDeleteIf, ruft aber TObject(Item).Free auf
    procedure ForEachEach(Action: TForEachEachProcedure);                               // Führt Action für jede Kombination von Items aus
    function  FirstThat (Test: TTestFunction) : TMCLPersistent; overload;               // Liefert den Ersten Eintrag, für den Test True liefert
    function  FirstThat (Test: TTestFunction2) : TMCLPersistent; overload;              // Liefert den Ersten Eintrag, für den Test True liefert
    function  LastThat (Test: TTestFunction) : TMCLPersistent; overload;                // Liefert den letzten Eintrag für den Test True liefert
    function  LastThat (Test: TTestFunction2) : TMCLPersistent; overload;               // Liefert den letzten Eintrag für den Test True liefert
    function  Locate(Test : TLocateFunction) : TMCLPersistent; overload;                // Ähnlich FirstThat für sortierte Listen
    function  LocateIndex(Test : TLocateFunction2; var Index : Integer) : boolean;      // Ähnlich Locate für sortierte Listen, liefert
                                                                                        // aber True, wenn der Eintrg gefunden wird und schreibt
                                                                                        // dessen Index in die Variable Index oder False,
                                                                                        // wenn er nicht gefunden wird und den Index wo der gesuchte
                                                                                        // Eintrag hätte stehen müssen, falls er gefunden worden
                                                                                        // wäre
    function  FindeRekursiv(Test : TTestFunction) : TMCLPersistent; overload;           // Iteriert rekursiv durch alle Unterobjekte bis Test True liefert
    function  FindeRekursiv(Test : TTestFunction2) : TMCLPersistent; overload;          // Iteriert rekursiv durch alle Unterobjekte bis Test True liefert
    function  GetClassVersion(ClassN : TMCLClassType) : byte;                           // Liefert die Versionsnummer der Klasse (für das streamen)
    procedure SetClassVersion(ClassN : TMCLClassType; Version : byte);                  // Setzt die Versionsnummer der Klasse (für das streamen)
    procedure QSort(Compare : TCompareFunction); virtual;                               // Wie Sort, nur mit lokaler Compare Funktion
    procedure MoveItems(OtherList : TMCLPersistent; ClearList : boolean = True);        // VERSCHIEBT alle Einträge in OtherList
    procedure Kill(Item : TMCLPersistent);
    procedure FreeAll;                                                                  // Leert die Liste und gibt alle Objekte frei
    function  Get(Index : integer) : TMCLPersistent;
    procedure Put(Index : integer; Item : TMCLPersistent);
    property  Items[Index : integer] : TMCLPersistent read Get write Put; default;
  end;

  TPosChangedEvent = procedure (Sender : TObject; Position : Byte) of Object;

  TMCLWriteReader = class
  private
    FFreeStreamOnDestroy : boolean;
    Fstream : Tstream;
    fPercent : Byte;
    fOnPercentChanged : TPosChangedEvent;
    {$ifdef StreamDebug}
    fLogFile : TextFile;
    fRunDebug : boolean;
    procedure SaveDebug(Msg : string);
    {$Endif StreamDebug}
  public
    constructor Create(astream : Tstream; FreeStreamOnDestroy : boolean = True {$ifdef StreamDebug} ; StartDebug : Boolean = False; LogFile : string = '' {$Endif});
    destructor  destroy; override;
    procedure Put (amum: TMCLPersistent);
    function  Get : TMCLPersistent;
    // Liest Count Bytes aus dem Stream und speichert diese in Buf
    procedure   Read (out Buf; Count: Longint);
    procedure   Write (var Buf; Count: Longint);
    procedure   WriteString (s: string);
    function    readstring : string;
    procedure   WriteCompressedString(s : string);
    function    ReadCompressedString : string;
    procedure   WriteInteger (ai: Integer);
    function    readInteger : Integer;
    procedure   WriteByte(ab : Byte);
    function    ReadByte : Byte;
    function    ReadDateTime : TDateTime;
    procedure   WriteDateTime(value : TDateTime);
    procedure   WriteDouble (ad: Double);
    function    ReadBoolean : boolean;
    procedure   WriteBoolean (ab: boolean);
    function    ReadDouble : Double;
    property    Stream : Tstream read Fstream;
    property    OnPercentChanged : TPosChangedEvent read fOnPercentChanged write fOnPercentChanged;
  end;

//// Registrierung für Filesystem
procedure RegisterMCLClass (AClass: TMCLClassType);
function  GeTMCLClassType(AClass : TMCLPersistent) : TMCLClassType;
function GetMCLClass (const ClassName: string) : TMCLClassType;
function FindMCLClassNum (const classnum: integer) : TMCLClassType;

{$ifdef GlobalLog}
type
 TGlobalLogType = (ltDebug, ltInfo, ltWarning, ltError);
const
 GlobalLogTypeStrings : array [ltDebug..ltError] of string = (
  'DEBUG', 'INFO', 'WARNUNG', 'FEHLER');

procedure InitGlobalLog;
procedure GlobalLog(Msg : string; LogType : TGlobalLogType = ltInfo);
{$endif GlobalLog}

{$ifdef StreamDebug}
var
    fGetCount,
    fPutCount : integer;
{$Endif}

implementation

uses
  {$ifdef useguessencoding}
  lconvencoding,
  {$endif}
  _crc {$ifdef StreamDebug}, DBugIntF {$endif} {$ifndef fpc}, zlib {$endif};


{$IFDEF DebugMem}

// Wird nur in der Delphiversion benötigt. In Lazarus ist das von Haus aus dabei
const BackTraceDeepness = 20;

type
 TCreateDebugInfo = record
  Adresses  : array[0..BackTraceDeepness] of integer;
  ClassAddr : integer;
  Name      : shortstring;
 end;
 PCreateDebugInfo = ^TCreateDebugInfo;

 TCreateList = class ( TList )
  procedure Add(Item : PCreateDebugInfo);
  function  Search(Address : integer) : PCreateDebugInfo;
  function  GetIndex(Address : integer) : Integer;
 end;


const CreateList : TCreateList = NIL;
      CItem : PCreateDebugInfo = NIL;
{$endif}

constructor TMCLPersistent.Create;
begin
  inherited Create;
  SetLength(fVersionen, 0);
end;


constructor TMCLPersistent.CreateFromStream(St: TMCLWriteReader);
var
  cnt : integer;
begin
  inherited Create;
  cnt := st.ReadInteger;
  if (cnt > 0) then
  begin
    SetLength(fVersionen, cnt);
    st.Read(fVersionen[0], cnt);
  end;
end;

procedure TMCLPersistent.WriteStream(St: TMCLWriteReader);
begin
  st.WriteInteger(Length(fVersionen));
  if Length(fVersionen) > 0 then st.Write(fVersionen[0], Length(fVersionen));
end;

destructor TMCLPersistent.destroy;
var
 j : integer;
 P : TMCLPersistent;
{$ifdef DebugMem}
    CI : PCreateDebugInfo;
    i  : integer;
{$endif}
begin
{$IFDEF DebugMem}
  CI := CreateList.Search(Longint(self));
  i := CreateList.GetIndex(LongInt(self));
  if Assigned(CI) then
  begin
   FreeMem(Ci, SizeOf(TCreateDebugInfo));
   CreateList.Delete(i);
  end;
{$endif}
  for j := 0 to Pred(Count) do
  begin
   P := TMCLPersistent(Items[Pred(Count)]);
   Delete(Pred(Count));
   P.Free;
  end;
  fVersionen := NIL;
  inherited destroy;
end;

class function TMCLPersistent.GetClassNum: cardinal;
var
  s : shortstring;
begin
  s := self.classname;
  result := Calc_CRC32 (@s[1], length (s));
end;

class function TMCLPersistent.GetClassNumUpper: cardinal;
var
  s : shortstring;
begin
  s := UpperCase(self.classname);
  result := Calc_CRC32 (@s[1], length (s));
end;

procedure TMCLPersistent.Foreach (Action: TForEachProcedure; Forward : boolean);
var
  item : TMCLPersistent;
  i : Integer;
begin
  if forward then i := 0 else i := Pred(Count);
  while ((forward) and (i < count)) or (not (forward) and (i >= 0)) do
  begin
    Item := TMCLPersistent(Items[i]);
    if Assigned(Item) then Action(Item);
    if forward then inc (i) else dec(i);
  end;
end;

procedure TMCLPersistent.Foreach(Action: TForEachProcedure2; Forward: boolean);
var
  item : TMCLPersistent;
  i : Integer;
begin
  if forward then i := 0 else i := Pred(Count);
  while ((forward) and (i < count)) or (not (forward) and (i >= 0)) do
  begin
    Item := TMCLPersistent(Items[i]);
    if Assigned(Item) then Action(Item, i);
    if forward then inc (i) else dec(i);
  end;
end;


function TMCLPersistent.FirstThat (Test: TTestFunction) : TMCLPersistent;
var
  item : TMCLPersistent;
  i : Integer;
begin
  result := nil;
  i := 0;
  while i < count do
  begin
    item := TMCLPersistent(items[i]);
    if assigned (item) then
    if Test(Item) then
    begin
     Result := Item;
     exit;
    end;
    inc (i)
  end;
end;

function TMCLPersistent.FirstThat (Test: TTestFunction2) : TMCLPersistent;
var
  item : TMCLPersistent;
  i : Integer;
begin
  result := nil;
  i := 0;
  while i < count do
  begin
    item := TMCLPersistent(items[i]);
    if assigned (item) then
    if Test(Item, i) then
    begin
     Result := Item;
     exit;
    end;
    inc (i)
  end;
end;

function TMCLPersistent.LastThat(Test: TTestFunction) : TMCLPersistent;
var
  item : TMCLPersistent;
  i : Integer;
begin
  result := nil;
  i := pred (count);
  while i >= 0 do
  begin
    item := TMCLPersistent(items[i]);
    dec (i);
    if assigned (item) then
    if Test(Item) then
    begin
     Result := Item;
     exit;
    end;
  end;
end;

function TMCLPersistent.LastThat(Test: TTestFunction2) : TMCLPersistent;
var
  item : TMCLPersistent;
  i : Integer;
begin
  result := nil;
  i := pred (count);
  while i >= 0 do
  begin
    item := TMCLPersistent(items[i]);
    dec (i);
    if assigned (item) then
    if Test(Item, i) then
    begin
     Result := Item;
     exit;
    end;
  end;
end;


///////////////////////////////////////////////////////////////////////
///////////// REGISTRIER FUNKTIONEN
///////////////////////////////////////////////////////////////////////
var
  ClassList : TMCLPersistent = nil;
  NumClassList : TMCLPersistent = nil;
  UpNumClassList : TMCLPersistent = nil;

//----------------------------------------------------------------------//
function GetMCLClass (const ClassName: string) : TMCLClassType;
var
  I : Integer;
begin
  for I := 0 to ClassList.Count - 1 do
  begin
    Result := TMCLClassType(ClassList[I]);
    if Result.ClassNameIs (ClassName) then
      Exit
  end;
  Result := nil;
end;


//----------------------------------------------------------------------//
function GetMCLClassNum (const ClassNum: integer) : TMCLClassType;
 function Test(Item : TMCLPersistent) : integer;
 var it : TClassListItem absolute Item;
 begin
  if cardinal(classnum) < it.num then
   Result := -1
  else if cardinal(classnum) > it.num then
   Result := 1
  else
   Result := 0;
   //Result := cardinal(Classnum) - Item.Num;Result := cardinal(Classnum) - Item.Num;
 end;
 function UpTest(Item : TMCLPersistent) : integer;
 var it : TClassListItem absolute Item;
 begin
  if cardinal(classnum) < it.upnum then
    Result := -1
  else if cardinal(classnum) > it.upnum then
    Result := 1
  else
    Result := 0;
  //Result := cardinal(Classnum) - Item.UpNum;
 end;
var cli : TClassListItem;
begin
 cli := TClassListItem(Pointer(NumClassList.Locate(@test)));
 if not Assigned(cli) then cli := TClassListItem(Pointer(UpNumClassList.Locate(@UpTest)));
 if Assigned(cli) then Result := cli.Item else Result := nil;
end;

//----------------------------------------------------------------------//
(*
function GetMCLClassNumUpper (const ClassNum: cardinal) : TMCLClassType;
var
  I : Integer;
begin
  for I := 0 to ClassList.Count - 1 do
  begin
    Result := TMCLClassType(ClassList[I]);
    if Result.GetClassNumUpper = ClassNum then
      Exit
  end;
  Result := nil;
end;
*)
function GetMCLClassNumUpper (const ClassNum: cardinal) : TMCLClassType;
  function test(cli : TMCLPersistent) : integer;
  var it : TClassListItem absolute cli;
  begin
    if ClassNum < it.upNum then
      Result := -1
    else if classnum > it.UpNum then
      Result := 1
    else
      Result := 0;
  end;
var cli : TClassListItem;
begin
  cli := TClassListItem(Pointer(UpNumClassList.Locate(@test)));
  if cli <> nil then Result := cli.Item else Result := nil;
end;

//----------------------------------------------------------------------//
function FindMCLClass (const ClassName: string) : TMCLClassType;
begin
  Result := GetMCLClass (ClassName);
end;

function FindMCLClassNum (const classnum: integer) : TMCLClassType;
begin
  Result := GetMCLClassNum (Classnum);
end;

function FindMCLClassNumUpper(const classnum: integer) : TMCLClassType;
begin
 Result := GetMCLClassNumUpper(ClassNum);
end;

//----------------------------------------------------------------------//
procedure RegisterMCLClass (AClass: TMCLClassType);
var
  ClassName : string;
  cli : TClassListItem;

 function ByNum(Item1, Item2 : TMCLPersistent) : integer;
 var it1 : TClassListItem absolute Item1;
     it2 : TClassListItem absolute Item2;
 begin
  if it1.num < it2.num then
    Result := -1
  else if it1.num > it2.num then
    Result := 1
  else
    Result := 0;
 end;

 function ByUpNum(Item1, Item2 : TMCLPersistent) : integer;
 var it1 : TClassListItem absolute Item1;
     it2 : TClassListItem absolute Item2;
 begin
  if it1.upnum < it2.upnum then
    Result := -1
  else if it1.upnum > it2.upnum then
    Result := 1
  else
    Result := 0;
 end;

begin
  while ClassList.IndexOf (AClass) = -1 do
  begin
    ClassName := AClass.ClassName;
    if GetMCLClass (ClassName) <> nil then
      abort;
    ClassList.Add (AClass);
    cli := TClassListItem.Create(AClass);
    NumClassList.Add(cli);
    UpNumClassList.Add(cli);
    if AClass = TMCLPersistent then
      Break;
    AClass := TMCLClassType (AClass.ClassParent);
  end;
  if NumClassList.Count > 1 then NumClassList.QSort(@ByNum);
  if UpNumClassList.Count > 1 then UpNumClassList.QSort(@ByUpNum);
end;


function  GeTMCLClassType(AClass : TMCLPersistent) : TMCLClassType;
begin
 Result := TMCLClassType(ClassList[Classlist.IndexOf(GetMCLClass(AClass.Classname))]);
end;

///////////////////////////////////////////////////////////////////////
///////////// TMCLWriteReader
///////////////////////////////////////////////////////////////////////
constructor TMCLWriteReader.Create (astream: Tstream; FreeStreamOnDestroy : boolean {$ifdef StreamDebug}; StartDebug : Boolean; LogFile : string {$Endif});
begin
  fFreeStreamOnDestroy := FreeStreamOnDestroy;
  fstream := astream;
  fPercent := 0;
  fOnPercentChanged := NIL;
  {$ifdef StreamDebug}
  fRunDebug := StartDebug;
  if fRunDebug then
  begin
   AssignFile(fLogFile, LogFile);
   ReWrite(fLogFile);
  end;
  {$Endif}
end;

//----------------------------------------------------------------------//
destructor TMCLWriteReader.destroy;
begin
 {$IFDEF StreamDebug}
  if fRunDebug then
  begin
   CloseFile(fLogFile);
  end;
 {$Endif}
  if fFreeStreamOnDestroy then fstream.free;
  inherited;
end;

//----------------------------------------------------------------------//
procedure TMCLWriteReader.Read (out Buf; Count: Longint);
begin
  if fstream <> nil then
    fstream.readBuffer (buf, count);
end;


//----------------------------------------------------------------------//
procedure TMCLWriteReader.write (var Buf; Count: Longint);
begin
  if fstream <> nil then
    fstream.writeBuffer (buf, count);
end;


//----------------------------------------------------------------------//
procedure TMCLWriteReader.WriteString (s: string);
var
  i : integer;
begin
  i := length (s);
  write (i, sizeof (i));
  if (i > 0) then write (s[1], i); // prevent Range Check error
end;

//----------------------------------------------------------------------//
function TMCLWriteReader.readstring : string;
var
  i : integer;
  s : string;
begin
  Result := ''; read (i, sizeof (i));
  if (i > 0) then
  begin
    SetString (Result, PChar (nil), i);
    Read (Result[1], I);
    {$ifdef useguessencoding}
      if (result <> '') then
      begin
        s := guessencoding(result);
        if (s <> 'utf8') then
        begin
         if s = 'cp1252' then
           Result := CP1252ToUTF8(result) // latin 1
         else
           raise Exception.Create('unknown encoding');
        end;
      end;
    {$endif}
  end;
end;

//----------------------------------------------------------------------//
procedure TMCLWriteReader.WriteInteger (ai: Integer);
begin
  write (ai, sizeof (ai));
end;

//----------------------------------------------------------------------//
function TMCLWriteReader.readInteger : Integer;
begin
  Result := 0; read (result, sizeof (result));
end;

//----------------------------------------------------------------------//
procedure TMCLWriteReader.WriteDouble (ad: Double);
begin
  write (ad, sizeof (ad));
end;

//----------------------------------------------------------------------//
function TMCLWriteReader.readDouble : Double;
begin
 Result := 0.0; read (result, sizeof (result));
end;

//----------------------------------------------------------------------//
function TMCLWriteReader.ReadDateTime : TDateTime;
begin
 Result := 0.0; read (result, sizeof (result));
end;

//----------------------------------------------------------------------//
procedure TMCLWriteReader.WriteDateTime(value : TDateTime);
begin
 write(value, sizeof(value));
end;

//----------------------------------------------------------------------//
function TMCLWriteReader.ReadBoolean : boolean;
begin
  Result := False; read (result, sizeof (result));
end;

//----------------------------------------------------------------------//
procedure TMCLWriteReader.WriteBoolean (ab: boolean);
begin
  write (ab, sizeof (ab));
end;

//----------------------------------------------------------------------//
procedure TMCLWriteReader.Put (amum: TMCLPersistent);
{$IFDEF StreamDebug}
var vorher : integer;
{$Endif}
begin
  if amum = nil then
    raise Exception.Create('Versuch ein NIL Objekt im Stream zu speichern');
  writeinteger (amum.GetClassNumUpper); //Calc_CRC(amum.Classname[1], Length(amum.Classname), true);

  {$Ifdef StreamDebug}
   if fRunDebug then
   begin
    Inc(fPutCount);
    Vorher := Stream.Position;
    SaveDebug('PUT : ' + IntToStr(fPutCount) + ' V ' + IntToStr(Vorher));
   end;
  {$Endif}
  amum.WriteStream (self);
  {$Ifdef StreamDebug}
  {$Endif}
end;

//----------------------------------------------------------------------//
function TMCLWriteReader.Get : TMCLPersistent;
var
  i : cardinal;
  tc : TMCLClassType;
{$Ifdef StreamDebug}
 Vorher : integer;
{$endif}
  NewP : Byte;
  fPos : Int64;
begin
  fPos := fStream.Position;
  if Assigned(fOnPercentChanged) then
  begin
   NewP := Round(fPos * 100 / fStream.Size);
   if NewP <> fPercent then
   begin
    fPercent := NewP;
    fOnPercentChanged(self, fPercent);
   end;
  end;

  result := nil;
  i := readinteger;
  if i <> 0 then
  begin
    {$ifdef FPC}
     tc := findMCLClassNumUpper(i);
    {$else}
     tc := findMCLClassnum (i);
    {$endif}
    if not Assigned(tc) then
     {$ifdef fpc}
      tc := findMCLClassnum (i);
     {$else}
      tc := findMCLClassNumUpper(i);
     {$endif}
    try
      {$Ifdef StreamDebug}
       if fRunDebug then
       begin
        Inc(fGetCount);
        Vorher := Stream.Position;
        SaveDebug('GET ' + IntToStr(fGetCount) + ' V ' + IntToStr(Vorher) + ' N ');
       end;
      {$Endif}
      if tc <> nil then
        result := tc.CreateFromStream (self) else
      raise Exception.Create('Versuch eine nicht beim Streamingsystem registrierte Klasse zu laden!');
    except
      on e : exception do
        //{$ifndef console} showmessage (e.Message) {$else} writeln(e.Message) {$endif};
    end;
  end;
end;

// Übergibt jede Kombination von Items der Liste an Action
procedure TMCLPersistent.ForEachEach(Action: TForEachEachProcedure);
var
  item  : TMCLPersistent;
  item2 : TMCLPersistent;
  i, j : Integer;
begin
  i := 0;
  while i < count do
  begin
   j := i + 1;
   while j < count do
   begin
    item  := TMCLPersistent(items[i]);
    item2 := TMCLPersistent(items[j]);
    if (assigned (item)) and
       (assigned (item2)) then
        action(item, item2);
    inc (j)
   end;
   inc(i);
  end;
end;


{$ifndef fpc}
function TMCLWriteReader.ReadCompressedString: string;
var BufSize : integer;
    s1, s2 : string;
    Adler : longint;
begin
  BufSize := ReadInteger;
  if BufSize = 0 then
  begin
   Result := '';
   exit;
  end else
  if BufSize = 1 then
   Result := ReadString
  else
  begin
    s1 := ReadString;
    SetLength(s2, BufSize * 2);
    if InflateData(PChar(s1)^, Length(s1), False, PChar(S2)^, BufSize * 2, False, Adler) then
    begin
     SetLength(s2, BufSize);
     Result := s2;
    end;
  end;
end;

procedure TMCLWriteReader.WriteCompressedString(s: string);
var s2 : string;
    BufSize : integer;
    Adler : longint;
    bw : integer;
begin
 WriteInteger(1);
 WriteString(s);
 exit;
 BufSize := Length(s);
 if BufSize = 0 then
 begin
  WriteInteger(0);
  exit;
 end;
 SetLength(s2, BufSize * 2);
 if DeflateData(PChar(s)^, Length(s), False, PChar(s2)^, BufSize * 2, False, 1, bw, Adler) then
 begin
  WriteInteger(Length(s));
  SetLength(s2, bw);
  WriteString(s2);
 end else
 begin
  WriteInteger(1); // Kennung für unkomprimierten String
  WriteString(s);
 end;
end;
{$else fpc}
function TMCLWriteReader.ReadCompressedString : string;
begin
 case ReadInteger of
  0 : Result := '';
  1 : Result := ReadString;
 else
  raise Exception.Create('Can''t read compressed strings!');
 end;
end;

procedure TMCLWriteReader.WriteCompressedString(s : string);
begin
 WriteInteger(1);
 WriteString(s);
end;
{$endif fpc}



function TMCLPersistent.GetClassVersion(ClassN: TMCLClassType): byte;
var i : integer;
begin
 i := 0;
 while (not (classN = TMCLPersistent)) do
 begin
  inc(i);
  classN := TMCLClassType(classN.ClassParent);
 end;
 if Pred(Length(fVersionen)) < i then Result := 0 else
  Result := fVersionen[i];
end;

procedure TMCLPersistent.SetClassVersion(ClassN: TMCLClassType;
  Version: byte);
var i : integer;
begin
 i := 0;
 while (not (classN = TMCLPersistent)) do
 begin
  classN := TMCLClassType(classN.ClassParent);
  inc(i);
 end;
 if Length(fVersionen) < i+1 then SetLength(fVersionen, i+1);
 fVersionen[i] := Version;
end;

procedure TMCLPersistent.ForeachDeleteIf(test : TTestFunction2);
var
  item : TMCLPersistent;
  i : Integer;
begin
  i := 0;
  while i < count do
  begin
    item := TMCLPersistent(items[i]);
    if assigned (item) then
    if (Test(item, i)) then
     Delete(i)
    else
     inc(i);
  end;
end;

procedure TMCLPersistent.ForeachDeleteIf(test : TTestFunction);
var
  item : TMCLPersistent;
  i : Integer;
begin
  i := 0;
  while i < count do
  begin
    item := TMCLPersistent(items[i]);
    if assigned (item) then
    if (Test(item)) then
     Delete(i)
    else
     inc(i);
  end;
end;

procedure TMCLPersistent.ForeachFreeIf(test: TTestFunction);
var
  item : TMCLPersistent;
  i : Integer;
begin
  i := 0;
  while i < count do
  begin
    item := TMCLPersistent(items[i]);
    if assigned (item) then
    if (Test(item)) then
    begin
     Delete(i);
     TObject(item).Free;
    end else
     inc (i)
  end;
end;

procedure TMCLPersistent.ForeachFreeIf(test: TTestFunction2);
var
  item : TMCLPersistent;
  i : Integer;
begin
  i := 0;
  while i < count do
  begin
    item := TMCLPersistent(items[i]);
    if assigned (item) then
    if (Test(item, i)) then
    begin
     Delete(i);
     TObject(item).Free;
    end else
     inc (i)
  end;
end;

function TMCLPersistent.FindeRekursiv(Test: TTestFunction): TMCLPersistent;
var i : integer;
begin
 Result := NIL;
 for i := 0 to Pred(Count) do
 begin
  if Test(TMCLPersistent(Items[i])) then
  begin
   Result := TMCLPersistent(Items[i]);
   Break;
  end;
  Result := TMCLPersistent(Items[i]).FindeRekursiv(Test);
  if Assigned(Result) then Break;
 end;
end;

function TMCLPersistent.FindeRekursiv(Test: TTestFunction2): TMCLPersistent;
var i : integer;
begin
 Result := NIL;
 for i := 0 to Pred(Count) do
 begin
  if Test(TMCLPersistent(Items[i]), i) then
  begin
   Result := TMCLPersistent(Items[i]);
   Break;
  end;
  Result := TMCLPersistent(Items[i]).FindeRekursiv(Test);
  if Assigned(Result) then Break;
 end;
end;

function TMCLWriteReader.ReadByte: Byte;
begin
 Result := 0;
 Read(Result, SizeOf(Byte));
end;

procedure TMCLWriteReader.WriteByte(ab: Byte);
begin
 Write(ab, SizeOf(Byte));
end;

{$ifdef GlobalLog}
procedure GlobalLog(Msg : string; LogType : TGlobalLogType = ltInfo);
var lf : TextFile;
    s : string;
begin
 s := Format('%s - %s - %s', [DateTimeToStr(Now), GlobalLogTypeStrings[LogType], Msg]);
 if Assigned(DebugLogger) then DebugLn(s) else
 begin
   AssignFile(lf, ChangeFileExt(ParamStr(0), '.log'));
   try
    Append(lf);
    WriteLn(lf, s);
    CloseFile(lf);
   except
    ON E:Exception do
    {$ifdef console}
     writeLn(Format('Fehler beim speichern des Startlogs %s, Message %s, wanna write %s', [e.classname, e.message, s]));
    {$else}
     MessageDlg('Fehler beim speichern des Startlogs', mtError, [mbOk], 0);
    {$endif}
   end;
 end;
end;


procedure InitGlobalLog;
var lf : TextFile;
    s : string;
begin
 s := ChangeFileExt(ParamStr(0), '.log');
 if FileExists(s) then DeleteFile(PChar(s));
 AssignFile(lf, s);
 ReWrite(lf);
 CloseFile(lf);
 GlobalLog('Logfile angelegt');
end;

{$endif GlobalLog}

{$ifdef StreamDebug}
procedure TMCLWriteReader.SaveDebug(Msg: string);
begin
 WriteLn(FLogFile, Msg);
end;
{$Endif}

// Locate geht davon aus, das die Einträge nach dem Kriterium sortiert sind, für die Test Ergebnisse liefert!
// Test muß auf eine lokale Funktion zeigen, welche einen Eintrag aus List geliefert bekommt und
// Werte kleiner 0 zurückliefern, wenn der gesuchte Eintrag weiter vorn sein muß,
// genau 0 wenn der gesuchte Eintrag gefunden wurde oder Werte > 0 wenn der gesuchte Eintrag weiter hinten
// kommt
function TMCLPersistent.Locate(Test: TLocateFunction): TMCLPersistent;
var
  item : TMCLPersistent;
  l, c, h : Integer;
  TestResult : integer;
begin
  result := nil;
  if count = 0 then exit;
  l := 0;
  h := Pred(Count);
  c := h shr 1;

  while (l < h) do
  begin
    item := TMCLPersistent(items[c]);
    if assigned (item) then
    TestResult := Test(Item);
    if TestResult = 0 then
    begin
      result := item;
      break
    end else
    if (TestResult) < 0 then
     h := c-1
    else
     l := c+1;
    c := l + ((h-l) shr 1);
  end;
  if not Assigned(Result) and (l=h) then
  begin
   item := TMCLPersistent(items[l]);
   (*
   asm
    mov  eax,item
    push callerBP
    call test
    pop  ecx
    mov  TestResult,eax
   end;
   *)
   testResult := Test(Item);
   if TestResult = 0 then Result := item;
  end;
end;

procedure TMCLPersistent.MoveItems(OtherList : TMCLPersistent; ClearList : boolean);
 procedure all(Item : TMCLPersistent);
 begin
  OtherList.Add(Item);
 end;
begin
 if not Assigned(Otherlist) then exit;
 if ClearList then Otherlist.Clear;
 ForEach(@all);
end;

procedure TMCLPersistent.Kill(Item: TMCLPersistent);
begin
  if Assigned(Item) then
  begin
    Extract(Item);
    Item.Free;
  end;
end;

procedure TMCLPersistent.FreeAll;
 procedure DoKill(Item : TMCLPersistent; i : integer);
 begin
  Item.Free;
 end;
begin
  ForEach(@DoKill);
  Clear;
end;

function TMCLPersistent.Get(Index: integer): TMCLPersistent;
begin
  Result := TMCLPersistent(inherited Get(Index));
end;

procedure TMCLPersistent.Put(Index: integer; Item: TMCLPersistent);
begin
  inherited Put(Index, Item);
end;

// Sortiert die Einträge in fList nach dem Schlüssel, den die lokale! Funktion Compare zurückliefert
// Compare funktioniert nach dem gleichen Prinzip wie TListSortCompare -mcl
procedure TMCLPersistent.QSort(Compare: TCompareFunction);

  procedure QuickSort(SortList: PPointerList; L, R: Integer);
  var
    I, J: Integer;
    P, T: TMCLPersistent;
  begin
    repeat
      I := L;
      J := R;
      P := TMCLPersistent(SortList^[(L + R) shr 1]);
      repeat
       while (compare(TMCLPersistent(SortList^[i]), P) < 0) do Inc(i);
       while (compare(TMCLPersistent(Sortlist^[j]), P) > 0) do dec(j);
        if I <= J then
        begin
          T := TMCLPersistent(SortList^[I]);
          SortList^[I] := SortList^[J];
          SortList^[J] := T;
          Inc(I);
          Dec(J);
        end;
      until I > J;
      if L < J then
        QuickSort(SortList, L, J);
      L := I;
    until I >= R;
  end;

begin
 if (List <> NIL) and (Count > 1) then
  QuickSort(List, 0, Pred(Count));
end;

procedure TMCLPersistent.ForeachOther(OtherList: TMCLPersistent;
  Action: TForEachOtherFunction);
var
  myitem, OtherItem : TMCLPersistent;
  i, j : Integer;
begin
  i := 0;
  while i < count do
  begin
    myitem := TMCLPersistent(items[i]);
    if assigned (myitem) then
    begin
     j := 0;
     while (j < OtherList.Count) do
     begin
      OtherItem := TMCLPersistent(OtherList[j]);
      if Assigned(OtherItem) then
      begin
       if not (Action(MyItem, OtherItem)) then
         exit;
      end;
      inc(j);
     end; // while j < OtherList.Count
    end;
    inc (i);
  end; // while i < count
end;

function TMCLPersistent.LocateIndex(Test: TLocateFunction2;
  var Index: Integer): boolean;
var
  item : TMCLPersistent;
  l, c, h : Integer;
  TestResult : integer;
begin
  l := 0;
  h := Pred(Count);
  c := h shr 1;
  Result := False;
  Index := 0;

  while (l < h) do
  begin
    item := TMCLPersistent(items[c]);
    if assigned (item) then
    TestResult := Test(Item, c);
    if TestResult = 0 then
    begin
      result := True;
      Index := c;
      break
    end else
    if (TestResult) < 0 then
     h := c-1
    else
     l := c+1;
    Index := c;
    c := l + ((h-l) shr 1);
  end;
  if not (Result) and (l=h) then
  begin
   item := TMCLPersistent(items[l]);
   TestResult := Test(item, l);
   if TestResult = 0 then
   begin
    Result := True;
    Index := l;
   end else
   if Testresult > 0 then
   begin
    Index := l+1
   end else
    Index := l;
  end;
end;

{ TClassListItem }

constructor TClassListItem.Create(AClass: TMCLClassType);
var s : string;
begin
 s := aClass.Classname;
 Item  := AClass;
 Num   := AClass.GetClassNum;
 UpNum := AClass.GetClassNumUpper;
end;


initialization

{$Ifdef GlobalLog}

 InitGlobalLog;
 globallog('mumstreams initialization');
{$Endif GlobalLog}

{$IFDEF DebugMem}
  CreateList := TCreateList.Create;
{$endif}

  ClassList      := TMCLPersistent.Create;
  NumClassList   := TMCLPersistent.Create;
  UpNumClassList := TMCLPersistent.Create;

finalization
 {$ifdef globallog}
  globallog('mumstreams finalization');
 {$endif}
  NumClassList.Clear;
  NumClassList.Free;
  UpNumClassList.Free;
  ClassList.Clear;
  ClassList.Free;
{$IFDEF DebugMem}
  if CreateList.Count > 0 then SaveLeacks;
  CreateList.Free;
{$endif}
 {$ifdef globallog}
  globallog('mumstreams finalization done');
 {$endif}
end.


