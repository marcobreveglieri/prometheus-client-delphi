unit Prometheus.Formatting;

interface

uses
  System.SysUtils;

const

  /// <summary>
  ///  Format settings to be used for exported label and metric values.
  /// </summary>
  PromFormatSettings: TFormatSettings = (
    ThousandSeparator : ',';
    DecimalSeparator : '.';
  );

implementation

end.
