// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_box/otel_box.dart';

/// Traces Box calls with OpenTelemetry.
///
/// `otel_box` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Box call in
/// [tracedBox]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'box-example');

  // Wraps a Box API call in a CLIENT span.
  final boxId = await tracedBox<String>(
    resource: 'files',
    action: 'get',
    itemId: 'item_8f3a2c',
    sizeBytes: 512,
    invoke: () async {
      // Make the Box call here, then report what it returned.
      return 'box_8f3a2c';
    },
  );
  OTelLog.info('tracedBox returned $boxId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutBoxInstrumentationAsync.
  await runWithoutBoxInstrumentationAsync(
    () => tracedBox<String>(
      resource: 'files',
      action: 'get',
      itemId: 'item_8f3a2c',
      sizeBytes: 512,
      invoke: () async {
        return 'box_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
