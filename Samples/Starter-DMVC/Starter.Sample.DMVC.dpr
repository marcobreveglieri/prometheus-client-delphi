program Starter.Sample.DMVC;

{$APPTYPE CONSOLE}


uses
  System.SysUtils,
  Web.WebReq,
  IdHTTPWebBrokerBridge,
  WebModules.App in 'WebModules.App.pas' {AppWebModule: TWebModule},
  Controllers.Demo in 'Controllers.Demo.pas';

{$R *.res}

var
  LServer: TIdHTTPWebBrokerBridge;

procedure StartServer(APort: Integer);
begin
  Writeln(Format('Starting HTTP Server or port %d', [APort]));
  LServer := TIdHTTPWebBrokerBridge.Create(nil);
  try
    LServer.DefaultPort := APort;
    LServer.MaxConnections := 0;
    LServer.ListenQueue := 200;
    LServer.Active := True;
    WriteLn('Press ENTER to quit the server.');
    Readln;
  finally
    LServer.Free;
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    if WebRequestHandler <> nil then
      WebRequestHandler.WebModuleClass := WebModuleClass;
    WebRequestHandlerProc.MaxConnections := 1024;
    StartServer(9000);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
