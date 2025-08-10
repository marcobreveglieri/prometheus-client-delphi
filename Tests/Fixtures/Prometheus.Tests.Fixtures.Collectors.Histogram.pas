unit Prometheus.Tests.Fixtures.Collectors.Histogram;

interface

uses
  DUnitX.TestFramework;

type

{ THistogramCollectorTestFixture }

  [TestFixture]
  THistogramCollectorTestFixture = class
  public
    [Test]
    procedure HistogramBucketsMustBeSorted;
    [Test]
    procedure HistogramBucketsMustIncrementBySpecifiedAmount;
    [Test]
    procedure HistogramBucketsMustStartAtZero;
    [Test]
    procedure HistogramCountMustIncrementBySpecifiedAmount;
    [Test]
    procedure HistogramCountMustStartAtZero;
    [Test]
    procedure HistogramLabelMustThrowExceptionIfUseReservedName;
    [Test]
    procedure HistogramSumMustIncrementBySpecifiedAmount;
    [Test]
    procedure HistogramSumMustStartAtZero;
  end;

implementation

uses
  System.SysUtils,
  Prometheus.Collectors.Histogram;

{ THistogramCollectorTestFixture }

procedure THistogramCollectorTestFixture.HistogramBucketsMustBeSorted;
begin
  var LHistogram := THistogram.Create('Sample', '', [2, 0.5, 1]);
  try
    Assert.AreEqual(4, Length(LHistogram.Buckets));
    Assert.AreEqual(0.5, LHistogram.Buckets[0], Double.Epsilon);
    Assert.AreEqual(1.0, LHistogram.Buckets[1], Double.Epsilon);
    Assert.AreEqual(2.0, LHistogram.Buckets[2], Double.Epsilon);
    Assert.AreEqual(INFINITE, LHistogram.Buckets[3], Double.Epsilon);
  finally
    LHistogram.Free;
  end;
end;

procedure THistogramCollectorTestFixture.HistogramBucketsMustIncrementBySpecifiedAmount;
begin
  var LHistogram := THistogram.Create('Sample', '', [0.025, 0.05]);
  try
    LHistogram.Observe(0.01);
    LHistogram.Observe(0.04);
    LHistogram.Observe(0.05);
    LHistogram.Observe(1);

    var LMetricArray := LHistogram.Collect;
    Assert.AreEqual(1, Length(LMetricArray));

    for var LMetric in LMetricArray do
    begin
      Assert.AreEqual('Sample', LMetric.MetricName);
      Assert.AreEqual(4, LMetric.MetricCount, 0);

      for var LSample in LMetric.Samples do
      begin
        Assert.AreEqual('Sample_bucket', LSample.MetricName);
        Assert.AreEqual('le', LSample.LabelNames[0]);
        if LSample.LabelValues[0] = '0.025' then
          Assert.AreEqual(1, LSample.Value, 0)
        else if LSample.LabelValues[0] = '0.05' then
          Assert.AreEqual(3, LSample.Value, 0)
        else if LSample.LabelValues[0] = '+Inf' then
          Assert.AreEqual(4, LSample.Value, 0);
      end;
    end;
  finally
    LHistogram.Free;
  end;
end;

procedure THistogramCollectorTestFixture.HistogramBucketsMustStartAtZero;
begin
  var LHistogram := THistogram.Create('Sample', '', [0.025, 0.05]);
  try
    var LMetricArray := LHistogram.Collect;

    Assert.AreEqual(1, Length( LMetricArray));
    for var LMetric in LMetricArray do
    begin
      Assert.AreEqual('Sample', LMetric.MetricName);
      Assert.AreEqual(0, LMetric.MetricCount, 0);
      for var LSample in LMetric.Samples do
      begin
        Assert.AreEqual('Sample_bucket', LSample.MetricName);
        Assert.AreEqual('le', LSample.LabelNames[0]);
        if LSample.LabelValues[0] = '0.025' then
          Assert.AreEqual(0, LSample.Value, 0);
        if LSample.LabelValues[0] = '0.05' then
          Assert.AreEqual(0, LSample.Value, 0);
        if LSample.LabelValues[0] = '+Inf' then
          Assert.AreEqual(0, LSample.Value, 0);
      end;
    end;
  finally
    LHistogram.Free;
  end;
end;

procedure THistogramCollectorTestFixture.HistogramCountMustIncrementBySpecifiedAmount;
begin
  var LHistogram := THistogram.Create('Sample', '', [0.025, 0.05]);
  try
    LHistogram.Observe(0.01);
    LHistogram.Observe(0.04);
    LHistogram.Observe(1);
    Assert.AreEqual(3, LHistogram.Count, 0);
  finally
    LHistogram.Free;
  end;
end;

procedure THistogramCollectorTestFixture.HistogramCountMustStartAtZero;
begin
  var LHistogram := THistogram.Create('Sample');
  try
    Assert.AreEqual(0, LHistogram.Count, Double.Epsilon);
  finally
    LHistogram.Free;
  end;
end;

procedure THistogramCollectorTestFixture.HistogramLabelMustThrowExceptionIfUseReservedName;
begin
  Assert.WillRaise(
  procedure
  begin
    THistogram.Create('Sample', '', [],   ['le']);
  end,
  EInvalidOpException);
end;

procedure THistogramCollectorTestFixture.HistogramSumMustIncrementBySpecifiedAmount;
begin
  var LHistogram := THistogram.Create('Sample', '', [0.025, 0.05]);
  try
    LHistogram.Observe(0.01);
    LHistogram.Observe(0.04);
    LHistogram.Observe(1);
    Assert.AreEqual(1.05,  LHistogram.Sum  ,0);
  finally
    LHistogram.Free;
  end;
end;

procedure THistogramCollectorTestFixture.HistogramSumMustStartAtZero;
begin
  var LHistogram := THistogram.Create('Sample');
  try
    Assert.AreEqual(0, LHistogram.Sum, Double.Epsilon);
  finally
    LHistogram.Free;
  end;
end;

initialization

  TDUnitX.RegisterTestFixture(THistogramCollectorTestFixture);

end.
