// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:get_it/get_it.dart';

import 'get_it_suppression.dart';

const _tracerName = 'otel_get_it';
const _diSystem = 'get_it';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Typed attribute keys for get_it spans.
///
/// No upstream OTel semantic convention exists for service-locator
/// / dependency-injection containers; these `di.*` keys are
/// package-local until a proposal lands. Stable across the 0.x line.
enum GetItSemantics implements OTelSemantic {
  /// `di.system` — always `get_it` for spans we emit.
  diSystem('di.system'),

  /// `di.operation` — `register_async` / `get_async` / `unregister`
  /// / `all_ready` / `reset`.
  diOperation('di.operation'),

  /// `di.type` — the registered type's name (e.g. `AuthService`).
  diType('di.type'),

  /// `di.instance_name` — the optional `instanceName` argument from
  /// `get_it`, when the user is registering multiple instances of
  /// the same type.
  diInstanceName('di.instance_name');

  const GetItSemantics(this.key);

  @override
  final String key;

  @override
  String toString() => key;
}

Attributes _attrs({
  required String operation,
  required String typeName,
  String? instanceName,
}) =>
    OTel.attributesFromMap(<String, Object>{
      GetItSemantics.diSystem.key: _diSystem,
      GetItSemantics.diOperation.key: operation,
      GetItSemantics.diType.key: typeName,
      if (instanceName != null) GetItSemantics.diInstanceName.key: instanceName,
    });

/// Generic helper. Opens a CLIENT span named
/// `get_it <operation> <type>` carrying `di.system=get_it`,
/// `di.operation=<op>`, `di.type=<typeName>`, and optionally
/// `di.instance_name=<name>`. Runs [invoke] and ends the span on
/// completion.
Future<R> tracedGetItCall<R>({
  required String operation,
  required String typeName,
  String? instanceName,
  required Future<R> Function() invoke,
}) async {
  if (getItInstrumentationSuppressed()) return invoke();
  final span = _tracer().startSpan(
    'get_it $operation $typeName',
    kind: SpanKind.client,
    attributes: _attrs(
      operation: operation,
      typeName: typeName,
      instanceName: instanceName,
    ),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Traced async-singleton registration. The span lifetime mirrors
/// the async factory's execution — so the time it takes to bring
/// up the service appears in your trace.
///
/// Sync `get_it.get<T>()` is intentionally NOT wrapped — those
/// calls are sub-microsecond on the hot path and span overhead
/// would dominate.
extension OTelGetIt on GetIt {
  /// Traced `registerSingletonAsync`. Wraps [factoryFunc] so the
  /// initialization is captured as a span, parented to whatever
  /// active span is around when the future awaits.
  void tracedRegisterSingletonAsync<T extends Object>(
    Future<T> Function() factoryFunc, {
    String? instanceName,
    Iterable<Type>? dependsOn,
    bool? signalsReady,
    DisposingFunc<T>? dispose,
  }) {
    registerSingletonAsync<T>(
      () => tracedGetItCall<T>(
        operation: 'register_async',
        typeName: T.toString(),
        instanceName: instanceName,
        invoke: factoryFunc,
      ),
      instanceName: instanceName,
      dependsOn: dependsOn,
      signalsReady: signalsReady,
      dispose: dispose,
    );
  }

  /// Traced `allReady`. Useful for measuring how long DI bootstrap
  /// took at app startup.
  Future<void> tracedAllReady({
    Duration? timeout,
    bool ignorePendingAsyncCreation = false,
  }) {
    return tracedGetItCall<void>(
      operation: 'all_ready',
      typeName: 'GetIt',
      invoke: () => allReady(
        timeout: timeout,
        ignorePendingAsyncCreation: ignorePendingAsyncCreation,
      ),
    );
  }

  /// Traced async lookup. For synchronous `get<T>()`, just call
  /// the method directly — wrapping is too noisy for sync
  /// resolution.
  Future<T> tracedGetAsync<T extends Object>({String? instanceName}) {
    return tracedGetItCall<T>(
      operation: 'get_async',
      typeName: T.toString(),
      instanceName: instanceName,
      invoke: () => getAsync<T>(instanceName: instanceName),
    );
  }

  /// Traced `unregister`.
  Future<void> tracedUnregister<T extends Object>({
    T? instance,
    String? instanceName,
    FutureOr<dynamic> Function(T)? disposingFunction,
  }) {
    return tracedGetItCall<void>(
      operation: 'unregister',
      typeName: T.toString(),
      instanceName: instanceName,
      invoke: () async => unregister<T>(
        instance: instance,
        instanceName: instanceName,
        disposingFunction: disposingFunction,
      ),
    );
  }

  /// Traced `reset`. Useful at test teardown or during hot reload
  /// to see when the container was wiped.
  Future<void> tracedReset({bool dispose = true}) {
    return tracedGetItCall<void>(
      operation: 'reset',
      typeName: 'GetIt',
      invoke: () => reset(dispose: dispose),
    );
  }
}
