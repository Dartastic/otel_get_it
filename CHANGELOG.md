# Changelog

## [0.2.0-wip]

### Changed

- `get_it` constraint widened to `>=8.0.0 <10.0.0` — supports get_it 9.x
  (verified against 9.2.1) while keeping 8.x compatibility.
- Dependency floors raised to `dartastic_opentelemetry ^1.1.0-beta.12` and
  `dartastic_opentelemetry_api ^1.0.0-rc.1`. The previous floors declared
  compatibility with API versions that predate the semconv enums this
  package uses and could not actually resolve-and-compile.
- `repository` URL corrected to the canonical `Dartastic` org casing so
  pub.dev repository verification succeeds.

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
- Ten tests on the SDK's test surface
  (`package:dartastic_opentelemetry/testing.dart`; instance-scoped via
  `GetIt.asNewInstance()`; no global state, no network).
  Coverage: every traced method's success path, the error path on
  `registerSingletonAsync`, `instanceName` propagation, both
  suppression entry points, and multi-registration spans.
- `example/example.md` showing a full app-boot trace.
