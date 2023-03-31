unit Controllers.Metrics;

interface

uses
  MVCFramework,
  MVCFramework.Commons;

type

{ TMetricsController }

  [MVCPath('/')]
  TMetricsController = class(TMVCController)
  public
    [MVCPath('/metrics')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces(TMVCMediaType.TEXT_PLAIN, TMVCCharSet.UTF_8)]
    procedure GetMetrics();
  end;

implementation

uses
  Prometheus.Registry,
  Prometheus.Exposers.Text;

{ TMetricsController }

procedure TMetricsController.GetMetrics();
begin
  var LExposer := TTextExposer.Create;
  try
    LExposer.Render(ResponseStream, TCollectorRegistry.DefaultRegistry.Collect);
  finally
    LExposer.Free;
  end;
  RenderResponseStream;
end;

end.
