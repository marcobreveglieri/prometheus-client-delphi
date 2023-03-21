unit Prometheus.Tests.Fixtures.Collector;

interface

uses
  DUnitX.TestFramework;

type

{ TCollectorTestFixture }

  [TestFixture]
  TCollectorTestFixture = class
  strict private
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure CollectorRegisterShouldUseDefaultRegistry;
    [Test]
    procedure CollectorMustSupportMoreRegistries;
  end;

implementation

uses
  Prometheus.Collector,
  Prometheus.Collectors.Counter,
  Prometheus.Registry;

{ TCollectorTestFixture }

procedure TCollectorTestFixture.Setup;
begin
end;

procedure TCollectorTestFixture.TearDown;
begin
end;

procedure TCollectorTestFixture.CollectorMustSupportMoreRegistries;
begin
  var LRegistry1 := TCollectorRegistry.Create(True);
  var LRegistry2 := TCollectorRegistry.Create(False);
  var LCollector := TCounter.Create('sample', 'sample collector');
  LCollector.Register(LRegistry1);
  LCollector.Register(LRegistry2);
  Assert.IsTrue((LCollector = LRegistry1.GetCollector<TCounter>('sample'))
    and (LCollector = LRegistry2.GetCollector<TCounter>('sample')));
  LRegistry1.Free;
  LRegistry2.Free;
end;

procedure TCollectorTestFixture.CollectorRegisterShouldUseDefaultRegistry;
begin
  var LRegistry := TCollectorRegistry.DefaultRegistry;
  var LCollector := TCounter.Create('sample');
  LCollector.Register();
  Assert.AreEqual(LCollector, LRegistry.GetCollector<TCounter>('sample'));
end;

initialization

  TDUnitX.RegisterTestFixture(TCollectorTestFixture);

end.
