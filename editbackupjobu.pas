unit editbackupjobu;
{$i mlbackupsettings.inc}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn,
  ExtCtrls, Buttons, ComCtrls, ShellCtrls, Menus, laz.VirtualTrees,
  mlbackuptypes, mclstreams, dynlibs;

type

  { TeditBackupJobForm }

  TeditBackupJobForm = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    btnAddDir: TSpeedButton;
    btnAddFiles: TSpeedButton;
    cbStoreEmptyDirectories: TCheckBox;
    edDestination: TDirectoryEdit;
    edDir: TLabeledEdit;
    edJobName: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    ItemsTree: TLazVirtualStringTree;
    Tree: TLazVirtualStringTree;
    lbWhatIDo: TLabel;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    rbOnlySelected: TRadioButton;
    rbAllExceptSelected: TRadioButton;
    ShellTree: TShellTreeView;
    btnDeleteItem: TSpeedButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    tbDirectories: TTabSheet;
    procedure BitBtn2Click(Sender: TObject);
    procedure btnAddDirClick(Sender: TObject);
    procedure btnAddFilesClick(Sender: TObject);
    procedure btnDeleteItemClick(Sender: TObject);
    procedure cbStoreEmptyDirectoriesChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ItemsTreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure ItemsTreeFocusChanged(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Column: TColumnIndex);
    procedure ItemsTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure SelectionChange(Sender: TObject);
    procedure ShellTreeSelectionChanged(Sender: TObject);
    procedure TreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle;
      var HintText: String);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
  private
    fJob : TBackupJob;
    procedure UpdateTree(CurrentItem : TBackupJobItem);
    procedure CheckButtons;
    procedure ShowDir(s : string);
  protected
  public
    function Execute(aJob : TBackupJob) : boolean;
  end;

var
  editBackupJobForm: TeditBackupJobForm;

function EditBackupJob(aJob : TBackupJob) : boolean;

implementation
uses progressformu;

function EditBackupJob(aJob: TBackupJob): boolean;
begin
  editBackupJobForm := TEditBackupJobForm.Create(nil);
  Result := EditBackupJobForm.Execute(aJob);
  FreeAndNil(EditBackupJobForm);
end;

{$R *.lfm}

{ TeditBackupJobForm }

procedure TeditBackupJobForm.ItemsTreeGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: String);
var bi : TBackupItem;
begin
  if Assigned(Node) then
  bi := TBackupItem(ItemsTree.GetNodeData(Node)^);
   CellText := bi.GetText(Column);
end;

procedure TeditBackupJobForm.SelectionChange(Sender: TObject);
var
  ji : TBackupJobItem;
begin
  if Assigned(ItemsTree.FocusedNode) then
  ji := TBackupJobItem(ItemsTree.GetNodeData(ItemsTree.FocusedNode)^);
  if Assigned(ji) then
  begin
    ji.OnlySelected := rbOnlySelected.Checked;
  end;
end;

procedure TeditBackupJobForm.ShellTreeSelectionChanged(Sender: TObject);
begin
  edDir.Text := ShellTree.GetPathFromNode(ShellTree.Selections[0]);
end;

procedure TeditBackupJobForm.TreeChecked(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var d : TDirectory;
begin
  if Assigned(Node) then
    d := TDirectory(Tree.GetNodeData(Node)^);
  if Assigned(D) then
    D.Selected := Node^.CheckState = csCheckedNormal;
end;

procedure TeditBackupJobForm.TreeGetHint(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex;
  var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
var O : TObject;
begin
  if Assigned(Node) then
    O := TObject(Tree.GetNodeData(Node)^);
  if Assigned(O) then
  if (O is TFileIOItem) then
    HintText := TFileIOItem(O).GetPath + #13#10 +
                TFileIOItem(O).GetDestPath;
end;

procedure TeditBackupJobForm.TreeGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: String);
var bi : TBackupItem;
begin
  if (Assigned(Node)) then
    bi := TBackupItem(Tree.GetNodeData(Node)^);
  if (Assigned(bi)) then
    CellText := bi.GetText(Column);
end;

procedure TeditBackupJobForm.btnAddDirClick(Sender: TObject);
var i : integer;
   ji : TBackupJobItem;
   nn : PVirtualNode;
begin
  for i := 0 to ShellTree.SelectionCount - 1 do
  begin
    ji := TBackupJobItem.Create(fJob, ShellTree.GetPathFromNode(ShellTree.Selections[i]));
    ji.Selected := True;
    fJob.Add(ji);
    nn := ItemsTree.AddChild(nil, ji);
    ji.SetNodeCheckbox(nn);
  end;
end;

procedure TeditBackupJobForm.btnAddFilesClick(Sender: TObject);
var i : integer;
   ji : TBackupJobItem;
   nn : PVirtualNode;
   od : TOpenDialog;
   sr : TSearchRec;
    e : Integer;
   fi : TFile;
begin
  od := TOpenDialog.Create(Application);
  od.InitialDir := ShellTree.GetPathFromNode(ShellTree.Selections[0]);
  od.Options := [ofAllowMultiSelect, ofFileMustExist];
  if od.Execute then
  begin
    ji := TBackupJobFilesItem.Create(fJob, ShellTree.GetPathFromNode(ShellTree.Selections[0]));
    ji.Selected := True;
    fJob.Add(ji);
    nn := ItemsTree.AddChild(nil, ji);
    ji.SetNodeCheckbox(nn);
    for i := 0 to od.Files.Count - 1 do
    begin
      e := FindFirst(od.Files[i], faAnyFile, sr);
      if (e = 0) then
      begin
        fi := TFile.Create(ji, sr);
        fi.Selected := true;
        ji.Add(fi);
      end;
      FindClose(sr);
    end;
  end;
end;

procedure TeditBackupJobForm.btnDeleteItemClick(Sender: TObject);
var Node, NextNode : PVirtualNode;
    ji : TBackupJobItem;
begin
  Node := ItemsTree.GetFirst;
  while Assigned(Node) do
  begin
    NextNode := Node^.NextSibling;
    if ItemsTree.Selected[Node] then
    begin
      ji := TBackupJobItem(ItemsTree.GetNodeData(Node)^);
      if (Assigned(ji)) then
      begin
         Tree.Clear();
         ItemsTree.DeleteNode(Node);
         fJob.Kill(ji);
         fJob.Modified := true;
      end;
    end;
    Node := NextNode;
  end;
  CheckButtons;
end;

procedure TeditBackupJobForm.cbStoreEmptyDirectoriesChange(Sender: TObject);
var
  ji : TBackupJobItem;
begin
  if Assigned(ItemsTree.FocusedNode) then
  ji := TBackupJobItem(ItemsTree.GetNodeData(ItemsTree.FocusedNode)^);
  if Assigned(ji) then
  begin
    ji.StoreEmptyDirectories := cbStoreEmptyDirectories.Checked;
  end;
end;

procedure TeditBackupJobForm.FormCreate(Sender: TObject);
begin
  lbWhatIDo.Caption := '';
  ItemsTree.NodeDataSize := SizeOf(Pointer);
  Tree.NodeDataSize := SizeOf(Pointer);
end;

procedure TeditBackupJobForm.BitBtn2Click(Sender: TObject);
var pg : TProgressForm;
begin
  Tree.Clear;
  fJob.Destination := edDestination.Text;
  if (fJob.Destination <> '') and (DirectoryExists(fJob.Destination)) then
  begin
    if (ItemsTree.RootNodeCount > 0) then
    begin
      pg := TProgressForm.Create(Application);
      pg.Show();
      fJob.PrepareBackup(@pg.BeginPrepare, @pg.ProcessDir);
      if not fJob.StartBackup(@pg.BeginJob, @pg.NewFile, @pg.Progress, @pg.FileDone, @pg.Error) then
        ShowMessage('Backupvorgang abgebrochen!')
      else
        ShowMessage('Backupvorgang beendet');
      if (not (pg.btnError.Visible)) then
      begin
        pg.Hide;
        pg.Free;
      end;
    end else
      MessageDlg('Es müssen zuerst die zu sichernden Verzeichnisse ausgewählt werden!', mtError, [mbOk], 0);
  end
  else
    MessageDlg('Zielverzeichnis ist nicht verfügbar', mtError, [mbOk], 0);
end;

procedure TeditBackupJobForm.ItemsTreeChecked(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var bi : TBackupItem;
begin
  if (Assigned(Node)) then
    bi := TBackupItem(ItemsTree.GetNodeData(Node)^);
  if (Assigned(bi)) then
    bi.Selected := Node^.CheckState = csCheckedNormal;
end;

procedure TeditBackupJobForm.ItemsTreeFocusChanged(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex);
var ji : TBackupJobItem;

   procedure SetupTree(aParentNode: PVirtualNode; aItem : TFileIOItem);
   var NewNode : PVirtualNode;
       i : integer;
   begin
     if (aItem is TDirectory) then
     begin
       NewNode := Tree.AddChild(aParentNode, aItem);
       aItem.SetNodeCheckbox(NewNode);
       for i := 0 to aItem.Count - 1 do
         SetupTree(NewNode, aItem[i]);
     end;
   end;

begin
  CheckButtons;
  if (not (Assigned(Node))) then exit;
  ji := TBackupJobItem(ItemsTree.GetNodeData(Node)^);
  if (Assigned(ji)) then
  begin
    btnDeleteItem.Enabled := True;
    ShellTree.Path:=ji.Path;
    edDir.Text := ji.Path;
    if ji.OnlySelected then
      rbOnlySelected.Checked := True
    else
      rbAllExceptSelected.Checked := True;
    cbStoreEmptyDirectories.Checked := ji.StoreEmptyDirectories;
    Tree.BeginUpdate;
    try
      Tree.Clear;
      SetupTree(nil, ji.SourceTree);
      Tree.Expanded[Tree.GetFirst] := True;
    finally
      Tree.EndUpdate;
    end;
  end else
    btnDeleteItem.Enabled := False;
  CheckButtons;
end;

procedure TeditBackupJobForm.UpdateTree(CurrentItem: TBackupJobItem);
  procedure SetupTree(ParentNode : PVirtualNode; Dir : TBackupItem);
  var NewNode : PVirtualNode;

    procedure All(Item : TMCLPersistent);
    begin
      SetupTree(NewNode, TBackupItem(Item));
    end;

  begin
    NewNode := Tree.AddChild(ParentNode, Dir);
    if (Dir is TDirectory) then
      Dir.ForEach(@All);
  end;
begin
end;

procedure TeditBackupJobForm.CheckButtons;
begin
  Panel6.Enabled := ItemsTree.FocusedNode <> nil;
end;

procedure TeditBackupJobForm.ShowDir(s: string);
begin
  lbWhatIDo.Caption := Format('%s', [s]);
  Application.ProcessMessages();
end;

function TeditBackupJobForm.Execute(aJob: TBackupJob): boolean;
  procedure SetupTree(Item : TMCLPersistent);
  var N  : PVirtualNode;
      ji : TBackupJobItem absolute Item;
  begin
    N := ItemsTree.AddChild(nil, Item);
    ji.SetNodeCheckbox(N);
  end;
begin
  fJob := aJob;
  edJobName.Text := fJob.Name;
  edDestination.Text := fJob.Destination;
  fJob.ForEach(@SetupTree);
  CheckButtons;
  Result := ShowModal = mrOk;
  if (Result) then
  begin
    fJob.Name := edJobName.Text;
    fJob.Destination := edDestination.Text;
  end;
end;

end.

