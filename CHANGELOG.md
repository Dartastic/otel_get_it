# Changelog

## [0.1.0-beta.1-wip]

### Added

- Extension methods on `GetIt`: `tracedRegisterSingletonAsync`,
  `tracedAllReady`, `tracedGetAsync`, `tracedUnregister`,
  `tracedReset`. Each opens a CLIENT span named
  `get_it <operation> <type>` with `di.system=get_it`,
  `di.operation`, `di.type`, and optionally `di.instance_name`.
- Synchronous `get<T>()` is intentionally NOT wrapped — those
  calls are sub-microsecond and span overhead would dominate.
  The async path (`registerSingletonAsync`, `allReady`,
  `getAsync`) is where instrumentation pays off — it captures DI
  bootstrap cost at startup.
- `tracedGetItCall<R>({operation, typeName, instanceName,
  invoke})` — generic helper for testability and custom call
  sites.
- Local `GetItSemantics` enum (implements `OTelSemantic`) for the
  `di.system` / `di.operation` / `di.type` / `di.instance_name`
  keys — replaces raw-string keys per the OTel-Dart wrapper style
  guide.
- Zone-scoped suppression
  (`runWithoutGetItInstrumentation` and async variant).
- Ten tests on the canonical `_helpers/otel_test_harness.dart`
  (instance-scoped via `GetIt.asNewInstance()`; no global state).
  Coverage: every traced method's success path, the error path on
  `registerSingletonAsync`, `instanceName` propagation, both
  suppression entry points, and multi-registration spans.
- `example/example.md` showing a full app-boot trace.
