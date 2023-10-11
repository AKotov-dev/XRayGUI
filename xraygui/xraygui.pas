program xraygui;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
  cthreads,
      {$ENDIF} {$IFDEF HASAMIGA}
  athreads,
      {$ENDIF}
  Process,
  Classes,
  Dialogs,
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  start_trd,
  portscan_trd,
  update_trd, reality_gen { you can add units after this };

{$R *.res}

//--- Определяем, запущена ли копия программы
var
  PID: TStringList;
  ExProcess: TProcess;

begin
  ExProcess := TProcess.Create(nil);
  PID := TStringList.Create;
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add('pidof xraygui'); //Имя приложения
    ExProcess.Options := ExProcess.Options + [poUsePipes];

    ExProcess.Execute;
    PID.LoadFromStream(ExProcess.Output);

  finally
    ExProcess.Free;
  end;

  //Количество запущенных копий > 1 = не запускать новый экземпляр
  if Pos(' ', PID.Text) <> 0 then //пробел = более одного pid
  begin
    MessageDlg(SAppRunning, mtWarning, [mbOK], 0);
    PID.Free;
    Application.Free;
    Halt(1);
  end;
  PID.Free;

  //---

  RequireDerivedFormResource := True;
  Application.Title:='XRayGUI v1.8';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TRealityForm, RealityForm);
  Application.Run;
end.
