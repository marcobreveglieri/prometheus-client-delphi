unit Prometheus.Collector;

interface

uses
  Prometheus.Samples;

type

{ TCollector }

  /// <summary>
  ///  This is the base class for all the collector types.
  ///  Each collector is scraped for metrics and can be registered at one
  ///  ore more registries.
  /// </summary>
  TCollector = class abstract
  public
    /// <summary>
    ///  Collects all the metrics and the samples from this collector.
    /// </summary>
    function Collect: TArray<TMetricSamples>; virtual; abstract;
    /// <summary>
    ///  Gets all the metric names that are part of this collector.
    /// </summary>
    function GetNames: TArray<string>; virtual; abstract;
  end;

implementation

end.
