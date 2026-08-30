import 'package:flutter/material.dart';

import '../../core/formatting.dart';
import '../controllers/converter_controller.dart';

/// Thin strip above the results that communicates data freshness:
/// - offline fallback  -> amber, "you're offline, rates from X ago" (F6.AC1)
/// - API-unavailable fallback -> amber, names a server problem (F6.AC3)
/// - fresh -> a quiet "updated X ago" line, plus a spinner while refreshing
///
/// The amber variants are dismissible (F6.AC1); dismissal resets whenever the
/// underlying reason changes.
class StatusBanner extends StatefulWidget {
  const StatusBanner({
    super.key,
    required this.state,
    required this.onRefresh,
  });

  final ConverterState state;
  final VoidCallback onRefresh;

  @override
  State<StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<StatusBanner> {
  bool _dismissed = false;

  /// A key describing "why is a banner showing" so we can re-show it after a
  /// dismiss once the situation changes.
  String get _reasonKey {
    final ConverterState s = widget.state;
    if (s.isOffline) return 'offline';
    if (s.isStale) return 'stale';
    return 'fresh';
  }
  String _dismissedReason = '';

  @override
  Widget build(BuildContext context) {
    final ConverterState state = widget.state;
    if (state.status != ConverterStatus.ready) return const SizedBox.shrink();

    final String updatedAgo = state.fetchedAt == null
        ? 'the last update'
        : formatRelativeTime(state.fetchedAt!);

    final bool showWarning = state.isOffline || state.isStale;
    if (showWarning && !(_dismissed && _dismissedReason == _reasonKey)) {
      return _WarningBanner(
        icon: state.isOffline ? Icons.cloud_off : Icons.warning_amber_rounded,
        message: state.isOffline
            ? "You're offline — showing rates from $updatedAgo."
            : 'Rates service is unavailable — showing rates from $updatedAgo.',
        onRefresh: widget.onRefresh,
        onDismiss: () => setState(() {
          _dismissed = true;
          _dismissedReason = _reasonKey;
        }),
      );
    }

    // Fresh (or a dismissed warning): quiet status line.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(Icons.check_circle_outline,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text('Rates updated $updatedAgo',
              style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          if (state.isRefreshing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.icon,
    required this.message,
    required this.onRefresh,
    required this.onDismiss,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRefresh;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final Color bg = Theme.of(context).colorScheme.tertiaryContainer;
    final Color fg = Theme.of(context).colorScheme.onTertiaryContainer;
    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: fg, fontSize: 13)),
          ),
          TextButton(onPressed: onRefresh, child: const Text('Refresh')),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close, size: 18, color: fg),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
