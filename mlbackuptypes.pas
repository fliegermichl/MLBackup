unit mlbackuptypes;
{$i mlbackupsettings.inc}

interface

uses
  Classes, SysUtils, types, mclstreams, laz.virtualtrees;

type
  TOnBeginPrepare = procedure(const Msg : string) of object;
  TOnProcessDir   = procedure(const Msg : String) of Object;
  TOnBeginJob     = procedure(const Msg : string; aEntireSize : Int64) of object;
  TOnNewFile      = procedure(const src, dst : string; size : Int64) of object;
  TOnProgress     = function(BytesDone, BytesLeft : Int64) : boolean of object;
  TOnFileDone     = procedure() of object;
  TOnError        = procedure(src, dst, ErrorMessage : string) of object;

  TBackupItem = class;
  TBackupFlag = (bfModified,               // Eintrag wurde modifiziert
                 bfSelected,               // Eintrag ist markiert
                 bfRes1,
                 bfRes2);
  TBackupFlags = set of TBackupFlag;

  { TBackupItem }

  TBackupItem = class ( TMCLPersistent )
  private
    {$ifdef storeclassnames}
     fMyClassName : string;
    {$endif}
    fOwner : TBackupItem;
    fFlags : TBackupFlags;
    procedure SetSelected(AValue: boolean);
    function  GetSelected : boolean;
    function  GetModified : boolean;
    procedure SetModified(const AValue : boolean);
    function  GetOwner : TBackupItem;
    function  GetParentSelected : boolean;
  protected
    procedure SetOwner(aOwner : TBackupItem); virtual;
  public
    constructor Create(aOwner : TBackupItem); reintroduce; virtual;
    constructor CreateFromStream(st : TMCLWriteReader); override;
    procedure   Loaded; virtual;
    procedure   WriteStream(st : TMCLWriteReader); override;
    function    GetCopy : TBackupItem; virtual;
    procedure   Assign(aSource : TBackupItem); virtual;
    function  Get(Index : Integer) : TBackupItem;
    procedure SetNodeCheckbox(Node : PVirtualNode);
    procedure Put(Index : Integer; Item : TBackupItem);
    function  GetText(Column : integer) : string; virtual;
    procedure KillUnselected;
    property  Items[Index : Integer] : TBackupItem read Get write Put; default;
    property  Selected : boolean read GetSelected write SetSelected;
    property  ParentSelected : boolean read GetParentSelected;
    property  Modified : boolean read GetModified write SetModified;
    property  Owner : TBackupItem read GetOwner;
  end;

  // gemeinsamer Vorfahr für Dateien und Verzeichnisse

  { TFileIOItem }

  TFileIOItem = class ( TBackupItem )
  private
    fName : string;
    fTime   : TDateTime;
  public
    constructor Create(aOwner : TBackupItem; aSearchRec : TSearchRec); reintroduce; virtual;
    constructor CreateFromStream(st : TMCLWriteReader); override;
    procedure   WriteStream(st : TMCLWriteReader); override;
    function    Get(Index : integer) : TFileIOItem;
    procedure   Put(Index : integer; Item : TFileIOItem);
    function    GetPath : string; virtual;
    function    GetDestPath : string; virtual;
    function    FindItem(OtherItem : TFileIOItem) : TFileIOItem;
    procedure   Assign(ASource : TBackupItem); override;
    property    Name : string read fName write fName;
    property    Time : TDateTime read fTime;
    property    Items[Index : integer] : TFileIOItem read Get write Put; default;
  end;

  TRootDirectory = class;
  TDirectory = class;
  TBackupJobItem = class;

  { TFile }

  TFile = class ( TFileIOItem )
  private
    fSize : Int64;
    fDestSize : Int64;
  public
    constructor Create(aOwner : TBackupItem; aSearchRec : TSearchRec); override;
    constructor CreateFromStream(st : TMCLWriteReader); override;
    procedure   WriteStream(st : TMCLWriteReader); override;
    function    GetText(Column : integer) : string; override;
    procedure   Assign(ASource : TBackupItem); override;
    property    Size : Int64 read fSize;
    property    DestSize : Int64 read fDestSize;
  end;

  { TDirectory }

  TDirectory = class ( TFileIOItem )
  private
    fSize : Int64;
    fDestSize : Int64;
    function  GetSize : Int64;
    function  GetDestSize : Int64;
  public
    function    GetText(Column : integer) : string; override;
    procedure   ClearSize;
    property    Size : Int64 read GetSize;
    property    DestSize : Int64 read GetDestSize;
  end;

  { TRootDirectory }

  TRootDirectory = class ( TDirectory )
  private
    fParentJobItem : TBackupJobItem;
  public
    function GetPath : string; override;
    function GetDestPath : string; override;
    property ParentJobItem : TBackupJobItem read fParentJobItem write fParentJobItem;
  end;

  TBackupJob = class;

  // Definiert einen Eintrag in dem BackupJob
  // Das kann ein komplettes Verzeichnis (mit Ausnahmen) oder einzelne Dateien
  // enthalten

  { TBackupJobItem }

  TBackupJobItem = class ( TDirectory )
  private
    fPath : string;
    fOnlySelected : boolean;
    fDestBaseDir : string;
    fOnBeginPrepare : TOnBeginPrepare;
    fOnProcessDir : TOnProcessDir;
    fEntireSize : Int64;
    fStoreEmptyDirectories : boolean;
    procedure   SetPath(const aValue : string);
    procedure   SetOnlySelected(const aValue : boolean);
    function    GetDestBaseDir : string;
    procedure   SetStoreEmptyDirectories(const Value : boolean);
  protected
    fSourceTree : TRootDirectory;
    function    GetSourceTree : TDirectory; virtual;
    procedure   SyncWithSource;
    procedure   DestroySourceTree;
  public
    constructor Create(aOwner : TBackupItem; aPath : string); reintroduce; virtual;
    constructor CreateFromStream(st : TMCLWriteReader); override;
    procedure   WriteStream(st : TMCLWriteReader); override;
    destructor  Destroy; override;
    function    GetText(Column : integer) : string; override;
    function    GetPath : string; override;
    function    GetDestPath : string; override;
    function    PrepareBackup(aJob : TBackupJob; aOnBeginPrepare : TOnBeginPrepare = nil; aOnProcessDir : TOnProcessDir = nil) : int64;
    function    StartBackup(aJob : TBackupJob; aOnNewFile  : TOnNewFile  = nil;
                                               aOnProgress : TOnProgress = nil;
                                               aOnFileDone : TOnFileDone = nil;
                                               aonError    : TOnError = nil) : boolean;
    property    Path : string read fPath write SetPath;
    property    SourceTree : TDirectory read GetSourceTree;
    property    OnlySelected : boolean read fOnlySelected write SetOnlySelected;
    property    DestBaseDir : string read GetDestBaseDir;
    property    StoreEmptyDirectories : boolean read  fStoreEmptyDirectories
                                                write SetStoreEmptyDirectories;
  end;

  // Dieses hält nur eine Liste von Dateien

  { TBackupJobFilesItem }

  TBackupJobFilesItem = class ( TBackupJobItem )
  protected
    function    GetSourceTree : TDirectory; override;
  public
    constructor Create(aOwner : TBackupItem; aPath : string); override;
    function    GetText(Column : integer) : string; override;
  end;

  { TBackupJob }

  TBackupJob = class ( TBackupItem )
  private
    fName : string;
    fDestination : string;
    fEntireSize : int64;
    procedure   SetDestination(AValue: string);
    procedure   SetName(const aValue : string);
  protected
    procedure   DestroySourceTree;
  public
    constructor Create(aOwner : TBackupItem); override;
    constructor CreateFromStream(st : TMCLWriteReader); override;
    procedure   WriteStream(st : TMCLWriteReader); override;
    function    Get(Index : integer) : TBackupJobItem;
    procedure   Put(Index : integer; Item : TBackupJobItem);
    procedure   SyncWithSource;
    procedure   PrepareBackup(aBeginPrepare : TOnBeginPrepare = nil; aOnProcessDir : TOnProcessDir = nil);
    function    StartBackup(aOnBeginJob : TOnBeginJob = nil;
                            aOnNewFile  : TOnNewFile  = nil;
                            aOnProgress : TOnProgress = nil;
                            aOnFileDone : TOnFileDone = nil;
                            aOnError    : TOnError = nil) : boolean;
    property    Name : string read fName write SetName;
    property    Destination : string read fDestination write SetDestination;
    property    Items[Index : integer] : TBackupJobItem read Get write Put; default;
  end;

  { TBackupJobs }

  TBackupJobs = class ( TBackupItem )
  public
    function  Get(Index : integer) : TBackupJob;
    procedure Put(Index : integer; Item : TBackupJob);
    procedure SyncWithSource;
    property  Items[Index : integer] : TBackupJob read get write Put; default;
  end;

const
  FileTimeBase      = -109205.0;
  FileTimeStep: Extended = 24.0 * 60.0 * 60.0 * 1000.0 * 1000.0 * 10.0; // 100 nSek pro Tag


function FileTimeToDateTime(const FileTime: TFileTime): TDateTime;
function ReadDirTree(Root : string; aProcessDir : TOnProcessDir = nil;
                     CreateIfNotExist : boolean = false) : TRootDirectory;
function FormatSize(Bytes : Int64) : string;
procedure RegisterBackupTypes;
function CopyFile(src, dst : string; out UserAbort : boolean; out ErrorMessage : string; aOnProgress : TOnProgress = nil) : boolean;

implementation
uses forms, controls, fileutil, messagewindowu;

{$ifdef mswindows}
type
  TExecutionState = cardinal;
const
  ES_AWAYMODE_REQUIRED = $000000040;
  ES_CONTINUOUS        = $80000000;
  ES_DISPLAY_REQUIRED = $00000002;
  ES_SYSTEM_REQUIRED = $00000001;

function SetThreadExecutionState(esFlags : TExecutionState) : TExecutionState; external 'kernel32';
{$endif}

function FileTimeToDateTime(const FileTime: TFileTime): TDateTime;
begin
  Result := Int64(FileTime) / FileTimeStep;
  Result := Result + FileTimeBase;
end;

{ TBackupItem }

procedure TBackupItem.SetSelected(AValue: boolean);
begin
  if Selected=AValue then Exit;
  if (AValue) then
    Include(fFlags, bfSelected)
  else
    Exclude(fFlags, bfSelected);
  Modified := True;
end;

function TBackupItem.GetSelected: boolean;
begin
  Result := bfSelected in fFlags;
end;

function TBackupItem.GetModified: boolean;

  function Test(Item : TMCLPersistent) : boolean;
  begin
    Result := TBackupItem(Item).Modified;
  end;

{$ifdef debugnames}
var s : string;
{$endif}
begin
  {$ifdef debugnames}
  s := classname;
  {$endif}
  Result := bfModified in fFlags;
  if not Result then Result := Assigned(FirstThat(@Test));
end;

procedure TBackupItem.SetModified(const AValue: boolean);

  procedure All(Item : TMCLPersistent);
  var bi : TBackupItem absolute Item;
  begin
    bi.Modified := False;
  end;

begin
  if AValue then
    Include(fFlags, bfModified)
  else begin
    Exclude(fFlags, bfModified);
    ForEach(@All);
  end;
end;

function TBackupItem.GetOwner: TBackupItem;
begin
  Result := fOwner;
end;

function TBackupItem.GetParentSelected: boolean;
var aOwner : TBackupItem;
begin
  Result := False;
  aOwner := Owner;
  while Assigned(aOwner) do
  begin
    if aOwner.Selected then
    begin
      Result := True;
      exit;
    end;
    aOwner := aOwner.Owner;
  end;
end;

procedure TBackupItem.SetOwner(aOwner: TBackupItem);
begin
  fOwner := aOwner;
end;

constructor TBackupItem.Create(aOwner : TBackupItem);
begin
  inherited Create;
  fOwner := aOwner;
  fFlags := [bfModified];
  {$ifdef storeclassnames}
   fMyClassName := className;
  {$endif}
end;

constructor TBackupItem.CreateFromStream(st: TMCLWriteReader);
var cnt, i : Integer;
      Item : TBackupItem;
begin
  inherited CreateFromStream(st);
  {$ifdef storeclassnames}
   fMyClassName := className;
  {$endif}
  st.Read(fFlags, SizeOf(fFlags));
  cnt := st.ReadInteger;
  for i := 1 to cnt do
  begin
    Item := TBackupItem(st.Get);
    Add(Item);
    Item.SetOwner(self);
  end;
  Modified := False;
end;

procedure TBackupItem.Loaded;
  procedure All(Item : TMCLPersistent);
  begin
    with TBackupItem(Item) do
    begin
      SetOwner(self);
      Loaded;
    end;
  end;
begin
  ForEach(@All);
end;

procedure TBackupItem.WriteStream(st: TMCLWriteReader);

  procedure All(Item : TMCLPersistent);
  begin
    st.Put(Item);
  end;

begin
  inherited WriteStream(st);
  st.Write(fFlags, SizeOf(fFlags));
  st.WriteInteger(count);
  ForEach(@All);
end;

function TBackupItem.GetCopy: TBackupItem;
var ct : TMCLClassType;
begin
  ct := TMCLClassType(ClassType);
  Result := TBackupItem(CT.Create);
  Result.Assign(self);
end;

procedure TBackupItem.Assign(aSource: TBackupItem);
begin
  fOwner := ASource.Owner;
  fFlags := ASource.fFlags;
end;

function TBackupItem.Get(Index: Integer): TBackupItem;
begin
  Result := TBackupItem(inherited Get(Index));
end;

procedure TBackupItem.SetNodeCheckbox(Node: PVirtualNode);
begin
  Node^.CheckType := ctCheckBox;
  if Selected then
    Node^.CheckState := csCheckedNormal
  else
    Node^.CheckState := csunCheckedNormal;
end;

procedure TBackupItem.Put(Index: Integer; Item: TBackupItem);
begin
  inherited Put(Index, Item);
end;

function TBackupItem.GetText(Column: integer): string;
begin
  Result := '';
end;

procedure TBackupItem.KillUnselected;

  function test(item : TMCLPersistent) : boolean;

    function FindSelected(item : TMCLPersistent) : boolean;
    var i : integer;
    begin
      Result := TBackupItem(Item).selected;
    end;

  begin
    TBackupItem(Item).KillUnselected;
    Result := not TBackupItem(Item).Selected;
    if not Result then exit;
    Result := not (Assigned(item.FindeRekursiv(@FindSelected)));
  end;

begin
  ForEachFreeIf(@test);
end;

{ TFileIOItem }

constructor TFileIOItem.Create(aOwner: TBackupItem; aSearchRec: TSearchRec);
begin
  inherited Create(aOwner);
  fName := aSearchRec.Name;
  //fCreationTime   := FileTimeToDateTime(aSearchRec.FindData.ftCreationTime);
  //fLastAccessTime := FileTimeToDateTime(aSearchRec.FindData.ftLastAccessTime);
  //fLastWriteTime  := FileTimeToDateTime(aSearchRec.FindData.ftLastWriteTime);
  fTime := aSearchRec.TimeStamp;
end;

constructor TFileIOItem.CreateFromStream(st: TMCLWriteReader);
var V : Byte;
begin
  inherited CreateFromStream(st);
  V := GetClassVersion(TFileIOItem);
  fName := st.Readstring;
  if (V > 0) then
    fTime := st.ReadDateTime
  else begin
    {fCreationTime   := }st.ReadDateTime;
    {fLastAccessTime := }st.ReadDateTime;
    fTime  := st.ReadDateTime;
  end;
end;

procedure TFileIOItem.WriteStream(st: TMCLWriteReader);
begin
  SetClassVersion(TFileIOItem, 1);
  inherited WriteStream(st);
  st.WriteString(fName);
  //st.WriteDateTime(fCreationTime);
  //st.WriteDateTime(fLastAccessTime);
  st.WriteDateTime(fTime);
end;

function TFileIOItem.Get(Index: integer): TFileIOItem;
begin
  Result := TFileIOItem(inherited Get(Index));
end;

procedure TFileIOItem.Put(Index: integer; Item: TFileIOItem);
begin
  inherited Put(Index, Item);
end;

function TFileIOItem.GetPath: string;
var aOwner : TBackupItem;
begin
  aOwner := Owner;
  Result := '';
  if (aOwner <> nil) and (aOwner is TFileIOItem) then
    Result := TFileIOItem(aOwner).GetPath;
  if Result <> '' then Result := IncludeTrailingPathDelimiter(Result);
  Result := Result + Name;
end;

function TFileIOItem.GetDestPath: string;
 var aOwner : TBackupItem;
  begin
    aOwner := Owner;
    Result := '';
    if (aOwner <> nil) and (aOwner is TFileIOItem) then
      Result := TFileIOItem(aOwner).GetDestPath;
    if Result <> '' then Result := IncludeTrailingPathDelimiter(Result);
    Result := Result + Name;
end;

function TFileIOItem.FindItem(OtherItem: TFileIOItem): TFileIOItem;
var OtherItemPath, ItemPath : string;
    i : integer;
    Item : TFileIOItem;
begin
  Result := nil;
  OtherItemPath := OtherItem.GetPath;
  ItemPath := GetPath;
  if (AnsiCompareText(OtherItemPath, ItemPath) = 0) then
  begin
    Result := self;
    exit;
  end;
  for i := 0 to count - 1 do
  begin
    Item := Items[i];
    ItemPath := Item.GetPath;
    if (AnsiCompareText(OtherItemPath, ItemPath) = 0) then
      Result := Item;
    if Result = nil then Result := Item.FindItem(OtherItem);
    if Result <> nil then Break;
  end;
end;

procedure TFileIOItem.Assign(ASource: TBackupItem);
var fio : TFileIOItem absolute ASource;
begin
  inherited Assign(ASource);
  Assert(ASource is TFileIOItem);
  fName := fio.Name;
  //fCreationTime := fio.CreationTime;
  //fLastAccessTime := fio.LastAccessTime;
  //fLastWriteTime := fio.LastWriteTime;
  fTime := fio.Time;
end;

{ TFile }

constructor TFile.Create(aOwner: TBackupItem; aSearchRec: TSearchRec);
begin
  inherited Create(aOwner, aSearchRec);
  fSize := aSearchRec.Size;
end;

constructor TFile.CreateFromStream(st: TMCLWriteReader);
begin
  inherited CreateFromStream(st);
  st.Read(fSize, SizeOf(fSize));
end;

procedure TFile.WriteStream(st: TMCLWriteReader);
begin
  inherited WriteStream(st);
  st.Write(fSize, SizeOf(fSize));
end;

function TFile.GetText(Column: integer): string;
begin
  case Column of
    -1, 0 : Result := name;
        1 : Result := 'Datei';
        2 : Result := FormatDateTime('dd.mm.YYYY HH:MM', fTime);
        3 : Result := FormatSize(Size);
  else
    Result := inherited GetText(Column);
  end;
end;

procedure TFile.Assign(ASource: TBackupItem);
begin
  inherited Assign(ASource);
  Assert(ASource is TFile);
  fSize := TFile(ASource).Size;
end;

{ TDirectory }

function TDirectory.GetSize: Int64;
  procedure All(Item : TMCLPersistent);
  begin
    if (Item is TDirectory) then
      fSize := fSize + TDirectory(Item).Size
    else if (Item is TFile) then
      fSize := fSize + TFile(Item).Size;
  end;
begin
  if fSize > 0 then
    Result := fSize
  else begin
    fSize := 0;
    ForEach(@all);
    Result := fSize;
  end;
end;

function TDirectory.GetDestSize: Int64;
  procedure All(Item : TMCLPersistent);
  begin
    if (Item is TDirectory) then
      fDestSize += TDirectory(Item).DestSize
    else if (Item is TFile) then
      fDestSize += TFile(Item).DestSize;
  end;
begin
  if fSize > 0 then
    Result := fDestSize
  else begin
    fDestSize := 0;
    ForEach(@all);
    Result := fDestSize;
  end;
end;

function TDirectory.GetText(Column: integer): string;
begin
  case Column of
    -1, 0 : Result := Name;
        1 : Result := 'Dir';
        2 : Result := FormatDateTime('dd.mm.YYYY HH:MM', fTime);
        3 : Result := FormatSize(Size);
  else
    Result:=inherited GetText(Column);
  end;
end;

procedure TDirectory.ClearSize;

  procedure all(Item : TMCLPersistent);
  begin
    if (Item is TDirectory) then
      TDirectory(Item).ClearSize;
  end;

begin
  fSize := -1;
  fDestSize := -1;
  ForEach(@all);
end;

{ TRootDirectory }

function TRootDirectory.GetPath: string;
begin
  Result:=inherited GetPath;
  if (Result <> '') then Result := IncludeTrailingPathDelimiter(Result);
end;

function TRootDirectory.GetDestPath: string;
begin
  if fParentJobItem <> nil then
    Result := fParentJobItem.GetDestPath
  else
    Result:=inherited GetDestPath;
  if (Result <> '') then Result := IncludeTrailingPathDelimiter(Result);
end;

{ TBackupJobItem }

procedure TBackupJobItem.SetPath(const aValue: string);
begin
  if fPath = aValue then exit;
  fPath := aValue;
  Modified := True;
end;

function TBackupJobItem.GetSourceTree: TDirectory;
var msgWin : TMessageWindow;

  function IsClass(O: TObject; ClassList: array of TClass): boolean;
  var i : integer;
  begin
   Result := True;
   for i := Low(ClassList) to High(ClassList) do if (o is ClassList[i]) then exit;
   Result := False;
  end;


  procedure SortItems(Item : TMCLPersistent);
  var fio : TFileIOItem absolute Item;
        i : integer;

    function Compare(Item1, Item2 : TMCLPersistent) : integer;
    var fio1 : TFileIOItem absolute Item1;
        fio2 : TFileIOItem absolute Item2;
    begin
      if (Item1 <> Item2) then
        Result := AnsiCompareText(fio1.Name, fio2.Name)
      else
        Result := 0;
    end;

  begin
    fio.QSort(@Compare);
    for i := 0 to Item.Count - 1 do
        SortItems(Item[i]);
  end;

  procedure SetCheckedItems(Item : TMCLPersistent);
  var sItem : TFileIOItem;
          i : integer;
  begin
    sItem := FindItem(TFileIOItem(Item));
    if (sItem <> nil) and not (isClass(SItem, [TBackupJobItem])) and (sItem.Selected) then
      TBackupItem(Item).Selected := True;
    for i := 0 to Item.Count - 1 do
      SetCheckedItems(Item[i]);
  end;

begin
  if (fSourceTree = nil) then
  begin
    Screen.Cursor := crHourGlass;
    try
      if (not (Assigned(fOnProcessDir))) then
      begin
        msgWin := TMessageWindow.Create(Application);
        fOnProcessDir := @msgWin.OnProcessDir;
        msgWin.Show();
      end else
        msgWin := nil;
      fSourceTree := ReadDirTree(fPath, fOnProcessDir);
      fSourceTree.ParentJobItem := self;
      fSourceTree.ForEach(@SortItems);
      SetCheckedItems(fSourceTree);
      fSourceTree.Modified := False;
    finally
      if msgWin <> nil then
      begin
        fOnProcessDir := nil;
        msgWin.Free;
      end;
      Screen.Cursor := crDefault;
    end;
  end;
  Result := fSourceTree;
end;

procedure TBackupJobItem.SetOnlySelected(const aValue: boolean);
begin
  if fOnlySelected = aValue then exit;
  fOnlySelected := aValue;
  Modified := true;
end;

function TBackupJobItem.GetDestBaseDir: string;
var Job : TBackupJob;
    i : integer;
    s, rp : string;
begin
  if (fDestBaseDir = '') then
  begin
    Job := TBackupJob(Owner);
    if DirectoryExists(Job.Destination) then
    begin
      s := ExtractFileDrive(Path);
      if (s = '') then // Linux?
      begin
        s := copy(path, 2, Length(Path)-1);
        i := Pos(DirectorySeparator, s);
        if (i > 0) then
          s := copy(s, 1, i-1);
      end;
      s := 'Lw' + s;
      if s[Length(s)] = ':' then system.delete(s, Length(s), 1);
      fDestBaseDir := Job.Destination + DirectorySeparator + s;
    end;
  end;
  Result := fDestBaseDir;
end;

procedure TBackupJobItem.SetStoreEmptyDirectories(const Value: boolean);
begin
  if fStoreEmptyDirectories <> Value then
  begin
    fStoreEmptyDirectories := Value;
    Modified := true;
  end;
end;

procedure TBackupJobItem.SyncWithSource;

  procedure DoSetOwner(Item : TMCLPersistent);
  begin
     TBackupItem(Item).SetOwner(self);
  end;

begin
  if (fSourceTree = nil) or
     (not (fSourceTree.Modified)) then exit;
  fSourceTree.KillUnselected;
  fSourceTree.MoveItems(self);
  fSourceTree.Clear;
  FreeAndNil(fSourceTree);
  ForEach(@DoSetOwner);
end;

procedure TBackupJobItem.DestroySourceTree;
begin
  fEntireSize := 0;
  if Assigned(fSourceTree) then FreeAndNil(fSourceTree);
end;

constructor TBackupJobItem.Create(aOwner: TBackupItem; aPath: string);
var sr : TSearchRec;
    i : integer;
begin
  aPath := ExcludeTrailingPathDelimiter(aPath);
  i := FindFirst(aPath, faAnyFile, sr);
  if (i = 0) and ((sr.Attr and faDirectory) <> 0) then
  begin
    inherited Create(aOwner, sr);
    Name := aPath;
    fPath := aPath;
    Selected := True;
  end else
    fail;
  FindClose(sr);
end;

constructor TBackupJobItem.CreateFromStream(st: TMCLWriteReader);
var s : string;
    V : Byte;
begin
  inherited CreateFromStream(st);
  V := GetClassVersion(TBackupJobItem);
  if count > 0 then s := Items[0].classname;
  fPath := st.ReadString;
  fOnlySelected := st.ReadBoolean;
  if (V > 0) then
    fStoreEmptyDirectories := st.ReadBoolean
  else
    fStoreEmptyDirectories := false;
end;

procedure TBackupJobItem.WriteStream(st: TMCLWriteReader);
begin
  SetClassVersion(TBackupJobItem, 1);
  inherited;
  st.WriteString(fPath);
  st.WriteBoolean(fOnlySelected);
  st.WriteBoolean(fStoreEmptyDirectories);
end;

destructor TBackupJobItem.Destroy;
begin
  if fSourceTree <> nil then fSourceTree.Free;
  inherited Destroy;
end;

function TBackupJobItem.GetText(Column: integer): string;
begin
  if Column < 1 then
    Result := Name
  else
    Result := inherited GetText(Column);
end;

function TBackupJobItem.GetPath: string;
begin
  Result := fPath;
  if (Result <> '') then Result := IncludeTrailingPathDelimiter(Result);
end;

function TBackupJobItem.GetDestPath: string;
begin
  Result:=DestBaseDir;
  if Result <> '' then
  begin
    if (Length(fPath) > 2) and (fPath[2] = ':') then
      Result += Copy(fPath, 3, Length(fPath)-2);
    Result := IncludeTrailingPathDelimiter(Result);
  end;
end;

function TBackupJobItem.PrepareBackup(aJob : TBackupJob;
                                       aOnBeginPrepare : TOnBeginPrepare;
                                       aOnProcessDir : TOnProcessDir) : int64;

 function Test(item : TMCLPersistent) : boolean;
 var fi : TFileIOItem absolute Item;
      i : integer;
      s : boolean;
      src,
      dst : string;
 begin
   s := fi.Selected or fi.ParentSelected;
   Result := ((OnlySelected) and not (S)) or
             (not (OnlySelected) and (S));
   if (not (Result)) then
   begin
     src := fi.GetPath;
     if (fi is TFile) then
     begin
       dst := fi.GetDestPath;
       if (FileExists(src)) and
          (FileExists(dst)) and
          (FileSize(src) = FileSize(dst)) and
          (FileAge(src) = FileAge(dst)) then
       begin
         Result := True;
         exit;
       end else
       begin
         fEntireSize += FileSize(src);
         exit;
       end;
     end else
     begin
       if (Assigned(fOnProcessDir)) then fOnProcessDir(src);
       i := 0;
       while (i < item.count) do
       begin
         if Test(Item[i]) then
           item.Kill(item[i])
         else
           inc(i);
       end;
       Result := (not (StoreEmptyDirectories)) and (Item.Count = 0);
     end;
   end;
 end;

begin
  fOwner := aJob;
  fEntireSize := 0;
  Result := fEntireSize;
  if (not (Selected)) then exit;
  fOnBeginPrepare := aOnBeginPrepare;
  fOnProcessDir := aOnProcessDir;
  SourceTree;
  fEntireSize := 0;

  // Alle Dateien / Verzeichnisse aus SourceTree entfernen welche entweder:
  // 1. per Definition nicht gesichert werden sollen (all except selected bzw. onlyselected)
  // 2. In DestTree bereits enthalten sind und sich weder die Größe noch die Zugriffszeit geändert hat
  if Assigned(fOnBeginPrepare) then fOnBeginPrepare('Prüfe Quellverzeichnisse...');
  SourceTree.ForEachFreeIf(@test);
  Result := fEntireSize;
end;

function TBackupJobItem.StartBackup(aJob: TBackupJob;
                                     aOnNewFile  : TOnNewFile;
                                     aOnProgress : TOnProgress;
                                     aOnFileDone : TOnFileDone;
                                     aonError    : TOnError = nil) : boolean;
var Aborted : boolean;

  procedure ProcessNode(Node : TFileIOItem);
  var i : integer;
    src, dst : string;
    ErrorMessage : string;
    s : string;
  begin
    s := Node.Name;
    if (Node is TFile) then
    begin
      src := PChar(TFile(Node).GetPath);
      dst := PChar(TFile(Node).GetDestPath);
      if Assigned(aOnNewFile) then aOnNewFile(src, dst, FileSize(src));
        if not CopyFile(src, dst, Aborted, ErrorMessage, aOnProgress) then
        begin
          if Assigned(aonError) then aOnError(src, dst, ErrorMessage);
        end;
      if Assigned(aOnFileDone) then aOnFileDone();
    end else
    if (Node is TDirectory) then
    begin
      dst := Node.GetDestPath();
      if StoreEmptyDirectories then
        if (not (DirectoryExists(dst))) then
           ForceDirectories(Dst);
    end;
    if Aborted then exit;
    for i := 0 to Node.Count - 1 do
      if not Aborted then ProcessNode(Node[i]);
  end;

begin
  fOwner := aJob;
  Result := True;
  Aborted := False;
  if (not (Selected)) then exit;
  ProcessNode(SourceTree);
  Result := not Aborted;
end;

{ TBackupJobFilesItem }

function TBackupJobFilesItem.GetSourceTree: TDirectory;
var sr : TSearchRec;

  procedure All(Item : TMCLPersistent);
  begin
    fSourceTree.Add(TBackupItem(Item).GetCopy);
  end;

begin
  if (fSourceTree = nil) then
  begin
    sr.Name := fName;
    fSourceTree := TRootDirectory.Create(self, sr);
    ForEach(@All);
  end;
  Result := fSourceTree;
end;

constructor TBackupJobFilesItem.Create(aOwner: TBackupItem; aPath: string);
begin
  inherited Create(aOwner, aPath);
  OnlySelected := true;
end;

function TBackupJobFilesItem.GetText(Column: integer): string;
begin
  if (Column < 1) then
    Result := Format('%d Dateien in %s', [count, GetPath])
  else
    Result := inherited GetText(Column);
end;

{ TBackupJob }

procedure TBackupJob.SetName(const aValue: string);
begin
  if fName = aValue then exit;
  fName := aValue;
  Modified := True;
end;

procedure TBackupJob.DestroySourceTree;

  procedure All(ji : TMCLPersistent);
  begin
    TBackupJobItem(ji).DestroySourceTree;
  end;

begin
  fEntireSize := 0;
  ForEach(@All);
end;

constructor TBackupJob.Create(aOwner: TBackupItem);
begin
  inherited Create(aOwner);
  fName := 'default';
end;

constructor TBackupJob.CreateFromStream(st: TMCLWriteReader);
begin
  inherited CreateFromStream(st);
  fName := st.ReadString;
  fDestination := st.ReadString;
  Loaded;
end;

procedure TBackupJob.WriteStream(st: TMCLWriteReader);
begin
  inherited WriteStream(st);
  st.WriteString(fName);
  st.WriteString(fDestination);
end;

function TBackupJob.Get(Index: integer): TBackupJobItem;
begin
  Result := TBackupJobItem(inherited Get(Index));
end;

procedure TBackupJob.Put(Index: integer; Item: TBackupJobItem);
begin
  inherited Put(Index, Item);
end;

procedure TBackupJob.SyncWithSource;

  procedure All(Item : TMCLPersistent);
  begin
    TBackupJobItem(Item).SyncWithSource;
  end;

begin
  forEach(@All);
end;

procedure TBackupJob.PrepareBackup(aBeginPrepare : TOnBeginPrepare; aOnProcessDir : TOnProcessDir);

  procedure All(Item : TMCLPersistent);
  begin
    fEntireSize += TBackupJobItem(Item).PrepareBackup(self, aBeginPrepare, aOnProcessDir);
  end;

begin
  fEntireSize := 0;
  ForEach(@all);
end;

function TBackupJob.StartBackup(aOnBeginJob : TOnBeginJob;
                                 aOnNewFile  : TOnNewFile;
                                 aOnProgress : TOnProgress;
                                 aOnFileDone : TOnFileDone;
                                 aOnError    : TOnError = nil) : boolean;
var Aborted : boolean;

  function All(Item : TMCLPersistent) : boolean;
  begin
    Aborted := not TBackupJobItem(Item).StartBackup(self, aOnNewFile, aOnProgress, aOnFileDone, aOnError);
    Result := Aborted;
  end;

begin
  {$ifdef mswindows}
  SetThreadExecutionState(ES_CONTINUOUS or ES_SYSTEM_REQUIRED or ES_AWAYMODE_REQUIRED);
  {$endif}
  try
    Aborted := False;
    if Assigned(aOnBeginJob) then aOnBeginJob(Format('Bearbeitung %s', [fName]), fEntireSize);
    Result := not Assigned(FirstThat(@all));
    DestroySourceTree();
  finally
    {$ifdef mswindows}
    SetThreadExecutionState(ES_CONTINUOUS);
    {$endif}
  end;
end;

procedure TBackupJob.SetDestination(AValue: string);
begin
  if fDestination=AValue then Exit;
  fDestination:=AValue;
  Modified := true;
end;

{ TBackupJobs }

function TBackupJobs.Get(Index: integer): TBackupJob;
begin
  Result := TBackupJob(inherited Get(Index));
end;

procedure TBackupJobs.Put(Index: integer; Item: TBackupJob);
begin
  inherited Put(Index, Item);
end;

procedure TBackupJobs.SyncWithSource;

  procedure All(Item : TMCLPersistent);
  begin
    TBackupJob(Item).SyncWithSource;
  end;

begin
  ForEach(@All);
end;

function ReadDirTree(Root : string; aProcessDir : TOnProcessDir;
                     CreateIfNotExist : boolean = false) : TRootDirectory;
var s, s1 : string;
    i : integer;

  procedure ProcessSubDir(Parent : TDirectory; Dir : string);
  var fs : TSearchRec;
       i : integer;
    Node : TBackupItem;
    DirNode : TDirectory absolute Node;
    FileNode : TFile absolute Node;
  begin
    i := FindFirst(Dir + DirectorySeparator + ALLFILESMASK, faDirectory, fs);
    if (i <> 0) then exit;
    while (i = 0) do
    begin
      if (fs.Name <> '.') and
         (fs.Name <> '..') and
         ((fs.Attr and faDirectory) <> 0) then
      begin
        if aProcessDir <> nil then aProcessDir(Dir + DirectorySeparator + fs.Name);
        DirNode := TDirectory.Create(Parent, fs);
        Parent.Add(DirNode);
        ProcessSubDir(DirNode, Dir + DirectorySeparator + fs.Name);
      end;
      i := FindNext(fs);
    end;
    FindClose(fs);

    i := FindFirst(Dir + DirectorySeparator + ALLFILESMASK, faAnyFile, fs);
    if (i <> 0) then exit;
    while (i=0) do
    begin
      if ((fs.Attr and faDirectory) = 0) then
      begin
        FileNode := TFile.Create(Parent, fs);
        Parent.Add(FileNode);
      end;
      i := FindNext(fs);
    end;
    FindClose(fs);
  end;

var fs : TSearchRec;
begin
  if (FindFirst(Root, faAnyFile, fs) = 0) then
  begin
    Result := TRootDirectory.Create(nil, fs);
    Result.Name := root;
    FindClose(fs);
    ProcessSubDir(Result, Root);
  end else
  begin
    if (CreateIfNotExist) then
    begin
      s := Root;
      i := Pos(DirectorySeparator, s);
      while (i > 0) do
      begin
        s1 := copy(s, 1, i);
        system.Delete(s, 1, i);
        if (not (DirectoryExists(s1))) then mkDir(s1);
        chDir(s1);
        i := Pos(DirectorySeparator, s);
      end;
      if (not (DirectoryExists(s))) then
      begin
        mkDir(s);
        chDir(s);
      end;
      if (FindFirst(Root, faAnyFile, fs) = 0) then
      begin
        Result := TRootDirectory.Create(nil, fs);
        Result.Name := root;
        FindClose(fs);
      end else
        raise Exception.CreateFmt('Kann Zielverzeichnis %s nicht erzeugen.', [root]);
    end else
      Result := nil;
  end;
end;

function FormatSize(Bytes: Int64): string;
const
  Kilo = 1024;
  Mega = Kilo * Kilo;
  Giga = UInt64(Mega) * Kilo;
  Tera = UInt64(Giga) * Kilo;
  SBytes = 'Bytes';
  SKilo = 'Kb';
  SMega = 'Mb';
  SGiga = 'Gb';
  STera = 'Tb';
var S: String;
begin
  if (Bytes > Tera) then
  begin
    S := Format('%.2f %s',[Bytes/Tera, STera]);
  end
  else if (Bytes > Giga) then
  begin
    S := Format('%.2f %s',[Bytes/Giga, SGiga]);
  end
  else if (Bytes > Mega) then
  begin
    S := Format('%.2f %s',[Bytes/Mega, SMega]);
  end
  else if (Bytes > Kilo) then
  begin
    S := Format('%.2f %s',[Bytes/Kilo, SKilo]);
  end
  else
  begin
    S := Format('%d %s',[Bytes, SBytes]);
  end;
  Result := S;
end;

procedure RegisterBackupTypes;
begin
  RegisterMCLClass(TBackupItem);
  RegisterMCLClass(TFileIOItem);
  RegisterMCLClass(TRootDirectory);
  RegisterMCLClass(TDirectory);
  RegisterMCLClass(TFile);
  RegisterMCLClass(TBackupJobItem);
  RegisterMCLClass(TBackupJobFilesItem);
  RegisterMCLClass(TBackupJob);
  RegisterMCLClass(TBackupJobs);
end;

function CopyFile(src, dst: string; out UserAbort : boolean; out ErrorMessage : string; aOnProgress: TOnProgress): boolean;
var
    SrcHandle: THandle;
    DestHandle: THandle;
    Buffer: array[1..4096] of byte;
    ReadCount, WriteCount, TryCount: LongInt;
    wtBytes, BytesLeft, ges : Int64;
begin
    Result := False;
    UserAbort := False;
    ErrorMessage := '';
    if (not DirectoryExists(ExtractFilePath(Dst))) and
       (not ForceDirectories(ExtractFilePath(Dst))) then
      exit;
    TryCount := 0;
    BytesLeft := FileSize(src);
    ges := BytesLeft;
    wtBytes := 0;
    While TryCount <> 3 Do Begin
      SrcHandle := FileOpen(Src, fmOpenRead or fmShareDenyWrite);
      if SrcHandle = feInvalidHandle then Begin
        Inc(TryCount);
        Sleep(10);
      End
      Else Begin
        TryCount := 0;
        Break;
      End;
    End;
    If TryCount > 0 Then
    begin
        ErrorMessage := Format({SFOpenError}'Datei kann nicht geöffnet werden "%s"', [Src]);
        exit;
    end;
    try
      DestHandle := FileCreate(Dst);
      if DestHandle = feInvalidHandle then
      begin
          ErrorMessage := Format({SFCreateError}'Datei kann nicht erzeugt werden "%s"',[Dst]);
          Exit;
      end;
      try
        repeat
          ReadCount:=FileRead(SrcHandle,Buffer[1],High(Buffer));
          if ReadCount<=0 then break;
          WriteCount:=FileWrite(DestHandle,Buffer[1],ReadCount);
          if WriteCount<ReadCount then
          begin
              ErrorMessage := Format({SFCreateError}'Kann nicht in Zieldatei schreiben "%s"',[Dst]);
              Exit;
          end;
          if Assigned(aOnProgress) then
          begin
            wtBytes += WriteCount;
            BytesLeft -= WriteCount;
            if not aOnProgress(wtBytes, BytesLeft) then
            begin
              UserAbort := True;
              ErrorMessage := 'Backupvorgang durch Benutzer abgebrochen';
              exit;
            end;
          end;
        until false;
      finally
        FileClose(DestHandle);
      end;
      FileSetDate(Dst, FileGetDate(SrcHandle));
      Result := True;
    finally
      FileClose(SrcHandle);
    end;
end;

initialization
 RegisterBackupTypes;
end.

