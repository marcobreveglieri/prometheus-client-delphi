unit Prometheus.Exposers.Text;

interface

uses
  System.Classes,
  System.SysUtils,
  Prometheus.Samples;

type

{ TTextExposer }

  /// <summary>
  ///  Provides methods to export metrics using the Prometheus text representation.
  /// </summary>
  TTextExposer = class
  strict private
    function EscapeToken(const AText: string): string;
    function FormatNumber(const AValue: Double): string;
  public
    /// <summary>
    ///  Renders the specified samples as a string.
    /// </summary>
    function Render(ASamples: TArray<TMetricSamples>): string; overload;
    /// <summary>
    ///  Renders the specified samples to a string buffer.
    /// </summary>
    procedure Render(ABuilder: TStringBuilder; ASamples: TArray<TMetricSamples>); overload;
    /// <summary>
    ///  Renders the specified samples to a destination stream.
    /// </summary>
    procedure Render(AStream: TStream; ASamples: TArray<TMetricSamples>); overload;
    /// <summary>
    ///  Renders the specified samples to a text writer instance.
    /// </summary>
    procedure Render(AWriter: TTextWriter; ASamples: TArray<TMetricSamples>); overload;
  end;

implementation

uses
  System.Math;

type

{ TTextEncoding }

  /// <summary>
  ///  Represents the UTF-8 encoding that is compliant with Prometheus text format.
  /// </summary>
  TTextEncoding = class(TUTF8Encoding)
  public
    /// <summary>
    ///  Returns this encoding preamble in a byte array.
    /// </summary>
    function GetPreamble: TBytes; override;
  end;

function TTextEncoding.GetPreamble: TBytes;
begin
  SetLength(Result, 0);
end;

{ TTextExposer }

function TTextExposer.EscapeToken(const AText: string): string;
begin
  Result := AText
    .Replace('\', '\\')
    .Replace(#13#10, '\n')
    .Replace(#13, '\n')
    .Replace(#10, '\n')
    .Replace(#9, '\t')
    .Replace('"', '\"');
end;

function TTextExposer.FormatNumber(const AValue: Double): string;
begin
  if AValue.IsNegativeInfinity then
  begin
    Result := '-Inf';
    Exit;
  end;
  if AValue.IsPositiveInfinity then
  begin
    Result := '+Inf';
    Exit;
  end;
  if AValue.IsNan then
  begin
    Result := 'Nan';
    Exit;
  end;
  Result := AValue.ToString;
end;

function TTextExposer.Render(ASamples: TArray<TMetricSamples>): string;
begin
  var LBuffer := TStringBuilder.Create;
  try
    Render(LBuffer, ASamples);
    Result := LBuffer.ToString;
  finally
    LBuffer.Free;
  end;
end;

procedure TTextExposer.Render(ABuilder: TStringBuilder; ASamples: TArray<TMetricSamples>);
begin
  var LWriter := TStringWriter.Create(ABuilder);
  try
    Render(LWriter, ASamples);
  finally
    LWriter.Free;
  end;
end;

procedure TTextExposer.Render(AStream: TStream; ASamples: TArray<TMetricSamples>);
begin
  var LEncoding := TTextEncoding.Create;
  try
    var LWriter := TStreamWriter.Create(AStream, LEncoding);
    try
      Render(LWriter, ASamples);
    finally
      LWriter.Free;
    end;
  finally
    LEncoding.Free;
  end;
end;

procedure TTextExposer.Render(AWriter: TTextWriter; ASamples: TArray<TMetricSamples>);
begin
  // TODO: Check output if LMetricSet.Samples == 0
  for var LMetricSet in ASamples do
  begin
    // Metric help
    AWriter.Write('# HELP');
    AWriter.Write(' ');
    AWriter.Write(LMetricSet.MetricName);
    AWriter.Write(' ');
    AWriter.Write(EscapeToken(LMetricSet.MetricHelp));
    if not LMetricSet.MetricHelp.EndsWith('.') then
      AWriter.Write('.');
    AWriter.Write(#10);

    // Metric type
    AWriter.Write('# TYPE');
    AWriter.Write(' ');
    AWriter.Write(LMetricSet.MetricName);
    AWriter.Write(' ');
    AWriter.Write(LMetricSet.MetricType);
    AWriter.Write(#10);

    // Samples
    for var LSample in LMetricSet.Samples do
    begin
      // Samples - metric
      AWriter.Write(LSample.MetricName);

      // Samples - label + values
      if LSample.HasLabels then
      begin
        AWriter.Write('{');
        var LLabelCount := Min(Length(LSample.LabelNames), Length(LSample.LabelValues));
        if LLabelCount <= 0 then
          Continue;
        for var LLabelIndex := 0 to Pred(LLabelCount) do
        begin
          if LLabelIndex > 0 then
            AWriter.Write(',');
          AWriter.Write(LSample.LabelNames[LLabelIndex]);
          AWriter.Write('="');
          AWriter.Write(EscapeToken(LSample.LabelValues[LLabelIndex]));
          AWriter.Write('"');
        end;
        AWriter.Write('}');
      end;
      AWriter.Write(' ');

      // Samples - total value
      AWriter.Write(FormatNumber(LSample.Value));
      if LSample.HasTimeStamp then
      begin
        AWriter.Write(' ');
        AWriter.Write(LSample.TimeStamp);
      end;
      AWriter.Write(#10);
    end;
  end;
end;

end.
