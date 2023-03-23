unit Server.Resources.Metrics;

interface

uses
  WiRL.Core.Attributes,
  WiRL.http.Accept.MediaType;

type

{ TMetricsResource }

  [Path('metrics')]
  TMetricsResource = class
  public
    [GET, Produces(TMediaType.TEXT_PLAIN)]
    function GetMetrics: string;
  end;

implementation

uses
  Prometheus.Registry,
  Prometheus.Exposers.Text,
  WiRL.Core.Registry;

{ TMetricsResource }

function TMetricsResource.GetMetrics: string;
begin
  var LWriter := TTextExposer.Create;
  try
    Result := LWriter.Render(TCollectorRegistry.DefaultRegistry.Collect);
  finally
    LWriter.Free;
  end;
end;

initialization
  TWiRLResourceRegistry.Instance.RegisterResource<TMetricsResource>;

end.
