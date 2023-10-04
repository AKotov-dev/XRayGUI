unit reality_gen;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Process,
  StdCtrls, Buttons, IniPropStorage, Clipbrd;

type

  { TRealityForm }

  TRealityForm = class(TForm)
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label10: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Memo1: TMemo;
    SaveDialog1: TSaveDialog;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    procedure Edit1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
  private

  public

  end;

var
  RealityForm: TRealityForm;

implementation

uses unit1;

{$R *.lfm}

{ TRealityForm }

procedure TRealityForm.FormShow(Sender: TObject);
begin
  //  IniPropStorage1.Restore;
end;

//Get UUID
procedure TRealityForm.SpeedButton1Click(Sender: TObject);
var
  S: ansistring;
begin
  if RunCommand('bash', ['-c', '~/.config/xraygui/xray/xray uuid'], S) then
    Edit3.Text := Trim(S);
end;

//Get Pub/Priv Keys
procedure TRealityForm.SpeedButton2Click(Sender: TObject);
var
  S: ansistring;
begin
  //Список ключей
  if RunCommand('/bin/bash', ['-c',
    '~/.config/xraygui/xray/xray x25519 | cut -f2 -d":"'], S) then
  begin
    //Private Key
    Edit5.Text := Trim(Copy(S, 0, Pos(#10, S) - 1));
    //Public Key
    Edit4.Text := Trim(Copy(S, Pos(#10, S), Length(S)));
  end;
end;

//Get Sid
procedure TRealityForm.SpeedButton3Click(Sender: TObject);
var
  S: ansistring;
begin
  if RunCommand('/bin/bash', ['-c', 'openssl rand -hex 8'], S) then
    Edit6.Text := Trim(S);
end;

//Однострочная конфигурация клиента в Буфер
procedure TRealityForm.SpeedButton4Click(Sender: TObject);
begin
  Clipboard.AsText := Memo1.Text;
end;

//Save server.json
procedure TRealityForm.SpeedButton5Click(Sender: TObject);
var
  S: TStringList;
begin
  try
    S := TStringList.Create;
    if SaveDialog1.Execute then
    begin
      S.Add('{');
      S.Add('  "log": {');
      S.Add('    "loglevel": "warning"');
      S.Add('  },');
      S.Add('  "routing": {');
      S.Add('    "rules": [],');
      S.Add('    "domainStrategy": "AsIs"');
      S.Add('  },');
      S.Add('  "inbounds": [');
      S.Add('    {');
      S.Add('      "port": ' + Edit2.Text + ',');
      S.Add('      "protocol": "vless",');
      S.Add('      "tag": "vless_tls",');
      S.Add('      "settings": {');
      S.Add('        "clients": [');
      S.Add('          {');
      S.Add('            "id": "' + Edit3.Text + '",');
      S.Add('            "email": "user1@myserver",');
      S.Add('            "flow": "' + ComboBox1.Text + '"');
      S.Add('          }');
      S.Add('        ],');
      S.Add('        "decryption": "none"');
      S.Add('      },');
      S.Add('      "streamSettings": {');
      S.Add('        "network": "tcp",');
      S.Add('        "security": "reality",');
      S.Add('		"realitySettings": {');
      S.Add('			"show": false,');
      S.Add('			"dest": "' + ComboBox2.Text + ':443",');
      S.Add('			"serverNames": [');
      S.Add('				"' + ComboBox2.Text + '"');
      S.Add('			],');
      S.Add('			"privateKey": "' + Edit5.Text + '",');
      S.Add('			"shortIds": [');
      S.Add('				"' + Edit6.Text + '"');
      S.Add('			]');
      S.Add('		}');
      S.Add('      },');
      S.Add('      "sniffing": {');
      S.Add('        "enabled": true,');
      S.Add('        "destOverride": [');
      S.Add('          "http",');
      S.Add('          "tls",');
      S.Add('          "quic"');
      S.Add('        ]');
      S.Add('      }');
      S.Add('    }');
      S.Add('  ],');
      S.Add('  "outbounds": [');
      S.Add('    {');
      S.Add('      "protocol": "freedom",');
      S.Add('      "tag": "direct"');
      S.Add('    },');
      S.Add('    {');
      S.Add('      "protocol": "blackhole",');
      S.Add('      "tag": "block"');
      S.Add('    }');
      S.Add('  ]');
      S.Add('}');
      S.Add('');

      S.SaveToFile(SaveDialog1.FileName);
    end;

  finally
    S.Free;
  end;
end;

procedure TRealityForm.FormCreate(Sender: TObject);
begin
  IniPropStorage1.IniFileName := MainForm.IniPropStorage1.IniFileName;
end;

//Пересоздаём однострочную конфигурацию клиента
procedure TRealityForm.Edit1Change(Sender: TObject);
begin
  Memo1.Text := 'vless://' + Edit3.Text + '@' + Edit1.Text + ':' +
    Edit2.Text + '?encryption=none&flow=' + ComboBox1.Text +
    '&security=reality&sni=' + ComboBox2.Text + '&fp=' + ComboBox3.Text +
    '&pbk=' + Edit4.Text + '&sid=' + Edit6.Text +
    '&type=tcp&headerType=none#VLESS%20West';
end;

end.
