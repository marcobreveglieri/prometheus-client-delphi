<div>
  <img alt="Prometheus Client for Delphi" height="256" src="https://ucarecdn.com/a7019e45-d14b-47cd-8ceb-70ba7848f049/">
  <h1>Prometheus Client for Delphi</h1>
</div>

<p align="center">
  <strong>Instrument your Delphi applications with Prometheus metrics for modern observability</strong>
</p>

<p align="center">
  <img alt="Delphi" src="https://img.shields.io/badge/Delphi-11%2B-red?logo=delphi&logoColor=white">
  <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg">
  <img alt="Boss" src="https://img.shields.io/badge/Boss-available-blue">
</p>

## 📑 Table of Contents

- [❓ What is Prometheus?](#-what-is-prometheus)
- [🚀 Prometheus Delphi Client](#-prometheus-delphi-client)
- [🧩 Features](#-features)
- [📦 Installation](#-installation)
- [⚡ Quick Start Guide](#-quick-start-guide)
- [📏 Metric Types](#-metric-types)
- [🏷️ Working with Labels](#-working-with-labels)
- [📤 Exporting Metrics](#-exporting-metrics)
- [🌐 Web Framework Integration](#-web-framework-integration)
- [💡 Real-World Examples](#-real-world-examples)
- [📚 Documentation](#-documentation)
- [🖥️ Delphi Compatibility](#-delphi-compatibility)
- [✅ Problem? Solved!](#-problem-solved)
- [🤝 Contributing](#-contributing)
- [🔗 Resources](#-resources)
- [📄 License](#-license)

## ❓ What is Prometheus?

[Prometheus](http://prometheus.io) is an open-source monitoring and alerting toolkit that has become the de-facto standard for cloud-native monitoring. Originally built at SoundCloud, it's now a graduated [CNCF](https://www.cncf.io/) project used by organizations worldwide.

### 🔄 How Prometheus works

```
┌─────────────┐          ┌─────────────┐          ┌─────────────┐
│ Delphi App  │          │ Prometheus  │          │   Grafana   │
│             │          │   Server    │          │  Dashboard  │
│  /metrics   │ ◄─scrape─┤             │ ◄─query──┤             │
│  endpoint   │          │  (storage)  │          │  (display)  │
└─────────────┘          └─────────────┘          └─────────────┘
```

1. Your Delphi app exposes a `/metrics` HTTP endpoint
2. Prometheus periodically **scrapes** (pulls) metrics from your app
3. Metrics are stored in a time-series database
4. You query metrics using **PromQL** (Prometheus Query Language)
5. Visualize data in **Grafana** dashboards
6. Set up **alerts** when metrics exceed thresholds

### ✨ Key Prometheus features

- **Multi-dimensional data model** - Metrics identified by name and labels (key-value pairs)
- **Powerful query language (PromQL)** - Flexible queries and aggregations
- **Pull-based model** - Prometheus scrapes your app (no agent needed)
- **Service discovery** - Automatic discovery of monitoring targets
- **Built-in alerting** - Alert manager for handling alerts
- **Efficient storage** - Local time-series database with optional remote storage

### 👀 Monitoring matters!

Modern applications need **observability** to understand their behavior in production. Without proper monitoring, you're flying blind:

- **How many requests is your API handling?** Without metrics, you won't know if you're at 10% or 90% capacity.
- **Why did your application slow down?** Response time metrics help identify performance bottlenecks.
- **Is that new feature being used?** Business metrics show real user behavior.
- **When should you scale?** Resource metrics (CPU, memory, connections) guide infrastructure decisions.

**Observability** is the practice of understanding your application's internal state by examining its outputs. Prometheus metrics are a core pillar of observability, alongside logs and traces.

## 🚀 Prometheus Delphi Client

The **Prometheus Delphi Client** library provides everything you need to instrument your Delphi applications with Prometheus metrics.

## 🧩 Features

The Prometheus Delphi Client library offers a comprehensive set of features:

- **Standard Metric Types**
  - **Counter** - Cumulative metrics that only increase (requests, errors, etc.)
  - **Gauge** - Metrics that can go up and down (memory usage, connections, etc.)
  - **Histogram** - Distribution of values in configurable buckets (response times, sizes)
  - **Summary** - Quantiles over sliding time windows with configurable objectives

- **Label Support** - Add context to metrics with key-value pairs for multi-dimensional data

- **Collector Registry** - Centralized registry to manage multiple metrics efficiently

- **Text Format Exporter** - Export metrics in Prometheus text-based exposition format

- **Thread-Safe Operations** - Safe to use in multi-threaded and concurrent applications

- **Custom Collectors** - Extend with your own metric types and collectors

- **Web Framework Integration** - Ready-to-use middlewares for popular Delphi web frameworks

- **Best Practices Built-in** - Follows [Prometheus best practices](https://prometheus.io/docs/practices/) for naming and usage

## 📦 Installation

### 📥 Using Boss Package Manager

[Boss](https://github.com/HashLoad/boss) is a dependency manager for Delphi. If you have Boss installed:

```bash
boss install marcobreveglieri/prometheus-client-delphi
```

### 🛠️ Manual Installation

1. Download or clone the repository from [GitHub](https://github.com/marcobreveglieri/prometheus-client-delphi)
2. Add the `Source` folder to your project's search path:
   - Open **Project > Options**
   - Navigate to **Delphi Compiler > Search Path** (or **Resource Compiler > Directories and Conditionals > Include file search path** for older versions)
   - Add the path: `prometheus-client-delphi\Source`

Example:
```
C:\Projects\prometheus-client-delphi\Source
```

## ⚡ Quick Start Guide

Let's create a complete working example that tracks HTTP requests.

### 1️⃣ Step 1: Add Required Units

```delphi
uses
  Prometheus.Collectors.Counter,
  Prometheus.Collectors.Histogram,
  Prometheus.Registry,
  Prometheus.Exposers.Text;
```

### 2️⃣ Step 2: Create and Register Metrics

```delphi
var
  LCounter: TCounter;
  LDuration: THistogram;

procedure InitializeMetrics;
begin
  // Counter for total requests
  LCounter := TCounter.Create(
    'http_requests_total',
    'Total HTTP requests processed',
    ['method', 'path', 'status']
  ).Register();

  // Histogram for request duration
  LDuration := THistogram.Create(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'path']
  ).Register();
end;
```

### 3️⃣ Step 3: Track Metrics in Your Application

```delphi
procedure HandleRequest(const AMethod, APath: string; AStatusCode: Integer);
var
  LStopwatch: TStopwatch;
begin
  LStopwatch := TStopwatch.StartNew;
  try
    // Your request handling code here
    ProcessRequest(AMethod, APath);
  finally
    LStopwatch.Stop;

    // Record metrics
    LCounter.Labels([AMethod, APath, IntToStr(AStatusCode)]).Inc();
    LDuration.Labels([AMethod, APath]).Observe(LStopwatch.Elapsed.TotalSeconds);
  end;
end;
```

### 4️⃣ Step 4: Expose Metrics Endpoint

```delphi
// Example using Indy HTTP Server
procedure HandleMetricsRequest(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  LExposer: TTextExposer;
begin
  if ARequestInfo.Document = '/metrics' then
  begin
    LExposer := TTextExposer.Create;
    try
      AResponseInfo.ContentType := 'text/plain; charset=utf-8';
      AResponseInfo.ContentText := LExposer.Render(
        TCollectorRegistry.DefaultRegistry.Collect()
      );
      AResponseInfo.ResponseNo := 200;
    finally
      LExposer.Free;
    end;
  end;
end;
```

### 5️⃣ Step 5: Configure Prometheus

Create `prometheus.yml` to scrape your application:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'my-delphi-app'
    static_configs:
      - targets: ['localhost:9090']
    metrics_path: '/metrics'
```

Start Prometheus and visit `http://localhost:9090` to query your metrics!

**Next Steps**: Check the [Getting Started](https://github.com/marcobreveglieri/prometheus-client-delphi/wiki/Getting-Started) wiki page for more detailed tutorials.

## 📏 Metric Types

### ➕ Counter

A **counter** is a cumulative metric that only increases (or resets to zero on restart). Use counters for values that accumulate over time.

**Use cases**: Total requests, errors, tasks completed, bytes processed

```delphi
uses
  Prometheus.Collectors.Counter;

var
  LCounter: TCounter;
begin
  // Create and register
  LCounter := TCounter.Create('app_requests_total', 'Total requests processed')
    .Register();

  // Increment by 1
  LCounter.Inc();

  // Increment by specific amount
  LCounter.Inc(5);
end;
```

**With labels**:
```delphi
var
  LCounter: TCounter;
begin
  LCounter := TCounter.Create('http_requests_total', 'Total HTTP requests', ['method', 'status'])
    .Register();

  LCounter.Labels(['GET', '200']).Inc();
  LCounter.Labels(['POST', '404']).Inc();
end;
```

### 🌡️ Gauge

A **gauge** is a metric that can arbitrarily increase or decrease. Use gauges for values that represent current state.

**Use cases**: Memory usage, active connections, queue depth, temperature

```delphi
uses
  Prometheus.Collectors.Gauge;

var
  LGauge: TGauge;
begin
  // Create and register
  LGauge := TGauge.Create('memory_usage_bytes', 'Current memory usage in bytes')
    .Register();

  // Increment and decrement
  LGauge.Inc();        // +1
  LGauge.Inc(100);     // +100
  LGauge.Dec(50);      // -50

  // Set to specific value
  LGauge.SetTo(1024);

  // Set to duration of operation
  LGauge.SetDuration(
    procedure
    begin
      // Your code here - gauge will be set to execution time in milliseconds
      ProcessData();
    end);
end;
```

### 📊 Histogram

A **histogram** samples observations and counts them in configurable buckets. Histograms are ideal for measuring distributions like request durations or response sizes.

**Use cases**: Request/response durations, response sizes, query times

```delphi
uses
  Prometheus.Collectors.Histogram;

var
  LHistogram: THistogram;
begin
  // Create with default buckets
  LHistogram := THistogram.Create(
    'request_duration_seconds',
    'HTTP request duration in seconds'
  ).Register();

  // Record observations
  LHistogram.Observe(0.25);  // 250ms
  LHistogram.Observe(0.5);   // 500ms
  LHistogram.Observe(1.2);   // 1.2s
end;
```

**With custom buckets**:
```delphi
var
  LHistogram: THistogram;
begin
  // Custom buckets optimized for your use case
  LHistogram := THistogram.Create(
    'api_response_time_seconds',
    'API response time',
    [],  // No labels
    [0.01, 0.05, 0.1, 0.5, 1.0, 2.5, 5.0]  // Custom buckets in seconds
  ).Register();

  LHistogram.Observe(0.123);
end;
```

### Σ Summary

A **summary** samples observations and calculates configurable φ-quantiles (e.g. p50/p90/p99) over a sliding time window (default: 10 minutes, split into 5 age buckets), together with a cumulative sum and count of all observed values. Quantiles are estimated on the client side with the CKMS streaming algorithm, so each objective specifies both the quantile rank and its allowed estimation error.

**Use cases**: Request durations and latencies when you need precomputed client-side quantiles

```delphi
uses
  Prometheus.Collectors.Summary;

var
  LSummary: TSummary;
begin
  // Create with default objectives: 0.5 ± 0.05, 0.9 ± 0.01, 0.99 ± 0.001
  LSummary := TSummary.Create(
    'request_duration_seconds',
    'HTTP request duration in seconds');
  LSummary.Register();

  // Record observations
  LSummary.Observe(0.25);  // 250ms

  // Or time a block of code (records the elapsed seconds)
  LSummary.ObserveDuration(
    procedure
    begin
      ProcessData();
    end);
end;
```

**With custom objectives, labels and time window**:
```delphi
uses
  Prometheus.Collectors.Summary,
  Prometheus.Quantiles;

var
  LSummary: TSummary;
begin
  LSummary := TSummary.Create(
    'api_response_time_seconds',
    'API response time',
    [TQuantileObjective.Create(0.95, 0.005),
     TQuantileObjective.Create(0.99, 0.001)],  // Quantile objectives
    ['endpoint'],                              // Labels
    5 * 60 * 1000,                             // Max age: 5 minutes (in milliseconds)
    5                                          // Age buckets
  );
  LSummary.Register();

  LSummary.Labels(['/users']).Observe(0.123);
end;
```

Keep in mind that quantile values are reported as `NaN` when no observation falls within the sliding time window, while `_sum` and `_count` are cumulative and unaffected by it. Note also that summaries are more expensive than histograms on the client side and their quantiles cannot be aggregated across instances: prefer histograms when server-side aggregation is needed.

**Learn more**: See [Metric Types](https://github.com/marcobreveglieri/prometheus-client-delphi/wiki/Metric-Types) in the wiki for detailed information, including when to use each type.

## 🏷️ Working with Labels

**Labels** add dimensions to your metrics, allowing you to slice and dice data in Prometheus queries.

### Basic Label Usage

```delphi
var
  LCounter: TCounter;
begin
  // Create metric with labels
  LCounter := TCounter.Create(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'path', 'status']  // Label names
  ).Register();

  // Increment specific label combinations
  LCounter.Labels(['GET', '/api/users', '200']).Inc();
  LCounter.Labels(['POST', '/api/orders', '201']).Inc();
  LCounter.Labels(['GET', '/api/users', '404']).Inc();
end;
```

### Retrieving and Reusing Metrics

```delphi
// Later in your code, retrieve the metric from the registry
var
  LCounter: TCounter;
begin
  LCounter := TCollectorRegistry.DefaultRegistry
    .GetCollector<TCounter>('http_requests_total');

  if Assigned(LCounter) then
    LCounter.Labels(['GET', '/api/products', '200']).Inc();
end;
```

### Best Practices for Labels

- **Keep cardinality low** - Avoid labels with unbounded values (user IDs, timestamps, etc.)
- **Use consistent names** - Standardize label names across metrics (`method`, `status`, `endpoint`)
- **Don't overuse labels** - 3-5 labels per metric is typically sufficient
- **Label values should be bounded** - Use categories, not unique identifiers

**Learn more**: See [Working with Labels](https://github.com/marcobreveglieri/prometheus-client-delphi/wiki/Working-with-Labels) for advanced patterns and best practices.

## 📤 Exporting Metrics

Metrics must be exposed via an HTTP endpoint for Prometheus to scrape them.

### 📝 Basic Export to String

```delphi
uses
  Prometheus.Exposers.Text,
  Prometheus.Registry;

var
  LExposer: TTextExposer;
  LMetrics: string;
begin
  LExposer := TTextExposer.Create;
  try
    LMetrics := LExposer.Render(
      TCollectorRegistry.DefaultRegistry.Collect()
    );
    Writeln(LMetrics);
  finally
    LExposer.Free;
  end;
end;
```

**Output example**:
```
# HELP http_requests_total Total HTTP requests.
# TYPE http_requests_total counter
http_requests_total{method="GET",status="200"} 150
http_requests_total{method="POST",status="201"} 42

# HELP memory_usage_bytes Current memory usage.
# TYPE memory_usage_bytes gauge
memory_usage_bytes 1048576
```

### 🧱 Delphi MVC Framework

The [DMVC Prometheus Metrics](https://github.com/marcobreveglieri/dmvc-prometheus-metrics) middleware integrates with DelphiMVCFramework applications.

**Installation**:
```bash
boss install marcobreveglieri/dmvc-prometheus-metrics
```

The middleware automatically exposes metrics and can track requests, response times, and more.

**Learn more**: See [Web Framework Integration](https://github.com/marcobreveglieri/prometheus-client-delphi/wiki/Web-Framework-Integration) for framework-specific guides.

### 🔌 HTTP Endpoint with Indy

```delphi
uses
  IdHTTPServer, IdContext, IdCustomHTTPServer,
  Prometheus.Exposers.Text, Prometheus.Registry;

procedure TForm1.IdHTTPServer1CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  LExposer: TTextExposer;
begin
  if ARequestInfo.Document = '/metrics' then
  begin
    LExposer := TTextExposer.Create;
    try
      AResponseInfo.ContentType := 'text/plain; charset=utf-8';
      AResponseInfo.ContentText := LExposer.Render(
        TCollectorRegistry.DefaultRegistry.Collect()
      );
      AResponseInfo.ResponseNo := 200;
    finally
      LExposer.Free;
    end;
  end;
end;
```

**Learn more**: See [Exporting Metrics](https://github.com/marcobreveglieri/prometheus-client-delphi/wiki/Exporting-Metrics) for more export methods, including streams, Windows services, and security best practices.

## 🌐 Web Framework Integration

For popular Delphi web frameworks, use these official middleware packages that automatically expose metrics:

### 🐎 Horse Framework

The [Horse Prometheus Metrics](https://github.com/marcobreveglieri/horse-prometheus-metrics) middleware provides automatic metrics exposition and optional request tracking.

**Installation**:
```bash
boss install marcobreveglieri/horse-prometheus-metrics
```

**Usage**:
```delphi
uses
  Horse,
  Horse.Prometheus;

begin
  // Automatically exposes /metrics endpoint
  THorse.Use(Prometheus);

  // Your routes here
  THorse.Get('/api/users', HandleGetUsers);

  THorse.Listen(9000);
end;
```

## 💡 Real-World Examples

### 🔍 Complete HTTP Request Tracking

```delphi
uses
  Prometheus.Collectors.Counter,
  Prometheus.Collectors.Histogram,
  System.Diagnostics;

type
  THTTPMetrics = class
  private
    FRequestCounter: TCounter;
    FDurationHistogram: THistogram;
  public
    constructor Create;
    procedure TrackRequest(const AMethod, APath: string;
      AStatus: Integer; ADuration: Double);
  end;

constructor THTTPMetrics.Create;
begin
  inherited;

  FRequestCounter := TCounter.Create(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'path', 'status']
  ).Register();

  FDurationHistogram := THistogram.Create(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'path'],
    [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0]  // Buckets
  ).Register();
end;

procedure THTTPMetrics.TrackRequest(const AMethod, APath: string;
  AStatus: Integer; ADuration: Double);
begin
  FRequestCounter.Labels([AMethod, APath, IntToStr(AStatus)]).Inc();
  FDurationHistogram.Labels([AMethod, APath]).Observe(ADuration);
end;

// Usage in your application
var
  GMetrics: THTTPMetrics;

procedure HandleHTTPRequest(ARequest: TRequest; AResponse: TResponse);
var
  LStopwatch: TStopwatch;
begin
  LStopwatch := TStopwatch.StartNew;
  try
    // Process your request
    ProcessRequest(ARequest, AResponse);
  finally
    LStopwatch.Stop;
    GMetrics.TrackRequest(
      ARequest.Method,
      ARequest.PathInfo,
      AResponse.StatusCode,
      LStopwatch.Elapsed.TotalSeconds
    );
  end;
end;
```

### 🧠 Memory and Connection Pool Monitoring

```delphi
uses
  Prometheus.Collectors.Gauge;

type
  TSystemMetrics = class
  private
    FMemoryUsage: TGauge;
    FActiveConnections: TGauge;
  public
    constructor Create;
    procedure UpdateMetrics;
  end;

constructor TSystemMetrics.Create;
begin
  FMemoryUsage := TGauge.Create(
    'app_memory_bytes',
    'Application memory usage in bytes'
  ).Register();

  FActiveConnections := TGauge.Create(
    'db_connections_active',
    'Number of active database connections'
  ).Register();
end;

procedure TSystemMetrics.UpdateMetrics;
var
  LMemStatus: TMemoryManagerState;
  LMemUsage: Int64;
begin
  // Update memory usage
  GetMemoryManagerState(LMemStatus);
  LMemUsage := LMemStatus.TotalAllocatedMediumBlockSize +
               LMemStatus.TotalAllocatedLargeBlockSize;
  FMemoryUsage.SetTo(LMemUsage);

  // Update connection pool
  FActiveConnections.SetTo(GetActiveConnectionCount());
end;

// Call UpdateMetrics() periodically (e.g., every 5 seconds via a timer)
```

**More examples**: See [Code Examples](https://github.com/marcobreveglieri/prometheus-client-delphi/wiki/Code-Examples) in the wiki for database monitoring, cache tracking, job queues, and more.

## 📚 Documentation

Comprehensive documentation is available in the [GitHub Wiki](https://github.com/marcobreveglieri/prometheus-client-delphi/wiki).

## 🖥️ Delphi Compatibility

**Prometheus Client for Delphi** requires **Delphi 11 Alexandria** or later versions.

The library leverages modern Delphi language features including:

- Inline variable declarations
- Anonymous methods
- Generics
- Advanced RTTI

While it may work with earlier Delphi versions with modifications, official support and testing target Delphi 11 Alexandria and newer releases. Development and testing are currently carried out on **Delphi 13.1**.

## ✅ Problem? Solved!

| Problem | Solution |
|---------|----------|
| **"How do I add metrics to my Delphi app?"** | Ready-to-use metric types: Counter, Gauge, Histogram, Summary |
| **"How do I export metrics in Prometheus format?"** | Built-in text format exporter compatible with Prometheus |
| **"How do I add context to my metrics?"** | Label support for multi-dimensional metrics |
| **"Is it thread-safe?"** | Yes, all operations are thread-safe for multi-threaded apps |
| **"How do I integrate with my web framework?"** | Official middlewares for Horse and DMVC Framework |
| **"Can I create custom metrics?"** | Extensible architecture for custom collectors |

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

- **Report bugs** - Open an issue on [GitHub Issues](https://github.com/marcobreveglieri/prometheus-client-delphi/issues)
- **Suggest features** - Share your ideas for improvements
- **Submit pull requests** - Fix bugs or add features
- **Improve documentation** - Help make the docs clearer and more comprehensive
- **Share examples** - Contribute real-world usage examples

See the [Contributing Guide](https://github.com/marcobreveglieri/prometheus-client-delphi/wiki/Contributing) for more details.

## 🔗 Resources

### 🌍 Official Links
- [GitHub Repository](https://github.com/marcobreveglieri/prometheus-client-delphi)
- [Wiki Documentation](https://github.com/marcobreveglieri/prometheus-client-delphi/wiki)
- [Issue Tracker](https://github.com/marcobreveglieri/prometheus-client-delphi/issues)

### 📊 Prometheus Resources
- [Prometheus Official Site](https://prometheus.io)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [PromQL Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)

### 📈 Grafana Resources
- [Grafana Official Site](https://grafana.com)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Data Source Guide](https://grafana.com/docs/grafana/latest/datasources/prometheus/)

### 🧰 Middleware Packages
- [Horse Prometheus Metrics](https://github.com/marcobreveglieri/horse-prometheus-metrics) - Horse framework middleware
- [DMVC Prometheus Metrics](https://github.com/marcobreveglieri/dmvc-prometheus-metrics) - Delphi MVC Framework middleware

### 🎥 Video Tutorials
- [Using Delphi with Prometheus and Grafana](https://www.youtube.com/watch?v=-bPDl6MP6jo) (Italian)

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <strong>Made with ❤️ for the Delphi community</strong>
</p>

<p align="center">
  <a href="https://github.com/marcobreveglieri/prometheus-client-delphi/issues">Report Bug</a> •
  <a href="https://github.com/marcobreveglieri/prometheus-client-delphi/issues">Request Feature</a> •
  <a href="https://github.com/marcobreveglieri/prometheus-client-delphi/wiki">Documentation</a>
</p>
> [!IMPORTANT]
>
> **Note**: This documentation has been generated with the assistance of LLMs (Claude Code). While we strive for accuracy, some information may be incorrect or incomplete. If you find errors or have improvements, please open a pull request on the [GitHub Wiki repository](https://github.com/marcobreveglieri/prometheus-client-delphi.wiki). Your contributions help make this documentation better for everyone!
