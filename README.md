# otel_get_it

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
  otel_get_it: ^0.2.0
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
