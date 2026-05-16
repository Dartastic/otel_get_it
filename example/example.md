# otel_get_it example

App-startup DI bootstrap traced from `main()`.

```dart
// example/lib/main.dart

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:get_it/get_it.dart';
import 'package:otel_get_it/otel_get_it.dart';

class DatabaseService {
  DatabaseService(this.dbPath);
  final String dbPath;
}

class AuthService {
  AuthService(this.db);
  final DatabaseService db;
}

Future<void> main() async {
  await OTel.initialize(
    serviceName: 'get-it-demo',
    endpoint: 'http://localhost:4317',
  );

  final getIt = GetIt.instance;
  final tracer = OTel.tracer();
  final boot = tracer.startSpan(
    'app boot',
    kind: SpanKind.internal,
  );

  // Async registrations — each becomes a child of `app boot`.
  getIt.tracedRegisterSingletonAsync<DatabaseService>(() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return DatabaseService('/tmp/app.db');
  });
  getIt.tracedRegisterSingletonAsync<AuthService>(
    () async {
      // dependsOn ensures DB is up first.
      await Future<void>.delayed(const Duration(milliseconds: 40));
      return AuthService(getIt<DatabaseService>());
    },
    dependsOn: [DatabaseService],
  );

  // Total bootstrap wait — also a span, parented to `app boot`.
  await getIt.tracedAllReady();

  boot.end();

  // ...runApp(...)
}
```

## Trace shape

```
app boot
├── get_it register_async DatabaseService  (80ms)
├── get_it register_async AuthService      (40ms)
└── get_it all_ready GetIt                 (≈120ms total)
```

Each registration span carries:
- `di.system = get_it`
- `di.operation = register_async`
- `di.type = DatabaseService` (or `AuthService`)

On failure (e.g. the DB factory throws):

```
app boot
├── get_it register_async DatabaseService  STATUS=Error
│     error.type = SocketException
│     [exception event]
└── get_it all_ready GetIt                 STATUS=Error
```

Synchronous lookups (`getIt<DatabaseService>()`) are intentionally
not spanned — they're sub-microsecond and span overhead would
dominate.
