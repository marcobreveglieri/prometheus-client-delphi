unit Server.Forms.Main;

interface

uses
  System.Actions,
  System.Classes,
  System.SysUtils,
  Vcl.Forms,
  Vcl.ActnList,
  Vcl.ComCtrls,
  Vcl.StdCtrls,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Imaging.pngimage,
  WiRL.http.Server;

type

{ TMainForm }

  TMainForm = class(TForm)
    TopPanel: TPanel;
    StartServerButton: TButton;
    StopServerButton: TButton;
    MainActionList: TActionList;
    StartServerAction: TAction;
    StopServerAction: TAction;
    PortNumberEdit: TEdit;
    PortNumberLabel: TLabel;
    WiRLImage: TImage;
    PromImage: TImage;
    procedure StartServerActionExecute(Sender: TObject);
    procedure StopServerActionExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure MainActionListUpdate(Action: TBasicAction; var Handled: Boolean);
  private
    FServer: TWiRLServer;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  WiRL.Core.Engine,
  WiRL.Core.Application,
  WiRL.http.Server.Indy,
  Prometheus.Registry,
  Prometheus.Collectors.Counter;

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  StartServerAction.Execute;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  StopServerAction.Execute;
end;

procedure TMainForm.MainActionListUpdate(Action: TBasicAction;
  var Handled: Boolean);
begin
  StartServerAction.Enabled := (FServer = nil) or (FServer.Active = False);
  StopServerAction.Enabled := not StartServerAction.Enabled;
end;

procedure TMainForm.StartServerActionExecute(Sender: TObject);
begin
  // Create the WiRL HTTP Web Server.
  FServer := TWiRLServer.Create(nil);

  // Set up the server configuration.
  FServer
    .SetPort(StrToIntDef(PortNumberEdit.Text, 8080))
    .AddEngine<TWiRLEngine>('/rest')
    .SetEngineName('WiRL ContentType Demo')
    .AddApplication('/app')
    .SetAppName('Content App')
    .SetWriters('*')
    .SetReaders('*')
    .SetResources('Server.Resources.*');

  // Create a sample counter metric and register it into the default registry.
  TCounter
    .Create('http_requests_count', 'Received HTTP request count', ['path', 'status'])
    .Register();

  // Start the Web server.
  if not FServer.Active then
    FServer.Active := True;
end;

procedure TMainForm.StopServerActionExecute(Sender: TObject);
begin
  // Turn off the server.
  FServer.Active := False;
  FServer.Free;

  // Clear all the previously registered metrics to restart from scratch.
  TCollectorRegistry.DefaultRegistry.Clear;
end;

end.
