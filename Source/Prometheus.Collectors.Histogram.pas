unit Prometheus.Collectors.Histogram;

interface

uses
  System.StrUtils,
  System.SysUtils,
  System.Generics.Collections,
  Prometheus.Labels,
  Prometheus.Samples,
  Prometheus.SimpleCollector;

type
  TBuckets = TArray<Double>;

const
  DEFAULT_BUCKETS: TBuckets = [0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10, INFINITE];

type
  THistogram = class;

  /// <summary>Histogram Data Collection for a given label combination</summary>
  /// <remarks>Includes the individual "Bucket" values for the specified labels<remarks>
  THistogramChild = class
  private
    FOwner: THistogram;
    FLock: TObject;
    FCount: Int64;
    FSum: Double;
    FBucketValues: TArray<Int64>;
    procedure CollectChild(var ASamples: TArray<TSample>; const ALabelValues: TLabelValues);
  public
    /// <summary>Creates a new instance of this histogram collector child.</summary>
    constructor Create(AOwner: THistogram);
    /// <summary>Performs object cleanup releasing all the owned instances.</summary>
    destructor Destroy; override;
    /// <summary>Array of the cummulative counts for values falling within the intervals specified by the parent histogram</summary>
    property Values: TArray<Int64> read FBucketValues;
    /// <summary>Adds an observation to this labelled child</summary>
    /// <remarks>Increments the parent values<remarks>
    function Observe(AValue: Double): THistogram;
    /// <summary>Total number of samples collected for this labelled child</summary>
    property Count: Int64 read FCount;
    /// <summary>Total cummulative value collected for this labelled child.</summary>
    property Sum: Double read FSum;
  end;

  TComplexBucketFunc = reference to function: TBuckets;

  /// <summary>Classic Histogram with individually labelled object to collect values based on a histogram</summary>
  THistogram = class(TSimpleCollector<THistogramChild>)
  private
    FBuckets: TBuckets;
    FSum: Double;
    FCount: Int64;
    function GetValue: Double;
  protected
    function CreateChild: THistogramChild; override;
    procedure IncrementOwner(AValue: Double);
  public
    /// <summary>Creates a new instance of this histogram collector.</summary>
    constructor Create(const AName: string; const AHelp: string = ''; const ABuckets: TBuckets = [];
      const ALabelNames: TLabelNames = []); reintroduce; overload;

    /// <summary>Creates a new instance of this histogram collector with an increasing sequence in the bucket</summary>
    constructor Create(const AName: string; const AHelp: string; const AStart, AFactor: Double; const ACount: Integer;
      const ALabelNames: TLabelNames); reintroduce; overload;

    /// <summary>Creates a new instance of this histogram collector with a customised sequence of buckets</summary>
    constructor Create(const AName: string; const AHelp: string; GenerateBuckets: TComplexBucketFunc; const ALabelNames: TLabelNames);
      reintroduce; overload;

    /// <summary>Add an observation to the top level histogram i.e. no labels applied.</summary>
    function Observe(AValue: Double): THistogram;
    /// <summary> Collects all the metrics and the samples from this collector. </summary>
    function Collect: TArray<TMetricSamples>; override;
    /// <summary>Gets all the metric names that are part of this collector.</summary>
    function GetNames: TArray<string>; override;
    /// <summary>An array holding the upper limit of each histogram bucket.</summary>
    property Buckets: TBuckets read FBuckets;
    /// <summary>Returns the current value of the total count metric.</summary>
    property Count: Int64 read FCount;
    /// <summary>Returns the current value of the total sum metric.</summary>
    property Sum: Double read FSum;
    /// <summary>Returns the current value of the default (unlabelled) histogram. </summary>
    property Value: Double read GetValue;
  end;

implementation

const
  RESERVED_LABEL_NAME = 'le';

  { THistogramChild }
constructor THistogramChild.Create(AOwner: THistogram);
begin
  inherited Create;
  FLock := TObject.Create;
  FOwner := AOwner;
  SetLength(FBucketValues, Length(AOwner.FBuckets));
end;

destructor THistogramChild.Destroy;
begin
  if Assigned(FLock) then
    FreeAndNil(FLock);
  inherited Destroy;
end;

function THistogramChild.Observe(AValue: Double): THistogram;
(* The buckets are cummulative and any value that is less than the upper bound will increment the bucket *)
begin
  TMonitor.Enter(FLock);
  try
    Inc(FBucketValues[0]); (* the smallest bucket is always incremented ! *)
    for var I := 1 to Length(FBucketValues) - 1 do
    begin
      if AValue <= FOwner.FBuckets[I - 1] then
        Break;
      Inc(FBucketValues[I])
    end;
    Inc(FCount);
    FSum := FSum + AValue;
  finally
    TMonitor.Exit(FLock);
  end;

  FOwner.IncrementOwner(AValue);
  Result := FOwner;
end;

procedure THistogramChild.CollectChild(var ASamples: TArray<TSample>; const ALabelValues: TLabelValues);
var
  StartIdx: Integer;
  lSample: PSample;
  lLabelNames: TLabelNames;
  lLabelValues: TLabelValues;
begin
  TMonitor.Enter(FLock);
  try
    StartIdx := Length(ASamples);
    SetLength(ASamples, StartIdx + Length(FOwner.FBuckets));

    lLabelNames := FOwner.LabelNames;
    (* force a copy and resize, otherwise local is just a pointer to original *)
    SetLength(lLabelNames, Length(FOwner.LabelNames) + 1);
    lLabelNames[Length(FOwner.LabelNames)] := RESERVED_LABEL_NAME;

    (* force a copy and resize *)
    lLabelValues := ALabelValues;
    SetLength(lLabelValues, Length(ALabelValues) + 1);

    for var I := 0 to Length(FOwner.FBuckets) - 1 do
    begin
      lSample := PSample(@ASamples[StartIdx + I]);
      lSample^.MetricName := FOwner.Name + '_bucket';

      lSample^.LabelNames := lLabelNames;
      if FOwner.FBuckets[I] < INFINITE then
      begin
        var
        lFormatSettings := TFormatSettings.Create;
        lFormatSettings.DecimalSeparator := '.';
        lFormatSettings.ThousandSeparator := ',';
        lLabelValues[Length(ALabelValues)] := FloatToStr(FOwner.FBuckets[I], lFormatSettings)
      end
      else
        lLabelValues[Length(ALabelValues)] := '+Inf';

      lSample^.LabelValues := lLabelValues;
      (* NB: this forces a copy rather than a ref *)
      SetLength(lSample^.LabelValues, Length(lLabelValues));

      lSample^.TimeStamp := 0;
      lSample^.Value := FBucketValues[I];
    end;
  finally
    TMonitor.Exit(FLock);
  end;
end;

{ THistogram }
constructor THistogram.Create(const AName, AHelp: string; const ABuckets: TBuckets; const ALabelNames: TLabelNames);
var
  LastBucketIdx: Integer;
begin
  if IndexText(RESERVED_LABEL_NAME, ALabelNames) > -1 then
    raise EInvalidOpException.CreateFmt('Label name ''%s'' is reserved', [RESERVED_LABEL_NAME]);

  if Length(ABuckets) > 0 then
    FBuckets := ABuckets
  else
    FBuckets := DEFAULT_BUCKETS;
  TArray.Sort<Double>(FBuckets);
  LastBucketIdx := Length(FBuckets);
  if FBuckets[LastBucketIdx - 1] < INFINITE then
  begin
    SetLength(FBuckets, LastBucketIdx + 1);
    FBuckets[LastBucketIdx] := INFINITE;
  end;

  inherited Create(AName, AHelp, ALabelNames);
end;

constructor THistogram.Create(const AName, AHelp: string; GenerateBuckets: TComplexBucketFunc; const ALabelNames: TLabelNames);
var
  lBuckets: TBuckets;
begin
  lBuckets := GenerateBuckets;
  Create(AName, AHelp, lBuckets, ALabelNames);
end;

constructor THistogram.Create(const AName, AHelp: string; const AStart, AFactor: Double; const ACount: Integer;
  const ALabelNames: TLabelNames);
var
  lBuckets: TBuckets;
  lNextValue: Double;
begin
  SetLength(lBuckets, ACount);
  lNextValue := AStart;
  for var I := 0 to ACount - 1 do
  begin
    lBuckets[I] := lNextValue;
    lNextValue := lNextValue * AFactor;
  end;
  Create(AName, AHelp, lBuckets, ALabelNames);
end;

function THistogram.CreateChild: THistogramChild;
begin
  Result := THistogramChild.Create(Self);
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
  TMonitor.Enter(FLock);
  try
    Inc(FCount);
    FSum := FSum + AValue;
  finally
    TMonitor.Exit(FLock);
  end;
end;

function THistogram.Observe(AValue: Double): THistogram;
begin
  Result := Self;
  TMonitor.Enter(FLock);
  try
    GetNoLabelChild.Observe(AValue);
  finally
    TMonitor.Exit(FLock);
  end;
end;

function THistogram.Collect: TArray<TMetricSamples>;
begin
  TMonitor.Enter(FLock);
  try
    SetLength(Result, 1);
    var
    LMetric := PMetricSamples(@Result[0]);
    LMetric^.MetricName := Name;
    LMetric^.MetricHelp := Help;
    LMetric^.MetricType := TMetricType.mtHistogram;
    LMetric^.MetricSum := FSum;
    LMetric^.MetricCount := FCount;
    (* clear link to previous Samples *)
    SetLength(LMetric.Samples, 0);

    EnumChildren(
      procedure(const ALabelValues: TLabelValues; const AChild: THistogramChild)
      var
        StartIdx: Integer;
        lSample: PSample;
      begin
        if Length(LabelNames) > 0 then
        begin
          (* add the top level sum for the child *)
          StartIdx := Length(LMetric.Samples);
          SetLength(LMetric.Samples, StartIdx + 1);

          lSample := PSample(@LMetric.Samples[StartIdx]);
          lSample^.MetricName := Name + '_sum';
          lSample^.LabelNames := LabelNames;
          lSample^.LabelValues := ALabelValues;
          lSample^.TimeStamp := 0;
          lSample^.Value := AChild.Sum;
          (* add the top level count for the child *)
          StartIdx := Length(LMetric.Samples);
          SetLength(LMetric.Samples, StartIdx + 1);

          lSample := PSample(@LMetric.Samples[StartIdx]);
          lSample^.MetricName := Name + '_count';
          lSample^.LabelNames := LabelNames;
          lSample^.LabelValues := ALabelValues;
          lSample^.TimeStamp := 0;
          lSample^.Value := AChild.Count;
        end;
        AChild.CollectChild(LMetric^.Samples, ALabelValues);
      end);
  finally
    TMonitor.Exit(FLock);
  end;
end;

end.
