{
Bedeutung der Windowskonstanten:
EWX_LOGOFF
  Alle Prozesse des Benutzers werden beendet.
  Der Benutzer wird abgemeldet.

EWX_POWEROFF
  Fährt Windows herunter und setzt den Computer in den StandBy-Modus.
  (Die Hardware muss dies unterstützen)

EWX_REBOOT
  Fährt Windows herunter und startet es neu

EWX_SHUTDOWN
  Fährt Windows herunter

EWX_FORCE
  Beendet die Prozesse ohne Rückfrage

EWX_FORCEIFHUNG
  Beendet Prozesse mit vorheriger Nachfrage
}

unit utools;

{$mode Delphi}

interface

uses SysUtils, Variants, StrUtils, ComObj, ActiveX, Windows, Graphics, Dialogs;

type
  TStringArray = array of string;
  TMyBOOL = (myFalse = integer(0), myTrue = integer(1));

  IAudioEndpointVolumeCallback = interface(IUnknown)
    ['{657804FA-D6AD-4496-8A60-352752AF4F89}']
  end;

  IAudioEndpointVolume = interface(IUnknown)
    ['{5CDF2C82-841E-4546-9722-0CF74078229A}']

    function RegisterControlChangeNotify(AudioEndPtVol:
      IAudioEndpointVolumeCallback): HRESULT; stdcall;
    function UnregisterControlChangeNotify(
      AudioEndPtVol: IAudioEndpointVolumeCallback): HRESULT; stdcall;
    function GetChannelCount(Out PInteger): HRESULT; stdcall;

    function SetMasterVolumeLevel(fLevelDB: single;
      pguidEventContext: PGUID): HRESULT; stdcall;
    function SetMasterVolumeLevelScalar(fLevelDB: single;
      pguidEventContext: PGUID): HRESULT; stdcall;

    function GetMasterVolumeLevel(Out fLevelDB: single): HRESULT; stdcall;
    function GetMasterVolumeLevelScalar(Out fLevelDB: single): HRESULT;
      stdcall;

    function SetChannelVolumeLevel(nChannel: integer; fLevelDB: double;
      pguidEventContext: PGUID): HRESULT; stdcall;
    function SetChannelVolumeLevelScalar(nChannel: integer;
      fLevelDB: double; pguidEventContext: PGUID): HRESULT; stdcall;

    function GetChannelVolumeLevel(nChannel: integer;
      Out fLevelDB: double): HRESULT; stdcall;
    function GetChannelVolumeLevelScalar(nChannel: integer;
      Out fLevelDB: double): HRESULT; stdcall;

    function SetMute(bSetMute: Bool; pguidEventContext: PGUID): HRESULT; stdcall;
    function GetMute(Out bGetMute: Bool): HRESULT; stdcall;

    function GetVolumeStepInfo(pnStep: integer;
      Out pnStepCount: integer): HRESULT; stdcall;
    function VolumeStepUp(pguidEventContext: PGUID): HRESULT; stdcall;
    function VolumeStepDown(pguidEventContext: PGUID): HRESULT; stdcall;
    function GetVolumeRange(Out pflVolumeMindB: double;
      Out pflVolumeMaxdB: double; Out pflVolumeIncrementdB: double): HRESULT;
      stdcall;
    function QueryHardwareSupport(Out pdwHardwareSupportMask): HRESULT;
      stdcall;
  end;

  IAudioMeterInformation = interface(IUnknown)
    ['{C02216F6-8C67-4B5B-9D00-D008E73E0064}']
  end;

  IPropertyStore = interface(IUnknown)
  end;

  IMMDevice = interface(IUnknown)
    ['{D666063F-1587-4E43-81F1-B948E807363F}']

    function Activate(const refId: TGUID; dwClsCtx: DWORD;
      pActivationParams: PInteger;
      Out pEndpointVolume: IAudioEndpointVolume): HRESULT; stdcall;
    function OpenPropertyStore(stgmAccess: DWORD;
      Out ppProperties: IPropertyStore): HRESULT; stdcall;
    function GetId(Out ppstrId: PLPWSTR): HRESULT; stdcall;
    function GetState(Out State: integer): HRESULT; stdcall;
  end;

  IMMDeviceCollection = interface(IUnknown)
    ['{0BD7A1BE-7A1A-44DB-8397-CC5392387B5E}']
  end;

  IMMNotificationClient = interface(IUnknown)
    ['{7991EEC9-7E89-4D85-8390-6C703CEC60C0}']
  end;

  IMMDeviceEnumerator = interface(IUnknown)
    ['{A95664D2-9614-4F35-A746-DE8DB63617E6}']

    function EnumAudioEndpoints(dataFlow: TOleEnum; deviceState: SYSUINT;
      DevCollection: IMMDeviceCollection): HRESULT; stdcall;
    function GetDefaultAudioEndpoint(EDF: SYSUINT; ER: SYSUINT;
      Out Dev: IMMDevice): HRESULT; stdcall;
    function GetDevice(pwstrId: Pointer; Out Dev: IMMDevice): HRESULT; stdcall;
    function RegisterEndpointNotificationCallback(
      pClient: IMMNotificationClient): HRESULT; stdcall;
  end;

function WMIGen_Win32_Battery: string;
function WMIGen_Win32_Processor: string;
function WMIGen_Win32_OperatingSystem: string;
function WMIGen_Win32_ComputerSystem: string;
function GetHostname: string;
function ParseStrToArray(const s: string; delim: char): TStringArray;
function WebColorStrToColor(WebColor: string): TColor;
function RGB(r, g, b: byte): TColor;
function funExitWindows(RebootParam: longword): boolean;
procedure SetBrightness(Timeout: integer; Brightness: byte);
procedure SetMasterVolume(sinVol: single);
procedure GetMasterVolume(Out sinVol: single);
function GetMasterMute: TMyBOOL;
procedure SetMasterMute(Value: TMyBOOL);

const
  //Soft-Variante
  logoff = EWX_LOGOFF or EWX_FORCEIFHUNG;
  standby = EWX_POWEROFF or EWX_FORCEIFHUNG;
  reboot = EWX_REBOOT or EWX_FORCEIFHUNG;
  shutdown = EWX_SHUTDOWN or EWX_FORCEIFHUNG;

  //Harte-Variante
  logoff_f = EWX_LOGOFF or EWX_FORCE;
  standby_f = EWX_POWEROFF or EWX_FORCE;
  reboot_f = EWX_REBOOT or EWX_FORCE;
  shutdown_f = EWX_SHUTDOWN or EWX_FORCE;
  CLASS_IMMDeviceEnumerator: TGUID = '{BCDE0395-E52F-467C-8E3D-C4579291692E}';
  IID_IMMDeviceEnumerator: TGUID = '{A95664D2-9614-4F35-A746-DE8DB63617E6}';
  IID_IAudioEndpointVolume: TGUID = '{5CDF2C82-841E-4546-9722-0CF74078229A}';
// SYSTEM VOLUME END

implementation

function VarArrayToStr(const vArray: variant): string;

  function _VarToStr(const V: variant): string;

  var
    Vt: integer;
  begin
    Vt := TVarData(V).VType;
    case Vt of
      varSmallint,
      varInteger: Result := IntToStr(integer(V));
      varSingle,
      varDouble,
      varCurrency: Result := FloatToStr(double(V));
      varDate: Result := VarToStr(V);
      varOleStr: Result := WideString(V);
      varBoolean: Result := VarToStr(V);
      varVariant: Result := VarToStr(variant(V));
      varByte: Result := char(byte(V));
      varString: Result := string(V);
      varArray: Result := VarArrayToStr(variant(V));
    end;
  end;

var
  i: integer;
begin
  Result := '';
  if (TVarData(vArray).VType and VarArray) = 0 then
    Result := _VarToStr(vArray)
  else
    for i := VarArrayLowBound(vArray, 1) to VarArrayHighBound(vArray, 1) do
      if i = VarArrayLowBound(vArray, 1) then
        Result := Result + _VarToStr(vArray[i])
      else
        Result := Result + ';' + _VarToStr(vArray[i]);
end;

function VarStrNull(const V: olevariant): string; //avoid problems with null strings
begin
  Result := '';
  if not VarIsNull(V) then
  begin
    if VarIsArray(V) then
      Result := VarArrayToStr(V)
    else
      Result := VarToStr(V);
  end;
end;

function GetWMIObject(const objectName: string): IDispatch;
var
  chEaten: PULONG;
  BindCtx: IBindCtx;
  Moniker: IMoniker;
begin
  OleCheck(CreateBindCtx(0, bindCtx));
  OleCheck(MkParseDisplayName(BindCtx, StringToOleStr(objectName), chEaten, Moniker));
  Olecheck(Moniker.BindToObject(BindCtx, nil, IDispatch, Result));
end;

function WMIGen_Win32_Battery: string;
var
  objWMIService: olevariant;
  colItems: olevariant;
  colItem: olevariant;
  oEnum: IEnumvariant;
  sTemp: string;
  pNull: longword;

begin
  objWMIService := GetWMIObject(Format('winmgmts://%s/root/CIMV2', ['localhost']));
  colItems := objWMIService.ExecQuery('SELECT * FROM Win32_Battery', 'WQL', 0);
  oEnum := IUnknown(colItems._NewEnum) as IEnumVariant;

  while oEnum.Next(1, colItem, pNull) = 0 do
    sTemp := VarStrNull(colItem.EstimatedChargeRemaining);
  Result := sTemp;
end;

function WMIGen_Win32_Processor: string;
var
  objWMIService: olevariant;
  colItems: olevariant;
  colItem: olevariant;
  oEnum: IEnumvariant;
  sTemp: string;
  pNull: longword;

begin
  objWMIService := GetWMIObject(Format('winmgmts://%s/root/CIMV2', ['localhost']));
  colItems := objWMIService.ExecQuery(
    'SELECT LoadPercentage FROM Win32_Processor', 'WQL', 0);
  oEnum := IUnknown(colItems._NewEnum) as IEnumVariant;

  while oEnum.Next(1, colItem, pNull) = 0 do
    sTemp := VarStrNull(colItem.LoadPercentage);
  Result := sTemp;
end;

function WMIGen_Win32_OperatingSystem: string;
var
  objWMIService: olevariant;
  colItems: olevariant;
  colItem: olevariant;
  oEnum: IEnumvariant;
  sTemp: string;
  pNull: longword;

begin
  objWMIService := GetWMIObject(Format('winmgmts://%s/root/CIMV2', ['localhost']));
  colItems := objWMIService.ExecQuery(
    'SELECT FreePhysicalMemory FROM Win32_OperatingSystem', 'WQL', 0);
  oEnum := IUnknown(colItems._NewEnum) as IEnumVariant;

  while oEnum.Next(1, colItem, pNull) = 0 do
    sTemp := VarStrNull(colItem.FreePhysicalMemory);
  Result := sTemp;
end;

function WMIGen_Win32_ComputerSystem: string;
var
  objWMIService: olevariant;
  colItems: olevariant;
  colItem: olevariant;
  oEnum: IEnumvariant;
  sTemp: string;
  pNull: longword;

begin
  objWMIService := GetWMIObject(Format('winmgmts://%s/root/CIMV2', ['localhost']));
  colItems := objWMIService.ExecQuery(
    'SELECT TotalPhysicalMemory FROM Win32_ComputerSystem', 'WQL', 0);
  oEnum := IUnknown(colItems._NewEnum) as IEnumVariant;

  while oEnum.Next(1, colItem, pNull) = 0 do
    sTemp := VarStrNull(colItem.TotalPhysicalMemory);
  Result := sTemp;
end;

function GetHostname: string;
var
  objWMIService: olevariant;
  colItems: olevariant;
  colItem: olevariant;
  oEnum: IEnumvariant;
  sTemp: string;
  pNull: longword;

begin
  objWMIService := GetWMIObject(Format('winmgmts://%s/root/CIMV2', ['localhost']));
  colItems := objWMIService.ExecQuery(
    'SELECT DNSHostName FROM Win32_NetworkAdapterConfiguration', 'WQL', 0);
  oEnum := IUnknown(colItems._NewEnum) as IEnumVariant;

  while oEnum.Next(1, colItem, pNull) = 0 do
    begin
      sTemp := VarStrNull(colItem.DNSHostName);
      if sTemp <> '' then break;
    end;
  Result := sTemp;
end;

procedure SetBrightness(Timeout: integer; Brightness: byte);
var
  FSWbemLocator: olevariant;
  FWMIService: olevariant;
  FWbemObjectSet: olevariant;
  FWbemObject: olevariant;
  oEnum: IEnumvariant;
  iValue: longword;
begin
  ;
  FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
  FWMIService := FSWbemLocator.ConnectServer('localhost', 'root\WMI', '', '');
  FWbemObjectSet := FWMIService.ExecQuery(
    'SELECT * FROM WmiMonitorBrightnessMethods Where Active=True', 'WQL', $00000020);
  oEnum := IUnknown(FWbemObjectSet._NewEnum) as IEnumVariant;
  while oEnum.Next(1, FWbemObject, iValue) = 0 do
  begin
    FWbemObject.WmiSetBrightness(Timeout, Brightness);
    FWbemObject := Unassigned;
  end;
end;

function ParseStrToArray(const s: string; delim: char): TStringArray;
var
  tsa: TStringArray;
  sbuf: string;
  x: byte;
begin
  if s = '' then
  begin
    Result := nil;
    exit;
  end;
  sbuf := s;
  setlength(tsa, 0);
  x := PosEx(delim, sbuf);
  while (x > 0) or (length(sbuf) > 0) do
  begin
    setlength(tsa, length(tsa) + 1);
    if (x = 0) and (length(sbuf) > 0) then
      tsa[length(tsa) - 1] := sbuf
    else
      tsa[length(tsa) - 1] := leftstr(sbuf, x - 1);
    if (x = 0) and (length(sbuf) > 0) then
      sbuf := ''
    else
      sbuf := rightstr(sbuf, length(sbuf) - x);
    x := PosEx(delim, sbuf);
  end;
  Result := tsa;
end;

function RGB(r, g, b: byte): TColor;
begin
  Result := (integer(r) or (integer(g) shl 8) or (integer(b) shl 16));
end;

function WebColorStrToColor(WebColor: string): TColor;
begin
  if (Length(WebColor) <> 7) or (WebColor[1] <> '#') then
    WebColor := '#F9FFE8';

  Result :=
    RGB(StrToInt('$' + Copy(WebColor, 2, 2)), StrToInt('$' + Copy(WebColor, 4, 2)),
    StrToInt('$' + Copy(WebColor, 6, 2)));
end;

function funExitWindows(RebootParam: longword): boolean;
var
  hToken: THandle;
  TokenPvg1: TTokenPrivileges;
  TokenPvg2: TTokenPrivileges;
  wrdGroesseTokenPvg2: DWORD;
  wrdPcbtpPreviousRequired: DWORD = 0;
  blnRueckgabe: boolean;

begin

  Result := False;

  try

    blnRueckgabe := OpenProcessToken(GetCurrentProcess(),
      TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken);

    if blnRueckgabe = True then
    begin
      blnRueckgabe := LookupPrivilegeValue(nil, 'SeShutdownPrivilege',
        TokenPvg1.Privileges[0].Luid);

      TokenPvg1.PrivilegeCount := 1;
      TokenPvg1.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
      wrdGroesseTokenPvg2 := SizeOf(TokenPvg2);

      if blnRueckgabe = True then
        Windows.AdjustTokenPrivileges(hToken, False, TokenPvg1,
          wrdGroesseTokenPvg2, TokenPvg2, wrdPcbtpPreviousRequired);

    end;

    Result := ExitWindowsEx(RebootParam, 0);

  except
    ShowMessage('Beim Herunterfahren von Windows ist ein Fehler aufgetreten');
  end;

end;

procedure SetMasterVolume(sinVol: single);
var
  EndpointVolume: IAudioEndpointVolume;
  DeviceEnumerator: IMMDeviceEnumerator;
  Device: IMMDevice;
begin
  CoCreateInstance(
    CLASS_IMMDeviceEnumerator, nil, CLSCTX_INPROC_SERVER,
    IID_IMMDeviceEnumerator, DeviceEnumerator);
  DeviceEnumerator.GetDefaultAudioEndpoint($00000000, $00000000, Device);
  Device.Activate(
    IID_IAudioEndpointVolume, CLSCTX_INPROC_SERVER, nil, EndpointVolume);
  EndpointVolume.SetMasterVolumeLevelScalar(sinVol, nil);
end;


procedure GetMasterVolume(Out sinVol: single);
var
  EndpointVolume: IAudioEndpointVolume;
  DeviceEnumerator: IMMDeviceEnumerator;
  Device: IMMDevice;
begin
  CoCreateInstance(
    CLASS_IMMDeviceEnumerator, nil, CLSCTX_INPROC_SERVER,
    IID_IMMDeviceEnumerator, DeviceEnumerator);
  DeviceEnumerator.GetDefaultAudioEndpoint($00000000, $00000000, Device);
  Device.Activate(
    IID_IAudioEndpointVolume, CLSCTX_INPROC_SERVER, nil, EndpointVolume);
  EndpointVolume.GetMasterVolumeLevelScalar(sinVol);
end;


function GetMasterMute: TMyBOOL;
var
  EndpointVolume: IAudioEndpointVolume;
  DeviceEnumerator: IMMDeviceEnumerator;
  Device: IMMDevice;

  bRes: BOOL;
begin
  CoCreateInstance(
    CLASS_IMMDeviceEnumerator, nil, CLSCTX_INPROC_SERVER,
    IID_IMMDeviceEnumerator, DeviceEnumerator);
  DeviceEnumerator.GetDefaultAudioEndpoint($00000000, $00000000, Device);
  Device.Activate(
    IID_IAudioEndpointVolume, CLSCTX_INPROC_SERVER, nil, EndpointVolume);
  EndpointVolume.GetMute(bRes);
  Result := TMyBOOL(bRes);
end;


procedure SetMasterMute(Value: TMyBOOL);
var
  EndpointVolume: IAudioEndpointVolume;
  DeviceEnumerator: IMMDeviceEnumerator;
  Device: IMMDevice;
begin
  CoCreateInstance(
    CLASS_IMMDeviceEnumerator, nil, CLSCTX_INPROC_SERVER,
    IID_IMMDeviceEnumerator, DeviceEnumerator);
  DeviceEnumerator.GetDefaultAudioEndpoint($00000000, $00000000, Device);
  Device.Activate(
    IID_IAudioEndpointVolume, CLSCTX_INPROC_SERVER, nil, EndpointVolume);
  EndpointVolume.SetMute(BOOL(Value), nil);
end;

initialization
  coInitialize(nil);

finalization
  coUnInitialize;
end.
