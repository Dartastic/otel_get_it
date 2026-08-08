// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:get_it/get_it.dart';
import 'package:otel_get_it/otel_get_it.dart';
import 'package:test/test.dart';

class _Service {
  _Service(this.name);
  final String name;
}

class _OtherService {
  _OtherService(this.id);
  final int id;
}

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;
  late GetIt getIt;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_get_it-test',
    );
    spans = harness.spans;
  });

  setUp(() async {
    harness.clear();
    getIt = GetIt.asNewInstance();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('tracedRegisterSingletonAsync', () {
    test('emits a span named "get_it register_async <T>"', () async {
      getIt.tracedRegisterSingletonAsync<_Service>(() async => _Service('A'));
      await getIt.allReady();

      final span = spans.findSpanByName('get_it register_async _Service');
      expect(span, isNotNull);
      final attrs = {
        for (final a in span!.attributes.toList()) a.key: a.value,
      };
      expect(attrs['di.system'], 'get_it');
      expect(attrs['di.operation'], 'register_async');
      expect(attrs['di.type'], '_Service');
    });

    test('passes instanceName through to attributes', () async {
      getIt.tracedRegisterSingletonAsync<_Service>(
        () async => _Service('A'),
        instanceName: 'primary',
      );
      await getIt.allReady();

      final span = spans.findSpanByName('get_it register_async _Service');
      expect(span, isNotNull);
      final attrs = {
        for (final a in span!.attributes.toList()) a.key: a.value,
      };
      expect(attrs['di.instance_name'], 'primary');
    });

    test('factory exception → span.status=Error + error.type', () async {
      getIt.tracedRegisterSingletonAsync<_Service>(
        () async => throw StateError('boom'),
      );
      try {
        await getIt.allReady();
      } catch (_) {
        // expected
      }
      final span = spans.findSpanByName('get_it register_async _Service');
      expect(span, isNotNull);
      expect(span!.status, SpanStatusCode.Error);
      final attrs = {
        for (final a in span.attributes.toList()) a.key: a.value,
      };
      expect(attrs['error.type'], 'StateError');
    });
  });

  group('tracedAllReady', () {
    test('emits a "get_it all_ready GetIt" span', () async {
      getIt.registerSingletonAsync<_Service>(() async => _Service('X'));
      await getIt.tracedAllReady();

      final span = spans.findSpanByName('get_it all_ready GetIt');
      expect(span, isNotNull);
      final attrs = {
        for (final a in span!.attributes.toList()) a.key: a.value,
      };
      expect(attrs['di.operation'], 'all_ready');
      expect(attrs['di.type'], 'GetIt');
    });
  });

  group('tracedGetAsync', () {
    test('emits a "get_it get_async <T>" span', () async {
      getIt.registerSingletonAsync<_Service>(() async => _Service('Y'));
      await getIt.allReady();
      harness.clear();

      final s = await getIt.tracedGetAsync<_Service>();
      expect(s.name, 'Y');

      final span = spans.findSpanByName('get_it get_async _Service');
      expect(span, isNotNull);
      final attrs = {
        for (final a in span!.attributes.toList()) a.key: a.value,
      };
      expect(attrs['di.operation'], 'get_async');
      expect(attrs['di.type'], '_Service');
    });
  });

  group('tracedUnregister', () {
    test('emits a "get_it unregister <T>" span', () async {
      getIt.registerSingleton<_Service>(_Service('Z'));
      await getIt.tracedUnregister<_Service>();

      final span = spans.findSpanByName('get_it unregister _Service');
      expect(span, isNotNull);
      expect(
        {
          for (final a in span!.attributes.toList()) a.key: a.value
        }['di.operation'],
        'unregister',
      );
    });
  });

  group('tracedReset', () {
    test('emits a "get_it reset GetIt" span', () async {
      getIt.registerSingleton<_Service>(_Service('q'));
      await getIt.tracedReset();

      final span = spans.findSpanByName('get_it reset GetIt');
      expect(span, isNotNull);
      expect(
        {
          for (final a in span!.attributes.toList()) a.key: a.value
        }['di.operation'],
        'reset',
      );
    });
  });

  group('suppression', () {
    test('runWithoutGetItInstrumentationAsync skips spans', () async {
      await runWithoutGetItInstrumentationAsync(() async {
        await getIt.tracedReset();
      });
      expect(spans.findSpansStartingWith('get_it'), isEmpty);
    });

    test('runWithoutGetItInstrumentation skips registerSingletonAsync',
        () async {
      runWithoutGetItInstrumentation(() {
        getIt.tracedRegisterSingletonAsync<_Service>(
          () async => _Service('A'),
        );
      });
      await getIt.allReady();
      expect(
        spans.findSpansStartingWith('get_it register_async'),
        isEmpty,
      );
    });
  });

  group('multiple registrations', () {
    test('each typed registration gets its own span', () async {
      getIt.tracedRegisterSingletonAsync<_Service>(() async => _Service('A'));
      getIt.tracedRegisterSingletonAsync<_OtherService>(
        () async => _OtherService(1),
      );
      await getIt.allReady();

      expect(
        spans.findSpansStartingWith('get_it register_async _Service'),
        hasLength(1),
      );
      expect(
        spans.findSpansStartingWith('get_it register_async _OtherService'),
        hasLength(1),
      );
    });
  });
}
