unit WebModules.App;

interface

uses
  System.Classes,
  System.SysUtils,
  Web.HTTPApp,
  MVCFramework;

type

  TAppWebModule = class(TWebModule)
    procedure WebModuleCreate(Sender: TObject);
    procedure WebModuleDestroy(Sender: TObject);
  private
    FEngine: TMVCEngine;
  end;

var
  WebModuleClass: TComponentClass = TAppWebModule;

implementation

{$R *.dfm}

uses
  Prometheus.Collectors.Counter,
  Controllers.Demo,
  Controllers.Metrics;

procedure TAppWebModule.WebModuleCreate(Sender: TObject);
begin
  // Creates the Delphi MVC Framework server application engine.
  FEngine := TMVCEngine.Create(Self);

  // Add a sample controller.
  FEngine.AddController(TDemoController);

  // Add the metrics controller!
  FEngine.AddController(TMetricsController);

  // Configure some sample metrics...
  TCounter
    .Create('http_requests_count', 'Received HTTP request count')
    .Register();
end;

procedure TAppWebModule.WebModuleDestroy(Sender: TObject);
begin
  FEngine.Free;
end;

end.
