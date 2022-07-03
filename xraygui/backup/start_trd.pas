unit start_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process;

type
  ShowLogTRD = class(TThread)
  private

    { Private declarations }
  protected
  var
    Result: TStringList;

    procedure Execute; override;

    procedure ShowLog;
    procedure StartTrd;

  end;

implementation

uses Unit1;

{ TRD }


procedure ShowLogTRD.Execute;
var
  ExProcess: TProcess;
begin
  try //Старт вывода
    Synchronize(@StartTRD);

    FreeOnTerminate := True; //Уничтожить по завершении
    Result := TStringList.Create;

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');

    //Если файл лога отсутствует - создаём пустой и читаем до Terminate
    ExProcess.Parameters.Add('[[ -f ~/.config/xraygui/xraygui.log ]] || touch ' +
      '~/.config/xraygui/xraygui.log && tail -n 100 -f ~/.config/xraygui/xraygui.log 2> >(grep -v truncated >&2)');

    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    //, poWaitOnExit (синхронный вывод)

    ExProcess.Execute;

    //Выводим лог динамически
    while ExProcess.Running do
    begin
      Result.LoadFromStream(ExProcess.Output);

      //Выводим лог
      if Result.Count <> 0 then
        Synchronize(@ShowLog);
    end;

  finally
    Result.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

//Старт вывода
procedure ShowLogTRD.StartTRD;
begin
  //Промотать список вниз (до вывода tail)
  MainForm.LogMemo.SelStart := Length(MainForm.LogMemo.Text);
  MainForm.LogMemo.SelLength := 0;
end;

//Вывод лога
procedure ShowLogTRD.ShowLog;
var
  i: integer;
begin
  //Вывод построчно
  for i := 0 to Result.Count - 1 do
    MainForm.LogMemo.Lines.Append(' ' + Result[i]);

  //Выводим последние записи минус 100
  if MainForm.LogMemo.Lines.Count > 500 then
    for i := 0 to 500 do
      MainForm.LogMemo.Lines.Delete(i);

  //Промотать список вниз
  MainForm.LogMemo.SelStart := Length(MainForm.LogMemo.Text);
  MainForm.LogMemo.SelLength := 0;
end;

end.
