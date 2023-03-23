{******************************************************************************}
{                                                                              }
{       WiRL: RESTful Library for Delphi                                       }
{                                                                              }
{       Copyright (c) 2015-2019 WiRL Team                                      }
{                                                                              }
{       https://github.com/delphi-blocks/WiRL                                  }
{                                                                              }
{******************************************************************************}
unit Server.Forms.Main;

interface

uses
  System.Classes, System.SysUtils, Vcl.Forms, Vcl.ActnList, Vcl.ComCtrls,
  Vcl.StdCtrls, Vcl.Controls, Vcl.ExtCtrls, System.Diagnostics, System.Actions,
  WiRL.Core.Engine,
  WiRL.Core.Application,
  WiRL.http.Server,
  WiRL.http.Server.Indy, Vcl.Imaging.pngimage;

type
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
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  Prometheus.Registry,
  Prometheus.Collectors.Counter,
  WiRL.Core.JSON,
  WiRL.Rtti.Utils;

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
  // Create http server
  FServer := TWiRLServer.Create(nil);

  // Server configuration
  FServer
    .SetPort(StrToIntDef(PortNumberEdit.Text, 8080))
    // Engine configuration
    .AddEngine<TWiRLEngine>('/rest')
      .SetEngineName('WiRL ContentType Demo')

      // Application configuration
      .AddApplication('/app')
        .SetAppName('Content App')
        .SetWriters('*')
        .SetReaders('*')
        .SetResources('Server.Resources.Metrics.TMetricsResource') // metrics!
        .SetResources('Server.Resources.TSampleResource');

  // Metrics configuration
  TCounter
    .Create('http_requests_count', 'Conteggio totale delle richieste HTTP ricevute')
    .Register();

  // Start the Web server
  if not FServer.Active then
    FServer.Active := True;
end;

procedure TMainForm.StopServerActionExecute(Sender: TObject);
begin
  FServer.Active := False;
  FServer.Free;
  // Clear metrics
  TCollectorRegistry.DefaultRegistry.Clear;
end;

end.
