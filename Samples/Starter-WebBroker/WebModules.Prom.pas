unit WebModules.Prom;

interface

uses
  System.Classes,
  System.SysUtils,
  Web.HTTPApp;

type
  TPromWebModule = class(TWebModule)
    procedure PromWebModuleDefaultHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure PromWebModuleMetricActionAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure PromWebModuleLeakAction(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
    procedure WebModuleAfterDispatch(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
    procedure WebModuleBeforeDispatch(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
  private
    procedure InitializeMetrics;
    procedure UpdateLastMinuteMetrics;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  WebModuleClass: TComponentClass = TPromWebModule;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  Prometheus.Collectors.Counter,
  Prometheus.Collectors.Gauge,
  Prometheus.Registry,
  Prometheus.Exposers.Text,
  Services.Memory;

constructor TPromWebModule.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  InitializeMetrics;
end;

procedure TPromWebModule.InitializeMetrics;
begin
  var LRegistry := TCollectorRegistry.DefaultRegistry;
  // Counter: http_requests_count
  if not LRegistry.HasCollector('http_requests_count') then
  begin
    TCounter
      .Create('http_requests_count', 'HTTP received request count')
      .Register();
  end;
  // Counter: http_requests_handled
  if not LRegistry.HasCollector('http_requests_handled') then
  begin
    TCounter
      .Create('http_requests_handled', 'HTTP handled request count',
        ['path', 'status'])
      .Register();
  end;
  // Gauge: memory_allocated_total
  if not LRegistry.HasCollector('memory_allocated_total') then
  begin
    var LGauge := TGauge
      .Create('memory_allocated_total', 'Total memory allocated by the process');
    LGauge.SetTo(TMemoryServices.GetTotalAllocatedMemory);
    LGauge.Register();
  end;
end;

procedure TPromWebModule.PromWebModuleDefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  if Request.PathInfo <> '/' then
  begin
    Response.StatusCode := 404;
    Response.Content := 'Not found!';
    Exit;
  end;
  Response.Content :=
    '<html>' +
    '<head><title>Web Server Application</title></head>' +
    '<body>' +
    '<h1>Web Server Application</h1>' +
    '<h2>Prometheus Delphi Client powered!</h2>' +
    '<p><a href="/metrics">View exposed Metrics</a></p>' +
    '</body>' +
    '</html>';
end;

procedure TPromWebModule.PromWebModuleMetricActionAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  UpdateLastMinuteMetrics;
  Response.ContentType := 'text/plain';
  Response.ContentStream := TMemoryStream.Create;
  var LWriter := TTextExposer.Create;
  try
    LWriter.Render(Response.ContentStream,
      TCollectorRegistry.DefaultRegistry.Collect);
  finally
    LWriter.Free;
  end;
end;

procedure TPromWebModule.PromWebModuleLeakAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  GetMemory(4096 * 10); // Intentional memory leak!
  Response.ContentType := 'text/plain';
  Response.Content := 'Done.';
end;

procedure TPromWebModule.UpdateLastMinuteMetrics;
begin
  TCollectorRegistry.DefaultRegistry
    .GetCollector<TGauge>('memory_allocated_total')
    .SetTo(TMemoryServices.GetTotalAllocatedMemory);
end;

procedure TPromWebModule.WebModuleAfterDispatch(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  var LPath := Request.PathInfo;
  var LStatus := IntToStr(Response.StatusCode);
  TCollectorRegistry.DefaultRegistry
    .GetCollector<TCounter>('http_requests_handled')
    .Labels([LPath, LStatus]) // ['path', 'status']
    .Inc();
end;

procedure TPromWebModule.WebModuleBeforeDispatch(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  TCollectorRegistry.DefaultRegistry
    .GetCollector<TCounter>('http_requests_count')
    .Inc();
end;

end.
