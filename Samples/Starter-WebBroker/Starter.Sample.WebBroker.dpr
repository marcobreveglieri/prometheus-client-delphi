program Starter.Sample.WebBroker;
{$APPTYPE GUI}

uses
  Vcl.Forms,
  Web.WebReq,
  IdHTTPWebBrokerBridge,
  Forms.Main in 'Forms.Main.pas' {MainForm},
  WebModules.Prom in 'WebModules.Prom.pas' {PromWebModule: TWebModule},
  Services.Memory in 'Services.Memory.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  if WebRequestHandler <> nil then
    WebRequestHandler.WebModuleClass := WebModuleClass;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
