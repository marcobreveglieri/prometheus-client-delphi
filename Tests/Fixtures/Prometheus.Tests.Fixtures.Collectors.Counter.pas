unit Prometheus.Tests.Fixtures.Collectors.Counter;

interface

uses
  DUnitX.TestFramework;

type

{ TCounterCollectorTestFixture }

  [TestFixture]
  TCounterCollectorTestFixture = class
  public
    [Test]
    procedure CounterMustStartAtZero;
    [Test]
    procedure CounterMustIncrementByOneAsDefault;
    [Test]
    procedure CounterMustIncrementBySpecifiedAmount;
    [Test]
    procedure CounterMustThrowExceptionIfAmountIsNegative;
  end;

implementation

uses
  System.SysUtils,
  Prometheus.Collectors.Counter;

{ TCounterCollectorTestFixture }

procedure TCounterCollectorTestFixture.CounterMustIncrementByOneAsDefault;
begin
  var LCounter := TCounter.Create('sample', 'sample counter');
  try
    LCounter.Inc();
    Assert.AreEqual(1, LCounter.Value, Double.Epsilon);
  finally
    LCounter.Free;
  end;
end;

procedure TCounterCollectorTestFixture.CounterMustIncrementBySpecifiedAmount;
begin
  var LCounter := TCounter.Create('sample', 'sample counter');
  try
    LCounter.Inc(123);
    Assert.AreEqual(123, LCounter.Value, Double.Epsilon);
  finally
    LCounter.Free;
  end;
end;

procedure TCounterCollectorTestFixture.CounterMustStartAtZero;
begin
  var LCounter := TCounter.Create('sample', 'sample counter');
  try
    Assert.AreEqual(0, LCounter.Value, Double.Epsilon);
  finally
    LCounter.Free;
  end;
end;

procedure TCounterCollectorTestFixture.CounterMustThrowExceptionIfAmountIsNegative;
begin
  var LCounter := TCounter.Create('sample', 'sample counter');
  try
    Assert.WillRaise(
    procedure
    begin
      LCounter.Inc(-1);
    end, EArgumentOutOfRangeException);
  finally
    LCounter.Free;
  end;
end;

initialization

  TDUnitX.RegisterTestFixture(TCounterCollectorTestFixture);

end.
