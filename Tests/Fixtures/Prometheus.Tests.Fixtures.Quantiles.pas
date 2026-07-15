unit Prometheus.Tests.Fixtures.Quantiles;

interface

uses
  DUnitX.TestFramework,
  Prometheus.Quantiles;

type

{ TQuantileEstimatorTestFixture }

  [TestFixture]
  TQuantileEstimatorTestFixture = class
  strict private
    function CreateDefaultEstimator: TQuantileEstimator;
  public
    [Test]
    procedure CreateMustRejectEmptyObjectives;
    [Test]
    procedure QueryMustReturnNaNOnEmptyStream;
    [Test]
    procedure QueryMustReturnExactValuesOnSmallStream;
    [Test]
    procedure QueryMustRespectTargetedErrorBounds;
    [Test]
    procedure InsertMustIgnoreNaNValues;
    [Test]
    procedure InsertMustHandleDescendingValues;
    [Test]
    procedure InsertMustHandleDuplicateValues;
    [Test]
    procedure ResetMustClearAllState;
    [Test]
    procedure CompressionMustKeepSampleCountBounded;
  end;

implementation

uses
  System.Math,
  System.SysUtils;

{ TQuantileEstimatorTestFixture }

function TQuantileEstimatorTestFixture.CreateDefaultEstimator: TQuantileEstimator;
begin
  Result := TQuantileEstimator.Create([
    TQuantileObjective.Create(0.5, 0.05),
    TQuantileObjective.Create(0.9, 0.01),
    TQuantileObjective.Create(0.99, 0.001)]);
end;

procedure TQuantileEstimatorTestFixture.CreateMustRejectEmptyObjectives;
begin
  Assert.WillRaise(
  procedure
  begin
    TQuantileEstimator.Create([]);
  end,
  EArgumentException);
end;

procedure TQuantileEstimatorTestFixture.QueryMustReturnNaNOnEmptyStream;
begin
  var LEstimator := CreateDefaultEstimator;
  try
    Assert.IsTrue(LEstimator.Query(0.5).IsNan);
    Assert.IsTrue(LEstimator.Query(0.99).IsNan);
  finally
    LEstimator.Free;
  end;
end;

procedure TQuantileEstimatorTestFixture.QueryMustReturnExactValuesOnSmallStream;
begin
  var LEstimator := CreateDefaultEstimator;
  try
    for var LValue := 1 to 100 do
      LEstimator.Insert(LValue);
    // The inserted values are the integers 1 to 100, so the value at a
    // quantile rank matches the rank itself; the estimation must stay
    // within twice the allowed error of each objective (the query itself
    // is biased by half the invariant, as in the reference implementation).
    var LMedian := LEstimator.Query(0.5);
    Assert.IsTrue((LMedian >= 40) and (LMedian <= 60),
      Format('Median out of bounds: %g', [LMedian]));
    var LNinety := LEstimator.Query(0.9);
    Assert.IsTrue((LNinety >= 88) and (LNinety <= 92),
      Format('0.9 quantile out of bounds: %g', [LNinety]));
    var LNinetyNine := LEstimator.Query(0.99);
    Assert.IsTrue((LNinetyNine >= 97) and (LNinetyNine <= 100),
      Format('0.99 quantile out of bounds: %g', [LNinetyNine]));
  finally
    LEstimator.Free;
  end;
end;

procedure TQuantileEstimatorTestFixture.QueryMustRespectTargetedErrorBounds;
const
  SAMPLE_COUNT = 100000;
begin
  // Build a deterministic shuffle of the values 1 to SAMPLE_COUNT using
  // a Lehmer linear congruential generator with a fixed seed, so that
  // this test never flakes while still feeding data in random order.
  var LValues: TArray<Double>;
  SetLength(LValues, SAMPLE_COUNT);
  for var LIndex := 0 to SAMPLE_COUNT - 1 do
    LValues[LIndex] := LIndex + 1;
  var LSeed: Int64 := 42;
  for var LIndex := SAMPLE_COUNT - 1 downto 1 do
  begin
    LSeed := (LSeed * 48271) mod 2147483647;
    var LSwapIndex := Integer(LSeed mod (LIndex + 1));
    var LTempValue := LValues[LIndex];
    LValues[LIndex] := LValues[LSwapIndex];
    LValues[LSwapIndex] := LTempValue;
  end;

  var LObjectives: TQuantileObjectives := [
    TQuantileObjective.Create(0.5, 0.05),
    TQuantileObjective.Create(0.9, 0.01),
    TQuantileObjective.Create(0.99, 0.001)];
  var LEstimator := TQuantileEstimator.Create(LObjectives);
  try
    for var LValue in LValues do
      LEstimator.Insert(LValue);
    // Since the values are a permutation of 1 to N, each value equals its
    // own rank: the estimation must fall within N * (phi - 2 * epsilon)
    // and N * (phi + 2 * epsilon) for every configured objective.
    for var LObjective in LObjectives do
    begin
      var LEstimate := LEstimator.Query(LObjective.Quantile);
      var LLowerBound := SAMPLE_COUNT * (LObjective.Quantile - 2 * LObjective.Error);
      var LUpperBound := SAMPLE_COUNT * (LObjective.Quantile + 2 * LObjective.Error);
      Assert.IsTrue((LEstimate >= LLowerBound) and (LEstimate <= LUpperBound),
        Format('Quantile %g estimate %g out of bounds [%g, %g]',
          [LObjective.Quantile, LEstimate, LLowerBound, LUpperBound]));
    end;
  finally
    LEstimator.Free;
  end;
end;

procedure TQuantileEstimatorTestFixture.InsertMustIgnoreNaNValues;
begin
  var LEstimator := CreateDefaultEstimator;
  try
    LEstimator.Insert(Double.NaN);
    Assert.AreEqual(0.0, LEstimator.Count, Double.Epsilon);
    Assert.IsTrue(LEstimator.Query(0.5).IsNan);
    // Values observed after a NaN must keep working normally.
    LEstimator.Insert(1);
    LEstimator.Insert(Double.NaN);
    LEstimator.Insert(2);
    LEstimator.Insert(3);
    var LMedian := LEstimator.Query(0.5);
    Assert.IsFalse(LMedian.IsNan);
    Assert.IsTrue((LMedian >= 1) and (LMedian <= 3),
      Format('Median out of bounds: %g', [LMedian]));
  finally
    LEstimator.Free;
  end;
end;

procedure TQuantileEstimatorTestFixture.InsertMustHandleDescendingValues;
begin
  var LEstimator := CreateDefaultEstimator;
  try
    for var LValue := 1000 downto 1 do
      LEstimator.Insert(LValue);
    var LMedian := LEstimator.Query(0.5);
    Assert.IsTrue((LMedian >= 400) and (LMedian <= 600),
      Format('Median out of bounds: %g', [LMedian]));
  finally
    LEstimator.Free;
  end;
end;

procedure TQuantileEstimatorTestFixture.InsertMustHandleDuplicateValues;
begin
  var LEstimator := CreateDefaultEstimator;
  try
    for var LIndex := 1 to 1000 do
      LEstimator.Insert(42);
    Assert.AreEqual(42.0, LEstimator.Query(0.5), Double.Epsilon);
    Assert.AreEqual(42.0, LEstimator.Query(0.99), Double.Epsilon);
  finally
    LEstimator.Free;
  end;
end;

procedure TQuantileEstimatorTestFixture.ResetMustClearAllState;
begin
  var LEstimator := CreateDefaultEstimator;
  try
    for var LValue := 1 to 1000 do
      LEstimator.Insert(LValue);
    LEstimator.Reset;
    Assert.AreEqual(0.0, LEstimator.Count, Double.Epsilon);
    Assert.IsTrue(LEstimator.Query(0.5).IsNan);
    // After a reset the estimation must reflect the new data only.
    for var LValue := 1 to 10 do
      LEstimator.Insert(LValue);
    var LMedian := LEstimator.Query(0.5);
    Assert.IsTrue((LMedian >= 1) and (LMedian <= 10),
      Format('Median out of bounds: %g', [LMedian]));
  finally
    LEstimator.Free;
  end;
end;

procedure TQuantileEstimatorTestFixture.CompressionMustKeepSampleCountBounded;
begin
  var LEstimator := CreateDefaultEstimator;
  try
    for var LValue := 1 to 100000 do
      LEstimator.Insert(LValue);
    LEstimator.Query(0.5); // Force a flush of the insertion buffer.
    Assert.AreEqual(100000.0, LEstimator.Count, Double.Epsilon);
    Assert.IsTrue(LEstimator.SampleCount < 5000,
      Format('Compressed summary too large: %d tuples', [LEstimator.SampleCount]));
  finally
    LEstimator.Free;
  end;
end;

initialization

  TDUnitX.RegisterTestFixture(TQuantileEstimatorTestFixture);

end.
