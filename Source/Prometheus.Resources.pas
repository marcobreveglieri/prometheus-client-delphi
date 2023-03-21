unit Prometheus.Resources;

interface

{ Resource strings }

resourcestring
  StrErrEmptyMetricName = 'Metric name is empty';
  StrErrEmptyLabelName = 'Metric label name is empty';
  StrErrInvalidMetricName = 'Invalid metric name';
  StrErrInvalidLabelName = 'Invalid metric label name';
  StrErrReservedLabelName = 'Metric label name is reserved for internal use';
  StrErrLabelNameValueMismatch = 'Length must match label names';
  StrErrLabelValuesMissing = 'Label values are missing';
  StrErrAmountLessThanZero = 'Amount must be greater than zero';
  StrErrNullProcReference = 'Reference to procedure not assigned';
  StrErrNullCollector = 'Collector reference not assigned';
  StrErrCollectorNameInUse = 'Name is already in use by another registered collector';
  StrErrCollectorHasLabels = 'This collectors has labels: use label values to retrieve children collectors';

implementation

end.
