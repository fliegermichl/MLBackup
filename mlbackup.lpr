program mlbackup;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, mclstreams, mlbackupmainu,
  mlbackuptypes, editbackupjobu, progressformu, messagewindowu;

{$R *.res}

begin
 {$ifopt d+}
  if UseHeaptrace then
  begin
    GlobalSkipIfNoLeaks := true; // supported as of debugger version 3.1.1
    SetHeapTraceOutput(Application.Location + 'heaptrace.txt');
  end;
 {$endif}
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMLBackupMainform, MLBackupMainform);
  Application.Run;
end.

