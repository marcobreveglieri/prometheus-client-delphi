unit Prometheus.SimpleCollector;

interface

uses
  System.Generics.Collections,
  Prometheus.Collector,
  Prometheus.Labels,
  Prometheus.Metrics,
  Prometheus.Registry;

type

{ References to procedures }

  /// <summary>
  ///  Represents a callback procedure that can be passed to a method that
  ///  enumerates the children of a collector using a specific criteria.
  /// </summary>
  TChildrenCallback<TChild: class> = reference to procedure (
    const ALabelValues: TLabelValues; const AChild: TChild
  );

{ TSimpleCollector<TChild> }

  /// <summary>
  ///  Represents the base class that any typical collector must inherit
  ///  and provides all the basic features, like registration and so on.
  /// </summary>
  TSimpleCollector<TChild: class> = class abstract(TCollector)
  strict private
    FChildren: TDictionary<TLabelValues, TChild>;
    FHelp: string;
    FLabelNames: TLabelNames;
    FName: string;
    procedure InitializeNoLabelChildIfNeeded();
    function GetChildrenCount: Integer;
  strict protected
    function CreateChild: TChild; virtual;
    procedure EnumChildren(ACallback: TChildrenCallback<TChild>);
    function GetNoLabelChild: TChild;
  public
    /// <summary>
    ///  Creates a new instance of this collector.
    /// </summary>
    constructor Create(const AName: string; const AHelp: string = '';
      const ALabelNames: TLabelNames = []); virtual;
    /// <summary>
    ///  Performs object cleanup releasing all the owned instances.
    /// </summary>
    destructor Destroy; override;
    /// <summary>
    ///  Clears any labelled children owned by this collector.
    /// </summary>
    procedure Clear;
    /// <summary>
    ///  Create or retrieve the metric child for the specified label values.
    /// </summary>
    /// <remarks>
    ///  The count of label values must match the count of label names.
    /// </remarks>
    function Labels(const ALabelValues: TLabelValues): TChild;
    /// <summary>
    ///  Remove the metric child for the specified label values.
    /// </summary>
    procedure RemoveLabels(const ALabelValues: TLabelValues);
    /// <summary>
    ///  Registers this collector within the specified registry.
    /// </summary>
    procedure &Register(ARegistry: TCollectorRegistry = nil);
    /// <summary>
    ///  Unregister this collector from the specified registry.
    /// </summary>
    procedure Unregister(ARegistry: TCollectorRegistry = nil);
    /// <summary>
    ///  Returns the count of children for this collector.
    /// </summary>
    property ChildrenCount: Integer read GetChildrenCount;
    /// <summary>
    ///  Returns the help text for the metric.
    /// </summary>
    property Help: string read FHelp;
    /// <summary>
    ///  Returns the set of label names for the metric.
    /// </summary>
    property LabelNames: TLabelNames read FLabelNames;
    /// <summary>
    ///  Returns the name of this collector.
    /// </summary>
    property Name: string read FName;
  end;

implementation

uses
  System.SysUtils,
  Prometheus.Resources;

{ TSimpleCollector<TChild> }

constructor TSimpleCollector<TChild>.Create(const AName: string;
  const AHelp: string = ''; const ALabelNames: TLabelNames = []);
begin
  inherited Create();
  TMetricValidator.CheckName(AName);
  if Length(ALabelNames) > 0 then
    TLabelValidator.CheckLabels(ALabelNames);
  FName := AName;
  FHelp := AHelp;
  FLabelNames := ALabelNames;
  FChildren := TObjectDictionary<TLabelValues, TChild>.Create([doOwnsValues],
    TLabelNamesEqualityComparer.Create);
  InitializeNoLabelChildIfNeeded;
end;

destructor TSimpleCollector<TChild>.Destroy;
begin
  if Assigned(FChildren) then
    FreeAndNil(FChildren);
  inherited Destroy;
end;

function TSimpleCollector<TChild>.CreateChild: TChild;
begin
  Result := nil;
end;

procedure TSimpleCollector<TChild>.EnumChildren(ACallback: TChildrenCallback<TChild>);
begin
  TMonitor.Enter(Self);
  try
    for var LChild in FChildren do
      ACallback(LChild.Key, LChild.Value);
  finally
    TMonitor.Exit(Self);
  end;
end;

function TSimpleCollector<TChild>.GetChildrenCount: Integer;
begin
  TMonitor.Enter(Self);
  try
    Result := FChildren.Count;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TSimpleCollector<TChild>.GetNoLabelChild: TChild;
begin
  TMonitor.Enter(Self);
  try
    if Length(FLabelNames) > 0 then
      raise EInvalidOpException.Create(StrErrCollectorHasLabels);
    InitializeNoLabelChildIfNeeded;
    Result := FChildren.Values.ToArray[0];
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TSimpleCollector<TChild>.InitializeNoLabelChildIfNeeded;
begin
  TMonitor.Enter(Self);
  try
    if (Length(FLabelNames) <= 0) and (FChildren.Count <= 0) then
      FChildren.Add(nil, CreateChild);
  finally
    TMonitor.Exit(Self);
  end;
end;

function TSimpleCollector<TChild>.Labels(const ALabelValues: TLabelValues): TChild;
begin
  TMonitor.Enter(Self);
  try
    if Length(ALabelValues) <= 0 then
      raise EArgumentException.Create(StrErrLabelValuesMissing);
    if Length(ALabelValues) <> Length(FLabelNames) then
      raise EArgumentException.Create(StrErrLabelNameValueMismatch);
    if FChildren.TryGetValue(ALabelValues, Result) then
      Exit;
    Result := CreateChild;
    if not Assigned(Result) then
      Exit;
    try
      FChildren.Add(ALabelValues, Result);
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TSimpleCollector<TChild>.Clear;
begin
  TMonitor.Enter(Self);
  try
    FChildren.Clear;
    InitializeNoLabelChildIfNeeded;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TSimpleCollector<TChild>.Register(ARegistry: TCollectorRegistry);
begin
  if not Assigned(ARegistry) then
    ARegistry := TCollectorRegistry.DefaultRegistry;
  ARegistry.&Register(Self);
end;

procedure TSimpleCollector<TChild>.RemoveLabels(const ALabelValues: TLabelValues);
begin
  TMonitor.Enter(Self);
  try
    FChildren.Remove(ALabelValues);
    InitializeNoLabelChildIfNeeded;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TSimpleCollector<TChild>.Unregister(ARegistry: TCollectorRegistry);
begin
  if not Assigned(ARegistry) then
    ARegistry := TCollectorRegistry.DefaultRegistry;
  ARegistry.Unregister(Self);
end;

end.
