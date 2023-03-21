unit Prometheus.Tests.Fixtures.Collectors.Gauge;

interface

uses
  DUnitX.TestFramework;

type

{ TGaugeCollectorTestFixture }

  [TestFixture]
  TGaugeCollectorTestFixture = class
  public
    [Test]
    procedure GaugeMustStartAtZero;
    [Test]
    procedure GaugeMustDecrementByOneAsDefault;
    [Test]
    procedure GaugeMustDecrementBySpecifiedAmount;
    [Test]
    procedure GaugeMustIncrementByOneAsDefault;
    [Test]
    procedure GaugeMustIncrementBySpecifiedAmount;
    [Test]
    procedure GaugeMustSetCurrentValue;
  end;

implementation

uses
  System.SysUtils,
  Prometheus.Collectors.Gauge;

{ TGaugeCollectorTestFixture }

procedure TGaugeCollectorTestFixture.GaugeMustStartAtZero;
begin
  var LGauge := TGauge.Create('sample', 'sample gauge');
  try
    Assert.AreEqual(0, LGauge.Value, Double.Epsilon);
  finally
    LGauge.Free;
  end;
end;

procedure TGaugeCollectorTestFixture.GaugeMustDecrementByOneAsDefault;
begin
  var LGauge := TGauge.Create('sample', 'sample gauge');
  try
    LGauge.Dec();
    Assert.AreEqual(-1, LGauge.Value, Double.Epsilon);
  finally
    LGauge.Free;
  end;
end;

procedure TGaugeCollectorTestFixture.GaugeMustDecrementBySpecifiedAmount;
begin
  var LGauge := TGauge.Create('sample', 'sample gauge');
  try
    LGauge.Dec(123);
    Assert.AreEqual(-123, LGauge.Value, Double.Epsilon);
  finally
    LGauge.Free;
  end;
end;

procedure TGaugeCollectorTestFixture.GaugeMustIncrementByOneAsDefault;
begin
  var LGauge := TGauge.Create('sample', 'sample gauge');
  try
    LGauge.Inc();
    Assert.AreEqual(1, LGauge.Value, Double.Epsilon);
  finally
    LGauge.Free;
  end;
end;

procedure TGaugeCollectorTestFixture.GaugeMustIncrementBySpecifiedAmount;
begin
  var LGauge := TGauge.Create('sample', 'sample gauge');
  try
    LGauge.Inc(123);
    Assert.AreEqual(123, LGauge.Value, Double.Epsilon);
  finally
    LGauge.Free;
  end;
end;

procedure TGaugeCollectorTestFixture.GaugeMustSetCurrentValue;
begin
  var LGauge := TGauge.Create('sample', 'sample gauge');
  try
    LGauge.SetTo(123);
    Assert.AreEqual(123, LGauge.Value, Double.Epsilon);
  finally
    LGauge.Free;
  end;
end;

initialization

  TDUnitX.RegisterTestFixture(TGaugeCollectorTestFixture);

end.
