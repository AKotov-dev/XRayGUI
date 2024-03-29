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
    procedure StopUpdate;

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

    //Если регистрация пройдена запустить Update
   { if Registered then UpdateProcess.Execute;

    //Показать версию WARP
    UpdateProcess.Parameters.Delete(1);
    UpdateProcess.Parameters.Add('warp-cli --version');
    UpdateProcess.Execute;

    S.LoadFromStream(UpdateProcess.Output);
    Synchronize(@StopUpdate); }
  finally
    S.Free;
    UpdateProcess.Free;
  end;
end;

//Останов обновления
procedure CheckUpdate.StopUpdate;
begin
  //Перечитываем версию в подсказке
 // MainForm.StartBtn.Hint := Trim(S[0]);
end;

end.
