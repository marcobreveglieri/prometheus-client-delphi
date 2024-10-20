unit Prometheus.Collectors.Counter;

interface

uses
  Prometheus.Labels,
  Prometheus.Samples,
  Prometheus.SimpleCollector;

type

{ TCounterChild }

  /// <summary>
  ///  Represents a child of a counter assigned to specific label values.
  /// </summary>
  TCounterChild = class
  strict private
    FLock: TObject;
    FValue: Double;
  public
    /// <summary>
    ///  Creates a new instance of this counter collector child.
    /// </summary>
    constructor Create;
    /// <summary>
    ///  Performs object cleanup releasing all the owned instances.
    /// </summary>
    destructor Destroy; override;
    /// <summary>
    ///  Increases this counter child by the amount provided.
    /// </summary>
    procedure Inc(const AAmount: Double = 1);
    /// <summary>
    ///  Returns the current value of this counter child.
    /// </summary>
    property Value: Double read FValue;
  end;

{ TCounter }

  /// <summary>
  ///  A counter is a metric that represents a single monotonically increasing
  ///  counter whose value can only increase or be reset to zero on restart.
  /// </summary>
  /// <remarks>
  ///  You can tipically use a counter to represent the number of requests
  ///  served, tasks completed, or errors. Do not use a counter to expose a
  ///  value that can decrease. For example, do not use a counter for the number
  ///  of currently running processes; use a <see cref="TGauge">gauge</see> instead.
  /// </remarks>
  TCounter = class (TSimpleCollector<TCounterChild>)
  strict private
    function GetValue: Double;
  strict protected
    function CreateChild: TCounterChild; override;
  public
    /// <summary>
    ///  Collects all the metrics and the samples from this collector.
    /// </summary>
    function Collect: TArray<TMetricSamples>; override;
    /// <summary>
    ///  Increases the default (unlabelled) counter by the amount provided.
    /// </summary>
    procedure Inc(const AAmount: Double = 1);
    /// <summary>
    ///  Gets all the metric names that are part of this collector.
    /// </summary>
    function GetNames: TArray<string>; override;
    /// <summary>
    ///  Returns the current value of the default (unlabelled) counter.
    /// </summary>
    property Value: Double read GetValue;
  end;

implementation

uses
  System.SysUtils,
  Prometheus.Resources;

{ TCounterChild }

constructor TCounterChild.Create;
begin
  inherited Create;
  FLock := TObject.Create;
end;

destructor TCounterChild.Destroy;
begin
  if Assigned(FLock) then
    FreeAndNil(FLock);
  inherited Destroy;
end;

procedure TCounterChild.Inc(const AAmount: Double);
begin
  TMonitor.Enter(FLock);
  try
    if AAmount <= 0 then
      raise EArgumentOutOfRangeException.Create(StrErrAmountLessThanZero);
    FValue := FValue + AAmount;
  finally
    TMonitor.Exit(FLock);
  end;
end;

{ TCounter }

function TCounter.Collect: TArray<TMetricSamples>;
begin
  TMonitor.Enter(Lock);
  try
    SetLength(Result, 1);
    var LMetric := PMetricSamples(@Result[0]);
    LMetric^.MetricName := Self.Name;
    LMetric^.MetricHelp := Self.Help;
    LMetric^.MetricType := TMetricType.mtCounter;
    SetLength(LMetric^.Samples, ChildrenCount);
    var LIndex := 0;
    EnumChildren(
      procedure (const ALabelValues: TLabelValues; const AChild: TCounterChild)
      begin
        var LSample := PSample(@LMetric^.Samples[LIndex]);
        LSample^.MetricName := Self.Name;
        LSample^.LabelNames := Self.LabelNames;
        LSample^.LabelValues := ALabelValues;
        LSample^.Value := AChild.Value;
        System.Inc(LIndex);
      end
    );
  finally
    TMonitor.Exit(Lock);
  end;
end;

function TCounter.CreateChild: TCounterChild;
begin
  Result := TCounterChild.Create();
end;

function TCounter.GetNames: TArray<string>;
begin
  Result := [Name];
end;

function TCounter.GetValue: Double;
begin
  Result := GetNoLabelChild.Value;
end;

procedure TCounter.Inc(const AAmount: Double);
begin
  GetNoLabelChild.Inc(AAmount);
end;

end.
