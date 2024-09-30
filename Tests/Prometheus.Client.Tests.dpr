program Prometheus.Client.Tests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}

{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  {$IFNDEF TESTINSIGHT}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ELSE}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.TestFramework,
  Prometheus.Tests.Fixtures.Collector in 'Fixtures\Prometheus.Tests.Fixtures.Collector.pas',
  Prometheus.Tests.Fixtures.Collectors.Counter in 'Fixtures\Prometheus.Tests.Fixtures.Collectors.Counter.pas',
  Prometheus.Tests.Fixtures.Collectors.Gauge in 'Fixtures\Prometheus.Tests.Fixtures.Collectors.Gauge.pas',
  Prometheus.Tests.Fixtures.Collectors.Histogram in 'Fixtures\Prometheus.Tests.Fixtures.Collectors.Histogram.pas';

begin
{$IFNDEF TESTINSIGHT}
  try
    ReportMemoryLeaksOnShutdown := True;

    // Check command line options, will exit if invalid.
    TDUnitX.CheckCommandLine;

    // Create the test runner.
    var LRunner: ITestRunner := TDUnitX.CreateRunner;

    // Tell the runner to use RTTI to find fixtures.
    LRunner.UseRTTI := True;

    // When true, Assertions must be made during tests.
    LRunner.FailsOnNoAsserts := False;

    // Tell the runner how we will log things.
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      var LLogger := TDUnitXConsoleLogger.Create(
        TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      LRunner.AddLogger(LLogger);
    end;


    // Generate an NUnit compatible XML File.
    var LXmlLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    LRunner.AddLogger(LXmlLogger);

    // Run tests and collect results.
    var LResults := LRunner.Execute;
    if not LResults.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    // We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}

  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ELSE}
  TestInsight.DUnitX.RunRegisteredTests;
{$ENDIF}

end.
