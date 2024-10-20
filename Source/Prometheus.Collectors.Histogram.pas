unit Prometheus.Collectors.Histogram;

interface

uses
  Prometheus.Labels,
  Prometheus.Samples,
  Prometheus.SimpleCollector;

type

{ TBuckets }

  TBuckets = TArray<Double>;

{ Consts }

const

  /// <summary>
  ///  Default histogram buckets.
  /// </summary>
  DEFAULT_BUCKETS: TBuckets = [
    0.005, 0.01, 0.025, 0.05, 0.075, 0.1,
    0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10,
    INFINITE
  ];

type

{ Forward class declarations }

  THistogram = class;

{ THistogramChild }

  /// <summary>
  ///  Represents a histogram data collection for a given label combination.
  /// </summary>
  /// <remarks>
  ///  Includes the individual "bucket" values for the specified labels.
  /// <remarks>
  THistogramChild = class
  strict private
    FOwner: THistogram;
    FLock: TObject;
    FCount: Int64;
    FSum: Double;
    FValues: TArray<Int64>;
  public
    /// <summary>
    ///  Creates a new instance of this histogram collector child.
    /// </summary>
    constructor Create(AOwner: THistogram);
    /// <summary>
    ///  Performs object cleanup releasing all the owned instances.
    /// </summary>
    destructor Destroy; override;
    /// <summary>
    ///  Collects all the samples of this histogram child.
    /// </summary>
    procedure CollectChild(var ASamples: TArray<TSample>;
      const ALabelValues: TLabelValues);
    /// <summary>
    ///  Adds a single observation to the histogram.
    /// </summary>
    /// <remarks>
    ///  The buckets are cummulative and any value that is less than - or equal
    ///  to - the upper bound will increment the bucket.
    /// </remarks>
    function Observe(AValue: Double): THistogram;
    /// <summary>
    ///  Gets the total number of samples collected for this labelled child.
    /// </summary>
    property Count: Int64 read FCount;
    /// <summary>
    ///  Gets the total cumulative value calculated for this labelled child.
    /// </summary>
    property Sum: Double read FSum;
    /// <summary>
    ///  The array of cumulative counts for values falling within
    ///  the intervals specified by the parent (owner) histogram.
    /// </summary>
    property Values: TArray<Int64> read FValues;
  end;

{ TBucketGeneratorFunc }

  /// <summary>
  ///  A function that returns the buckets to be used in histogram metrics.
  /// </summary>
  TBucketGeneratorFunc = reference to function: TBuckets;

{ THistogram }

  /// <summary>
  ///  An histogram is a metric that counts observed values using a number
  ///  of configurable buckets and expose those ones as individual counter
  ///  time series.
  /// </summary>
  /// <remarks>
  ///  Histograms are tipically used to allow a generic service to record the
  ///  distribution of a stream of data values into a set of ranged buckets.
  /// </remarks>
  THistogram = class(TSimpleCollector<THistogramChild>)
  strict private
    FBuckets: TBuckets;
    FCount: Int64;
    FSum: Double;
    function GetValue: Double;
  private
    procedure IncrementOwner(AValue: Double);
  strict protected
    function CreateChild: THistogramChild; override;
  public
    /// <summary>
    ///  Creates a new instance of a histogram collector.
    /// </summary>
    constructor Create(const AName: string; const AHelp: string = '';
      const ABuckets: TBuckets = []; const ALabelNames: TLabelNames = []); reintroduce; overload;
    /// <summary>
    ///  Creates a new instance of a histogram collector
    ///  with an increasing sequence in the bucket.
    /// </summary>
    constructor Create(const AName: string; const AHelp: string; const AStart, AFactor: Double; const ACount: Integer;
      const ALabelNames: TLabelNames); reintroduce; overload;
    /// <summary>
    ///  Creates a new instance of a histogram collector
    ///  with a custom sequence of buckets.
    /// </summary>
    /// <remarks>
    ///  Generate buckets by passing an appropriate function when calling this constructor.
    /// </remarks>
    constructor Create(const AName: string; const AHelp: string;
      ABucketGeneratorFunc: TBucketGeneratorFunc;
      const ALabelNames: TLabelNames); reintroduce; overload;
    /// <summary>
    ///  Adds an observation to the top level histogram (i.e. no labels applied).
    /// </summary>
    /// <summary></summary>
    function Observe(AValue: Double): THistogram;
    /// <summary>
    ///  Collects all the metrics and the samples from this collector.
    /// </summary>
    function Collect: TArray<TMetricSamples>; override;
    /// <summary>
    ///  Gets all the metric names that are part of this collector.
    /// </summary>
    function GetNames: TArray<string>; override;
    /// <summary>
    ///  Gets an array holding the upper limit of each histogram bucket.
    /// </summary>
    property Buckets: TBuckets read FBuckets;
    /// <summary>
    ///  Returns the current count of values belonging to this metric.
    /// </summary>
    property Count: Int64 read FCount;
    /// <summary>
    ///  Returns the current sum of values belonging to this metric.
    /// </summary>
    property Sum: Double read FSum;
    /// <summary>
    ///  Returns the current value of the default (unlabelled) histogram.
    /// </summary>
    property Value: Double read GetValue;
  end;

implementation

uses
  System.Generics.Collections,
  System.StrUtils,
  System.SysUtils,
  Prometheus.Resources;

const
  RESERVED_LABEL_NAME = 'le';

{ THistogramChild }

constructor THistogramChild.Create(AOwner: THistogram);
begin
  inherited Create;
  if not Assigned(AOwner) then
    raise EArgumentNilException.Create(StrErrHistogramOwnerNil);
  if Length(AOwner.Buckets) <= 0 then
    raise EArgumentException.Create(StrErrHistogramOwnerNoBuckets);
  FLock := TObject.Create;
  FOwner := AOwner;
  SetLength(FValues, Length(AOwner.Buckets));
end;

destructor THistogramChild.Destroy;
begin
  if Assigned(FLock) then
    FreeAndNil(FLock);
  inherited Destroy;
end;

procedure THistogramChild.CollectChild(var ASamples: TArray<TSample>;
  const ALabelValues: TLabelValues);
begin
  TMonitor.Enter(FLock);
  try
    var LStartIndex := Length(ASamples);
    SetLength(ASamples, LStartIndex + Length(FOwner.Buckets));

    var LLabelNames := FOwner.LabelNames;
    SetLength(LLabelNames, Length(FOwner.LabelNames) + 1);
    LLabelNames[Length(FOwner.LabelNames)] := RESERVED_LABEL_NAME;

    var LLabelValues := ALabelValues;
    SetLength(LLabelValues, Length(ALabelValues) + 1);

    for var LBucketIndex := 0 to Length(FOwner.Buckets) - 1 do
    begin
      var LSample := PSample(@ASamples[LStartIndex + LBucketIndex]);
      LSample^.MetricName := FOwner.Name + '_bucket';
      LSample^.LabelNames := LLabelNames;
      if FOwner.Buckets[LBucketIndex] < INFINITE then
      begin
        var LFormatSettings := TFormatSettings.Create;
        LFormatSettings.DecimalSeparator := '.';
        LFormatSettings.ThousandSeparator := ',';
        LLabelValues[Length(ALabelValues)] := FloatToStr(FOwner.Buckets[LBucketIndex], LFormatSettings)
      end
      else
        LLabelValues[Length(ALabelValues)] := '+Inf';
      LSample^.LabelValues := LLabelValues;
      SetLength(LSample^.LabelValues, Length(LLabelValues));
      LSample^.TimeStamp := 0;
      LSample^.Value := FValues[LBucketIndex];
    end;
  finally
    TMonitor.Exit(FLock);
  end;
end;

function THistogramChild.Observe(AValue: Double): THistogram;
begin
  TMonitor.Enter(FLock);
  try
    for var LIndex := Length(FValues) - 1 downto 0 do
    begin
      if AValue <= FOwner.Buckets[LIndex] then
        Inc(FValues[LIndex])
      else
        Break;
    end;
    Inc(FCount);
    FSum := FSum + AValue;
  finally
    TMonitor.Exit(FLock);
  end;
  FOwner.IncrementOwner(AValue);
  Result := FOwner;
end;

{ THistogram }

constructor THistogram.Create(const AName, AHelp: string;
  const ABuckets: TBuckets; const ALabelNames: TLabelNames);
begin
  if IndexText(RESERVED_LABEL_NAME, ALabelNames) > -1 then
    raise EInvalidOpException.CreateFmt('Label name ''%s'' is reserved', [RESERVED_LABEL_NAME]);

  if Length(ABuckets) > 0 then
    FBuckets := ABuckets
  else
    FBuckets := DEFAULT_BUCKETS;
  TArray.Sort<Double>(FBuckets);

  var LBucketCount := Length(FBuckets);
  if FBuckets[LBucketCount - 1] < INFINITE then
  begin
    SetLength(FBuckets, LBucketCount + 1);
    FBuckets[LBucketCount] := INFINITE;
  end;

  inherited Create(AName, AHelp, ALabelNames);
end;

constructor THistogram.Create(const AName, AHelp: string;
  ABucketGeneratorFunc: TBucketGeneratorFunc; const ALabelNames: TLabelNames);
begin
  Create(AName, AHelp, ABucketGeneratorFunc, ALabelNames);
end;

constructor THistogram.Create(const AName, AHelp: string;
  const AStart, AFactor: Double; const ACount: Integer;
  const ALabelNames: TLabelNames);
begin
  Create(AName, AHelp,
  function (): TBuckets
  begin
    SetLength(Result, ACount);
    var LCurrentValue := AStart;
    for var LCurrentIndex := 0 to ACount - 1 do
    begin
      Result[LCurrentIndex] := LCurrentValue;
      LCurrentValue := LCurrentValue * AFactor;
    end;
  end,
  ALabelNames);
end;

function THistogram.CreateChild: THistogramChild;
begin
  Result := THistogramChild.Create(Self);
end;

function THistogram.Collect: TArray<TMetricSamples>;
begin
  TMonitor.Enter(Lock);
  try
    SetLength(Result, 1);
    var LMetric := PMetricSamples(@Result[0]);
    LMetric^.MetricName := Self.Name;
    LMetric^.MetricHelp := Self.Help;
    LMetric^.MetricType := TMetricType.mtHistogram;
    LMetric^.MetricSum := FSum;
    LMetric^.MetricCount := FCount;
    SetLength(LMetric.Samples, 0); // Clear link to previous samples.
    EnumChildren(
      procedure(const ALabelValues: TLabelValues; const AChild: THistogramChild)
      begin
        if Length(LabelNames) > 0 then
        begin
          // Add the top level sum for the child.
          var LStartIndex := Length(LMetric.Samples);
          SetLength(LMetric.Samples, LStartIndex + 1);
          var LSample := PSample(@LMetric.Samples[LStartIndex]);
          LSample^.MetricName := Name + '_sum';
          LSample^.LabelNames := LabelNames;
          LSample^.LabelValues := ALabelValues;
          LSample^.TimeStamp := 0;
          LSample^.Value := AChild.Sum;
          // Add the top level count for the child.
          LStartIndex := Length(LMetric.Samples);
          SetLength(LMetric.Samples, LStartIndex + 1);
          LSample := PSample(@LMetric.Samples[LStartIndex]);
          LSample^.MetricName := Name + '_count';
          LSample^.LabelNames := LabelNames;
          LSample^.LabelValues := ALabelValues;
          LSample^.TimeStamp := 0;
          LSample^.Value := AChild.Count;
        end;
        AChild.CollectChild(LMetric^.Samples, ALabelValues);
      end);
  finally
    TMonitor.Exit(Lock);
  end;
end;

function THistogram.GetNames: TArray<string>;
begin
  Result := [Name];
end;

function THistogram.GetValue: Double;
begin
  Result := GetNoLabelChild.Sum;
end;

procedure THistogram.IncrementOwner(AValue: Double);
begin
  TMonitor.Enter(Lock);
  try
    Inc(FCount);
    FSum := FSum + AValue;
  finally
    TMonitor.Exit(Lock);
  end;
end;

function THistogram.Observe(AValue: Double): THistogram;
begin
  Result := Self;
  TMonitor.Enter(Lock);
  try
    GetNoLabelChild.Observe(AValue);
  finally
    TMonitor.Exit(Lock);
  end;
end;

end.
