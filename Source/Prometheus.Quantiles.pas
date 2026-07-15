unit Prometheus.Quantiles;

interface

uses
  System.Generics.Collections;

type

{ TQuantileObjective }

  /// <summary>
  ///  Represents a quantile estimation target made up of the desired
  ///  quantile rank (phi) and the allowed error of the estimation (epsilon).
  /// </summary>
  TQuantileObjective = record
    /// <summary>
    ///  The quantile rank to estimate (e.g. 0.99); it must fall
    ///  within the range 0 to 1.
    /// </summary>
    Quantile: Double;
    /// <summary>
    ///  The allowed absolute error of the estimation (e.g. 0.001); it must
    ///  be greater than - or equal to - zero and less than 1.
    /// </summary>
    Error: Double;
    /// <summary>
    ///  Creates a new quantile objective value.
    /// </summary>
    class function Create(AQuantile, AError: Double): TQuantileObjective; static;
  end;

{ TQuantileObjectives }

  /// <summary>
  ///  Represents a set of quantile objectives.
  /// </summary>
  TQuantileObjectives = TArray<TQuantileObjective>;

{ TQuantileEstimator }

  /// <summary>
  ///  Implements the CKMS streaming quantile estimation algorithm targeted
  ///  at a fixed set of quantile objectives (see Cormode, Korn,
  ///  Muthukrishnan and Srivastava: "Effective Computation of Biased
  ///  Quantiles over Data Streams").
  /// </summary>
  /// <remarks>
  ///  This class is not thread safe: callers must synchronize access to it.
  /// </remarks>
  TQuantileEstimator = class
  strict private
    type
      /// <summary>
      ///  A single tuple of the compressed sample summary holding the
      ///  observed value, the gap from the rank of the previous tuple
      ///  ("g" in the paper) and the rank uncertainty ("delta").
      /// </summary>
      TCkmsSample = record
        Value: Double;
        Width: Double;
        Delta: Double;
      end;
    const
      BUFFER_CAPACITY = 500;
    var
      FObjectives: TQuantileObjectives;
      FSamples: TList<TCkmsSample>;
      FBuffer: TArray<Double>;
      FBufferCount: Integer;
      FCount: Double;
    procedure Compress;
    procedure Flush;
    function GetSampleCount: Integer;
    function Invariant(ARank: Double): Double;
  public
    /// <summary>
    ///  Creates a new estimator for the specified quantile objectives.
    /// </summary>
    constructor Create(const AObjectives: TQuantileObjectives);
    /// <summary>
    ///  Performs object cleanup releasing all the owned instances.
    /// </summary>
    destructor Destroy; override;
    /// <summary>
    ///  Adds a value to the data stream; NaN values are ignored.
    /// </summary>
    procedure Insert(AValue: Double);
    /// <summary>
    ///  Returns the estimated value at the specified quantile rank,
    ///  or NaN if no value has been inserted into the stream yet.
    /// </summary>
    function Query(AQuantile: Double): Double;
    /// <summary>
    ///  Removes all data from the stream, restarting the estimation.
    /// </summary>
    procedure Reset;
    /// <summary>
    ///  Returns the total number of values inserted into the stream.
    /// </summary>
    property Count: Double read FCount;
    /// <summary>
    ///  Returns the number of tuples kept in the compressed summary;
    ///  values still sitting in the insertion buffer are not included.
    /// </summary>
    property SampleCount: Integer read GetSampleCount;
  end;

implementation

uses
  System.Generics.Defaults,
  System.Math,
  System.SysUtils,
  Prometheus.Resources;

{ Local functions }

function CeilToDouble(AValue: Double): Double;
begin
  Result := Int(AValue);
  if Frac(AValue) > 0 then
    Result := Result + 1;
end;

{ TQuantileObjective }

class function TQuantileObjective.Create(AQuantile, AError: Double): TQuantileObjective;
begin
  Result.Quantile := AQuantile;
  Result.Error := AError;
end;

{ TQuantileEstimator }

constructor TQuantileEstimator.Create(const AObjectives: TQuantileObjectives);
begin
  inherited Create;
  if Length(AObjectives) <= 0 then
    raise EArgumentException.Create(StrErrQuantileObjectivesEmpty);
  FObjectives := Copy(AObjectives);
  FSamples := TList<TCkmsSample>.Create;
  SetLength(FBuffer, BUFFER_CAPACITY);
  FBufferCount := 0;
  FCount := 0;
end;

destructor TQuantileEstimator.Destroy;
begin
  if Assigned(FSamples) then
    FreeAndNil(FSamples);
  inherited Destroy;
end;

procedure TQuantileEstimator.Compress;
begin
  if FSamples.Count < 2 then
    Exit;
  var LHead := FSamples[FSamples.Count - 1];
  var LHeadIndex := FSamples.Count - 1;
  var LRank := FCount - 1 - LHead.Width;
  for var LIndex := FSamples.Count - 2 downto 0 do
  begin
    var LCurrent := FSamples[LIndex];
    if LCurrent.Width + LHead.Width + LHead.Delta <= Invariant(LRank) then
    begin
      LHead.Width := LHead.Width + LCurrent.Width;
      FSamples[LHeadIndex] := LHead;
      FSamples.Delete(LIndex);
      Dec(LHeadIndex);
    end
    else
    begin
      LHead := LCurrent;
      LHeadIndex := LIndex;
    end;
    LRank := LRank - LCurrent.Width;
  end;
end;

procedure TQuantileEstimator.Flush;
begin
  if FBufferCount <= 0 then
    Exit;
  TArray.Sort<Double>(FBuffer, TComparer<Double>.Default, 0, FBufferCount);
  var LRank: Double := 0;
  var LIndex := 0;
  for var LBufferIndex := 0 to FBufferCount - 1 do
  begin
    var LValue := FBuffer[LBufferIndex];
    var LInserted := False;
    while LIndex < FSamples.Count do
    begin
      var LCurrent := FSamples[LIndex];
      if LCurrent.Value > LValue then
      begin
        var LNewSample: TCkmsSample;
        LNewSample.Value := LValue;
        LNewSample.Width := 1;
        LNewSample.Delta := Max(0, Floor(Invariant(LRank)) - 1);
        FSamples.Insert(LIndex, LNewSample);
        Inc(LIndex);
        LInserted := True;
        Break;
      end;
      LRank := LRank + LCurrent.Width;
      Inc(LIndex);
    end;
    if not LInserted then
    begin
      var LNewSample: TCkmsSample;
      LNewSample.Value := LValue;
      LNewSample.Width := 1;
      LNewSample.Delta := 0;
      FSamples.Add(LNewSample);
      Inc(LIndex);
    end;
    FCount := FCount + 1;
    LRank := LRank + 1;
  end;
  FBufferCount := 0;
  Compress;
end;

function TQuantileEstimator.GetSampleCount: Integer;
begin
  Result := FSamples.Count;
end;

function TQuantileEstimator.Invariant(ARank: Double): Double;
begin
  Result := Double.MaxValue;
  for var LObjective in FObjectives do
  begin
    var LDeviation: Double;
    if LObjective.Quantile * FCount <= ARank then
    begin
      if LObjective.Quantile > 0 then
        LDeviation := (2 * LObjective.Error * ARank) / LObjective.Quantile
      else
        LDeviation := Double.MaxValue;
    end
    else
    begin
      if LObjective.Quantile < 1 then
        LDeviation := (2 * LObjective.Error * (FCount - ARank)) / (1 - LObjective.Quantile)
      else
        LDeviation := Double.MaxValue;
    end;
    if LDeviation < Result then
      Result := LDeviation;
  end;
  // Keep the value within the integer range so that callers can safely
  // apply Floor() to it (degenerate objectives with a quantile rank of
  // exactly 0 or 1 make the allowed deviation unbounded).
  if Result > MaxInt then
    Result := MaxInt;
end;

procedure TQuantileEstimator.Insert(AValue: Double);
begin
  // NaN values are ignored: they cannot be ordered, so they would make
  // the comparisons performed while merging raise EInvalidOp under the
  // default floating point exception mask used by Delphi.
  if AValue.IsNan then
    Exit;
  // Flushing before the write (instead of after it) guarantees the
  // buffer index stays within bounds even if a flush raises.
  if FBufferCount >= BUFFER_CAPACITY then
    Flush;
  FBuffer[FBufferCount] := AValue;
  Inc(FBufferCount);
end;

function TQuantileEstimator.Query(AQuantile: Double): Double;
begin
  Flush;
  if FSamples.Count <= 0 then
    Exit(Double.NaN);
  var LTarget := CeilToDouble(AQuantile * FCount);
  LTarget := LTarget + CeilToDouble(Invariant(LTarget) / 2);
  var LPrevious := FSamples[0];
  var LRank: Double := 0;
  for var LIndex := 1 to FSamples.Count - 1 do
  begin
    var LCurrent := FSamples[LIndex];
    LRank := LRank + LPrevious.Width;
    if LRank + LCurrent.Width + LCurrent.Delta > LTarget then
      Exit(LPrevious.Value);
    LPrevious := LCurrent;
  end;
  Result := LPrevious.Value;
end;

procedure TQuantileEstimator.Reset;
begin
  FBufferCount := 0;
  FSamples.Clear;
  FCount := 0;
end;

end.
