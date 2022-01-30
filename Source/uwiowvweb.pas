unit uwiowvweb;

{$mode Delphi}

interface

uses
  SysUtils, Variants, Classes, Graphics, Forms, Controls,
  Dialogs, ExtCtrls, ComCtrls, Menus, lNetComponents, lNet, StrUtils,
  UniqueInstance, INIFiles, utools, Windows, umessage, comobj, uWVBrowser,
  uWVWindowParent, uWVLoader, uWVBrowserBase, uWVTypeLibrary, uWVTypes;

const
  WH_MOUSE_LL = 14;

type

  { TMainForm }

  TMainForm = class(TForm)
    Server: TLTCPComponent;
    Timer1: TTimer;
    Timer2: TTimer;
    Timer3: TTimer;
    TrayIcon1: TTrayIcon;
    UniqueInstance1: TUniqueInstance;
    WVWindowParent1: TWVWindowParent;
    WVBrowser1: TWVBrowser;
    procedure FormDestroy(Sender: TObject);
    procedure ServerReceive(aSocket: TLSocket);
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure WVBrowser1AfterCreated(Sender: TObject);
    procedure WVBrowser1InitializationError(Sender: TObject;
      aErrorCode: HRESULT; const aErrorMessage: wvstring);
    procedure WVBrowser1NavigationCompleted(Sender: TObject;
      const aWebView: ICoreWebView2;
      const aArgs: ICoreWebView2NavigationCompletedEventArgs);
    procedure StopSlideshow;
    procedure WVBrowser1SourceChanged(Sender: TObject;
      const aWebView: ICoreWebView2;
      const aArgs: ICoreWebView2SourceChangedEventArgs);
    procedure CreateMessage(var s: TStringArray);
  protected

  public

  end;

var
  MainForm: TMainForm;
  HookHandle: cardinal;
  Url: string;
  Port: integer;
  Browser: boolean;
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

function LowLevelMouseProc(nCode: integer; wParam: wParam;
  lParam: lParam): LRESULT; stdcall;
begin
  if (nCode >= 0) then
  begin
    if wParam = WM_LButtonDOWN then
      MainForm.StopSlideshow;
  end;
  Result := CallNextHookEx(HookHandle, nCode, wParam, lParam);
end;

function InstallMouseHook: boolean;
begin
  Result := False;
  if HookHandle = 0 then
  begin
    HookHandle := SetWindowsHookEx(WH_MOUSE_LL, @LowLevelMouseProc, hInstance, 0);
    Result := HookHandle <> 0;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TINIFile.Create('config.ini');
  Url := INI.ReadString('tcp', 'StartURL', 'http://google.de');
  Port := INI.ReadInteger('tcp', 'Port', 5000);
  Browser := INI.ReadBool('tcp', 'Browser', True);
  ini.Free;
  Server.Listen(Port);
  if Browser then
  begin
    InstallMouseHook;
    TrayIcon1.Hide;
    WVBrowser1.DefaultURL := Url;
    Mainform.WindowState := wsFullscreen;
    if GlobalWebView2Loader.InitializationError then
      ShowMessage(UTF8Encode(GlobalWebView2Loader.ErrorMessage))
    else
    if GlobalWebView2Loader.Initialized then
      WVBrowser1.CreateBrowser(WVWindowParent1.Handle)
    else
      Timer1.Enabled := True;
  end
  else
  begin
    Hide;
    TrayIcon1.Show;
  end;
end;

procedure TMainForm.Timer2Timer(Sender: TObject);
begin
  if Server.Connected then
  begin
    Server.SendMessage('{"TYP":"BATTERY","BATTERY":"' + WMIGen_Win32_Battery + '"}');
    Server.SendMessage('{"TYP":"CPU","CPU":"' + WMIGen_Win32_Processor + '"}');
    Server.SendMessage('{"TYP":"MEMORY","MEMORY":"' + WMIGen_Win32_OperatingSystem + '"}');
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

procedure TMainForm.WVBrowser1AfterCreated(Sender: TObject);
begin
  WVWindowParent1.UpdateSize;
end;

procedure TMainForm.StopSlideshow;
begin
  if Server.Connected then
    Server.SendMessage('{"TYP":"EVENT","EVENT":"GOTFOCUS"}');
end;

procedure TMainForm.WVBrowser1SourceChanged(Sender: TObject;
  const aWebView: ICoreWebView2; const aArgs: ICoreWebView2SourceChangedEventArgs);
var
  Uri: pwidechar;
begin
  aWebView.Get_Source(Uri);
  if Server.Connected then
    Server.SendMessage('{"TYP":"URL","URL":"' + UTF8Encode(WVBrowser1.Source) + '"}');
end;

procedure TMainForm.WVBrowser1InitializationError(Sender: TObject;
  aErrorCode: HRESULT; const aErrorMessage: wvstring);
begin
  ShowMessage(UTF8Encode(aErrorMessage));
end;

procedure TMainForm.WVBrowser1NavigationCompleted(Sender: TObject;
  const aWebView: ICoreWebView2;
  const aArgs: ICoreWebView2NavigationCompletedEventArgs);
var
  e: integer;
begin
  aArgs.Get_IsSuccess(e);
  if e <> 1 then
    if Server.Connected then
      Server.SendMessage('{"TYP":"ERROR","ERROR":"TRUE"}');
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;

  if GlobalWebView2Loader.Initialized then
    WVBrowser1.CreateBrowser(WVWindowParent1.Handle)
  else
    Timer1.Enabled := True;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  ini: TIniFile;
begin
  if HookHandle <> 0 then
    UnhookWindowsHookEx(HookHandle);
  ini := TINIFile.Create('config.ini');
  INI.WriteString('tcp', 'StartURL', Url);
  INI.WriteInteger('tcp', 'Port', Port);
  INI.WriteBool('tcp', 'Browser', Browser);
  ini.Free;
  Server.Disconnect(True);
end;

procedure TMainForm.ServerReceive(aSocket: TLSocket);
var
  Message: string;
  s: TStringArray;
  f: double;
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
        0:
          if Browser then
            WVBrowser1.Navigate(s[1]);
        1:
          if Browser then
          begin
            val(s[1], f);
            WVBrowser1.ZoomFactor := f;
          end;
        2:
          if s[1] = 'true' then
            MouseInput.Move([], MainForm, MainForm.Width, 0, 1);
        3:
          if s[1] = 'true' then
            SendMessage(Application.Handle, WM_SYSCOMMAND, SC_MONITORPOWER, 2);
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
          MessageForm.AlphaBlendValue:= StrToInt(s[5]);
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

initialization
  GlobalWebView2Loader := TWVLoader.Create(nil);
  GlobalWebView2Loader.UserDataFolder :=
    UTF8Decode(ExtractFileDir(Application.ExeName) + '\CustomCache');
  GlobalWebView2Loader.StartWebView2;

end.
