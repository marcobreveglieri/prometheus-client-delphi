unit Server.Resources.Samples;

interface

uses
  System.SysUtils,
  WiRL.Core.Attributes,
  WiRL.Core.MessageBody.Default,
  WiRL.http.Core,
  WiRL.http.Accept.MediaType;

type

{ TSampleResource }

  [Path('/samples')]
  TSampleResource = class
  public
    [GET]
    [Produces(TMediaType.TEXT_PLAIN)]
    function Ping(): string;
  end;

implementation

uses
  WiRL.Core.Registry,
  Prometheus.Collectors.Counter,
  Prometheus.Registry;

{ TSampleResource }

function TSampleResource.Ping: string;
begin
  // Increments the "counter" metric value with label values.
  TCollectorRegistry.DefaultRegistry
    .GetCollector<TCounter>('http_requests_count')
    .Labels(['/ping', IntToStr(TWiRLHttpStatus.OK)]) // ['path', 'status']
    .Inc();

  // Sends a sample response to the client.
  Result := 'pong';
end;

initialization
  TWiRLResourceRegistry.Instance.RegisterResource<TSampleResource>;

end.
