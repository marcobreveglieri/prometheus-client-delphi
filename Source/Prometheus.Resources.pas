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
  StrErrHistogramOwnerNil = 'Histogram owner is not assigned';
  StrErrHistogramOwnerNoBuckets = 'Histogram owner has no buckets';
  StrErrQuantileObjectivesEmpty = 'At least one quantile objective must be specified';
  StrErrSummaryOwnerNil = 'Summary owner is not assigned';
  StrErrSummaryInvalidQuantile = 'Summary quantile objectives must be between 0 and 1';
  StrErrSummaryInvalidError = 'Summary quantile objective error must be greater than or equal to 0 and less than 1';
  StrErrSummaryDuplicateQuantile = 'Summary quantile objectives must be unique';
  StrErrSummaryInvalidMaxAge = 'Summary max age must be greater than zero';
  StrErrSummaryInvalidAgeBuckets = 'Summary age buckets count must be greater than zero';

implementation

end.
