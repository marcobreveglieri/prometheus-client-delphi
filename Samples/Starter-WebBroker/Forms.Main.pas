unit Forms.Main;

interface

uses
  Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.AppEvnts, Vcl.StdCtrls, IdHTTPWebBrokerBridge, IdGlobal, Web.HTTPApp,
  System.Actions, Vcl.ActnList;

type

  TMainForm = class(TForm)
    StartServerButton: TButton;
    StopServerButton: TButton;
    PortEdit: TEdit;
    PortLabel: TLabel;
    OpenBrowserButton: TButton;
    MainActionList: TActionList;
    StartServerAction: TAction;
    StopServerAction: TAction;
    OpenBrowserAction: TAction;
    procedure MainActionListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure StartServerActionExecute(Sender: TObject);
    procedure StopServerActionExecute(Sender: TObject);
    procedure OpenBrowserActionExecute(Sender: TObject);
  private
    FServer: TIdHTTPWebBrokerBridge;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  Winapi.ShellApi,
  WinApi.Windows;

constructor TMainForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FServer := TIdHTTPWebBrokerBridge.Create(Self);
end;

destructor TMainForm.Destroy;
begin
  if Assigned(FServer) then
    FreeAndNil(FServer);
  inherited Destroy;
end;

procedure TMainForm.MainActionListUpdate(Action: TBasicAction; var Handled: Boolean);
var
  LServerRunning: Boolean;
begin
  LServerRunning := FServer.Active;
  StartServerAction.Enabled := not LServerRunning;
  StopServerAction.Enabled := LServerRunning;
  OpenBrowserAction.Enabled := LServerRunning;
  PortEdit.Enabled := not LServerRunning;
end;

procedure TMainForm.OpenBrowserActionExecute(Sender: TObject);
var
  LURL: string;
begin
  if not FServer.Active then
    Exit;
  LURL := Format('http://localhost:%s', [PortEdit.Text]);
  ShellExecute(0, nil, PChar(LURL), nil, nil, SW_SHOWNOACTIVATE);
end;

procedure TMainForm.StartServerActionExecute(Sender: TObject);
begin
  if FServer.Active then
    Exit;
  FServer.Bindings.Clear;
  FServer.DefaultPort := StrToInt(PortEdit.Text);
  FServer.Active := True;
end;

procedure TMainForm.StopServerActionExecute(Sender: TObject);
begin
  if not FServer.Active then
    Exit;
  FServer.Active := False;
  FServer.Bindings.Clear;
end;

end.
