program xraygui;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
  cthreads,
   {$ENDIF} {$IFDEF HASAMIGA}
  athreads,
   {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  start_trd { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:='XRayGUI v0.6';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
