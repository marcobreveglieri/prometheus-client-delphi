unit Prometheus.Samples;

interface

uses
  Prometheus.Labels,
  Prometheus.Metrics;

type

{ TSample }

  TMetricType = (mtCounter, mtGauge, mtHistogram);

  /// <summary>
  ///  Represents a typical sample that can belong to any metrics and can
  ///  be associated to label names and values. Each sample can be scraped
  ///  forming the actual time series data stored inside Prometheus.
  /// </summary>
  TSample = record
    /// <summary>
    ///  The metric name this sample belongs to.
    /// </summary>
    MetricName: string;
    /// <summary>
    ///  The names for the labels this sample is bound to.
    /// </summary>
    LabelNames: TLabelNames;
    /// <summary>
    ///  The values for the labels this sample is bound to.
    /// </summary>
    LabelValues: TArray<string>;
    /// <summary>
    ///  The timestamp of this sample.
    /// </summary>
    TimeStamp: Int64;
    /// <summary>
    ///  The current value of this sample.
    /// </summary>
    Value: Double;
    /// <summary>
    ///  Check if this sample is bound to label names and values.
    /// </summary>
    function HasLabels: Boolean;
    /// <summary>
    ///  Check if this sample has a valid timestamp.
    /// </summary>
    function HasTimeStamp: Boolean;
  end;

{ PSample }

  /// <summary>
  ///  Represents a pointer to a sample record.
  /// </summary>
  PSample = ^TSample;

{ TMetricSamples }

  /// <summary>
  ///  Represents a set of samples collected for a specific metric.
  /// </summary>
  TMetricSamples = record
    /// <summary>
    ///  The name of the metric.
    /// </summary>
    MetricName: string;
    /// <summary>
    ///  The help text for the metric.
    /// </summary>
    MetricHelp: string;
    /// <summary>
    ///  The type of the metric.
    /// </summary>
    MetricType: TMetricType;
    /// <summary>
    ///  The set of samples collected for the metric.
    /// </summary>
    Samples: TArray<TSample>;
    /// <summary>
    ///  The sum off all metrics values, used for histogram
    /// </summary>
    MetricSum: Double;
    /// <summary>
    ///  The count of all observed processes, used for histogram
    /// </summary>
    MetricCount: Double;
  end;

{ PMetricSamples }

  /// <summary>
  ///  Represents a pointer to a set of metric samples.
  /// </summary>
  PMetricSamples = ^TMetricSamples;

const
  StrMetricType: array[TMetricType] of string = ('counter', 'gauge', 'histogram');

implementation

{ TSample }

function TSample.HasLabels: Boolean;
begin
  Result := (Length(LabelNames) > 0) and (Length(LabelValues) > 0);
end;

function TSample.HasTimeStamp: Boolean;
begin
  Result := TimeStamp > 0;
end;

end.
