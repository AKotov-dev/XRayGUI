unit portscan_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Controls, SysUtils, Process, Graphics;

type
  PortScan = class(TThread)
  private

    { Private declarations }
  protected
  var
    ResultStr: TStringList;

    procedure Execute; override;
    procedure ShowStatus;

  end;

implementation

uses unit1;

{ TRD }

procedure PortScan.Execute;
var
  ScanProcess: TProcess;
begin
  FreeOnTerminate := True; //Уничтожать по завершении

  while not Terminated do
    try
      ResultStr := TStringList.Create;

      ScanProcess := TProcess.Create(nil);

      ScanProcess.Executable := 'bash';
      ScanProcess.Parameters.Add('-c');
      ScanProcess.Options := [poUsePipes, poWaitOnExit];

      ScanProcess.Parameters.Add(
        'ss -ltn | grep ' + MainForm.PortEdit.Text);
      ScanProcess.Execute;

      ResultStr.LoadFromStream(ScanProcess.Output);
      Synchronize(@ShowStatus);

      Sleep(1000);
    finally
      ResultStr.Free;
      ScanProcess.Free;
    end;
end;

procedure PortScan.ShowStatus;
begin
  with MainForm do
  begin
    if ResultStr.Count <> 0 then
    begin
      Shape1.Brush.Color := clLime;
      PortEdit.Enabled := False;
      LoadItem.Enabled := False;
    end
    else
    begin
      Shape1.Brush.Color := clYellow;
      PortEdit.Enabled := True;
      LoadItem.Enabled := True;
    end;
    MainForm.Shape1.Repaint;
  end;
end;

end.
