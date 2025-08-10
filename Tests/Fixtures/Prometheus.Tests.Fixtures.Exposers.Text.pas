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
  end;

implementation

uses
  Prometheus.Collectors.Gauge,
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

end.
