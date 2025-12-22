unit mlbackupmainu;

{$i mlbackupsettings.inc}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  mlbackuptypes, editbackupjobu, mclstreams;

type

  { TMLBackupMainform }

  TMLBackupMainform = class(TForm)
    btnAddBackupJob: TBitBtn;
    btnEditJob: TBitBtn;
    btnDeleteJob: TBitBtn;
    JobListbox: TListBox;
    procedure btnAddBackupJobClick(Sender: TObject);
    procedure btnDeleteJobClick(Sender: TObject);
    procedure btnEditJobClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure JobListboxDblClick(Sender: TObject);
    procedure JobListboxSelectionChange(Sender: TObject; User: boolean);
  private
    fJobs : TBackupJobs;
    procedure CheckButtons;
  public
    procedure LoadJobs;
    procedure SaveJobs;
  end;

var
  MLBackupMainform: TMLBackupMainform;

implementation

{$R *.lfm}

{ TMLBackupMainform }

procedure TMLBackupMainform.FormCreate(Sender: TObject);
begin
  LoadJobs;
end;

procedure TMLBackupMainform.FormDestroy(Sender: TObject);
begin
  fJobs.SyncWithSource;
  if fJobs.Modified then
  if MessageDlg('Jobs wurden gändert. Speichern?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    SaveJobs;
  fJobs.Free;
end;

procedure TMLBackupMainform.JobListboxDblClick(Sender: TObject);
begin
  if btnEditJob.Enabled then btnEditJobClick(btnEditJob);
end;

procedure TMLBackupMainform.JobListboxSelectionChange(Sender: TObject;
  User: boolean);
begin
  CheckButtons;
end;

procedure TMLBackupMainform.CheckButtons;
begin
  btnEditJob.Enabled := JobListBox.ItemIndex >= 0;
  btnDeleteJob.Enabled := btnEditJob.Enabled;
end;

procedure TMLBackupMainform.LoadJobs;

  procedure SetupJobList(Job : TMCLPersistent);
  begin
    JobListbox.Items.AddObject(TBackupJob(Job).Name, Job);
  end;

var fName : string;
begin
  fName := GetAppConfigDir(false) + 'jobs.dat';
  if (FileExists(fName)) then
  begin
    with TMCLWriteReader.Create(TFileStream.Create(fName, fmOpenRead or fmShareDenyNone)) do
    begin
      fJobs := TBackupJobs(Get);
      Free;
    end;
  end else
    fJobs := TBackupJobs.Create(nil);
  fJobs.ForEach(@SetupJobList);
  CheckButtons;
end;

procedure TMLBackupMainform.SaveJobs;
var fName : string;
    Dir : string;
begin
  Dir := GetAppConfigDir(false);
  if not DirectoryExists(Dir) then
    mkDir(Dir);
  fName := Dir + 'jobs.dat';
  with TMCLWriteReader.Create(TFileStream.Create(fName, fmCreate)) do
  begin
    Put(fJobs);;
    Free;
  end;
end;

procedure TMLBackupMainform.btnAddBackupJobClick(Sender: TObject);
var Job : TBackupJob;
begin
  Job := TBackupJob.Create(fJobs);
  if EditBackupJob(Job) then
  begin
    JobListBox.Items.AddObject(Job.Name, Job);
    fJobs.Add(Job);
  end else
    Job.Free;
end;

procedure TMLBackupMainform.btnDeleteJobClick(Sender: TObject);
var Job : TBackupJob;
      i : integer;
begin
  i := JoblistBox.ItemIndex;
  Job := TBackUpJob(JobListbox.Items.Objects[i]);
  fJobs.Extract(Job);
  JobListBox.Items.Delete(i);
  Job.Free;
  CheckButtons;
end;

procedure TMLBackupMainform.btnEditJobClick(Sender: TObject);
var i : Integer;
    Job : TBackupJob;
begin
  i := JoblistBox.ItemIndex;
  if (i >= 0) then
  begin
    Job := TBackupJob(JoblistBox.Items.Objects[i]);
    if EditBackupJob(Job) then
      JoblistBox.Items[i] := Job.Name;
  end;
end;

end.

