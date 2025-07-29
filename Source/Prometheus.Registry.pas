unit Prometheus.Registry;

interface

uses
  System.Generics.Collections,
  Prometheus.Collector,
  Prometheus.Samples;

type

{ TCollectorRegistry }

  /// <summary>
  ///  A collector registry is used to contain and manage collectors
  ///  and allows one or more of them to be registered.
  /// </summary>
  /// <remarks>
  ///  Collectors can be registered to one ore more collector registry.
  ///  Each registry can be scraped to collect metrics and samples from
  ///  collectors that are being managed by it.
  /// </remarks>
  TCollectorRegistry = class
  strict private
    FCollectorsToNames: TDictionary<TCollector, TArray<string>>;
    FLock: TObject;
    FNamesToCollectors: TDictionary<string, TCollector>;
    class var FDefaultRegistry: TCollectorRegistry;
    class function GetDefaultRegistry: TCollectorRegistry; static;
  public
    /// <summary>
    ///  Performs cleanup and release of resources used by this class.
    /// </summary>
    class destructor Finalize;
    /// <summary>
    ///  Creates a new collector registry.
    /// </summary>
    constructor Create(AOwnsCollectors: Boolean = True);
    /// <summary>
    ///  Performs object cleanup releasing all the owned instances.
    /// </summary>
    destructor Destroy; override;
    /// <summary>
    ///  Clears all the registered collectors within this instance.
    /// </summary>
    procedure Clear;
    /// <summary>
    ///  Collects all the metrics and their samples from the registered collectors.
    /// </summary>
    function Collect: TArray<TMetricSamples>;
    /// <summary>
    ///  Gets a collector of the specified type by its name.
    /// </summary>
    function GetCollector<T: TCollector>(const AName: string): T;
    /// <summary>
    ///  Check if a collector is registered with the specified name.
    /// </summary>
    function HasCollector(const AName: string): Boolean;
    /// <summary>
    ///  Registers a collector within this registry.
    /// </summary>
    procedure &Register(ACollector: TCollector);
    /// <summary>
    ///  Unregisters a collector from this registry.
    /// </summary>
    procedure Unregister(ACollector: TCollector);
    /// <summary>
    ///  Returns the default registry instance.
    /// </summary>
    /// <remarks>
    ///  Collectors can be registered in this default instance
    ///  or you can create a new registry instance by your own.
    /// </remarks>
    class property DefaultRegistry: TCollectorRegistry read GetDefaultRegistry;
  end;

implementation

uses
  System.SysUtils,
  Prometheus.Resources;

{ TCollectorRegistry }

constructor TCollectorRegistry.Create(AOwnsCollectors: Boolean);
begin
  inherited Create;
  if AOwnsCollectors then
    FCollectorsToNames := TObjectDictionary<TCollector, TArray<string>>.Create([doOwnsKeys])
  else
    FCollectorsToNames := TDictionary<TCollector, TArray<string>>.Create;
  FLock := TObject.Create;
  FNamesToCollectors := TDictionary<string, TCollector>.Create;
end;

destructor TCollectorRegistry.Destroy;
begin
  if Assigned(FCollectorsToNames) then
    FreeAndNil(FCollectorsToNames);
  if Assigned(FLock) then
    FreeAndNil(FLock);
  if Assigned(FNamesToCollectors) then
    FreeAndNil(FNamesToCollectors);
  inherited Destroy;
end;

class destructor TCollectorRegistry.Finalize;
begin
  if Assigned(FDefaultRegistry) then
    FreeAndNil(FDefaultRegistry);
end;

procedure TCollectorRegistry.Clear;
begin
  TMonitor.Enter(FLock);
  try
    FCollectorsToNames.Clear;
    FNamesToCollectors.Clear;
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TCollectorRegistry.Collect: TArray<TMetricSamples>;
begin
  TMonitor.Enter(FLock);
  try
    SetLength(Result, 0);
    if FCollectorsToNames.Count <= 0 then
      Exit;
    var LSamples := TList<TArray<TMetricSamples>>.Create;
    try
      for var LCollectorItem in FCollectorsToNames.Keys do
        LSamples.Add(LCollectorItem.Collect);
      Result := TArray.Concat<TMetricSamples>(LSamples.ToArray);
    finally
      LSamples.Free;
    end;
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TCollectorRegistry.GetCollector<T>(const AName: string): T;
var
  LItem: TCollector;
begin
  TMonitor.Enter(FLock);
  try
    if FNamesToCollectors.TryGetValue(AName, LItem) then
      Result := T(LItem)
    else
      Result := nil;
  finally
    TMonitor.Exit(FLock);
  end;
end;

class function TCollectorRegistry.GetDefaultRegistry: TCollectorRegistry;
begin
  if not Assigned(FDefaultRegistry) then
    FDefaultRegistry := TCollectorRegistry.Create;
  Result := FDefaultRegistry;
end;

function TCollectorRegistry.HasCollector(const AName: string): Boolean;
begin
  TMonitor.Enter(FLock);
  try
    Result := FNamesToCollectors.ContainsKey(AName);
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TCollectorRegistry.Register(ACollector: TCollector);
begin
  TMonitor.Enter(FLock);
  try
    if not Assigned(ACollector) then
      raise EArgumentException.Create(StrErrNullCollector);
    var LCollectorNames := ACollector.GetNames;
    for var LNameToCheck in LCollectorNames do
    begin
      if FNamesToCollectors.ContainsKey(LNameToCheck) then
        raise EListError.Create(StrErrCollectorNameInUse);
    end;
    for var LNameToAdd in LCollectorNames do
      FNamesToCollectors.AddOrSetValue(LNameToAdd, ACollector);
    FCollectorsToNames.AddOrSetValue(ACollector, LCollectorNames);
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TCollectorRegistry.Unregister(ACollector: TCollector);
begin
  TMonitor.Enter(FLock);
  try
    FCollectorsToNames.Remove(ACollector);
    for var LName in ACollector.GetNames do
      FNamesToCollectors.Remove(LName);
  finally
    TMonitor.Exit(FLock);
  end;
end;

end.
