program wioWvWeb;

{$mode Delphi}

uses
  Forms,
  Interfaces,
  uwiowvweb in 'uwiowvweb.pas' {MainForm},
  umessage in 'umessage.pas' {MessageForm};

{.$R *.res}

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TMessageForm, MessageForm);
  Application.Run;
end.
