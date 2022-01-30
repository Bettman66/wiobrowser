unit uwionoweb;

{$MODE Delphi}

interface

uses
  SysUtils, Variants, Classes, Graphics, Forms, Controls, Dialogs,
  ExtCtrls, ComCtrls, Windows, comobj, StrUtils, UniqueInstance,
  INIFiles, lNetComponents, lNet, utools, umessage;

type

  { TMainForm }

  TMainForm = class(TForm)
    Server: TLTCPComponent;
    Timer3: TTimer;
    Timer2: TTimer;
    TrayIcon1: TTrayIcon;
    UniqueInstance1: TUniqueInstance;
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ServerReceive(aSocket: TLSocket);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure CreateMessage(var s: TStringArray);
  private
    { Private declarations }
  protected

  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  Port: integer;
  mFont: integer;
  mColor: string;
  mTop: integer;
  mLeft: integer;
  mute: TMyBool;
  vol: single;

const
  WM_SYSCOMMAND = 274;
  SC_MONITORPOWER = 61808;

implementation

{$R *.lfm}

uses
  MouseAndKeyInput;

procedure TMainForm.ServerReceive(aSocket: TLSocket);
var
  Message: string;
  s: TStringArray;
  newstr: string = '';
  i: integer;
  SavedCW: word;
  SpVoice: variant;
begin
  aSocket.GetMessage(Message);
  try
    s := ParseStrToArray(Message, '|');
    if Length(s) > 0 then
    begin
      case IndexStr(s[0], ['sendUrl', 'zoom', 'screenon', 'screenoff',
          'message', 'close', 'command', 'config', 'brightness',
          'texttospeech', 'volume', 'mute']) of
        2:
          if s[1] = 'true' then
            MouseInput.Move([], MainForm, MainForm.Width, 0, 1);
        3:
          if s[1] = 'true' then
            SendMessage(Self.Handle, WM_SYSCOMMAND, SC_MONITORPOWER, 2);
        4:
          CreateMessage(s);
        5:
          Application.Terminate;
        6:
          if s[1] = 'reboot' then
            funExitWindows(reboot)
          else
          if s[1] = 'shutdown' then
            funExitWindows(shutdown)
          else
          begin
            if Length(s) > 2 then
            begin
              for i := 2 to Length(s) - 1 do
                newstr := newstr + s[i] + ' ';
              ShellExecute(Self.Handle, 'open', PChar(string(s[1])),
                PChar(newstr), nil, 1);
            end
            else
              ShellExecute(Self.Handle, 'open', PChar(string(s[1])), nil, nil, 1);
          end;
        7:
        begin
          mTop := StrToInt(s[1]);
          mLeft := StrToInt(s[2]);
          MessageForm.Color := WebColorStrToColor(s[3]);
          MessageForm.Label1.Font.Size := StrToInt(s[4]);
          MessageForm.Label2.Font.Size := StrToInt(s[4]);
          MessageForm.Label3.Font.Size := StrToInt(s[4]);
          MessageForm.AlphaBlendValue := StrToInt(s[5]);
          Server.SendMessage('{"TYP":"HOST","HOST":"' + GetHostname + '"}');
          Server.SendMessage('{"TYP":"IP","IP":"' + aSocket.LocalAddress + '"}');
        end;
        8:
          SetBrightness(1, byte(StrToInt(s[1])));
        9:
        begin
          SpVoice := CreateOleObject('SAPI.SpVoice');
          // Change FPU interrupt mask to avoid SIGFPE exceptions
          SavedCW := Get8087CW;
          try
            timer3.Enabled := False;
            Set8087CW(SavedCW or $4);
            if mute = myTrue then
            begin
              SetMasterMute(myFalse);
              if Server.Connected then
                Server.SendMessage('{"TYP":"MUTE","MUTE":"FALSE"}');
            end;
            SpVoice.Speak(s[1], 0);
            if mute = myTrue then
            begin
              SetMasterMute(myTrue);
              if Server.Connected then
                Server.SendMessage('{"TYP":"MUTE","MUTE":"TRUE"}');
            end;
            timer3.Enabled := True;
          finally
            // Restore FPU mask
            Set8087CW(SavedCW);
          end;
        end;
        10:
        begin
          timer3.Enabled := False;
          vol := 0.01 * StrToInt(s[1]);
          SetMasterVolume(vol);
          timer3.Enabled := True;
        end;
        11:
        begin
          timer3.Enabled := False;
          if s[1] = 'true' then
            mute := myTrue
          else
            mute := myFalse;
          SetMasterMute(mute);
          timer3.Enabled := True;
        end
        else
          ShowMessage(s[0] + ' -> Unbekannte Nachricht von ioBroker !');
      end;
    end;
  except
    ShowMessage('Error');
  end;
end;

procedure TMainForm.Timer2Timer(Sender: TObject);
begin
  if Server.Connected then
  begin
    Server.SendMessage('{"TYP":"BATTERY","BATTERY":"' + WMIGen_Win32_Battery + '"}');
    Server.SendMessage('{"TYP":"CPU","CPU":"' + WMIGen_Win32_Processor + '"}');
    Server.SendMessage('{"TYP":"MEMORY","MEMORY":"' +
      WMIGen_Win32_OperatingSystem + '"}');
  end;
end;

procedure TMainForm.Timer3Timer(Sender: TObject);
var
  dummy: single;
  i: integer;
  mut: TMyBool;
begin
  GetMasterVolume(dummy);
  if vol <> dummy then
  begin
    i := trunc(dummy * 100);
    if Server.Connected then
      Server.SendMessage('{"TYP":"VOLUME","VOLUME":"' + IntToStr(i) + '"}');
  end;
  vol := dummy;
  mut := GetMasterMute;
  if mut <> mute then
  begin
    if (mut = myTrue) and (Server.Connected) then
      Server.SendMessage('{"TYP":"MUTE","MUTE":"TRUE"}');
    if (mut = myFalse) and Server.Connected then
      Server.SendMessage('{"TYP":"MUTE","MUTE":"FALSE"}');
  end;
  mute := mut;
end;

procedure TMainForm.TrayIcon1DblClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TINIFile.Create('config.ini');
  INI.WriteInteger('tcp', 'Port', Port);
  ini.Free;
  Server.Disconnect(True);
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  ini: TIniFile;
begin
  hide;
  ini := TINIFile.Create('config.ini');
  Port := INI.ReadInteger('tcp', 'Port', 5000);
  ini.Free;
  Server.Listen(Port);
end;

procedure TMainForm.CreateMessage(var s: TStringArray);
begin
  if MessageForm.Label1.Caption = '' then
  begin
    MessageForm.Label1.Caption := s[1] + ' :' + ansistring(#13#10) + s[2];
    MessageForm.Panel1.Visible := True;
    MessageForm.Timer1.Interval := StrToInt(s[3]) * 1000;
    MessageForm.Panel1.Color := WebColorStrToColor(s[4]);
    MessageForm.Timer1.Enabled := True;
    MessageForm.Top := mTop;
    MessageForm.Left := mLeft;
    MessageForm.FormActual;
    MessageForm.Show;
  end
  else if MessageForm.Label2.Caption = '' then
  begin
    MessageForm.Label2.Caption := s[1] + ' :' + ansistring(#13#10) + s[2];
    MessageForm.Panel2.Visible := True;
    MessageForm.Timer2.Interval := StrToInt(s[3]) * 1000;
    MessageForm.Panel2.Color := WebColorStrToColor(s[4]);
    MessageForm.Timer2.Enabled := True;
    MessageForm.Top := mTop;
    MessageForm.Left := mLeft;
    MessageForm.FormActual;
  end
  else if MessageForm.Label3.Caption = '' then
  begin
    MessageForm.Label3.Caption := s[1] + ' :' + ansistring(#13#10) + s[2];
    MessageForm.Panel3.Visible := True;
    MessageForm.Timer3.Interval := StrToInt(s[3]) * 1000;
    MessageForm.Panel3.Color := WebColorStrToColor(s[4]);
    MessageForm.Timer3.Enabled := True;
    MessageForm.Top := mTop;
    MessageForm.Left := mLeft;
    MessageForm.FormActual;
  end;
end;

end.
