unit Controllers.Demo;

interface

uses
  MVCFramework,
  MVCFramework.Commons, 
  System.Diagnostics,
  Prometheus.Collectors.Histogram;

type

{ TDemoController }

  [MVCPath('/')]
  TDemoController = class(TMVCController)
  private
    FDuration: TStopwatch;
    function ResponseDurationHistogram: THistogram;
    function ResponseLengthHistogram: THistogram;
    function FilesSentHistogram: THistogram;

  protected
    procedure OnBeforeAction(AContext: TWebContext; const AActionName: string;
      var AHandled: Boolean); override;
    procedure OnAfterAction(AContext: TWebContext; const AActionName: string); override;
  public
    [MVCPath('/')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces(TMVCMediaType.TEXT_PLAIN)]
    procedure HelloWorld;

    [MVCPath('/redirect')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces(TMVCMediaType.TEXT_PLAIN)]
    procedure RedirectTo;

  end;

implementation

uses
  System.SysUtils,
  Prometheus.Collectors.Counter,
  Prometheus.Registry;

{ TDemoController }

procedure TDemoController.HelloWorld;
begin
  // Get the metric counter and increment it.
  TCollectorRegistry.DefaultRegistry
    .GetCollector<TCounter>('http_requests_count')
    .Inc();


  Sleep(Random(1000));

  // Render a sample string of text.
  Render('Hello World! It''s ' + TimeToStr(Time) + ' in the DMVCFramework Land!');

end;

procedure TDemoController.RedirectTo;
begin
  Redirect('/');
end;

function TDemoController.FilesSentHistogram: THistogram;
begin
  Result := TCollectorRegistry.DefaultRegistry.GetCollector<THistogram>('files_sent');
end;

function TDemoController.ResponseDurationHistogram: THistogram;
begin
  Result :=  TCollectorRegistry.DefaultRegistry.GetCollector<THistogram>('request_duration_seconds');
end;

function TDemoController.ResponseLengthHistogram: THistogram;
begin
  Result := TCollectorRegistry.DefaultRegistry.GetCollector<THistogram>('response_length');
end;

procedure TDemoController.OnAfterAction(AContext: TWebContext; const AActionName: string);
begin
  inherited;

  ResponseDurationHistogram.Labels([AContext.Request.PathInfo, AContext.Response.StatusCode.ToString ]).Observe(FDuration.Elapsed.TotalSeconds);

  ResponseLengthHistogram.Observe( AContext.Response.RawWebResponse.ContentLength);

  FilesSentHistogram.Observe(Random(50));

end;

procedure TDemoController.OnBeforeAction(AContext: TWebContext; const AActionName: string; var AHandled: Boolean);
begin
  FDuration := TStopwatch.Create;
  FDuration.Start;
  inherited;

end;

end.
