unit Prometheus.Collectors.Gauge;

interface

uses
  System.SysUtils,
  Prometheus.Labels,
  Prometheus.Samples,
  Prometheus.SimpleCollector;

type

{ TGaugeChild }

  /// <summary>
  ///  Represents a child of a gauge assigned to specific label values.
  /// </summary>
  TGaugeChild = class
  strict private
    FLock: TObject;
    FValue: Double;
  public
    /// <summary>
    ///  Creates a new instance of this gauge collector child.
    /// </summary>
    constructor Create;
    /// <summary>
    ///  Performs object cleanup releasing all the owned instances.
    /// </summary>
    destructor Destroy; override;
    /// <summary>
    ///  Decreases this gauge child by the amount provided.
    /// </summary>
    procedure Dec(const AAmount: Double = 1);
    /// <summary>
    ///  Increases this gauge child by the amount provided.
    /// </summary>
    procedure Inc(const AAmount: Double = 1);
    /// <summary>
    ///  Sets the value of this gauge child to the duration
    ///  of the execution of the specified function.
    /// </summary>
    procedure SetDuration(const AProc: TProc);
    /// <summary>
    ///  Sets the value of this gauge child to the specified amount.
    /// </summary>
    procedure SetTo(const AValue: Double);
    /// <summary>
    ///  Sets the value of this gauge child to the current time as a Unix.
    /// </summary>
    procedure SetToCurrentTime;
    /// <summary>
    ///  Returns the current value of this gauge child.
    /// </summary>
    property Value: Double read FValue;
  end;

{ TGauge }

  /// <summary>
  ///  A gauge is a metric that represents a single numerical value that can
  ///  arbitrarily go up and down.
  /// </summary>
  /// <remarks>
  ///  Gauges are typically used for measured values like temperatures or
  ///  current memory usage, but also "counts" that can go up and down,
  ///  like the number of concurrent requests.
  /// </remarks>
  TGauge = class (TSimpleCollector<TGaugeChild>)
  strict private
    function GetValue: Double;
  strict protected
    function CreateChild: TGaugeChild; override;
  public
    /// <summary>
    ///  Collects all the metrics and the samples from this collector.
    /// </summary>
    function Collect: TArray<TMetricSamples>; override;
    /// <summary>
    ///  Gets all the metric names that are part of this collector.
    /// </summary>
    function GetNames: TArray<string>; override;
    /// <summary>
    ///  Decreases the default (unlabelled) gauge by the amount provided.
    /// </summary>
    procedure Dec(const AAmount: Double = 1);
    /// <summary>
    ///  Increases the default (unlabelled) gauge by the amount provided.
    /// </summary>
    procedure Inc(const AAmount: Double = 1);
    /// <summary>
    ///  Set the value of the default (unlabelled) gauge to the
    ///  duration of the execution of the specified function.
    /// </summary>
    procedure SetDuration(const AProc: TProc);
    /// <summary>
    ///  Sets the value of the default (unlabelled) gauge to the specified amount.
    /// </summary>
    procedure SetTo(const AValue: Double);
    /// <summary>
    ///  Sets the value of the default (unlabelled) gauge to the current time as a Unix.
    /// </summary>
    procedure SetToCurrentTime;
    /// <summary>
    ///  Returns the current value of the default (unlabelled) gauge.
    /// </summary>
    property Value: Double read GetValue;
  end;

implementation

{ TGaugeChild }

uses
  System.DateUtils,
  System.Diagnostics,
  Prometheus.Resources;

constructor TGaugeChild.Create;
begin
  inherited Create;
  FLock := TObject.Create;
end;

destructor TGaugeChild.Destroy;
begin
  if Assigned(FLock) then
    FreeAndNil(FLock);
  inherited Destroy;
end;

procedure TGaugeChild.Dec(const AAmount: Double);
begin
  TMonitor.Enter(FLock);
  try
    FValue := FValue - AAmount;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TGaugeChild.Inc(const AAmount: Double);
begin
  TMonitor.Enter(FLock);
  try
    FValue := FValue + AAmount;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TGaugeChild.SetDuration(const AProc: TProc);
begin
  TMonitor.Enter(FLock);
  try
    if not Assigned(AProc) then
      raise EArgumentNilException.Create(StrErrNullProcReference);
    var LStopWatch := TStopwatch.StartNew;
    try
      AProc;
    finally
      LStopWatch.Stop;
      FValue := LStopWatch.Elapsed.TotalMilliseconds;
    end;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TGaugeChild.SetTo(const AValue: Double);
begin
  TMonitor.Enter(FLock);
  try
    FValue := AValue;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TGaugeChild.SetToCurrentTime;
begin
  TMonitor.Enter(FLock);
  try
    FValue := TDateTime.NowUTC.ToUnix();
  finally
    TMonitor.Exit(FLock);
  end;
end;

{ TGauge }

function TGauge.Collect: TArray<TMetricSamples>;
begin
  TMonitor.Enter(Lock);
  try
    SetLength(Result, 1);
    var LMetric := PMetricSamples(@Result[0]);
    LMetric^.MetricName := Self.Name;
    LMetric^.MetricHelp := Self.Help;
    LMetric^.MetricType := TMetricType.mtGauge;
    SetLength(LMetric^.Samples, ChildrenCount);
    var LIndex := 0;
    EnumChildren(
      procedure (const ALabelValues: TLabelValues; const AChild: TGaugeChild)
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

function TGauge.CreateChild: TGaugeChild;
begin
  Result := TGaugeChild.Create();
end;

procedure TGauge.Dec(const AAmount: Double);
begin
  GetNoLabelChild.Dec(AAmount);
end;

function TGauge.GetNames: TArray<string>;
begin
  Result := [Name];
end;

function TGauge.GetValue: Double;
begin
  Result := GetNoLabelChild.Value;
end;

procedure TGauge.Inc(const AAmount: Double);
begin
  GetNoLabelChild.Inc(AAmount);
end;

procedure TGauge.SetDuration(const AProc: TProc);
begin
  GetNoLabelChild.SetDuration(AProc);
end;

procedure TGauge.SetTo(const AValue: Double);
begin
  GetNoLabelChild.SetTo(AValue);
end;

procedure TGauge.SetToCurrentTime;
begin
  GetNoLabelChild.SetToCurrentTime;
end;

end.
