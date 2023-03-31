unit Controllers.Demo;

interface

uses
  MVCFramework,
  MVCFramework.Commons;

type

{ TDemoController }

  [MVCPath('/')]
  TDemoController = class(TMVCController)
  public
    [MVCPath('/')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces(TMVCMediaType.TEXT_PLAIN)]
    procedure HelloWorld;
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

  // Render a sample string of text.
  Render('Hello World! It''s ' + TimeToStr(Time) + ' in the DMVCFramework Land!');
end;

end.
