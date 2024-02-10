unit Prometheus.Tests.Fixtures.Collectors.Histogram;

interface

uses
  DUnitX.TestFramework;

type

{ TCollectorTestFixture }

  [TestFixture]
  THistogramCollectorTestFixture = class
  public
    [Test]
    procedure CounterAndSumMustStartAtZero;
    [Test]
    procedure CounterMustIncrementByOneAsDefault;
    [Test]
    procedure SumMustIncrementByOneAsDefault;
    [Test]
    procedure CounterMustIncrementBySpecifiedAmount;
    [Test]
    procedure SumMustIncrementBySpecifiedAmount;
    [Test]
    procedure HistogramMustThrowExceptionIfUseReservedLabelName;
  end;

implementation

uses
  System.SysUtils,
  Prometheus.Collectors.Histogram;

{ THistogramCollectorTestFixture }

procedure THistogramCollectorTestFixture.CounterAndSumMustStartAtZero;
var
  lHistogram: THistogram;
begin
  lHistogram := THistogram.Create('Sample');
  try
    Assert.AreEqual(0, lHistogram.Count, Double.Epsilon);
    Assert.AreEqual(0, lHistogram.Sum, Double.Epsilon);
  finally
    lHistogram.Free;
  end;
end;

procedure THistogramCollectorTestFixture.CounterMustIncrementByOneAsDefault;
var
  lHistogram: THistogram;
begin
  lHistogram := THistogram.Create('Sample');
  try
    lHistogram.IncCount;
    Assert.AreEqual(1, lHistogram.Count, Double.Epsilon);
  finally
    lHistogram.Free;
  end;
end;

procedure THistogramCollectorTestFixture.CounterMustIncrementBySpecifiedAmount;
var
  lHistogram: THistogram;
begin
  lHistogram := THistogram.Create('Sample');
  try
    lHistogram.IncCount(2.5);
    Assert.AreEqual(2.5, lHistogram.Count, Double.Epsilon);
  finally
    lHistogram.Free;
  end;
end;

procedure THistogramCollectorTestFixture.HistogramMustThrowExceptionIfUseReservedLabelName;
var
  lHistogram: THistogram;
begin
  Assert.WillRaise(
  procedure
  begin
    lHistogram := THistogram.Create('Sample', '', ['le']);
  end, EInvalidOpException);
end;

procedure THistogramCollectorTestFixture.SumMustIncrementByOneAsDefault;
var
  lHistogram: THistogram;
begin
  lHistogram := THistogram.Create('Sample');
  try
    lHistogram.IncSum;
    Assert.AreEqual(1, lHistogram.Sum, Double.Epsilon);
  finally
    lHistogram.Free;
  end;
end;

procedure THistogramCollectorTestFixture.SumMustIncrementBySpecifiedAmount;
var
  lHistogram: THistogram;
begin
  lHistogram := THistogram.Create('Sample');
  try
    lHistogram.IncSum(2.5);
    Assert.AreEqual(2.5, lHistogram.Sum, Double.Epsilon);
  finally
    lHistogram.Free;
  end;
end;

end.

