unit Prometheus.Collectors.Summary;

interface

uses
  System.SysUtils,
  Prometheus.Labels,
  Prometheus.Quantiles,
  Prometheus.Samples,
  Prometheus.SimpleCollector;

const

  /// <summary>
  ///  Default width of the sliding time window used to estimate
  ///  the quantiles of a summary metric (10 minutes).
  /// </summary>
  DEFAULT_MAX_AGE_MILLISECONDS = 600000;

  /// <summary>
  ///  Default number of age buckets the sliding time window
  ///  of a summary metric is split into.
  /// </summary>
  DEFAULT_AGE_BUCKETS = 5;

type

{ Forward class declarations }

  TSummary = class;

{ TSummaryChild }

  /// <summary>
  ///  Represents a summary data collection for a given label combination.
  /// </summary>
  /// <remarks>
  ///  Holds the cumulative sum and count of the observed values along with
  ///  the rotating set of quantile estimators that implements the sliding
  ///  time window used to estimate the quantiles.
  /// </remarks>
  TSummaryChild = class
  strict private
    FOwner: TSummary;
    FLock: TObject;
    FCount: Int64;
    FSum: Double;
    FStreams: TArray<TQuantileEstimator>;
    FHeadStreamIndex: Integer;
    FHeadStreamExpires: Int64;
    FStreamDuration: Int64;
    procedure MaybeRotateStreams;
  public
    /// <summary>
    ///  Creates a new instance of this summary collector child.
    /// </summary>
    constructor Create(AOwner: TSummary);
    /// <summary>
    ///  Performs object cleanup releasing all the owned instances.
    /// </summary>
    destructor Destroy; override;
    /// <summary>
    ///  Collects all the samples of this summary child.
    /// </summary>
    procedure CollectChild(var ASamples: TArray<TSample>;
      const ALabelValues: TLabelValues);
    /// <summary>
    ///  Returns the current estimation for the specified quantile rank
    ///  over the sliding time window, or NaN if no data is available.
    /// </summary>
    function GetQuantile(AQuantile: Double): Double;
    /// <summary>
    ///  Adds a single observation to the summary.
    /// </summary>
    function Observe(AValue: Double): TSummary;
    /// <summary>
    ///  Observes the duration, in seconds, taken by the execution
    ///  of the specified procedure.
    /// </summary>
    /// <remarks>
    ///  The duration is observed even if the procedure raises an exception.
    /// </remarks>
    function ObserveDuration(const AProc: TProc): TSummary;
    /// <summary>
    ///  Gets the total number of samples collected for this labelled child.
    /// </summary>
    property Count: Int64 read FCount;
    /// <summary>
    ///  Gets the total cumulative value calculated for this labelled child.
    /// </summary>
    property Sum: Double read FSum;
  end;

{ TSummary }

  /// <summary>
  ///  A summary samples observed values and provides a cumulative count
  ///  and sum of the observations along with a configurable set of quantile
  ///  estimations calculated over a sliding time window.
  /// </summary>
  /// <remarks>
  ///  Summaries are tipically used to track request durations or sizes
  ///  when precomputed client side quantiles are needed; the cumulative
  ///  sum and count are not affected by the sliding time window.
  /// </remarks>
  TSummary = class(TSimpleCollector<TSummaryChild>)
  strict private
    FObjectives: TQuantileObjectives;
    FMaxAgeMilliseconds: Int64;
    FAgeBuckets: Integer;
    FCount: Int64;
    FSum: Double;
    function GetValue: Double;
  private
    procedure IncrementOwner(AValue: Double);
  protected
    /// <summary>
    ///  Returns the current monotonic time in milliseconds; descendant
    ///  classes may override this method to inject a custom clock.
    /// </summary>
    function GetTimeMilliseconds: Int64; virtual;
  strict protected
    function CreateChild: TSummaryChild; override;
  public
    /// <summary>
    ///  Creates a new instance of a summary collector.
    /// </summary>
    /// <remarks>
    ///  If no quantile objectives are specified, the default set is used
    ///  (0.5 ± 0.05, 0.9 ± 0.01, 0.99 ± 0.001).
    /// </remarks>
    constructor Create(const AName: string; const AHelp: string = '';
      const AObjectives: TQuantileObjectives = [];
      const ALabelNames: TLabelNames = [];
      const AMaxAgeMilliseconds: Int64 = DEFAULT_MAX_AGE_MILLISECONDS;
      const AAgeBuckets: Integer = DEFAULT_AGE_BUCKETS); reintroduce;
    /// <summary>
    ///  Returns the current estimation for the specified quantile rank of
    ///  the top level summary (i.e. no labels applied) over the sliding
    ///  time window, or NaN if no data is available.
    /// </summary>
    function GetQuantile(AQuantile: Double): Double;
    /// <summary>
    ///  Adds an observation to the top level summary (i.e. no labels applied).
    /// </summary>
    function Observe(AValue: Double): TSummary;
    /// <summary>
    ///  Observes the duration, in seconds, taken by the execution of the
    ///  specified procedure into the top level summary (i.e. no labels applied).
    /// </summary>
    function ObserveDuration(const AProc: TProc): TSummary;
    /// <summary>
    ///  Collects all the metrics and the samples from this collector.
    /// </summary>
    function Collect: TArray<TMetricSamples>; override;
    /// <summary>
    ///  Gets all the metric names that are part of this collector.
    /// </summary>
    function GetNames: TArray<string>; override;
    /// <summary>
    ///  Gets the quantile objectives configured for this summary.
    /// </summary>
    property Objectives: TQuantileObjectives read FObjectives;
    /// <summary>
    ///  Gets the width of the sliding time window in milliseconds.
    /// </summary>
    property MaxAgeMilliseconds: Int64 read FMaxAgeMilliseconds;
    /// <summary>
    ///  Gets the number of buckets the sliding time window is split into.
    /// </summary>
    property AgeBuckets: Integer read FAgeBuckets;
    /// <summary>
    ///  Returns the current count of values belonging to this metric.
    /// </summary>
    property Count: Int64 read FCount;
    /// <summary>
    ///  Returns the current sum of values belonging to this metric.
    /// </summary>
    property Sum: Double read FSum;
    /// <summary>
    ///  Returns the current value of the default (unlabelled) summary.
    /// </summary>
    property Value: Double read GetValue;
  end;

/// <summary>
///  Returns the default quantile objectives used by summary metrics
///  (0.5 ± 0.05, 0.9 ± 0.01, 0.99 ± 0.001).
/// </summary>
function DefaultObjectives: TQuantileObjectives;

implementation

uses
  System.Diagnostics,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Math,
  System.StrUtils,
  Prometheus.Formatting,
  Prometheus.Resources;

const
  RESERVED_LABEL_NAME = 'quantile';

function DefaultObjectives: TQuantileObjectives;
begin
  Result := [
    TQuantileObjective.Create(0.5, 0.05),
    TQuantileObjective.Create(0.9, 0.01),
    TQuantileObjective.Create(0.99, 0.001)
  ];
end;

{ TSummaryChild }

constructor TSummaryChild.Create(AOwner: TSummary);
begin
  inherited Create;
  if not Assigned(AOwner) then
    raise EArgumentNilException.Create(StrErrSummaryOwnerNil);
  FLock := TObject.Create;
  FOwner := AOwner;
  SetLength(FStreams, AOwner.AgeBuckets);
  for var LIndex := 0 to Length(FStreams) - 1 do
    FStreams[LIndex] := TQuantileEstimator.Create(AOwner.Objectives);
  FStreamDuration := AOwner.MaxAgeMilliseconds div AOwner.AgeBuckets;
  if FStreamDuration <= 0 then
    FStreamDuration := 1;
  FHeadStreamIndex := 0;
  FHeadStreamExpires := AOwner.GetTimeMilliseconds + FStreamDuration;
end;

destructor TSummaryChild.Destroy;
begin
  for var LIndex := 0 to Length(FStreams) - 1 do
    FreeAndNil(FStreams[LIndex]);
  if Assigned(FLock) then
    FreeAndNil(FLock);
  inherited Destroy;
end;

procedure TSummaryChild.CollectChild(var ASamples: TArray<TSample>;
  const ALabelValues: TLabelValues);
begin
  TMonitor.Enter(FLock);
  try
    MaybeRotateStreams;

    var LObjectives := FOwner.Objectives;
    var LStartIndex := Length(ASamples);

    if Length(FOwner.LabelNames) > 0 then
    begin
      // Add the top level sum and count for this labelled child while
      // the child lock is held, so their values stay consistent with
      // each other and with the quantile samples below.
      SetLength(ASamples, LStartIndex + 2);
      var LSumSample := PSample(@ASamples[LStartIndex]);
      LSumSample^.MetricName := FOwner.Name + '_sum';
      LSumSample^.LabelNames := FOwner.LabelNames;
      LSumSample^.LabelValues := ALabelValues;
      LSumSample^.Value := FSum;
      var LCountSample := PSample(@ASamples[LStartIndex + 1]);
      LCountSample^.MetricName := FOwner.Name + '_count';
      LCountSample^.LabelNames := FOwner.LabelNames;
      LCountSample^.LabelValues := ALabelValues;
      LCountSample^.Value := FCount;
      LStartIndex := LStartIndex + 2;
    end;

    SetLength(ASamples, LStartIndex + Length(LObjectives));

    var LLabelNames := FOwner.LabelNames;
    SetLength(LLabelNames, Length(FOwner.LabelNames) + 1);
    LLabelNames[Length(FOwner.LabelNames)] := RESERVED_LABEL_NAME;

    var LLabelValues := ALabelValues;
    SetLength(LLabelValues, Length(ALabelValues) + 1);

    for var LIndex := 0 to Length(LObjectives) - 1 do
    begin
      var LSample := PSample(@ASamples[LStartIndex + LIndex]);
      LSample^.MetricName := FOwner.Name;
      LSample^.LabelNames := LLabelNames;
      LLabelValues[Length(ALabelValues)] := FloatToStr(
        LObjectives[LIndex].Quantile, PromFormatSettings);
      LSample^.LabelValues := LLabelValues;
      SetLength(LSample^.LabelValues, Length(LLabelValues));
      LSample^.Value := FStreams[FHeadStreamIndex]
        .Query(LObjectives[LIndex].Quantile);
    end;
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TSummaryChild.GetQuantile(AQuantile: Double): Double;
begin
  TMonitor.Enter(FLock);
  try
    MaybeRotateStreams;
    Result := FStreams[FHeadStreamIndex].Query(AQuantile);
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TSummaryChild.MaybeRotateStreams;
begin
  var LNow := FOwner.GetTimeMilliseconds;
  if LNow - FHeadStreamExpires >= FOwner.MaxAgeMilliseconds then
  begin
    // The summary has been idle for longer than the whole time window:
    // every stream holds stale data only, so reset all of them at once
    // instead of spinning through each overdue rotation one by one.
    for var LIndex := 0 to Length(FStreams) - 1 do
      FStreams[LIndex].Reset;
    FHeadStreamIndex := 0;
    FHeadStreamExpires := LNow + FStreamDuration;
    Exit;
  end;
  while LNow >= FHeadStreamExpires do
  begin
    FStreams[FHeadStreamIndex].Reset;
    Inc(FHeadStreamIndex);
    if FHeadStreamIndex >= Length(FStreams) then
      FHeadStreamIndex := 0;
    FHeadStreamExpires := FHeadStreamExpires + FStreamDuration;
  end;
end;

function TSummaryChild.Observe(AValue: Double): TSummary;
begin
  TMonitor.Enter(FLock);
  try
    MaybeRotateStreams;
    for var LIndex := 0 to Length(FStreams) - 1 do
      FStreams[LIndex].Insert(AValue);
    Inc(FCount);
    FSum := FSum + AValue;
  finally
    TMonitor.Exit(FLock);
  end;
  FOwner.IncrementOwner(AValue);
  Result := FOwner;
end;

function TSummaryChild.ObserveDuration(const AProc: TProc): TSummary;
begin
  if not Assigned(AProc) then
    raise EArgumentNilException.Create(StrErrNullProcReference);
  var LStopwatch := TStopwatch.StartNew;
  try
    AProc();
  finally
    LStopwatch.Stop;
    Result := Observe(LStopwatch.Elapsed.TotalSeconds);
  end;
end;

{ TSummary }

constructor TSummary.Create(const AName: string; const AHelp: string;
  const AObjectives: TQuantileObjectives; const ALabelNames: TLabelNames;
  const AMaxAgeMilliseconds: Int64; const AAgeBuckets: Integer);
begin
  if IndexText(RESERVED_LABEL_NAME, ALabelNames) > -1 then
    raise EInvalidOpException.CreateFmt('Label name ''%s'' is reserved', [RESERVED_LABEL_NAME]);
  if Length(AObjectives) > 0 then
    FObjectives := Copy(AObjectives)
  else
    FObjectives := DefaultObjectives;
  for var LObjective in FObjectives do
  begin
    if (LObjective.Quantile < 0) or (LObjective.Quantile > 1) then
      raise EArgumentException.Create(StrErrSummaryInvalidQuantile);
    if (LObjective.Error < 0) or (LObjective.Error >= 1) then
      raise EArgumentException.Create(StrErrSummaryInvalidError);
  end;
  if AMaxAgeMilliseconds <= 0 then
    raise EArgumentException.Create(StrErrSummaryInvalidMaxAge);
  if AAgeBuckets <= 0 then
    raise EArgumentException.Create(StrErrSummaryInvalidAgeBuckets);
  TArray.Sort<TQuantileObjective>(FObjectives,
    TComparer<TQuantileObjective>.Construct(
      function(const ALeft, ARight: TQuantileObjective): Integer
      begin
        Result := CompareValue(ALeft.Quantile, ARight.Quantile);
      end));
  for var LIndex := 1 to Length(FObjectives) - 1 do
  begin
    if FObjectives[LIndex].Quantile = FObjectives[LIndex - 1].Quantile then
      raise EArgumentException.Create(StrErrSummaryDuplicateQuantile);
  end;
  FMaxAgeMilliseconds := AMaxAgeMilliseconds;
  FAgeBuckets := AAgeBuckets;
  inherited Create(AName, AHelp, ALabelNames);
end;

function TSummary.CreateChild: TSummaryChild;
begin
  Result := TSummaryChild.Create(Self);
end;

function TSummary.Collect: TArray<TMetricSamples>;
begin
  TMonitor.Enter(Lock);
  try
    SetLength(Result, 1);
    var LMetric := PMetricSamples(@Result[0]);
    LMetric^.MetricName := Self.Name;
    LMetric^.MetricHelp := Self.Help;
    LMetric^.MetricType := TMetricType.mtSummary;
    LMetric^.MetricSum := FSum;
    LMetric^.MetricCount := FCount;
    SetLength(LMetric.Samples, 0); // Clear link to previous samples.
    EnumChildren(
      procedure(const ALabelValues: TLabelValues; const AChild: TSummaryChild)
      begin
        // The child emits its own top level sum and count samples (when
        // labelled) along with the quantile samples, under its own lock.
        AChild.CollectChild(LMetric^.Samples, ALabelValues);
      end
    );
  finally
    TMonitor.Exit(Lock);
  end;
end;

function TSummary.GetNames: TArray<string>;
begin
  Result := [Name];
end;

function TSummary.GetQuantile(AQuantile: Double): Double;
begin
  TMonitor.Enter(Lock);
  try
    Result := GetNoLabelChild.GetQuantile(AQuantile);
  finally
    TMonitor.Exit(Lock);
  end;
end;

function TSummary.GetTimeMilliseconds: Int64;
begin
  // Split the conversion to avoid overflowing Int64 on platforms where
  // the stopwatch frequency is high (e.g. nanosecond resolution on POSIX).
  var LTicks := TStopwatch.GetTimeStamp;
  var LFrequency := TStopwatch.Frequency;
  Result := (LTicks div LFrequency) * 1000
    + ((LTicks mod LFrequency) * 1000) div LFrequency;
end;

function TSummary.GetValue: Double;
begin
  Result := GetNoLabelChild.Sum;
end;

procedure TSummary.IncrementOwner(AValue: Double);
begin
  TMonitor.Enter(Lock);
  try
    Inc(FCount);
    FSum := FSum + AValue;
  finally
    TMonitor.Exit(Lock);
  end;
end;

function TSummary.Observe(AValue: Double): TSummary;
begin
  Result := Self;
  TMonitor.Enter(Lock);
  try
    GetNoLabelChild.Observe(AValue);
  finally
    TMonitor.Exit(Lock);
  end;
end;

function TSummary.ObserveDuration(const AProc: TProc): TSummary;
begin
  Result := Self;
  if not Assigned(AProc) then
    raise EArgumentNilException.Create(StrErrNullProcReference);
  // Measure the duration first and resolve the child only afterwards,
  // so that no child reference is kept alive while the procedure runs
  // (a concurrent Clear may free and replace the children meanwhile).
  var LStopwatch := TStopwatch.StartNew;
  try
    AProc();
  finally
    LStopwatch.Stop;
    Observe(LStopwatch.Elapsed.TotalSeconds);
  end;
end;

end.
