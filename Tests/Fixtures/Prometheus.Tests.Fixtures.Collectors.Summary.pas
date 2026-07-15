unit Prometheus.Tests.Fixtures.Collectors.Summary;

interface

uses
  DUnitX.TestFramework;

type

{ TSummaryCollectorTestFixture }

  [TestFixture]
  TSummaryCollectorTestFixture = class
  public
    [Test]
    procedure SummaryCountMustStartAtZero;
    [Test]
    procedure SummaryCountMustIncrementBySpecifiedAmount;
    [Test]
    procedure SummarySumMustStartAtZero;
    [Test]
    procedure SummarySumMustIncrementBySpecifiedAmount;
    [Test]
    procedure SummaryLabelMustThrowExceptionIfUseReservedName;
    [Test]
    procedure SummaryObjectivesMustDefaultWhenEmpty;
    [Test]
    procedure SummaryObjectivesMustBeSorted;
    [Test]
    procedure SummaryMustRejectInvalidObjectives;
    [Test]
    procedure SummaryMustRejectDuplicateObjectives;
    [Test]
    procedure SummaryMustRejectInvalidMaxAge;
    [Test]
    procedure SummaryMustRejectInvalidAgeBuckets;
    [Test]
    procedure SummaryQuantilesMustBeNaNWhenEmpty;
    [Test]
    procedure SummaryCollectMustEmitQuantileSamples;
    [Test]
    procedure SummaryWithLabelsMustEmitPerChildSumAndCount;
    [Test]
    procedure SummaryObserveDurationMustRecordElapsedSeconds;
    [Test]
    procedure SummaryObserveDurationMustThrowExceptionIfProcIsNil;
    [Test]
    procedure SummaryQuantilesMustSlideOutOfTimeWindow;
    [Test]
    procedure SummarySumAndCountMustSurviveWindowRotation;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  Prometheus.Collectors.Summary,
  Prometheus.Quantiles;

type

{ TTestableSummary }

  /// <summary>
  ///  A summary with an injectable clock, used to test the sliding
  ///  time window without actually waiting for it to elapse.
  /// </summary>
  TTestableSummary = class(TSummary)
  strict private
    FTimeMilliseconds: Int64;
  protected
    function GetTimeMilliseconds: Int64; override;
  public
    procedure AdvanceTime(AMilliseconds: Int64);
  end;

function TTestableSummary.GetTimeMilliseconds: Int64;
begin
  Result := FTimeMilliseconds;
end;

procedure TTestableSummary.AdvanceTime(AMilliseconds: Int64);
begin
  FTimeMilliseconds := FTimeMilliseconds + AMilliseconds;
end;

{ TSummaryCollectorTestFixture }

procedure TSummaryCollectorTestFixture.SummaryCountMustStartAtZero;
begin
  var LSummary := TSummary.Create('Sample');
  try
    Assert.AreEqual(0, LSummary.Count, 0);
  finally
    LSummary.Free;
  end;
end;

procedure TSummaryCollectorTestFixture.SummaryCountMustIncrementBySpecifiedAmount;
begin
  var LSummary := TSummary.Create('Sample');
  try
    LSummary.Observe(0.01);
    LSummary.Observe(0.04);
    LSummary.Observe(1);
    Assert.AreEqual(3, LSummary.Count, 0);
  finally
    LSummary.Free;
  end;
end;

procedure TSummaryCollectorTestFixture.SummarySumMustStartAtZero;
begin
  var LSummary := TSummary.Create('Sample');
  try
    Assert.AreEqual(0, LSummary.Sum, Double.Epsilon);
  finally
    LSummary.Free;
  end;
end;

procedure TSummaryCollectorTestFixture.SummarySumMustIncrementBySpecifiedAmount;
begin
  var LSummary := TSummary.Create('Sample');
  try
    LSummary.Observe(0.01);
    LSummary.Observe(0.04);
    LSummary.Observe(1);
    Assert.AreEqual(1.05, LSummary.Sum, 0);
  finally
    LSummary.Free;
  end;
end;

procedure TSummaryCollectorTestFixture.SummaryLabelMustThrowExceptionIfUseReservedName;
begin
  Assert.WillRaise(
  procedure
  begin
    TSummary.Create('Sample', '', [], ['quantile']);
  end,
  EInvalidOpException);
end;

procedure TSummaryCollectorTestFixture.SummaryObjectivesMustDefaultWhenEmpty;
begin
  var LSummary := TSummary.Create('Sample');
  try
    Assert.AreEqual(3, Length(LSummary.Objectives));
    Assert.AreEqual(0.5, LSummary.Objectives[0].Quantile, Double.Epsilon);
    Assert.AreEqual(0.9, LSummary.Objectives[1].Quantile, Double.Epsilon);
    Assert.AreEqual(0.99, LSummary.Objectives[2].Quantile, Double.Epsilon);
  finally
    LSummary.Free;
  end;
end;

procedure TSummaryCollectorTestFixture.SummaryObjectivesMustBeSorted;
begin
  var LSummary := TSummary.Create('Sample', '', [
    TQuantileObjective.Create(0.99, 0.001),
    TQuantileObjective.Create(0.5, 0.05)]);
  try
    Assert.AreEqual(2, Length(LSummary.Objectives));
    Assert.AreEqual(0.5, LSummary.Objectives[0].Quantile, Double.Epsilon);
    Assert.AreEqual(0.99, LSummary.Objectives[1].Quantile, Double.Epsilon);
  finally
    LSummary.Free;
  end;
end;

procedure TSummaryCollectorTestFixture.SummaryMustRejectInvalidObjectives;
begin
  Assert.WillRaise(
  procedure
  begin
    TSummary.Create('Sample', '', [TQuantileObjective.Create(1.5, 0.05)]);
  end,
  EArgumentException);
  Assert.WillRaise(
  procedure
  begin
    TSummary.Create('Sample', '', [TQuantileObjective.Create(0.5, 1)]);
  end,
  EArgumentException);
end;

procedure TSummaryCollectorTestFixture.SummaryMustRejectDuplicateObjectives;
begin
  Assert.WillRaise(
  procedure
  begin
    TSummary.Create('Sample', '', [
      TQuantileObjective.Create(0.5, 0.05),
      TQuantileObjective.Create(0.5, 0.01)]);
  end,
  EArgumentException);
end;

procedure TSummaryCollectorTestFixture.SummaryMustRejectInvalidMaxAge;
begin
  Assert.WillRaise(
  procedure
  begin
    TSummary.Create('Sample', '', [], [], 0);
  end,
  EArgumentException);
end;

procedure TSummaryCollectorTestFixture.SummaryMustRejectInvalidAgeBuckets;
begin
  Assert.WillRaise(
  procedure
  begin
    TSummary.Create('Sample', '', [], [], DEFAULT_MAX_AGE_MILLISECONDS, 0);
  end,
  EArgumentException);
end;

procedure TSummaryCollectorTestFixture.SummaryQuantilesMustBeNaNWhenEmpty;
begin
  var LSummary := TSummary.Create('Sample');
  try
    var LMetricArray := LSummary.Collect;
    Assert.AreEqual(1, Length(LMetricArray));
    Assert.AreEqual(3, Length(LMetricArray[0].Samples));
    for var LSample in LMetricArray[0].Samples do
      Assert.IsTrue(LSample.Value.IsNan);
  finally
    LSummary.Free;
  end;
end;

procedure TSummaryCollectorTestFixture.SummaryCollectMustEmitQuantileSamples;
begin
  var LSummary := TSummary.Create('Sample');
  try
    for var LValue := 1 to 100 do
      LSummary.Observe(LValue);

    var LMetricArray := LSummary.Collect;
    Assert.AreEqual(1, Length(LMetricArray));

    var LMetric := LMetricArray[0];
    Assert.AreEqual('Sample', LMetric.MetricName);
    Assert.AreEqual(100, LMetric.MetricCount, 0);
    Assert.AreEqual(5050.0, LMetric.MetricSum, 0);
    Assert.AreEqual(3, Length(LMetric.Samples));

    for var LSample in LMetric.Samples do
    begin
      Assert.AreEqual('Sample', LSample.MetricName);
      Assert.AreEqual('quantile', LSample.LabelNames[0]);
      // The observed values are the integers 1 to 100, so each estimation
      // must stay within twice the allowed error of its quantile objective.
      if LSample.LabelValues[0] = '0.5' then
        Assert.IsTrue((LSample.Value >= 40) and (LSample.Value <= 60))
      else if LSample.LabelValues[0] = '0.9' then
        Assert.IsTrue((LSample.Value >= 88) and (LSample.Value <= 92))
      else if LSample.LabelValues[0] = '0.99' then
        Assert.IsTrue((LSample.Value >= 97) and (LSample.Value <= 100))
      else
        Assert.Fail('Unexpected quantile label value: ' + LSample.LabelValues[0]);
    end;
  finally
    LSummary.Free;
  end;
end;

procedure TSummaryCollectorTestFixture.SummaryWithLabelsMustEmitPerChildSumAndCount;
begin
  var LSummary := TSummary.Create('Sample', '', [], ['method']);
  try
    LSummary.Labels(['get'])
      .Observe(1);
    LSummary.Labels(['get'])
      .Observe(2);

    var LMetricArray := LSummary.Collect;
    Assert.AreEqual(1, Length(LMetricArray));

    var LSumFound := False;
    var LCountFound := False;
    var LQuantileCount := 0;
    for var LSample in LMetricArray[0].Samples do
    begin
      if LSample.MetricName = 'Sample_sum' then
      begin
        LSumFound := True;
        Assert.AreEqual('method', LSample.LabelNames[0]);
        Assert.AreEqual('get', LSample.LabelValues[0]);
        Assert.AreEqual(3.0, LSample.Value, 0);
      end
      else if LSample.MetricName = 'Sample_count' then
      begin
        LCountFound := True;
        Assert.AreEqual('get', LSample.LabelValues[0]);
        Assert.AreEqual(2.0, LSample.Value, 0);
      end
      else if LSample.MetricName = 'Sample' then
      begin
        Inc(LQuantileCount);
        Assert.AreEqual('method', LSample.LabelNames[0]);
        Assert.AreEqual('quantile', LSample.LabelNames[1]);
        Assert.AreEqual('get', LSample.LabelValues[0]);
      end;
    end;
    Assert.IsTrue(LSumFound, 'Missing per-child sum sample');
    Assert.IsTrue(LCountFound, 'Missing per-child count sample');
    Assert.AreEqual(3, LQuantileCount);
  finally
    LSummary.Free;
  end;
end;

procedure TSummaryCollectorTestFixture.SummaryObserveDurationMustRecordElapsedSeconds;
begin
  var LSummary := TSummary.Create('Sample');
  try
    LSummary.ObserveDuration(
      procedure
      begin
        TThread.Sleep(20);
      end);
    Assert.AreEqual(1, LSummary.Count, 0);
    Assert.IsTrue(LSummary.Sum >= 0.015,
      Format('Expected an elapsed time of at least 0.015 seconds, got %g', [LSummary.Sum]));
    Assert.IsTrue(LSummary.Sum < 10,
      Format('Elapsed time not recorded in seconds: %g', [LSummary.Sum]));
  finally
    LSummary.Free;
  end;
end;

procedure TSummaryCollectorTestFixture.SummaryObserveDurationMustThrowExceptionIfProcIsNil;
begin
  var LSummary := TSummary.Create('Sample');
  try
    Assert.WillRaise(
    procedure
    begin
      LSummary.ObserveDuration(nil);
    end,
    EArgumentNilException);
  finally
    LSummary.Free;
  end;
end;

procedure TSummaryCollectorTestFixture.SummaryQuantilesMustSlideOutOfTimeWindow;
begin
  // Sliding window of 10 seconds split into 5 age buckets,
  // so one stream rotation occurs every 2 seconds.
  var LSummary := TTestableSummary.Create('Sample', '', [], [], 10000, 5);
  try
    LSummary.Observe(100);
    Assert.AreEqual(100.0, LSummary.GetQuantile(0.9), Double.Epsilon);

    // After 4 seconds both values are still within the time window.
    LSummary.AdvanceTime(4000);
    LSummary.Observe(1);
    Assert.AreEqual(100.0, LSummary.GetQuantile(0.9), Double.Epsilon);

    // After 10.5 seconds the first value has slid out of the time window
    // while the second one is still part of it.
    LSummary.AdvanceTime(6500);
    Assert.AreEqual(1.0, LSummary.GetQuantile(0.9), Double.Epsilon);
  finally
    LSummary.Free;
  end;
end;

procedure TSummaryCollectorTestFixture.SummarySumAndCountMustSurviveWindowRotation;
begin
  var LSummary := TTestableSummary.Create('Sample', '', [], [], 10000, 5);
  try
    LSummary.Observe(100);
    LSummary.Observe(50);

    // Advance beyond the whole time window: the quantile estimations
    // become NaN but the cumulative sum and count keep their values.
    LSummary.AdvanceTime(20000);
    Assert.IsTrue(LSummary.GetQuantile(0.5).IsNan);
    Assert.AreEqual(2, LSummary.Count, 0);
    Assert.AreEqual(150.0, LSummary.Sum, 0);
  finally
    LSummary.Free;
  end;
end;

initialization

  TDUnitX.RegisterTestFixture(TSummaryCollectorTestFixture);

end.
