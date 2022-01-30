program wioNoweb;

{$MODE Delphi}

uses
  Forms,
  Interfaces,
  uwionoweb {MainForm},
  uMessage in 'uMessage.pas' {MessageForm};

{.$R *.res}

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TMessageForm, MessageForm);
  Application.Run;
end.
