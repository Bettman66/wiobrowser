// ************************************************************************
// ***************************** CEF4Delphi *******************************
// ************************************************************************

// CEF4Delphi is based on DCEF3 which uses CEF to embed a chromium-based
// browser in Delphi applications.

// The original license of DCEF3 still applies to CEF4Delphi.

// For more information about CEF4Delphi visit :
//         https://www.briskbard.com/index.php?lang=en&pageid=cef

//        Copyright © 2022 Salvador Diaz Fau. All rights reserved.

// ************************************************************************
// ************ vvvv Original license and comments below vvvv *************
// ************************************************************************
(*
 *                       Delphi Chromium Embedded 3
 *
 * Usage allowed under the restrictions of the Lesser GNU General Public License
 * or alternatively the restrictions of the Mozilla Public License 1.1
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * Unit owner : Henri Gourvest <hgourvest@gmail.com>
 * Web site   : http://www.progdigy.com
 * Repository : http://code.google.com/p/delphichromiumembedded/
 * Group      : http://groups.google.com/group/delphichromiumembedded
 *
 * Embarcadero Technologies, Inc is not permitted to use or redistribute
 * this source code without explicit permission.
 *
 *)

unit uwiochweb;

{$MODE Delphi}

interface

uses
  SysUtils, Variants, Classes, Graphics, Forms, Controls,
  Dialogs, ExtCtrls, ComCtrls, Menus, lNetComponents, lNet, StrUtils,
  UniqueInstance, INIFiles, utools, Windows, umessage, comobj,
  uCEFChromium, uCEFWindowParent, uCEFInterfaces, uCEFTypes, uCEFConstants;

const
  WH_MOUSE_LL = 14;

type

  { TMainForm }

  TMainForm = class(TForm)
    CEFWindowParent1: TCEFWindowParent;
    Chromium1: TChromium;
    Server: TLTCPComponent;
    Timer1: TTimer;
    Timer2: TTimer;
    Timer3: TTimer;
    TrayIcon1: TTrayIcon;
    UniqueInstance1: TUniqueInstance;
    procedure Chromium1AddressChange(Sender: TObject; const browser: ICefBrowser;
      const frame: ICefFrame; const url: ustring);
    procedure Chromium1LoadError(Sender: TObject; const browser: ICefBrowser;
      const frame: ICefFrame; errorCode: TCefErrorCode;
      const errorText, failedUrl: ustring);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Chromium1AfterCreated(Sender: TObject; const browser: ICefBrowser);
    procedure ServerReceive(aSocket: TLSocket);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure Chromium1BeforeClose(Sender: TObject; const browser: ICefBrowser);
    procedure Chromium1Close(Sender: TObject; const browser: ICefBrowser;
      var aAction: TCefCloseBrowserAction);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure StopSlideshow;
    procedure CreateMessage(var s: TStringArray);
  private
    { Private declarations }
  protected
    // Variables to control when can we destroy the form safely
    FCanClose: boolean;  // Set to True in TChromium.OnBeforeClose
    FClosing: boolean;  // Set to True in the CloseQuery event.

    procedure BrowserDestroyMsg(var aMessage: TMessage); message CEF_DESTROY;

  public
    { Public declarations }
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

procedure CreateGlobalCEFApp;

implementation

{$R *.lfm}

uses
  uCEFApplication, MouseAndKeyInput;

// Destruction steps
// =================
// 1. FormCloseQuery sets CanClose to FALSE calls TChromium.CloseBrowser which triggers the TChromium.OnClose event.
// 2. TChromium.OnClose sends a CEFBROWSER_DESTROY message to destroy CEFWindowParent1 in the main thread, which triggers the TChromium.OnBeforeClose event.
// 3. TChromium.OnBeforeClose calls TCEFSentinel.Start, which will trigger TCEFSentinel.OnClose when the renderer processes are closed.
// 4. TCEFSentinel.OnClose sets FCanClose := True and sends WM_CLOSE to the form.

procedure CreateGlobalCEFApp;
begin
  GlobalCEFApp := TCefApplication.Create;
  GlobalCEFApp.cache := 'cache';
  //GlobalCEFApp.LogFile          := 'cef.log';
  //GlobalCEFApp.LogSeverity      := LOGSEVERITY_VERBOSE;
end;

function LowLevelMouseProc(nCode: integer; wParam: wParam;
  lParam: lParam): LRESULT; stdcall;
begin
  if (nCode >= 0) then
  begin
    if wParam = WM_LButtonDOWN then
      Mainform.StopSlideshow;
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

procedure TMainForm.StopSlideshow;
begin
  if Server.Connected then
    Server.SendMessage('{"TYP":"EVENT","EVENT":"GOTFOCUS"}');
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  if not (Chromium1.CreateBrowser(CEFWindowParent1, '')) and not
    (Chromium1.Initialized) then
    Timer1.Enabled := True;
end;

procedure TMainForm.Chromium1AfterCreated(Sender: TObject; const browser: ICefBrowser);
begin
  PostMessage(Handle, CEF_AFTERCREATED, 0, 0);
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
            Chromium1.LoadURL(s[1], 0);
        1:
          if Browser then
          begin
            val(s[1], f);
            Chromium1.ZoomLevel := f;
          end;
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
          finally
            // Restore FPU mask
            Set8087CW(SavedCW);
            timer3.Enabled := True;
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

procedure TMainForm.Chromium1BeforeClose(Sender: TObject; const browser: ICefBrowser);
begin
  FCanClose := True;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose := FCanClose;

  if not (FClosing) then
  begin
    FClosing := True;
    Visible := False;
    Chromium1.CloseBrowser(True);
  end;
end;

procedure TMainForm.Chromium1Close(Sender: TObject; const browser: ICefBrowser;
  var aAction: TCefCloseBrowserAction);
begin
  PostMessage(Handle, CEF_DESTROY, 0, 0);
  aAction := cbaDelay;
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
  TrayIcon1.Show;
  Application.Terminate;
end;

procedure TMainForm.BrowserDestroyMsg(var aMessage: TMessage);
begin
  CEFWindowParent1.Free;
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
    Chromium1.DefaultUrl := Url;
    Mainform.WindowState := wsFullscreen;
    // GlobalCEFApp.GlobalContextInitialized has to be TRUE before creating any browser
    // If it's not initialized yet, we use a simple timer to create the browser later.
    if not (Chromium1.CreateBrowser(CEFWindowParent1, '')) then
      Timer1.Enabled := True;
  end
  else
  begin
    Hide;
    TrayIcon1.Show;
  end;
  FCanClose := False;
  FClosing := False;
end;

procedure TMainForm.Chromium1AddressChange(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame; const url: ustring);
begin
  if Server.Connected then
    Server.SendMessage('{"TYP":"URL","URL":"' + UTF8Encode(url) + '"}');
end;

procedure TMainForm.Chromium1LoadError(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; errorCode: TCefErrorCode; const errorText, failedUrl: ustring);
begin
  if Server.Connected then
    Server.SendMessage('{"TYP":"ERROR","ERROR":"TRUE"}');
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
