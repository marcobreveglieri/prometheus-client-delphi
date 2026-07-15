unit Prometheus.Tests.Fixtures.Exposers.Text;

interface

uses
  DUnitX.TestFramework;

type

{ TTextExposerTestFixture }

  [TestFixture]
  TTextExposerTestFixture = class
  strict private
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestExposerTextRenderIsNotEmpty;
    [Test]
    procedure TestExposerTextRendersSummary;
  end;

implementation

uses
  System.SysUtils,
  Prometheus.Collectors.Gauge,
  Prometheus.Collectors.Summary,
  Prometheus.Exposers.Text,
  Prometheus.Samples;

{ TTextExposerTestFixture }

procedure TTextExposerTestFixture.Setup;
begin
end;

procedure TTextExposerTestFixture.TearDown;
begin
end;

procedure TTextExposerTestFixture.TestExposerTextRenderIsNotEmpty;
begin
  var LSamples: TArray<TMetricSamples>;
  var LMetric := TGauge.Create('test_gauge');
  try
    LMetric.SetTo(99.99);
    LSamples := LMetric.Collect;
  finally
    LMetric.Free;
  end;
  var LExposer := TTextExposer.Create;
  try
    var LText := LExposer.Render(LSamples);
    Assert.IsNotEmpty(LText);
  finally
    LExposer.Free;
  end;
end;

procedure TTextExposerTestFixture.TestExposerTextRendersSummary;
begin
  var LSamples: TArray<TMetricSamples>;
  var LMetric := TSummary.Create('test_summary', 'A test summary');
  try
    LMetric.Observe(0.5);
    LMetric.Observe(1);
    LMetric.Observe(2);
    LSamples := LMetric.Collect;
  finally
    LMetric.Free;
  end;
  var LExposer := TTextExposer.Create;
  try
    var LText := LExposer.Render(LSamples);
    Assert.IsTrue(LText.Contains('# TYPE test_summary summary'),
      'Missing summary TYPE line');
    Assert.IsTrue(LText.Contains('test_summary{quantile="0.5"} '),
      'Missing 0.5 quantile sample');
    Assert.IsTrue(LText.Contains('test_summary{quantile="0.9"} '),
      'Missing 0.9 quantile sample');
    Assert.IsTrue(LText.Contains('test_summary{quantile="0.99"} '),
      'Missing 0.99 quantile sample');
    Assert.IsTrue(LText.Contains('test_summary_sum 3.5'#10),
      'Missing summary sum line');
    Assert.IsTrue(LText.Contains('test_summary_count 3'#10),
      'Missing summary count line');
  finally
    LExposer.Free;
  end;
end;

end.
