unit update_trd;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Forms, Controls, SysUtils, Process;

type
  CheckUpdate = class(TThread)
  private

    { Private declarations }
  protected
    S: TStringList;

    procedure Execute; override;

  end;

implementation

uses unit1;

{ TRD }

procedure CheckUpdate.Execute;
var
  UpdateProcess: TProcess;
begin
  S := TStringList.Create;
  FreeOnTerminate := True; //Уничтожать по завершении
  try
    UpdateProcess := TProcess.Create(nil);

    UpdateProcess.Executable := 'bash';
    UpdateProcess.Parameters.Add('-c');
    UpdateProcess.Options := [poUsePipes, poWaitOnExit];

    UpdateProcess.Parameters.Add(
      '[[ $(systemctl is-active xray-update) == active ]] || systemctl --user start xray-update');

    UpdateProcess.Execute;
  finally
    S.Free;
    UpdateProcess.Free;
  end;
end;

end.
