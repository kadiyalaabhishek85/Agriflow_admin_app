import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../datasources/notification_remote_data_source.dart';

/// A single meaningful Server-Sent Event received from
/// `GET /api/v1/events/stream` (contract verified live against the backend).
class NotificationStreamEvent {
  final String type;
  final Map<String, dynamic>? data;

  const NotificationStreamEvent({required this.type, this.data});
}

/// Incremental SSE frame parser.
///
/// Splits the byte stream on blank-line frame boundaries, extracts `event:`
/// and `data:` fields, ignores comment frames (`: keepalive`) and frames
/// without an event name. Pure and unit-testable — no I/O.
class SseFrameParser {
  String _buffer = '';

  /// Feeds the next chunk of the stream and returns any completed events.
  List<NotificationStreamEvent> feed(String chunk) {
    _buffer += chunk;
    final events = <NotificationStreamEvent>[];

    int idx;
    while ((idx = _buffer.indexOf('\n\n')) >= 0) {
      final rawFrame = _buffer.substring(0, idx);
      _buffer = _buffer.substring(idx + 2);

      String? eventName;
      final dataLines = <String>[];

      for (final line in rawFrame.split('\n')) {
        final trimmed = line.trimRight();
        if (trimmed.startsWith(':')) continue; // comment / keepalive
        if (trimmed.startsWith('event:')) {
          eventName = trimmed.substring('event:'.length).trim();
        } else if (trimmed.startsWith('data:')) {
          dataLines.add(trimmed.substring('data:'.length).trim());
        }
      }

      if (eventName == null || eventName.isEmpty) continue;

      Map<String, dynamic>? data;
      if (dataLines.isNotEmpty) {
        try {
          final decoded = jsonDecode(dataLines.join('\n'));
          if (decoded is Map<String, dynamic>) data = decoded;
        } catch (_) {
          data = {'raw': dataLines.join('\n')};
        }
      }

      events.add(NotificationStreamEvent(type: eventName, data: data));
    }

    return events;
  }
}

/// Maintains a live SSE connection to `GET /api/v1/events/stream`.
///
/// Contract (verified live on 2026-09-28):
/// - Ticket: `POST /api/v1/events/ticket` → `{data: {ticket, expires_in: 30}}`,
///   single-use, auth required.
/// - Stream: `Content-Type: text/event-stream`, `: connected` on open,
///   `: keepalive` comments every ~20s, real frames such as
///   `event: notification.created` / `event: dashboard.changed`.
/// - The stream itself needs no Authorization header — the ticket is it.
///
/// Behaviour: auto-reconnects with capped backoff whenever the connection
/// drops or idles out (no frame — not even keepalive — for [idleTimeout]).
/// [stop] aborts the in-flight connection immediately; [stop]→[start] cycles
/// are safe (epoch-guarded, never runs two loops at once).
class NotificationEventStream {
  final NotificationRemoteDataSource dataSource;
  final String accessToken;

  /// Base URL used as a fallback for the stream endpoint when [dataSource]
  /// is not the FastAPI implementation.
  final String baseUrl;

  final http.Client client;
  final bool _ownsClient;

  /// How long to wait before reconnecting after a clean disconnect.
  final Duration reconnectDelay;

  /// Maximum time without any frame before the connection is considered dead.
  final Duration idleTimeout;

  final StreamController<NotificationStreamEvent> _controller =
      StreamController<NotificationStreamEvent>.broadcast();

  bool _active = false;
  bool _disposed = false;
  int _epoch = 0;
  Timer? _backoffTimer;
  Completer<void>? _backoffCompleter;
  Completer<void>? _stopSignal;
  StreamSubscription? _liveSub;
  Future<void>? _loopFuture;

  NotificationEventStream({
    required this.dataSource,
    required this.accessToken,
    String? baseUrl,
    http.Client? client,
    this.reconnectDelay = const Duration(seconds: 3),
    this.idleTimeout = const Duration(seconds: 60),
  })  : baseUrl = baseUrl ??
            (dataSource is FastApiNotificationRemoteDataSource
                ? dataSource.baseUrl
                : FastApiNotificationRemoteDataSource.defaultBaseUrl),
        client = client ?? http.Client(),
        _ownsClient = client == null;

  /// Broadcast stream of incoming events. Remains open across reconnects
  /// and across [stop]/[start] cycles; closed only by [dispose].
  Stream<NotificationStreamEvent> get events => _controller.stream;

  bool get isActive => _active;

  void start() {
    if (_active || _disposed) return;
    _active = true;
    final epoch = ++_epoch;
    _loopFuture = _runLoop(epoch);
  }

  void stop() {
    _active = false;
    _epoch++;
    _backoffTimer?.cancel();
    _backoffTimer = null;
    // Unblock a loop that is waiting in backoff so stop/dispose never hang.
    final backoff = _backoffCompleter;
    if (backoff != null && !backoff.isCompleted) backoff.complete();
    final signal = _stopSignal;
    if (signal != null && !signal.isCompleted) signal.complete();
    final sub = _liveSub;
    _liveSub = null;
    sub?.cancel();
  }

  Future<void> dispose() async {
    stop();
    _disposed = true;
    await _loopFuture;
    if (_ownsClient) client.close();
    if (!_controller.isClosed) await _controller.close();
  }

  Future<void> _runLoop(int epoch) async {
    var failures = 0;
    while (_active && !_disposed && epoch == _epoch) {
      try {
        await _connectOnce(epoch);
        failures = 0;
      } catch (e) {
        final lower = e.toString().toLowerCase();
        if (lower.contains('session expired') ||
            lower.contains('401') ||
            lower.contains('session_expired')) {
          stop();
          break;
        }
        if (!_active || _disposed || epoch != _epoch) break;
        failures++;
      }
      if (!_active || _disposed || epoch != _epoch) break;

      final delaySeconds = failures == 0
          ? math.max(1, reconnectDelay.inSeconds)
          : math.min(30, 2 * failures);
      final completer = Completer<void>();
      _backoffCompleter = completer;
      _backoffTimer = Timer(Duration(seconds: delaySeconds), () {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
      _backoffTimer = null;
      _backoffCompleter = null;
    }
  }

  Uri _streamUri(String ticket) {
    if (dataSource is FastApiNotificationRemoteDataSource) {
      return (dataSource as FastApiNotificationRemoteDataSource)
          .buildStreamUri(ticket);
    }
    return Uri.parse(
        '$baseUrl/api/v1/events/stream?ticket=${Uri.encodeQueryComponent(ticket)}');
  }

  /// Opens one SSE connection and processes frames until the stream ends,
  /// errors, idles out, or [stop] is called.
  Future<void> _connectOnce(int epoch) async {
    final ticket = await dataSource.getStreamTicket(accessToken: accessToken);
    if (!_active || _disposed || epoch != _epoch) return;
    if (ticket.isEmpty) {
      throw StateError('Empty stream ticket');
    }

    final stopSignal = Completer<void>();
    _stopSignal = stopSignal;

    final request = http.Request('GET', _streamUri(ticket));
    final response =
        await client.send(request).timeout(const Duration(seconds: 15));

    // stop()/dispose() may have run while the connection was opening — bail
    // out before subscribing so a stale loop can never emit events after stop.
    if (!_active || _disposed || epoch != _epoch) return;

    if (response.statusCode != 200) {
      throw http.ClientException(
          'SSE connect failed (HTTP ${response.statusCode})');
    }

    final parser = SseFrameParser();
    final completer = Completer<void>();

    _liveSub = response.stream.timeout(idleTimeout).transform(utf8.decoder).listen(
      (chunk) {
        for (final event in parser.feed(chunk)) {
          if (!_disposed) _controller.add(event);
        }
      },
      onError: (Object e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    try {
      await Future.any<void>([completer.future, stopSignal.future]);
      completer.future.ignore();
    } finally {
      final sub = _liveSub;
      _liveSub = null;
      await sub?.cancel();
      if (identical(_stopSignal, stopSignal)) _stopSignal = null;
    }
  }
}
