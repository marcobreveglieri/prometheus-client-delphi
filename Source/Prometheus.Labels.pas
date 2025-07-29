unit Prometheus.Labels;

interface

uses
  System.Generics.Defaults;

type

{ TLabelNames }

  /// <summary>
  ///  Represents a set of label names.
  /// </summary>
  TLabelNames = TArray<string>;

{ TLabelValues }

  /// <summary>
  ///  Represents a set of label values.
  /// </summary>
  TLabelValues = TArray<string>;

{ TLabelValidator }

  /// <summary>
  ///  Provides methods to validate label names.
  /// </summary>
  TLabelValidator = class sealed
  strict private const
    NamePattern: string = '^[a-zA-Z_][a-zA-Z0-9_]*$';
    ReservedPattern: string = '^__.*$';
  public
    /// <summary>
    ///  Check if a label name is valid.
    /// </summary>
    class procedure CheckLabel(const AName: string);
    /// <summary>
    ///  Check if a set of label names is valid.
    /// </summary>
    class procedure CheckLabels(const ANames: TLabelNames);
  end;

{ TLabelNamesEqualityComparer }

  /// <summary>
  ///  Implements an equality comparer for label names.
  /// </summary>
  TLabelNamesEqualityComparer = class (TEqualityComparer<TLabelNames>)
  public
    function Equals(const Left, Right: TLabelNames): Boolean; override;
    function GetHashCode(const Value: TLabelNames): Integer; override;
  end;

implementation

uses
  System.Hash,
  System.RegularExpressions,
  System.SysUtils,
  Prometheus.Resources;

{ TLabelValidator }

class procedure TLabelValidator.CheckLabel(const AName: string);
begin
  if Length(Trim(AName)) <= 0 then
  begin
    raise EArgumentException.Create(StrErrEmptyLabelName);
  end;
  if not TRegEx.IsMatch(AName, NamePattern) then
  begin
    raise EArgumentException.Create(StrErrInvalidLabelName);
  end;
  if TRegEx.IsMatch(AName, ReservedPattern) then
  begin
    raise EArgumentException.Create(StrErrReservedLabelName);
  end;
end;

class procedure TLabelValidator.CheckLabels(const ANames: TLabelNames);
begin
  for var LName in ANames do
    CheckLabel(LName);
end;

{ TLabelNamesEqualityComparer }

function TLabelNamesEqualityComparer.Equals(
  const Left, Right: TLabelNames): Boolean;
begin
  if Length(Left) <> Length(Right) then
  begin
    Result := False;
    Exit;
  end;
  for var LIndex := 0 to Pred(Length(Left)) do
    if not SameText(Left[LIndex], Right[LIndex]) then
    begin
      Result := False;
      Exit;
    end;
  Result := True;
end;

function TLabelNamesEqualityComparer.GetHashCode(
  const Value: TLabelNames): Integer;
begin
  var LText := string.Empty;
  for var LIndex := 0 to Pred(Length(Value)) do
    LText := LText + LowerCase(Value[LIndex]);
  Result := THashFNV1a32.GetHashValue(LText);
end;

end.
