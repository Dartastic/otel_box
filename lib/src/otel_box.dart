// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_box_suppression.dart';

const _tracerName = 'dartastic_otel_libs_box';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps a Box API call in a CLIENT span. [resource] is one of
/// `files`, `folders`, `collaborations`, `users`, `groups`; [action]
/// is `get`, `upload`, `download`, `copy`, `move`, etc.
Future<T> tracedBox<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? itemId,
  int? sizeBytes,
}) async {
  if (boxInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'box.resource': resource,
    'box.action': action,
    'box.operation': '$resource.$action',
  };
  if (itemId != null) m['box.item.id'] = itemId;
  if (sizeBytes != null) m['box.item.size'] = sizeBytes;

  final span = _tracer().startSpan(
    'box $resource.$action',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
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
