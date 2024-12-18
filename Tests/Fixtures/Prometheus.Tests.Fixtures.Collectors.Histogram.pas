unit Prometheus.Tests.Fixtures.Collectors.Histogram;

interface

uses
  DUnitX.TestFramework;

type

{ TCollectorTestFixture }

  [TestFixture]
  THistogramCollectorTestFixture = class
  private
  public
    [Test]
    procedure BucketsMustStartAtZero;
    [Test]
    procedure CounterAndSumMustStartAtZero;
    [Test]
    procedure BucketsMustBeSorted;
    [Test]
    procedure HistogramMustThrowExceptionIfUseReservedLabelName;
    [Test]
    procedure BucketsMustIncrementBySpecifiedAmount;
    [Test]
    procedure SumMustIncrementBySpecifiedAmount;
  end;

implementation

uses
  System.SysUtils,
  Prometheus.Collectors.Histogram, Prometheus.Samples, Prometheus.Labels;

{ THistogramCollectorTestFixture }


procedure THistogramCollectorTestFixture.BucketsMustBeSorted;
var
  lHistogram: THistogram;
begin
  lHistogram := THistogram.Create('Sample', '', [2, 0.5, 1]);
  Assert.AreEqual(4, Length(lHistogram.Buckets));
  Assert.AreEqual(0.5, lHistogram.Buckets[0], Double.Epsilon);
  Assert.AreEqual(1, lHistogram.Buckets[1], Double.Epsilon);
  Assert.AreEqual(2, lHistogram.Buckets[2], Double.Epsilon);
  Assert.AreEqual(INFINITE, lHistogram.Buckets[3], Double.Epsilon);
end;

procedure THistogramCollectorTestFixture.BucketsMustIncrementBySpecifiedAmount;
var
  lHistogram: THistogram;
  Metrics: TArray<TMetricSamples>;
begin
  lHistogram := THistogram.Create('Sample', '', [0.025, 0.05]);
  try
    lHistogram.Observe(0.01);
    lHistogram.Observe(0.04);
    lHistogram.Observe(0.05);
    lHistogram.Observe(1);

    Metrics := lHistogram.Collect;
    Assert.AreEqual(1, Length( Metrics));
    for var  Metric in Metrics do
    begin
      Assert.AreEqual('Sample', Metric.MetricName);
      Assert.AreEqual(4, Metric.MetricCount, 0);

      for var Sample in Metric.Samples do
      begin
        Assert.AreEqual('Sample_bucket', Sample.MetricName);
        Assert.AreEqual('le', Sample.LabelNames[0]);
        if Sample.LabelValues[0] = '0.025' then
          Assert.AreEqual(1, Sample.Value, 0)
        else if Sample.LabelValues[0] = '0.05' then
          Assert.AreEqual(3, Sample.Value, 0)
        else if Sample.LabelValues[0] = '+Inf' then
          Assert.AreEqual(4, Sample.Value, 0);
      end;
    end;
  finally
    lHistogram.Free;
  end;
end;

procedure THistogramCollectorTestFixture.SumMustIncrementBySpecifiedAmount;
var
  lHistogram: THistogram;
begin
  lHistogram := THistogram.Create('Sample', '', [0.025, 0.05]);
  try
    lHistogram.Observe(0.01);
    lHistogram.Observe(0.04);
    lHistogram.Observe(1);
    Assert.AreEqual(3, lHistogram.Count, 0);
    Assert.AreEqual(1.05,  lHistogram.Sum  ,0);
  finally
    lHistogram.Free;
  end;
end;


procedure THistogramCollectorTestFixture.BucketsMustStartAtZero;
var
  lHistogram: THistogram;
  Metrics: TArray<TMetricSamples>;
begin
  lHistogram := THistogram.Create('Sample', '', [0.025, 0.05]);
  try
    Metrics := lHistogram.Collect;

    Assert.AreEqual(1, Length( Metrics));
    for var  Metric in Metrics do
    begin
      Assert.AreEqual('Sample', Metric.MetricName);
      Assert.AreEqual(0, Metric.MetricCount, 0);
      for var Sample in Metric.Samples do
      begin
        Assert.AreEqual('Sample_bucket', Sample.MetricName);
        Assert.AreEqual('le', Sample.LabelNames[0]);
        if Sample.LabelValues[0] = '0.025' then
          Assert.AreEqual(0, Sample.Value, 0);
        if Sample.LabelValues[0] = '0.05' then
          Assert.AreEqual(0, Sample.Value, 0);
        if Sample.LabelValues[0] = '+Inf' then
          Assert.AreEqual(0, Sample.Value, 0);
      end;
    end;
  finally
    lHistogram.Free;
  end;
end;

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


procedure THistogramCollectorTestFixture.HistogramMustThrowExceptionIfUseReservedLabelName;
var
  lHistogram: THistogram;
begin
  Assert.WillRaise(
  procedure
  begin
    try
      lHistogram := THistogram.Create('Sample', '', [],   ['le']);
    finally
      lHistogram.Free;
    end;
  end, EInvalidOpException);
end;



initialization

  TDUnitX.RegisterTestFixture(THistogramCollectorTestFixture);

end.

