unit Prometheus.Collectors.Histogram;

interface

uses
  System.StrUtils,
  System.SysUtils,
  System.Generics.Collections,

  Prometheus.Labels,
  Prometheus.Samples,
  Prometheus.SimpleCollector;

const
  DEFAULT_BUCKETS: TArray<Double> = [0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10, INFINITE];

type
  THistogramChild = class
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

  THistogram = class(TSimpleCollector<THistogramChild>)
  strict private
    FLock: TObject;
    FBuckets: TArray<Double>;
    FCount: Double;
    FSum: Double;

    function GetValue: Double;
    function GetBucketValue(AAmount: Double): string;
  strict protected
    function CreateChild: THistogramChild; override;
  public
    /// <summary>
    ///  Creates a new instance of this counter collector.
    /// </summary>
    constructor Create(const AName: string; const AHelp: string = '';
      const ALabelNames: TLabelNames = []); override;
    /// <summary>
    ///  Performs object cleanup releasing all the owned instances.
    /// </summary>
    destructor Destroy; override;
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
    ///  Increases proccess time in seconds.
    /// </summary>
    function IncSum(const AAmount: Double = 1): THistogram;
    /// <summary>
    ///  Increases proccess count
    /// </summary>
    function IncCount(const AAmount: Double = 1): THistogram;
    /// <summary>
    ///  Set the buckets of histogram
    /// </summary>
    function Buckets(ABuckets: TArray<Double>): THistogram;
    /// <summary>
    ///  Set label values and le label
    /// </summary>
    function Labels(const ALabelValues: TLabelValues; const LEValue: Double): THistogramChild; reintroduce;
    /// <summary>
    ///  Returns the current value of the default (unlabelled) counter.
    /// </summary>
    property Value: Double read GetValue;
    /// <summary>
    ///  Returns the current value of the total count metric.
    /// </summary>
    property Count: Double read FCount;
    /// <summary>
    ///  Returns the current value of the total sum metric.
    /// </summary>
    property Sum: Double read FSum;
  end;

implementation

const
  RESERVED_LABEL_NAME = 'le';

{ THistogram }

function THistogram.Buckets(ABuckets: TArray<Double>): THistogram;
begin
  Self.FBuckets := ABuckets;
  Result := Self;
end;

function THistogram.Collect: TArray<TMetricSamples>;
begin
  TMonitor.Enter(FLock);
  try
    SetLength(Result, 1);
    var LMetric := PMetricSamples(@Result[0]);
    LMetric^.MetricName := Self.Name;
    LMetric^.MetricHelp := Self.Help;
    LMetric^.MetricType := TMetricType.mtHistogram;
    LMetric^.MetricSum  := Self.FSum;
    LMetric^.MetricCount := Self.FCount;

    SetLength(LMetric^.Samples, ChildrenCount);
    var LIndex := 0;
    EnumChildren(
      procedure (const ALabelValues: TLabelValues; const AChild: THistogramChild)
      begin
        var LSample := PSample(@LMetric^.Samples[LIndex]);
        LSample^.MetricName := Self.Name;
        LSample^.LabelNames := Self.LabelNames;
        LSample^.LabelValues := ALabelValues;
        LSample^.TimeStamp := 0;
        LSample^.Value := AChild.Value;
        System.Inc(LIndex);
      end
    );
  finally
    TMonitor.Exit(FLock);
  end;
end;

constructor THistogram.Create(const AName, AHelp: string; const ALabelNames: TLabelNames);
var
  lLabelNames: TLabelNames;
begin
  lLabelNames := ALabelNames;
  if IndexText(RESERVED_LABEL_NAME, lLabelNames) > -1 then
    raise EInvalidOpException.Create('Label name ''le'' is reserved');

  Insert(RESERVED_LABEL_NAME, lLabelNames, 0);
  inherited Create(AName, AHelp, lLabelNames);
  FLock := TObject.Create;
  FBuckets := DEFAULT_BUCKETS;
end;

function THistogram.CreateChild: THistogramChild;
begin
  Result := THistogramChild.Create;
end;

destructor THistogram.Destroy;
begin
  if Assigned(FLock) then
    FreeAndNil(FLock);
  inherited;
end;

function THistogram.GetBucketValue(AAmount: Double): string;
var
  lValue: Double;
  lBucketLength: Integer;
  lBucketValue: Double;
  lFormatSettings: TFormatSettings;
begin
  lBucketLength := Length(Self.FBuckets);
  if lBucketLength <= 0 then
    raise EInvalidOpException.Create('Buckets are missing');

  lBucketValue := INFINITE;
  for lValue in Self.FBuckets do begin
    if AAmount <= lValue then begin
      lBucketValue := lValue;
      Break;
    end;
  end;

  if lBucketValue = INFINITE then
    Result := '+Inf'
  else begin
    lFormatSettings := TFormatSettings.Create;
    lFormatSettings.DecimalSeparator := '.';
    lFormatSettings.ThousandSeparator := ',';
    Result := FloatToStr(lBucketValue, lFormatSettings);
  end;
end;

function THistogram.GetNames: TArray<string>;
begin
  Result := [Name];
end;

function THistogram.GetValue: Double;
begin
  Result := GetNoLabelChild.Value;
end;

procedure THistogram.Inc(const AAmount: Double);
begin
  GetNoLabelChild.Inc(AAmount);
end;

function THistogram.IncCount(const AAmount: Double): THistogram;
begin
  Self.FCount := Self.FCount + AAmount;
  Result := Self;
end;

function THistogram.IncSum(const AAmount: Double): THistogram;
begin
  Self.FSum := Self.FSum + AAmount;
  Result := Self;
end;

function THistogram.Labels(const ALabelValues: TLabelValues; const LEValue: Double): THistogramChild;
var
  lLabelValues: TLabelValues;
  lBucketValue: string;
begin
  lLabelValues := ALabelValues;
  lBucketValue := Self.GetBucketValue(LEValue);
  Insert(lBucketValue, lLabelValues, 0);
  Result := inherited Labels(lLabelValues);
end;

{ THistogramChild }

constructor THistogramChild.Create;
begin
  inherited Create;
  FLock := TObject.Create;
end;

destructor THistogramChild.Destroy;
begin
  if Assigned(FLock) then
    FreeAndNil(FLock);
  inherited Destroy;
end;

procedure THistogramChild.Inc(const AAmount: Double);
begin
  TMonitor.Enter(FLock);
  try
    FValue := FValue + AAmount;
  finally
    TMonitor.Exit(FLock);
  end;
end;

end.
