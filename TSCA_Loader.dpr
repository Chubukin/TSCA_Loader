program TSCA_Loader;

uses
  Winapi.Windows,
  System.SyncObjs,
  Main in 'Main.pas',
  ExtUnit in 'ExtUnit.pas';

var
  CheckEvent: TEvent;

{$R *.res}
{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED}

begin
  CheckEvent := TEvent.Create(nil, false, true, 'Loader_CheckExist');
  if CheckEvent.WaitFor(10) = wrSignaled then
  begin
    StartLoader;
  end;
  CheckEvent.Free;
end.
