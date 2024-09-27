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
  MVCFramework.Commons,
  MVCFramework.Middleware.Metrics,
  Prometheus.Collectors.Counter,
  Prometheus.Collectors.Histogram,
  Controllers.Demo;

procedure TAppWebModule.WebModuleCreate(Sender: TObject);
begin
  // Creates the Delphi MVC Framework server application engine.
  FEngine := TMVCEngine.Create(Self);

  // Add a sample controller.
  FEngine.AddController(TDemoController);

  // Add the metrics middleware! It will export all values using the
  // default endpoint '/metrics' but you can change it as shown below:
  FEngine.AddMiddleware(GetMetricsMiddleware('/metrics'));

  // Configure some sample metrics...
  // ... a simple counter
  TCounter.Create('http_requests_count', 'Received HTTP request count').Register();
  // ... A request time histogram with two labels for path and status
  THistogram.Create('request_duration_seconds', 'Time taken to process request- in seconds', [2, 10, 0.05, 0.1, 0.25, 0.5, 1],
    ['path', 'status']).Register();
  // .. A request time histogram with no labels and an increasing bucket sequence
  THistogram.Create('response_length', 'Number of bytes sent in response', 10, 3, 10, []).Register();


  // .. A request time histogram with no labels and a custom linear increasing bucket sequence
  THistogram.Create('files_sent', 'Number of files sent in response',
    function : TBuckets
    var
      lNextValue: Double;
    const
       Start = 10;
       Count = 5;
       Step = 5;
    begin
      SetLength(result, Count);
      lNextValue := Start;
      for var I := 0 to Count - 1 do
      begin
        Result[I] := lNextValue;
        lNextValue := lNextValue + Start;
      end;
    end,
   []).Register();

end;

procedure TAppWebModule.WebModuleDestroy(Sender: TObject);
begin
  FEngine.Free;
end;

end.
