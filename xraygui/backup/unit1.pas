unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, ClipBrd, Spin, IniPropStorage, Process, Base64, DefaultTranslator,
  CheckLst, Menus, URIParser, StrUtils;

type

  { TMainForm }

  TMainForm = class(TForm)
    AutoStartBox: TCheckBox;
    ClearBox: TCheckBox;
    ConfigBox: TCheckListBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    LogMemo: TMemo;
    LoadItem: TMenuItem;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    SaveItem: TMenuItem;
    Separator1: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    PopupMenu1: TPopupMenu;
    Shape1: TShape;
    PasteBtn: TSpeedButton;
    StartBtn: TSpeedButton;
    StopBtn: TSpeedButton;
    SelAllBtn: TSpeedButton;
    DeleteBtn: TSpeedButton;
    PortEdit: TSpinEdit;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    StaticText1: TStaticText;
    procedure AutoStartBoxChange(Sender: TObject);
    procedure ClearBoxChange(Sender: TObject);
    procedure ConfigBoxClickCheck(Sender: TObject);
    procedure DeleteBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure IniPropStorage1RestoreProperties(Sender: TObject);
    procedure LoadItemClick(Sender: TObject);
    procedure PasteItemClick(Sender: TObject);
    procedure Panel1Resize(Sender: TObject);
    procedure Panel2Resize(Sender: TObject);
    procedure PasteBtnClick(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure SaveItemClick(Sender: TObject);
    procedure SelAllBtnClick(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure StartProcess(command: string);
    procedure StopBtnClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ButtonStatus;
    function VmessDecode(URL, val: string): string;
    procedure CreateVMESSConfig(VMESSURL, PORT, SAVEPATH: string);
    function SSDecode(URL: string; val: integer): string;
    procedure CreateSSConfig(SSURL, PORT, SAVEPATH: string);
    function VLESSDecode(URL, val: string): string;
    procedure CreateVLESSConfig(VLESSURL, PORT, SAVEPATH: string);
    function TrojanDecode(URL, val: string): string;
    procedure CreateTrojanConfig(TROJANURL, PORT, SAVEPATH: string);

  private

  public

  end;

var
  MainForm: TMainForm;

resourcestring
  SVmessOnlyMsg = 'Supported protocols:' + #13#10 +
    'VMESS/VLESS (ws, ws+tls) and SS (without obfs)!';
  SDeleteMsg = 'Delete the selected configurations?';
  SNotValidMsg = 'The file is not valid!';

implementation

uses start_trd, portscan_trd;

{$R *.lfm}

{ TMainForm }

//Статус панелей и кнопок
procedure TMainForm.ButtonStatus;
begin
  if ConfigBox.Count = 0 then
  begin
    DeleteBtn.Enabled := False;
    SelAllBtn.Enabled := False;
    Panel2.Enabled := False;
  end
  else
  begin
    DeleteBtn.Enabled := True;
    SelAllBtn.Enabled := True;
    Panel2.Enabled := True;
  end;
end;

//Общая процедура запуска команд (асинхронная)
procedure TMainForm.StartProcess(command: string);
var
  ExProcess: TProcess;
begin
  Application.ProcessMessages;
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := '/bin/bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(command);
    //  ExProcess.Options := ExProcess.Options + [poWaitOnExit];
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

//Проверка чекбокса ClearBox (очистка кеш/cookies)
function CheckClear: boolean;
begin
  if FileExists(GetUserDir + '.config/xraygui/clear') then
    Result := True
  else
    Result := False;
end;

//Проверка чекбокса AutoStart
function CheckAutoStart: boolean;
begin
  if FileExists(GetUserDir + '.config/autostart/xray.desktop') then
    Result := True
  else
    Result := False;
end;

//VMESS - Декодирование/Нормализация/Поиск URL из конфигурации VMESS
function TMainForm.VmessDecode(URL, val: string): string;
var
  i: integer;
  S: TStringList;
begin
  URL := Trim(URL);
  try
    S := TStringList.Create;

    if (Pos('vmess://', URL) <> 0) or (Pos('ss://', URL) <> 0) then
    begin
      //Преобразуем всё содержимое Base64 после "//"
      Result := DecodeStringBase64(Copy(URL, Pos('//', URL) + 2));
      //Убираем скобки {}
      Result := Copy(Result, 2, Length(Result) - 2);
      //Убираем переводы строк
      Result := StringReplace(Result, #13#10, '', [rfReplaceAll, rfIgnoreCase]);
      //Убираем пробелы
      Result := StringReplace(Result, ' ', '', [rfReplaceAll, rfIgnoreCase]);
      //Убираем кавычки
      Result := StringReplace(Result, '"', '', [rfReplaceAll, rfIgnoreCase]);
      //Грузим линейный текст
      S.Text := (Result);

      //Разделяем значения на Items по (,)
      S.Delimiter := ',';
      S.StrictDelimiter := True;
      S.DelimitedText := S[0];

      //Поиск соответствия (add, port, id, net и т.д.)
      for i := 0 to S.Count - 1 do
        if Copy(S[i], 1, Pos(':', S[i]) - 1) = val then
        begin
          Result := Copy(S[i], Pos(':', S[i]) + 1, Length(S[i]));
          Break;
        end;
    end;
  finally
    S.Free;
  end;
end;

//VMESS - Создать и сохранить ~./config/xraygui/config.json
procedure TMainForm.CreateVMESSConfig(VMESSURL, PORT, SAVEPATH: string);
var
  S: TStringList;
begin
  try
    S := TStringList.Create;

    S.Add('{');
    S.Add('  "policy": {');
    S.Add('    "system": {');
    S.Add('      "statsInboundUplink": true,');
    S.Add('      "statsInboundDownlink": true');
    S.Add('    }');
    S.Add('  },');
    S.Add('  "log": {');
    S.Add('    "access": "",');
    S.Add('    "error": "",');
    //LOG LEVEL (debug, info, warning, error)
    S.Add('    "loglevel": "info"');
    S.Add('  },');
    //DNS
    S.Add('        "dns": {');
    S.Add('        "servers": [');
    S.Add('            "1.1.1.1",');
    S.Add('            "8.8.8.8",');
    S.Add('            "9.9.9.9"');
    S.Add('        ]');
    S.Add('    },');
    S.Add('  "inbounds": [');
    S.Add('    {');
    S.Add('      "tag": "proxy",');
    S.Add('      "port": ' + PORT + ',');
    S.Add('      "listen": "0.0.0.0",');
    S.Add('      "protocol": "socks",');
    S.Add('      "sniffing": {');
    S.Add('        "enabled": true,');
    S.Add('        "destOverride": [');
    S.Add('          "http",');
    S.Add('          "tls"');
    S.Add('        ]');
    S.Add('      },');
    S.Add('      "settings": {');
    S.Add('        "auth": "noauth",');
    S.Add('        "udp": true,');
    S.Add('        "ip": null,');
    S.Add('        "address": null,');
    S.Add('        "clients": null');
    S.Add('      },');
    S.Add('      "streamSettings": null');
    S.Add('    }');
    S.Add('  ],');
    S.Add('  "outbounds": [');
    S.Add('    {');
    //Tag
    S.Add('      "tag": "' + VmessDecode(VMESSURL, 'ps') + ' ' +
      VmessDecode(VMESSURL, 'add') + ' ' + VmessDecode(VMESSURL, 'port') + '",');
    S.Add('      "protocol": "vmess",');
    S.Add('      "settings": {');
    S.Add('        "vnext": [');
    S.Add('          {');
    S.Add('            "users": [');
    S.Add('              {');
    S.Add('                "email": "t@t.tt",');
    S.Add('                "security": "auto",');
    //ID
    S.Add('                "id": "' + VmessDecode(VMESSURL, 'id') + '",');
    //AID
    S.Add('                "alterId": ' + VmessDecode(VMESSURL, 'aid'));
    S.Add('              }');
    S.Add('            ],');
    //ADD (ADDRESS)
    S.Add('            "address": "' + VmessDecode(VMESSURL, 'add') + '",');
    //PORT
    S.Add('            "port": ' + VmessDecode(VMESSURL, 'port'));
    S.Add('          }');
    S.Add('        ],');
    S.Add('        "servers": null,');
    S.Add('        "response": null');
    S.Add('      },');
    S.Add('      "streamSettings": {');
    //NETWORK
    S.Add('        "network": "' + VmessDecode(VMESSURL, 'net') + '",');
    //TLS
    if VmessDecode(VMESSURL, 'tls') = '' then
      S.Add('        "security": null,')
    else
      S.Add('        "security": "' + VmessDecode(VMESSURL, 'tls') + '",');
    S.Add('        "tlsSettings": {');
    S.Add('          "allowInsecure": true');
    S.Add('        },');
    S.Add('        "kcpSettings": {');
    S.Add('          "mtu": 1350,');
    S.Add('          "tti": 50,');
    S.Add('          "uplinkCapacity": 12,');
    S.Add('          "downlinkCapacity": 100,');
    S.Add('          "congestion": false,');
    S.Add('          "readBufferSize": 2,');
    S.Add('          "writeBufferSize": 2,');
    S.Add('          "header": {');
    S.Add('            "type": "wechat-video"');
    S.Add('          }');
    S.Add('        },');
    S.Add('        "wsSettings": {');
    S.Add('          "connectionReuse": true,');
    //PATH
    S.Add('          "path": "' + VmessDecode(VMESSURL, 'path') + '",');
    S.Add('          "headers": {');
    //HOST
    S.Add('            "Host": "' + VmessDecode(VMESSURL, 'host') + '"');
    S.Add('          }');
    S.Add('        },');
    S.Add('        "httpSettings": {');
    S.Add('          "host": [');
    S.Add('            "host.com"');
    S.Add('          ],');
    S.Add('          "path": "/host"');
    S.Add('        },');
    S.Add('        "quicSettings": {');
    S.Add('          "security": "none",');
    S.Add('          "key": "",');
    S.Add('          "header": {');
    //TYPE
    if VmessDecode(VMESSURL, 'type') = '' then
      S.Add('            "type": "none"')
    else
      S.Add('            "type": "' + VmessDecode(VMESSURL, 'type') + '"');
    S.Add('          }');
    S.Add('        },');
    S.Add('        "tcpSettings": {');
    S.Add('          "connectionReuse": true,');
    S.Add('          "header": {');
    S.Add('            "type": "http",');
    S.Add('            "request": {');
    S.Add('              "version": "1.1",');
    S.Add('              "method": "GET",');
    S.Add('              "path": [');
    S.Add('                "/"');
    S.Add('              ],');
    S.Add('              "headers": {');
    S.Add('                "Host": [');
    S.Add('                  ""');
    S.Add('                ],');
    S.Add('                "User-Agent": [');
    S.Add('                  "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36",');
    S.Add('                  "Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46"');
    S.Add('                ],');
    S.Add('                "Accept-Encoding": [');
    S.Add('                  "gzip, deflate"');
    S.Add('                ],');
    S.Add('                "Connection": [');
    S.Add('                  "keep-alive"');
    S.Add('                ],');
    S.Add('                "Pragma": "no-cache"');
    S.Add('              }');
    S.Add('            }');
    S.Add('          }');
    S.Add('        }');
    S.Add('      },');
    S.Add('      "mux": {');
    S.Add('        "enabled": false');
    S.Add('      }');
    S.Add('    },');
    S.Add('    {');
    S.Add('      "tag": "direct",');
    S.Add('      "protocol": "freedom",');
    S.Add('      "settings": {');
    S.Add('        "vnext": null,');
    S.Add('        "servers": null,');
    S.Add('        "response": null');
    S.Add('      },');
    S.Add('      "streamSettings": null,');
    S.Add('      "mux": null');
    S.Add('    },');
    S.Add('    {');
    S.Add('      "tag": "block",');
    S.Add('      "protocol": "blackhole",');
    S.Add('      "settings": {');
    S.Add('        "vnext": null,');
    S.Add('        "servers": null,');
    S.Add('        "response": {');
    S.Add('          "type": "http"');
    S.Add('        }');
    S.Add('      },');
    S.Add('      "streamSettings": null,');
    S.Add('      "mux": null');
    S.Add('    }');
    S.Add('  ],');
    S.Add('  "stats": {},');
    S.Add('  "api": {');
    S.Add('    "tag": "api",');
    S.Add('    "services": [');
    S.Add('      "StatsService"');
    S.Add('    ]');
    S.Add('  },');
    S.Add('  "dns": null,');
    S.Add('  "routing": {');
    S.Add('    "domainStrategy": "IPIfNonMatch",');
    S.Add('    "rules": [');
    S.Add('      {');
    S.Add('        "type": "field",');
    S.Add('        "port": null,');
    S.Add('        "inboundTag": "api",');
    S.Add('        "outboundTag": "api",');
    S.Add('        "ip": null,');
    S.Add('        "domain": null');
    S.Add('      }');
    S.Add('    ]');
    S.Add('  }');
    S.Add('}');

    //Сохранение готового конфига
    S.SaveToFile(SAVEPATH);
  finally
    S.Free;
  end;
end;

//SS - Декодирование/Нормализация/Поиск
function TMainForm.SSDecode(URL: string; val: integer): string;
const
  URISeparator = '@#&?';
var
  i: integer;
  S: TStringList;
begin
  try
    S := TStringList.Create;

    //Отсекаем ss://
    URL := Trim(Copy(URL, 6, Length(URL)));
    //Убираем переводы строк
    URL := StringReplace(URL, #13#10, '', [rfReplaceAll, rfIgnoreCase]);
    //Убираем пробелы
    URL := StringReplace(URL, ' ', '', [rfReplaceAll, rfIgnoreCase]);
    //Убираем кавычки
    URL := StringReplace(URL, '"', '', [rfReplaceAll, rfIgnoreCase]);

    //Заменяем символы URI-сепаратора на ':'
    for i := 1 to Length(URL) do
      if Pos(URL[i], URISeparator) > 0 then
        URL[i] := ':';

    //Получаем декодированную часть URL
    Result := DecodeStringBase64(Copy(URL, 1, Pos(':', URL) - 1));

    //Заменяем символы URI-сепаратора на ':' после расшифровки
    for i := 1 to Length(Result) do
      if Pos(Result[i], URISeparator) > 0 then
        Result[i] := ':';

    //Грузим линейный текст
    S.Text := StringReplace(URL, Copy(URL, 1, Pos(':', URL) - 1),
      Result, [rfReplaceAll, rfIgnoreCase]);

    //Разделяем значения на Items по (:)
    S.Delimiter := ':';
    S.StrictDelimiter := True;
    S.DelimitedText := S[0];

    Result := S[val];
  finally
    S.Free;
  end;
end;

//SS - Создать и сохранить ~./config/xraygui/config.json
procedure TMainForm.CreateSSConfig(SSURL, PORT, SAVEPATH: string);
var
  S: TStringList;
begin
  try
    S := TStringList.Create;

    S.Add('    {');
    S.Add('        "api": {');
    S.Add('            "services": [');
    S.Add('                "ReflectionService",');
    S.Add('                "HandlerService",');
    S.Add('                "LoggerService",');
    S.Add('                "StatsService"');
    S.Add('            ],');
    S.Add('            "tag": "XRayGUI_API"');
    S.Add('        },');
    //DNS
    S.Add('        "dns": {');
    S.Add('        "servers": [');
    S.Add('            "1.1.1.1",');
    S.Add('            "8.8.8.8",');
    S.Add('            "9.9.9.9"');
    S.Add('        ]');
    S.Add('    },');
    S.Add('        "inbounds": [');
    S.Add('            {');
    S.Add('                "listen": "127.0.0.1",');
    //LOCAL PORT
    S.Add('                "port": ' + PORT + ',');
    S.Add('                "protocol": "socks",');
    S.Add('                "settings": {');
    S.Add('                    "auth": "noauth",');
    S.Add('                    "ip": "127.0.0.1",');
    S.Add('                    "udp": true');
    S.Add('                },');
    S.Add('                "sniffing": {');
    S.Add('                },');
    S.Add('                "tag": "socks_IN"');
    S.Add('            }');
    S.Add('        ],');
    S.Add('        "log": {');
    //LOGLEVEL
    S.Add('            "loglevel": "info"');
    S.Add('        },');
    S.Add('        "outbounds": [');
    S.Add('            {');
    S.Add('                "protocol": "shadowsocks",');
    S.Add('                "sendThrough": "0.0.0.0",');
    S.Add('                "settings": {');
    S.Add('                    "servers": [');
    S.Add('                        {');
    //SERVER_ADDRESS
    S.Add('                            "address": "' + SSDecode(SSURL, 2) + '",');
    //METHOD
    S.Add('                            "method": "' + SSDecode(SSURL, 0) + '",');
    //PASSWORD
    S.Add('                            "password": "' + SSDecode(SSURL, 1) + '",');
    //SERVER_PORT
    S.Add('                            "port": ' + SSDecode(SSURL, 3));
    S.Add('                        }');
    S.Add('                    ]');
    S.Add('                },');
    S.Add('                "streamSettings": {');
    S.Add('                },');
    S.Add('                "tag": "PROXY"');
    S.Add('            },');
    S.Add('            {');
    S.Add('                "protocol": "freedom",');
    S.Add('                "sendThrough": "0.0.0.0",');
    S.Add('                "settings": {');
    S.Add('                    "domainStrategy": "AsIs",');
    S.Add('                    "redirect": ":0"');
    S.Add('                },');
    S.Add('                "streamSettings": {');
    S.Add('                },');
    S.Add('                "tag": "DIRECT"');
    S.Add('            },');
    S.Add('            {');
    S.Add('                "protocol": "blackhole",');
    S.Add('                "sendThrough": "0.0.0.0",');
    S.Add('                "settings": {');
    S.Add('                    "response": {');
    S.Add('                        "type": "none"');
    S.Add('                    }');
    S.Add('                },');
    S.Add('                "streamSettings": {');
    S.Add('                },');
    S.Add('                "tag": "BLACKHOLE"');
    S.Add('            }');
    S.Add('        ],');
    S.Add('        "policy": {');
    S.Add('            "system": {');
    S.Add('                "statsInboundDownlink": true,');
    S.Add('                "statsInboundUplink": true,');
    S.Add('                "statsOutboundDownlink": true,');
    S.Add('                "statsOutboundUplink": true');
    S.Add('            }');
    S.Add('        },');
    S.Add('        "routing": {');
    S.Add('            "domainMatcher": "mph",');
    S.Add('            "domainStrategy": "",');
    S.Add('            "rules": [');
    S.Add('                {');
    S.Add('                    "inboundTag": [');
    S.Add('                        "XRayGUI_API_INBOUND"');
    S.Add('                    ],');
    S.Add('                    "outboundTag": "XRayGUI_API",');
    S.Add('                    "type": "field"');
    S.Add('                },');
    S.Add('                {');
    S.Add('                    "ip": [');
    S.Add('                        "geoip:private"');
    S.Add('                    ],');
    S.Add('                    "outboundTag": "DIRECT",');
    S.Add('                    "type": "field"');
    S.Add('                },');
    S.Add('                {');
    S.Add('                    "ip": [');
    S.Add('                        "geoip:cn"');
    S.Add('                    ],');
    S.Add('                    "outboundTag": "DIRECT",');
    S.Add('                    "type": "field"');
    S.Add('                },');
    S.Add('                {');
    S.Add('                    "domain": [');
    S.Add('                        "geosite:cn"');
    S.Add('                    ],');
    S.Add('                    "outboundTag": "DIRECT",');
    S.Add('                    "type": "field"');
    S.Add('                }');
    S.Add('            ]');
    S.Add('        },');
    S.Add('        "stats": {');
    S.Add('        }');
    S.Add('    }');

    //Сохранение готового конфига
    S.SaveToFile(SAVEPATH);
  finally
    S.Free;
  end;
end;

//VLESS - Декодирование/Нормализация/Поиск
function TMainForm.VLESSDecode(URL, val: string): string;
const
  URISeparator = '@#&?';
var
  U: TURI;
  ch: char;
  posc, skip, i: integer;
  S: TStringList;
begin
  try
    S := TStringList.Create;
    Result := '';

    //Нормализация URL; Убираем переводы строк
    URL := StringReplace(URL, #13#10, '', [rfReplaceAll, rfIgnoreCase]);
    //Убираем пробелы
    URL := StringReplace(URL, ' ', '', [rfReplaceAll, rfIgnoreCase]);
    //Убираем кавычки
    URL := StringReplace(URL, '"', '', [rfReplaceAll, rfIgnoreCase]);

    //Декодируем и парсим URL (stage-1)
    U := URIParser.ParseURI(URL, True);

    case val of
      'id': Result := U.Username;
      'server': Result := U.Host;
      'port': Result := IntToStr(U.Port);
      'comment': Result := U.Bookmark;
    end;

    if Result = '' then
    begin
      //Stage-2; Остальные вводные: security, type, encryption, path; Декодируем URL
      posc := 0;
      skip := 0;

      //URI Decoder
      for ch in URL do
      begin
        if skip = 0 then
        begin
          if (ch = '%') and (posc < URL.length - 2) then
          begin
            skip := 2;
            Result := Result + ansichar(Hex2Dec('$' + URL[posc + 2] + URL[posc + 3]));
          end
          else
          begin
            Result := Result + ch;
          end;
        end
        else
        begin
          skip := skip - 1;
        end;
        posc := posc + 1;
      end;

      //Result=Decode URI (усекаем)
      Result := Trim(Copy(Result, 9, Length(Result)));

      //Символы = заменяем на :
      Result := StringReplace(Result, '=', ':', [rfReplaceAll, rfIgnoreCase]);

      //Заменяем символы URI-сепаратора на ','
      for i := 1 to Length(Result) do
        if Pos(Result[i], URISeparator) > 0 then
          Result[i] := ',';

      //Грузим линейный текст
      S.Text := Result;

      //Разделяем значения на Items по (,)
      S.Delimiter := ',';
      S.StrictDelimiter := True;
      S.DelimitedText := S[0];

      //Поиск соответствия
      for i := 0 to S.Count - 1 do
        if Copy(S[i], 1, Pos(':', S[i]) - 1) = val then
        begin
          Result := Copy(S[i], Pos(':', S[i]) + 1, Length(S[i]));
          Break;
        end
        else
          Result := 'none';
    end;

  finally
    S.Free;
  end;
end;

//VLESS - Создать и сохранить ~./config/xraygui/config.json
procedure TMainForm.CreateVLESSConfig(VLESSURL, PORT, SAVEPATH: string);
var
  S: TStringList;
begin
  try
    S := TStringList.Create;

    S.Add('    {');
    S.Add('        "api": {');
    S.Add('            "services": [');
    S.Add('                "ReflectionService",');
    S.Add('                "HandlerService",');
    S.Add('                "LoggerService",');
    S.Add('                "StatsService"');
    S.Add('            ],');
    S.Add('            "tag": "XRayGUI_API"');
    S.Add('        },');
    S.Add('        "dns": {');
    S.Add('            "servers": [');
    S.Add('                "1.1.1.1",');
    S.Add('                "8.8.8.8",');
    S.Add('                "9.9.9.9"');
    S.Add('            ]');
    S.Add('        },');
    S.Add('        "inbounds": [');
    S.Add('            {');
    S.Add('                "listen": "127.0.0.1",');
    //LOCAL_PORT
    S.Add('                "port": ' + PORT + ',');
    S.Add('                "protocol": "socks",');
    S.Add('                "settings": {');
    S.Add('                    "auth": "noauth",');
    S.Add('                    "ip": "127.0.0.1",');
    S.Add('                    "udp": true');
    S.Add('                },');
    S.Add('                "sniffing": {');
    S.Add('                },');
    S.Add('                "tag": "socks_IN"');
    S.Add('            }');
    S.Add('        ],');
    S.Add('        "log": {');
    S.Add('            "loglevel": "info"');
    S.Add('        },');
    S.Add('        "outbounds": [');
    S.Add('            {');
    S.Add('                "protocol": "vless",');
    S.Add('                "settings": {');
    S.Add('                    "vnext": [');
    S.Add('                        {');
    //SERVER
    S.Add('                            "address": "' +
      VlessDecode(VLESSURL, 'server') + '",');
    //PORT
    S.Add('                            "port": ' + VlessDecode(VLESSURL, 'port') + ',');
    S.Add('                            "users": [');
    S.Add('                                {');
    //ENCRYPTION
    S.Add('                                    "encryption": "' +
      VlessDecode(VLESSURL, 'encryption') + '",');
    //ID
    S.Add('                                    "id": "' +
      VlessDecode(VLESSURL, 'id') + '"');
    S.Add('                                }');
    S.Add('                            ]');
    S.Add('                        }');
    S.Add('                    ]');
    S.Add('                },');
    S.Add('                "streamSettings": {');
    //TYPE
    S.Add('                    "network": "' + VlessDecode(VLESSURL, 'type') + '",');
    //SECURITY
    S.Add('                    "security": "' + VlessDecode(VLESSURL,
      'security') + '",');
    S.Add('                    "tlsSettings": {');
    S.Add('                        "disableSystemRoot": false,');
    //SERVER
    S.Add('                        "serverName": "' +
      VlessDecode(VLESSURL, 'server') + '"');
    S.Add('                    },');
    S.Add('                    "wsSettings": {');
    S.Add('                        "headers": {');
    //SERVER-HOST
    S.Add('                            "Host": "' +
      VlessDecode(VLESSURL, 'server') + '"');
    S.Add('                        },');
    //PATH
    S.Add('                        "path": "' + VlessDecode(VLESSURL, 'path') + '"');
    S.Add('                    },');
    S.Add('                    "xtlsSettings": {');
    S.Add('                        "disableSystemRoot": false');
    S.Add('                    }');
    S.Add('                },');
    S.Add('                "tag": "xtndhxcnmdxhdjn"');
    S.Add('            },');
    S.Add('            {');
    S.Add('                "protocol": "freedom",');
    S.Add('                "sendThrough": "0.0.0.0",');
    S.Add('                "settings": {');
    S.Add('                    "domainStrategy": "AsIs",');
    S.Add('                    "redirect": ":0"');
    S.Add('                },');
    S.Add('                "streamSettings": {');
    S.Add('                },');
    S.Add('                "tag": "DIRECT"');
    S.Add('            },');
    S.Add('            {');
    S.Add('                "protocol": "blackhole",');
    S.Add('                "sendThrough": "0.0.0.0",');
    S.Add('                "settings": { ');
    S.Add('                    "response": { ');
    S.Add('                        "type": "none"');
    S.Add('                    }');
    S.Add('                },');
    S.Add('                "streamSettings": {');
    S.Add('                },');
    S.Add('                "tag": "BLACKHOLE"');
    S.Add('            }');
    S.Add('        ],');
    S.Add('        "policy": {');
    S.Add('            "system": {');
    S.Add('                "statsInboundDownlink": true,');
    S.Add('                "statsInboundUplink": true,');
    S.Add('                "statsOutboundDownlink": true,');
    S.Add('                "statsOutboundUplink": true');
    S.Add('            }');
    S.Add('        },');
    S.Add('        "routing": {');
    S.Add('            "domainMatcher": "mph",');
    S.Add('            "domainStrategy": "",');
    S.Add('            "rules": [');
    S.Add('                {');
    S.Add('                    "inboundTag": [');
    S.Add('                        "XRayGUI_API_INBOUND"');
    S.Add('                    ],');
    S.Add('                    "outboundTag": "XRayGUI_API",');
    S.Add('                    "type": "field"');
    S.Add('                },');
    S.Add('                {');
    S.Add('                    "ip": [');
    S.Add('                        "geoip:private"');
    S.Add('                    ],');
    S.Add('                    "outboundTag": "DIRECT",');
    S.Add('                    "type": "field"');
    S.Add('                },');
    S.Add('                {');
    S.Add('                    "ip": [');
    S.Add('                        "geoip:cn"');
    S.Add('                    ],');
    S.Add('                    "outboundTag": "DIRECT",');
    S.Add('                    "type": "field"');
    S.Add('                },');
    S.Add('                {');
    S.Add('                    "domain": [');
    S.Add('                        "geosite:cn"');
    S.Add('                    ],');
    S.Add('                    "outboundTag": "DIRECT",');
    S.Add('                    "type": "field"');
    S.Add('                }');
    S.Add('            ]');
    S.Add('        },');
    S.Add('        "stats": {');
    S.Add('        }');
    S.Add('    }');

    //Сохранение готового конфига
    S.SaveToFile(SAVEPATH);
  finally
  end;
end;

//TROJAN - Декодирование/Нормализация/Поиск
function TMainForm.TrojanDecode(URL, val: string): string;
var
  U: TURI;
begin
  try
    Result := '';
    //Нормализация URL; Убираем переводы строк
    URL := StringReplace(URL, #13#10, '', [rfReplaceAll, rfIgnoreCase]);
    //Убираем пробелы
    URL := StringReplace(URL, ' ', '', [rfReplaceAll, rfIgnoreCase]);
    //Убираем кавычки
    URL := StringReplace(URL, '"', '', [rfReplaceAll, rfIgnoreCase]);

    //Декодируем и парсим URL (stage-1)
    U := URIParser.ParseURI(URL, True);

    case val of
      'id': Result := U.Username;
      'server': Result := U.Host;
      'port': Result := IntToStr(U.Port)
      else
        Result := 'none';
    end;
  except;
    Abort;
  end;
end;

//TROJAN - Создать и сохранить ~./config/xraygui/config.json
procedure TMainForm.CreateTrojanConfig(TROJANURL, PORT, SAVEPATH: string);
var
  S: TStringList;
begin
  try
    S := TStringList.Create;
    S.Add('    {');
    S.Add('      "log": {');
    S.Add('        "access": "",');
    S.Add('        "error": "",');
    S.Add('        "loglevel": "info"');
    S.Add('      },');
    //DNS
    S.Add('        "dns": {');
    S.Add('        "servers": [');
    S.Add('            "1.1.1.1",');
    S.Add('            "8.8.8.8",');
    S.Add('            "9.9.9.9"');
    S.Add('        ]');
    S.Add('    },');

    S.Add('      "inbounds": [');
    S.Add('        {');
    S.Add('          "tag": "socks",');
    //PORT
    S.Add('          "port": ' + PORT + ',');
    S.Add('          "listen": "127.0.0.1",');
    S.Add('          "protocol": "socks",');
    S.Add('          "sniffing": {');
    S.Add('            "enabled": true,');
    S.Add('            "destOverride": [');
    S.Add('              "http",');
    S.Add('              "tls"');
    S.Add('            ]');
    S.Add('          },');
    S.Add('          "settings": {');
    S.Add('            "auth": "noauth",');
    S.Add('            "udp": true,');
    S.Add('            "allowTransparent": false');
    S.Add('          }');
    S.Add('        },');
    S.Add('        {');
    S.Add('          "tag": "http",');
    //HTTP PORT + 1
    S.Add('          "port": ' + IntToStr(PortEdit.Value + 1) + ',');
    S.Add('          "listen": "127.0.0.1",');
    S.Add('          "protocol": "http",');
    S.Add('          "sniffing": { ');
    S.Add('            "enabled": true,');
    S.Add('            "destOverride": [');
    S.Add('              "http",');
    S.Add('              "tls"');
    S.Add('            ]');
    S.Add('          },');
    S.Add('          "settings": {');
    S.Add('            "auth": "noauth",');
    S.Add('            "udp": true,');
    S.Add('            "allowTransparent": false');
    S.Add('          }');
    S.Add('        }');
    S.Add('      ],');
    S.Add('      "outbounds": [');
    S.Add('        {');
    S.Add('          "tag": "proxy",');
    S.Add('          "protocol": "trojan",');
    S.Add('          "settings": {');
    S.Add('            "servers": [');
    S.Add('              {');
    //SERVER
    S.Add('                "address": "' + TrojanDecode(TrojanURL, 'server') + '",');
    S.Add('                "method": "chacha20",');
    S.Add('                "ota": false,');
    //ID
    S.Add('                "password": "' + TrojanDecode(TrojanURL, 'id') + '",');
    //PORT
    S.Add('                "port": ' + TrojanDecode(TrojanURL, 'port') + ',');
    S.Add('                "level": 1,');
    S.Add('                "flow": ""');
    S.Add('              }');
    S.Add('            ]');
    S.Add('          },');
    S.Add('          "streamSettings": {');
    S.Add('            "network": "tcp",');
    S.Add('            "security": "tls",');
    S.Add('            "tlsSettings": {');
    S.Add('              "allowInsecure": false');
    S.Add('            }');
    S.Add('          },');
    S.Add('          "mux": {');
    S.Add('            "enabled": false,');
    S.Add('            "concurrency": -1');
    S.Add('          }');
    S.Add('        },');
    S.Add('        {');
    S.Add('          "tag": "direct",');
    S.Add('          "protocol": "freedom",');
    S.Add('          "settings": {}');
    S.Add('        },');
    S.Add('        {');
    S.Add('          "tag": "block",');
    S.Add('          "protocol": "blackhole",');
    S.Add('          "settings": {');
    S.Add('            "response": {');
    S.Add('              "type": "http"');
    S.Add('            }');
    S.Add('          }');
    S.Add('        }');
    S.Add('      ],');
    S.Add('      "routing": {');
    S.Add('        "domainStrategy": "IPIfNonMatch",');
    S.Add('        "domainMatcher": "linear",');
    S.Add('        "rules": [');
    S.Add('          {');
    S.Add('            "type": "field",');
    S.Add('            "inboundTag": [');
    S.Add('              "api"');
    S.Add('            ],');
    S.Add('            "outboundTag": "api",');
    S.Add('            "enabled": true');
    S.Add('          },');
    S.Add('          {');
    S.Add('            "type": "field",');
    S.Add('            "outboundTag": "direct",');
    S.Add('            "domain": [');
    S.Add('              "domain:example-example.com",');
    S.Add('              "domain:example-example2.com"');
    S.Add('            ],');
    S.Add('            "enabled": true');
    S.Add('          },');
    S.Add('          {');
    S.Add('            "type": "field",');
    S.Add('            "outboundTag": "block",');
    S.Add('            "domain": [');
    S.Add('              "geosite:category-ads-all"');
    S.Add('            ],');
    S.Add('            "enabled": true');
    S.Add('          },');
    S.Add('          {');
    S.Add('            "type": "field",');
    S.Add('            "outboundTag": "direct",');
    S.Add('            "domain": [');
    S.Add('              "geosite:cn"');
    S.Add('            ],');
    S.Add('            "enabled": true');
    S.Add('          },');
    S.Add('          {');
    S.Add('            "type": "field",');
    S.Add('            "outboundTag": "direct",');
    S.Add('            "ip": [');
    S.Add('              "geoip:private",');
    S.Add('              "geoip:cn"');
    S.Add('            ],');
    S.Add('            "enabled": true');
    S.Add('          },');
    S.Add('          {');
    S.Add('            "type": "field",');
    S.Add('            "port": "0-65535",');
    S.Add('            "outboundTag": "proxy",');
    S.Add('            "enabled": true');
    S.Add('          }');
    S.Add('        ]');
    S.Add('      }');
    S.Add('    }');

    //Сохранение готового конфига
    S.SaveToFile(SAVEPATH);
  finally
  end;
end;

//Останов
procedure TMainForm.StopBtnClick(Sender: TObject);
begin
  //Снять все чекбоксы
  ConfigBox.CheckAll(cbUnChecked);
  //Запомнить, что был останов (findex=100)
  INIPropStorage1.StoredValue['findex'] := '100';
  INIPropStorage1.Save;

  //Останавливаем XRay и удаляем лог чтобы не копить размер
  StartProcess('while [[ $(ss -ltn | grep ' + PortEdit.Text +
    ') ]]; do killall xray; sleep 1; done; ' +
    '> /home/$LOGNAME/.config/xraygui/xraygui.log');
end;

//Вставка нового URL...
procedure TMainForm.PasteBtnClick(Sender: TObject);
begin
  //Только VMESS (поверка)
  if (ClipBoard.AsText = '') or (Copy(Clipboard.AsText, 1, 8) <> 'vmess://') and
    (Copy(ClipBoard.AsText, 1, 8) <> 'vless://') and
    (Copy(ClipBoard.AsText, 1, 5) <> 'ss://') and
    (Copy(ClipBoard.AsText, 1, 9) <> 'trojan://') or
    (Pos('obfs', Clipboard.AsText) <> 0) then
  begin
    MessageDlg(SVmessOnlyMsg, mtWarning, [mbOK], 0);
    Exit;
  end;

  //Совпадение в списке - курсор на существующую позицию
  if ConfigBox.Items.IndexOf(Trim(ClipBoard.AsText)) <> -1 then
  begin
    ConfigBox.ItemIndex := ConfigBox.Items.IndexOf(Trim(ClipBoard.AsText));
    Exit;
  end;

  //Добавляем новый URL вниз
  ConfigBox.Items.Append(Trim(ClipBoard.AsText));
  ConfigBox.ItemIndex := ConfigBox.Count - 1;
  ConfigBox.Click;
  //Сохраняем новый список
  ConfigBox.Items.SaveToFile(GetUserDir + '.config/xraygui/configlist');
  //Проверяем статус панелей и кнопок
  ButtonStatus;
end;

procedure TMainForm.PopupMenu1Popup(Sender: TObject);
begin
  if ConfigBox.Count = 0 then SaveItem.Enabled := False
  else
    SaveItem.Enabled := True;
end;

procedure TMainForm.SaveItemClick(Sender: TObject);
begin
  if SaveDialog1.Execute then ConfigBox.Items.SaveToFile(SaveDialog1.FileName);
end;

//Выбрать все записи в списке конфигураций
procedure TMainForm.SelAllBtnClick(Sender: TObject);
begin
  ConfigBox.SelectAll;
end;

//Запуск прокси (XRay)
procedure TMainForm.StartBtnClick(Sender: TObject);
begin
  //От двойного клика если список пуст
  if ConfigBox.Count = 0 then Exit;

  ConfigBox.CheckAll(cbUnChecked);
  ConfigBox.Checked[ConfigBox.ItemIndex] := True;
  INIPropStorage1.StoredValue['findex'] := IntToStr(ConfigBox.ItemIndex);
  INIPropStorage1.Save;

  if Pos('vmess://', ConfigBox.Items[ConfigBox.ItemIndex]) > 0 then
    //VMESS - Создаём/Сохраняем config.json для xray
    CreateVMESSConfig(ConfigBox.Items[ConfigBox.ItemIndex], PortEdit.Text,
      GetUserDir + '.config/xraygui/config.json')
  else
  if Pos('vless://', ConfigBox.Items[ConfigBox.ItemIndex]) > 0 then
    //VLESS - Создаём/Сохраняем config.json для xray
    CreateVLESSConfig(ConfigBox.Items[ConfigBox.ItemIndex], PortEdit.Text,
      GetUserDir + '.config/xraygui/config.json')
  else
  if Pos('ss://', ConfigBox.Items[ConfigBox.ItemIndex]) > 0 then
    //SS - Создаём/Сохраняем config.json для xray
    CreateSSConfig(ConfigBox.Items[ConfigBox.ItemIndex], PortEdit.Text,
      GetUserDir + '.config/xraygui/config.json')
  else
    CreateTrojanConfig(ConfigBox.Items[ConfigBox.ItemIndex], PortEdit.Text,
      GetUserDir + '.config/xraygui/config.json');

  //Быстрая очистка вывода перед стартом
  LogMemo.Clear;

  //Старт XRay: Завершаем предыдущий и выводим лог (каждый запуск - новый лог)
  SetCurrentDir(ExtractFilePath(Application.ExeName));
  StartProcess('killall xray; cd ./xray; ' +
    'nohup ./xray -config=/home/$LOGNAME/.config/xraygui/config.json > ' +
    '~/.config/xraygui/xraygui.log &');
end;

//Создание формы
procedure TMainForm.FormCreate(Sender: TObject);
var
  FPortScanThread: TThread;
begin
  MainForm.Caption := Application.Title;

  //Директория ссылок Автозапуска
  if not DirectoryExists(GetUserDir + '.config/autostart') then
    MkDir(GetUserDir + '.config/autostart');

  //Рабочая директория (конфигурации + лог)
  if not DirectoryExists(GetUserDir + '.config/xraygui') then
    MkDir(GetUserDir + '.config/xraygui');

  //Файл настроек формы
  IniPropStorage1.IniFileName := GetUserDir + '.config/xraygui/xraygui.ini';

  //Загрузка списка конфигураций из файла если есть
  if FileExists(GetUserDir + '.config/xraygui/configlist') then
    ConfigBox.Items.LoadFromFile(GetUserDir + '.config/xraygui/configlist');

  //Получаем FileName (фиксация); ActiveControl = ConfigBox
  ConfigBox.Click;

    //Поток проверки состояния
  FPortScanThread := PortScan.Create(False);
  FPortScanThread.Priority := tpNormal;
end;

//Удаление выбранных конфигураций из писка
procedure TMainForm.DeleteBtnClick(Sender: TObject);
var
  i: integer;
begin
  if MessageDlg(SDeleteMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then

  begin
    with ConfigBox do
    begin
      for i := -1 + Items.Count downto 0 do
        if (Selected[i]) and (ConfigBox.Checked[i] = False) then
          ConfigBox.Items.Delete(i);
    end;

    //Сохранение нового списка
    ConfigBox.Items.SaveToFile(GetUserDir + '.config/xraygui/configlist');

    if ConfigBox.Count <> 0 then
    begin
      ConfigBox.ItemIndex := 0;
      ConfigBox.Click;
    end
    else
    begin
      //Список пуст = удаляем ярлык автозагрузки
      DeleteFile(GetUserDir + '.config/autostart/xray.desktop');
      AutoStartBox.Checked := CheckAutoStart;
    end;
  end;

  //Запоминаем позицию чекера
  if ConfigBox.Count = 0 then
    INIPropStorage1.StoredValue['findex'] := '100' //UnCheck = 100
  else
    INIPropStorage1.StoredValue['findex'] := IntToStr(ConfigBox.ItemIndex);
  INIPropStorage1.Save;

  ButtonStatus;
end;

//Исключаем включение всех кроме одного чекера
procedure TMainForm.ConfigBoxClickCheck(Sender: TObject);
begin
  ConfigBox.CheckAll(cbUnchecked, False, False);
  if IniPropStorage1.ReadInteger('findex', 100) <> 100 then
    ConfigBox.Checked[IniPropStorage1.ReadInteger('findex', 100)] := True;
end;

//Файл-флаг автоочистки кеша и кукисов
procedure TMainForm.ClearBoxChange(Sender: TObject);
var
  S: ansistring;
begin
  if not ClearBox.Checked then
    RunCommand('/bin/bash', ['-c', 'rm -f ~/.config/xraygui/clear'], S)
  else
    RunCommand('/bin/bash', ['-c', 'touch ~/.config/xraygui/clear'], S);
end;

//Автостарт
procedure TMainForm.AutoStartBoxChange(Sender: TObject);
var
  S: ansistring;
begin
  if not AutoStartBox.Checked then
    RunCommand('/bin/bash', ['-c', 'rm -f ~/.config/autostart/xray.desktop'], S)
  else
    RunCommand('/bin/bash', ['-c',
      'cp -f /usr/share/xraygui/xray.desktop ~/.config/autostart/xray.desktop'], S);
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  //Масштабирование для Plasma
  IniPropStorage1.Save;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  FShowLogTRD: TThread;
begin
  //Масштабирование для Plasma
  IniPropStorage1.Restore;
  ConfigBox.Click;

  ButtonStatus;
  ClearBox.Checked := CheckClear;
  AutoStartBox.Checked := CheckAutoStart;

  //Процесс непрерывного чтения лога
  FShowLogTRD := ShowLogTRD.Create(False);
  FShowLogTRD.Priority := tpNormal;
end;

//Восстанавливаем индекс Check
procedure TMainForm.IniPropStorage1RestoreProperties(Sender: TObject);
begin
  if IniPropStorage1.ReadInteger('findex', 100) <> 100 then
    ConfigBox.Checked[IniPropStorage1.ReadInteger('findex', 100)] := True;
end;

//Загрузка/Нормализация/Валидация на vmess://...
procedure TMainForm.LoadItemClick(Sender: TObject);
var
  i: integer;
  S: TStringList;
begin
  S := TStringList.Create;

  if OpenDialog1.Execute then
  begin
    S.LoadFromFile(OpenDialog1.FileName);

    //Нормализация списка
    for i := S.Count - 1 downto 0 do
    begin
      S[i] := Trim(S[i]);
      if S[i] = '' then S.Delete(i);
    end;

    //Проверяем на валидность (vmess://...)
    for i := 0 to S.Count - 1 do
    begin
      if (Copy(S[i], 1, 8) <> 'vmess://') and (Copy(S[i], 1, 8) <> 'vless://') and
        (Copy(S[i], 1, 5) <> 'ss://') and (Copy(S[i], 1, 9) <> 'trojan://') or
        (Pos('obfs', S[i]) <> 0) then
      begin
        MessageDlg(SNotValidMsg, mtWarning, [mbOK], 0);
        S.Free;
        EXit;
      end;
    end;

    //Создаём новый список конфигураций
    ConfigBox.Items.Assign(S);
    ConfigBox.Items.SaveToFile(GetUserDir + '.config/xraygui/configlist');
    ButtonStatus;

    //Фиксация
    if ConfigBox.Count <> 0 then ConfigBox.ItemIndex := 0;

    S.Free;
  end;
end;

//Вставить из буфера
procedure TMainForm.PasteItemClick(Sender: TObject);
begin
  PasteBtn.Click;
end;

//Одинаковая высота левой и правой панелей при изменении
procedure TMainForm.Panel1Resize(Sender: TObject);
begin
  Panel2.Height := Panel1.Height;
end;

//Одинаковая высота левой и правой панелей при изменении
procedure TMainForm.Panel2Resize(Sender: TObject);
begin
  Panel1.Height := Panel2.Height;
end;

end.
