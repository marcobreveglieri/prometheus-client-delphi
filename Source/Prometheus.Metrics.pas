unit Prometheus.Metrics;

interface

type

{ TMetricValidator }

  /// <summary>
  ///  Provides methods to validate metric names.
  /// </summary>
  TMetricValidator = class sealed
  strict private const
    NamePattern: string = '^[a-zA-Z_:][a-zA-Z0-9_:]*$';
  public
    /// <summary>
    ///  Check if a metric name is valid.
    /// </summary>
    class procedure CheckName(const AName: string);
  end;

implementation

{ TMetricValidator }

uses
  System.RegularExpressions,
  System.SysUtils,
  Prometheus.Resources;

class procedure TMetricValidator.CheckName(const AName: string);
begin
  if Length(AName) <= 0 then
    raise EArgumentException.Create(StrErrEmptyMetricName);
  if not TRegEx.IsMatch(AName, NamePattern) then
    raise EArgumentException.Create(StrErrInvalidMetricName);
end;

end.
