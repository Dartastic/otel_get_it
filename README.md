<!-- dartastic-header:start -->
# OpenTelemetry instrumentation for `get_it`

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![OpenTelemetry Specification](https://img.shields.io/badge/OpenTelemetry-Specification-blueviolet)](https://opentelemetry.io/docs/specs/otel/)

`otel_get_it` is an [OpenTelemetry](https://opentelemetry.io/) instrumentation for `get_it` that
easily adds standard observability to applications that use `get_it`.  This package depends on 
[dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api).

This package can be used with any OTel backend because it's compliant with the OpenTelemetry Specification.

This package supports Android, iOS, Linux, macOS, Web and Windows, for versions of `get_it` that support those platforms. It is WASM-ready.

This Apache-2.0 package is professionally maintained and supported with 💙 by Michael Bushe,
Dart and Flutter Maintainer at OpenTelemetry and the creator of [dartastic_opentelemetry](https://pub.dev/packages/dartastic_opentelemetry)
and [dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api). This package is professionally supported by
[Dartastic.io](https://dartastic.io).

---
## Dartastic.io: AI Code Healing and Real User Monitoring for Flutter

**See what your users experience. Find problems with Flutter apps in production. Fix them with AI.**

[Dartastic.io](https://dartastic.io) brings AI code healing, real user monitoring, and OpenTelemetry observability together in one platform built for Dart and Flutter. (Patents pending)

![Dartastic AI answering "Why did crashes jump after the last release?" over a Flutter App Health dashboard](https://dartastic.io/img/pub-dev/HomePageCrashesQuestion.png)

### Dartastic AI — From Production Problems to Code Fixes

Dartastic AI analyzes production telemetry alongside your application source code to diagnose problems and propose fixes.

- **Investigate production issues** using crashes, errors, traces, metrics, and real user telemetry.
- **Find the offending code** by connecting observed problems with your application's source in Dartastic Pub or your source code repos.
- **Generate code patches** that address the underlying problems.
- **Create actionable issues** in your issue tracker, complete with findings and the proposed code patch.

### Dartastic RUM — See What Your Users See

Understand how people actually experience your Flutter application.

- **Replay user sessions** in the Dartastic Observatory session player.
- **Choose your replay fidelity**, from privacy-preserving widget outlines to pixel-level reproductions of the user experience.
- **Investigate real user problems** using session replay and production observability data.

![Dartastic RUM Session Replay](https://dartastic.io/img/pub-dev/session-replay.png)

### Dartastic Observatory — Observability Built for Flutter

A complete observability backend where Flutter and Dart are first-class citizens.

- **Flutter-specific dashboards** for application performance, health, and reliability.
- **Alerts and notifications** through email, Slack, and PagerDuty.
- **Dartastic Cloud Observatory** — Start with a 30-day free trial on isolated, shared infrastructure, as low as $39/mo.
- **Dartastic Hosted Observatory** — Run the observability stack in a private managed environment, sized from Mini to Enterprise XL.
- **Dartastic Self-Hosted Observatory** — The whole platform inside your own network. Your keys, your cluster, with nothing leaving your perimeter.

### Dartastic Native OTel Runtime — Native OpenTelemetry Performance

Collect production telemetry without burdening Flutter's main isolate.

- **Native OpenTelemetry runtime** that moves telemetry processing off the main isolate.
- **Native crash reporting** for problems that Dart can't catch.
- **Widget performance diagnostics** to identify janky widgets.
- **On-device PII filtering** before sensitive data leaves your application.
- **Source-level error diagnostics** powered by the Dartastic Symbolizer API.
- **Platform-native metrics** for iOS, Android, and Linux, including iOS MetricKit and Android Vitals.
- **OpenTelemetry compatibility** — Send telemetry to Dartastic Observatory or any OpenTelemetry platform.

### Dartastic Labs — OpenTelemetry Integrations

Instrument more of your application without writing everything yourself.

- **650+ open-source integrations** for Dart and Flutter libraries and services, including Dio, Shelf, Logger, Anthropic, AWS, Azure, and Stripe. Look for otel_* on pub.dev.

### More Dartastic Tools

**[Dartastic Pub](https://dartastic.io/pub)**

A private Dart package registry for sharing packages and plugins with your team, partners, and customers.

**[Dartastic Symbolizer](https://dartastic.io/symbolizer)**

Turn production errors into lines of source code through a web API, while keeping your source code artifacts private.

### Professional Support and Training

Dartastic.io offers commercial support for the open-source `dartastic_opentelemetry` and `dartastic_opentelemetry_api` packages and the complete Dartastic product suite.

- **Professional support** with available around-the-clock coverage and response times under four hours on qualifying plans.
- **OpenTelemetry training** for teams instrumenting Dart, Flutter, mobile, and web applications.

### Open Standards. No Mandatory Backend.

The Dartastic OpenTelemetry API and SDK are open source and standards-based. You can use them independently of Dartastic's commercial services and send telemetry to any compatible OpenTelemetry backend.

Dartastic's commercial products add native performance, advanced diagnostics, session replay, AI-assisted remediation, and managed observability services.

**[Explore Dartastic.io](https://dartastic.io)**

---
<!-- dartastic-header:end -->

OpenTelemetry instrumentation for
[`package:get_it`](https://pub.dev/packages/get_it) —
Thomas Burkhart's service locator.

Adds CLIENT-kind spans around the async registration and resolution
paths so DI bootstrap cost is visible in your traces. Synchronous
`get<T>()` is intentionally **not** wrapped — those calls are
sub-microsecond on the hot path and span overhead would dominate.

## Install

```yaml
dependencies:
  get_it: ^9.0.0 # 8.x also supported
  otel_get_it: ^0.3.0
```

## Use

```dart
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:get_it/get_it.dart';
import 'package:otel_get_it/otel_get_it.dart';

Future<void> main() async {
  await OTel.initialize(
    serviceName: 'my-app',
  );

  final getIt = GetIt.instance;

  // Async registrations — span lifetime mirrors the factory's
  // execution, so you see how long each service took to bring up.
  getIt.tracedRegisterSingletonAsync<DatabaseService>(() async {
    return DatabaseService(await openDatabase('app.db'));
  });
  getIt.tracedRegisterSingletonAsync<AuthService>(() async {
    return AuthService(await FirebaseAuth.instance);
  });

  // Total bootstrap wait.
  await getIt.tracedAllReady();

  runApp(const MyApp());
}
```

## Span shape

| Function                            | Span name                          | `di.operation`    |
|-------------------------------------|------------------------------------|-------------------|
| `tracedRegisterSingletonAsync<T>`   | `get_it register_async <T>`        | `register_async`  |
| `tracedAllReady`                    | `get_it all_ready GetIt`           | `all_ready`       |
| `tracedGetAsync<T>`                 | `get_it get_async <T>`             | `get_async`       |
| `tracedUnregister<T>`               | `get_it unregister <T>`            | `unregister`      |
| `tracedReset`                       | `get_it reset GetIt`               | `reset`           |

All spans carry:

| Attribute            | Source                                       |
|----------------------|----------------------------------------------|
| `di.system`          | hardcoded `get_it`                           |
| `di.operation`       | the operation name (see table above)         |
| `di.type`            | the registered type's name (e.g. `_Service`) |
| `di.instance_name`   | the optional `instanceName` argument         |
| `error.type`         | exception class on throw                     |

These keys are package-local (no upstream OTel semconv exists yet
for DI / service locators); they're stable across the 0.x line.

## Why no sync `get<T>()` wrap?

Synchronous resolution is sub-microsecond on the hot path. A span
per `getIt<Foo>()` call would produce gigabytes of low-value trace
data. Use the async variants when you want visibility, or wrap
individual call sites yourself if you have a specific service
whose lookup cost matters.

## Suppression

```dart
await runWithoutGetItInstrumentationAsync(() async {
  await getIt.tracedReset();  // skipped
});
```

## See also

- [`otel_watch_it`](https://pub.dev/packages/otel_watch_it) — Thomas
  Burkhart's Flutter binding to `get_it`. Instruments widget
  lifecycle hooks (`callOnce`, `pushScope`, `onDispose`).
- [`otel_command_it`](https://pub.dev/packages/otel_command_it) —
  Thomas Burkhart's `Command` pattern for UI actions.

## License

Apache 2.0 — copyright Mindful Software LLC.
