import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

const _agentDebugSessionId = 'b1883a';
const _agentDebugLogPath = 'debug-b1883a.log';
const _agentDebugEndpoint =
    'http://127.0.0.1:7679/ingest/555f9914-bbf7-410c-a0da-e3a57b261bed';

Future<void> agentDebugLog({
  required String runId,
  required String hypothesisId,
  required String location,
  required String message,
  required Map<String, Object?> data,
}) async {
  final payload = <String, Object?>{
    'sessionId': _agentDebugSessionId,
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final line = jsonEncode(payload);
  debugPrint('[agent-debug] $line');

  try {
    await File(_agentDebugLogPath).writeAsString(
      '$line\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (_) {
    // Keep runtime behavior unchanged if file logging is unavailable.
  }

  try {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse(_agentDebugEndpoint));
    request.headers.contentType = ContentType.json;
    request.headers.set('X-Debug-Session-Id', _agentDebugSessionId);
    request.write(line);
    await request.close();
    client.close();
  } catch (_) {
    // Keep runtime behavior unchanged if HTTP logging is unavailable.
  }
}

String agentDebugId(String value) {
  if (value.isEmpty) return 'empty';
  return '${value.length}:${value.hashCode}';
}
