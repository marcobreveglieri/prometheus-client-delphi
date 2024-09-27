unit MVCFramework.Middleware.Metrics;

interface

uses
  MVCFramework;

{ Routines }

/// <summary>
///  Returns a new instance of DMVC middleware properly configured
///  to export metric values from Prometheus Client.
/// </summary>
/// <param name="APathInfo">Set the path that will expose the metrics.</param>
function GetMetricsMiddleware(const APathInfo: string = '/metrics'): IMVCMiddleware;

implementation

uses
  System.Classes, System.SysUtils,
  MVCFramework.Commons,
  Prometheus.Registry, Prometheus.Exposers.Text;

type

{ TMetricsMiddleware }

  /// <summary>
  ///  Implements a middleware to export metric values from Prometheus Client.
  /// </summary>
  TMetricsMiddleware = class(TInterfacedObject, IMVCMiddleware)
  private
    FPathInfo: string;
  public
    constructor Create(const APathInfo: string);
    procedure OnAfterControllerAction(Context: TWebContext;
      const AControllerQualifiedClassName: string; const AActionName: string;
      const AHandled: Boolean);
    procedure OnAfterRouting(Context: TWebContext; const AHandled: Boolean);
    procedure OnBeforeControllerAction(Context: TWebContext;
      const AControllerQualifiedClassName: string; const AActionNAme: string;
      var Handled: Boolean);
    procedure OnBeforeRouting(Context: TWebContext; var Handled: Boolean);
  end;

{ TMetricsMiddleware }

constructor TMetricsMiddleware.Create(const APathInfo: string);
begin
  inherited Create;
  FPathInfo := APathInfo;
end;

procedure TMetricsMiddleware.OnAfterControllerAction(Context: TWebContext;
  const AControllerQualifiedClassName, AActionName: string;
  const AHandled: Boolean);
begin
  // Do nothing.
end;

procedure TMetricsMiddleware.OnAfterRouting(Context: TWebContext;
  const AHandled: Boolean);
begin
  // Do nothing.
end;

procedure TMetricsMiddleware.OnBeforeControllerAction(Context: TWebContext;
  const AControllerQualifiedClassName, AActionNAme: string;
  var Handled: Boolean);
begin
  // Do nothing.
end;

procedure TMetricsMiddleware.OnBeforeRouting(Context: TWebContext;
  var Handled: Boolean);
begin
  // Check whether the current path request matches the metrics one.
  if not SameText(Context.Request.PathInfo, FPathInfo) then
    Exit;

  // We create a stream that will contain metric values exposed as text,
  // using the appropriate exposer from Prometheus Client to render it.
  var LStream := TMemoryStream.Create;
  try
    var LExposer := TTextExposer.Create;
    try
      LExposer.Render(LStream, TCollectorRegistry.DefaultRegistry.Collect());
    finally
      LExposer.Free;
    end;
  except
    LStream.Free;
    raise;
  end;

  // Let's send all the generated text to the client.
  Context.Response.SetContentStream(LStream,
    Format('%s; charset=%s', [TMVCMediaType.TEXT_PLAIN, TMVCCharSet.UTF_8]));
  Context.Response.Flush();

  // Set the request has fully handled.
  Handled := True;
end;

{ Routines }

function GetMetricsMiddleware(const APathInfo: string): IMVCMiddleware;
begin
  Result := TMetricsMiddleware.Create(APathInfo);
end;

end.

