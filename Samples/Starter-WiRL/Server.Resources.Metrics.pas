unit Server.Resources.Metrics;

interface

uses
  WiRL.Core.Attributes,
  WiRL.Core.MessageBody.Default,
  WiRL.http.Accept.MediaType;

type

{ TMetricsResource }

  [Path('/metrics')]
  TMetricsResource = class
  public
    [GET, Produces(TMediaType.TEXT_PLAIN)]
    function GetMetrics: string;
  end;

implementation

uses
  Prometheus.Exposers.Text,
  Prometheus.Registry,
  WiRL.Core.Registry;

{ TMetricsResource }

function TMetricsResource.GetMetrics: string;
begin
  // Export the metrics using Prometheus text format.
  var LExposer := TTextExposer.Create;
  try
    Result := LExposer.Render(TCollectorRegistry.DefaultRegistry.Collect);
  finally
    LExposer.Free;
  end;
end;

initialization
  TWiRLResourceRegistry.Instance.RegisterResource<TMetricsResource>;

end.
