program Starter.Sample.Horse;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.Classes,
  System.SysUtils,
  Horse,
  Prometheus.Collectors.Counter,
  Prometheus.Exposers.Text,
  Prometheus.Registry;

begin

  try

    (*
      PROMETHEUS SETUP
    *)

    // Creates a Prometheus "counter" metric to count HTTP handled requests
    // and registers it into the default collector registry for later access;
    // the counter will store different values varying by path and status code.
    TCounter
      .Create('http_requests_handled', 'Count all HTTP handled requests', ['path', 'status'])
      .Register();

    //
    // NOTE!! If you don't want to implement the endpoint below for any of your
    // web project, consider downloading and installing this Horse middleware:
    // https://github.com/marcobreveglieri/horse-prometheus-metrics
    //

    // Creates and endpoint for Horse web framework to expose metric values.
    THorse.Get('/metrics',
      procedure(Req: THorseRequest; Res: THorseResponse)
      begin

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

        // Let's send all the text to the client.
        Res.RawWebResponse.ContentStream := LStream;
        Res.RawWebResponse.ContentType := Format('text/plain; charset=%s', ['utf-8']);
        Res.RawWebResponse.StatusCode := Integer(THTTPStatus.OK);
        Res.RawWebResponse.SendResponse;
      end);

    (*
      HORSE APPLICATION
    *)

    // Creates a test endpoint using Horse web framework.
    THorse.Get('/ping',
      procedure(Req: THorseRequest; Res: THorseResponse)
      begin
        // Increments the "counter" metric value specifying label values.
        TCollectorRegistry.DefaultRegistry
          .GetCollector<TCounter>('http_requests_handled')
          .Labels([Req.PathInfo, IntToStr(Res.Status)]) // ['path', 'status']
        .Inc();

        // Sends a sample response to the client.
        Res.Send('pong');
      end);

    // Creates another test endpoint using Horse web framework.
    THorse.Get('/secret',
      procedure(Req: THorseRequest; Res: THorseResponse)
      begin
        // You are not authorized to see this!
        Res.Status(THTTPStatus.Unauthorized);

        // Increments the "counter" metric value specifying label values.
        TCollectorRegistry.DefaultRegistry
          .GetCollector<TCounter>('http_requests_handled')
          .Labels([Req.PathInfo, IntToStr(Res.Status)]) // ['path', 'status']
        .Inc();

        // Sends a sample response to the client.
        Res.Send('Access denied');
      end);

    // Starts the Horse web server listening to port 9000.
    THorse.Listen(9000);

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
