<div>  
  <img alt="Prometheus Client for Delphi" height="256" src="https://ucarecdn.com/a7019e45-d14b-47cd-8ceb-70ba7848f049/">
  <h1>Prometheus Client for Delphi</h1>
</div>
<br />

This is a Delphi client library for [Prometheus](http://prometheus.io), similar to [libraries created for other languages](https://prometheus.io/docs/instrumenting/writing_clientlibs/).  

## Overview

The **Prometheus Delphi Client** library is a set of classes that allow you to instrument your Delphi applications with *Prometheus* metrics.

It allows you to instrument your Delphi code with custom metrics and provides some built-in and ready to use metrics.

The library also supports Prometheus' text based exposition format, that can be configured and made available via an HTTP endpoint on your Web application's instance using specific middlewares or directly calling the text exporter.

### What is Prometheus

[Prometheus](http://prometheus.io) is a popular open-source monitoring tool that is widely used in modern software environments. It provides a powerful system for collecting and analyzing metrics from various sources, including applications, servers, and other systems.

To use *Prometheus* effectively, you need a [client library](https://prometheus.io/docs/instrumenting/clientlibs/) implemented in your favorite programming language that can be integrated into your applications to expose the relevant metrics to the Prometheus server.

Here we will discuss the client library for Prometheus written for [Embarcadero Delphi](https://www.embarcadero.com/products/delphi/).

### Main Features

The Prometheus Delphi Client library offers a **range of features** that make it a powerful and flexible tool for monitoring Delphi applications using Prometheus.

By using the library, you can gain valuable insights into the performance and behavior of your Delphi applications and make data-driven decisions to improve them.

Here are some of supported features:

+ **Basic metrics**: the library allows you to define some basic metrics supported by Prometheus to track some relevant values in your application, like the number of times an event has occured or the current amount of allocated memory and so on.
+ **Labels**: these are key-value pairs that allow you to add additional context to your metrics.
+ **Custom Collectors**: the library allows you to define custom collectors that can be used to collect metrics from any source.

## Getting Started

To get started with the Prometheus Delphi Client library, you need to follow these steps.

### ⚙ Install the library

Installation is done using the [`boss install`](https://github.com/HashLoad/boss) command:
``` sh
boss install marcobreveglieri/prometheus-client-delphi
```
If you choose to install it manually, download the source code from GitHub simply add the following folders to your project, in *Project > Options > Resource Compiler > Directories and Conditionals > Include file search path*
```
prometheus-client-delphi/Source
```

### 📏 Define your metrics

Define the metrics you want to track using the appropriate classes (see below).

### 📒 Register your metrics

Register your metrics inside the default collector registry or in a registry of your own for subsequent handling and exportation.

### ✔ Update your metrics

Update your metrics as needed calling the appropriate methods you can find on collector instance depending on the classes they are based to.

### 💾 Export all your metric samples

You can export your metrics calling the text based exporter or making use of a ready to use middleware that targets your favourite Delphi Web framework (see [Middlewares](#Middlewares) section below for details).

## Metrics

Prometheus Delphi Client supports the following metric types.

### Counter

A **counter** is a cumulative metric that represents a single monotonically increasing counter whose value can only increase or be reset to zero on restart. For example, you can use a counter to represent the number of requests served, tasks completed, or errors.

Do not use a counter to expose a value that can decrease. For example, do not use a counter for the number of currently running processes; instead use a gauge.

```delphi
uses
  Prometheus.Collectors.Counter;

begin
  var LCounter := TCounter.Create('sample', 'Description of this counter');
  LCounter.Inc(); // increment by 1
  LCounter.Inc(123); // increment by 123
end.
```

### Gauge

A **gauge** is a metric that represents a single numerical value that can arbitrarily go up and down.

Gauges are typically used for measured values like temperatures or current memory usage, but also "counts" that can go up and down, like the number of concurrent requests.

```delphi
uses
  Prometheus.Collectors.Gauge;

begin
  var LGauge := TGauge.Create('sample', 'Description of this gauge');
  LGauge.Inc(); // increment by 1
  LGauge.Inc(123); // increment by 123
  LGauge.Dec(10); // decrement by 10
  LGauge.SetTo(123); // set value directly to 123
  LGauge.SetDuration( // set value to duration of method execution
    procedure
    begin
      // User code
    end);
end.
```

### Summary

Similar to a histogram, a **summary** samples observations (usually things like request durations and response sizes). While it also provides a total count of observations and a sum of all observed values, it calculates configurable quantiles over a sliding time window.

*** !!! Under Development !!! ***

### Histogram

A **histogram** samples observations (usually things like request durations or response sizes) and counts them in configurable buckets. It also provides a sum of all observed values.

*** !!! Under Development !!! ***

### Custom metrics

You can also implement your own custom metrics by inheriting the appropriate classes (**TCollector** or **TSimpleCollector**).

## Labels

All metrics can have **labels**, allowing grouping of related time series.

Taking a counter as an example:

```delphi
uses
  Prometheus.Collectors.Counter;

begin
  var LCounter := TCounter
    .Create('http_requests_handled', 'HTTP handled requests total', ['path', 'status'])
    .Register();
end.
```

Metrics with labels are not initialized when declared, because the client can't know what values the label can have.
It is recommended to initialize the label values by calling the appropriate method and then eventually call another method to alter the value of the metric associated to label values:

```delphi
uses
  Prometheus.Collectors.Counter;

begin
  TCollectorRegistry.DefaultRegistry
    .GetCollector<TCounter>('http_requests_handled')
    .Labels(['/api', 200]) // ['path', 'status']
    .Inc(); // increment child counter attached to these label values
end.
```

## Exporting metrics

There are several options for exporting metrics. For example, you can export metrics from a *Windows Service Application* using a **TIdHttp** server component from *Indy Components* and exposing a "/metrics" endpoint where you export text based metrics data to Prometheus server.

You can also download a middleware for your favourite Web framework or take a look at the sample projects.

## Middlewares

To ease the use of Prometheus Client inside Web applications created with Delphi, you will find here **middlewares** to download and install.

Each middleware integrates support for exposing metrics to Prometheus server using the appropriate format and without having to code each endpoint manually.

You can find official **Prometheus Client middlewares** into these separate repositories:

| Middleware |
| ------------------------------------------------------------------------------------------ |
|  [Delphi MVC Framework](https://github.com/marcobreveglieri/dmvc-prometheus-metrics)       |
|  [Horse](https://github.com/marcobreveglieri/horse-prometheus-metrics)                     |

## Delphi compatibility

*Prometheus Client* works with **Delphi 11 Alexandria** as it makes use of advanced features of Delphi language, but with some slight changes it maybe could work in previous versions.

## Additional links

+ [Prometheus Official Page](https://prometheus.io)
+ [Using Delphi with Prometheus and Grafana (in Italian language)](https://www.youtube.com/watch?v=-bPDl6MP6jo)
