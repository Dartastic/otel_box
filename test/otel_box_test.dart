// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_box/otel_box.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_box-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('files.upload records CLIENT span', () async {
    await tracedBox<String>(
      resource: 'files',
      action: 'upload',
      itemId: 'f-1',
      sizeBytes: 102400,
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('box files.upload')!);
    expect(a['box.resource'], 'files');
    expect(a['box.action'], 'upload');
    expect(a['box.item.id'], 'f-1');
    expect(a['box.item.size'], 102400);
  });

  test('suppression skips spans', () async {
    await runWithoutBoxInstrumentationAsync(() async {
      await tracedBox<String>(
        resource: 'r',
        action: 'a',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('box '), isEmpty);
  });
}
