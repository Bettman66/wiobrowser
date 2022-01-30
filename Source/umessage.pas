unit umessage;

{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type

  { TMessageForm }

  TMessageForm = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Timer1: TTimer;
    Timer2: TTimer;
    Timer3: TTimer;
    procedure Label1Click(Sender: TObject);
    procedure Label2Click(Sender: TObject);
    procedure Label3Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
  private

  public
    procedure FormActual;
  const
    Time: Integer = 10000;
  end;

var
  MessageForm: TMessageForm;

implementation

{$R *.lfm}

{ TMessageForm }

procedure TMessageForm.FormActual;
begin
  Panel2.Top:= Panel1.Top + Panel1.Height;
  Panel3.Top:= Panel2.Top + Panel2.Height;
  Panel1.Left := 75;
  Panel2.Left := 75;
  Panel3.Left := 75;
  if Time > 0 then
  begin
    Timer1.Interval:= Time;
    Timer1.Enabled := True;
  end;
end;

procedure TMessageForm.Timer1Timer(Sender: TObject);
begin
  Label1.Caption:='';
  Panel1.Visible:=False;
  Panel2.Top:= Panel1.Top;
  if Label2.Caption = '' then
     Panel3.Top:= Panel1.Top
  else
    Panel3.Top:= Panel2.Top + Panel2.Height;
  Timer1.Enabled := False;
  if (Label2.Caption = '') and (Label3.Caption = '') then
    Hide;
end;

procedure TMessageForm.Label1Click(Sender: TObject);
begin
  Label1.Caption:='';
  Panel1.Visible:=False;
  Panel2.Top:= Panel1.Top;
  if Label2.Caption = '' then
     Panel3.Top:= Panel1.Top
  else
    Panel3.Top:= Panel2.Top + Panel2.Height;
  Timer1.Enabled := False;
  if (Label2.Caption = '') and (Label3.Caption = '') then
    Hide;
end;

procedure TMessageForm.Timer2Timer(Sender: TObject);
begin
  Label2.Caption:='';
  Panel2.Visible:=False;
  if (Label1.Caption = '') and (Label2.Caption = '') then
    Panel3.Top:= Panel1.Top
  else if Label2.Caption = '' then
    Panel3.Top:= Panel1.Top + Panel1.Height;
  Timer2.Enabled := False;
  if (Label1.Caption = '') and (Label3.Caption = '') then
    Hide;
end;

procedure TMessageForm.Label2Click(Sender: TObject);
begin
  Label2.Caption:='';
  Panel2.Visible:=False;
  if (Label1.Caption = '') and (Label2.Caption = '') then
    Panel3.Top:= Panel1.Top
  else if Label2.Caption = '' then
    Panel3.Top:= Panel1.Top + Panel1.Height;
  Timer2.Enabled := False;
  if (Label1.Caption = '') and (Label3.Caption = '') then
    Hide;
end;

procedure TMessageForm.Timer3Timer(Sender: TObject);
begin
  Label3.Caption:='';
  Panel3.Visible:=False;
  Timer3.Enabled := False;
  if (Label1.Caption = '') and (Label2.Caption = '') then
    Hide;
end;

procedure TMessageForm.Label3Click(Sender: TObject);
begin
  Label3.Caption:='';
  Panel3.Visible:=False;
  Timer3.Enabled := False;
  if (Label1.Caption = '') and (Label2.Caption = '') then
    Hide;
end;

end.
