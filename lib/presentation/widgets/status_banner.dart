import 'package:flutter/material.dart';

import '../../core/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../controllers/converter_controller.dart';

/// Communicates data freshness above the results:
/// - offline / API-down fallback -> a dismissible warning card (F6.AC1/AC3)
/// - fresh -> a quiet "updated x ago" pill, with a spinner while refreshing
///
/// A dismissed warning re-appears if the underlying reason changes.
class StatusBanner extends StatefulWidget {
  const StatusBanner({
    super.key,
    required this.state,
    required this.onRefresh,
  });

  final ConverterState state;
  final Future<void> Function() onRefresh;

  @override
  State<StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<StatusBanner> {
  String? _dismissedReason;

  String get _reason {
    if (widget.state.isOffline) return 'offline';
    if (widget.state.isStale) return 'stale';
    return 'fresh';
  }

  @override
  Widget build(BuildContext context) {
    final ConverterState state = widget.state;
    if (state.status != ConverterStatus.ready) return const SizedBox.shrink();

    final String updatedAgo = state.fetchedAt == null
        ? 'the last update'
        : formatRelativeTime(state.fetchedAt!);
    final bool warning = state.isOffline || state.isStale;

    if (warning && _dismissedReason != _reason) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          0,
        ),
        child: _WarningCard(
          offline: state.isOffline,
          message: state.isOffline
              ? "You're offline — showing rates from $updatedAgo."
              : 'Rates service is unavailable — showing rates from $updatedAgo.',
          onRefresh: widget.onRefresh,
          onDismiss: () => setState(() => _dismissedReason = _reason),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: _FreshPill(updatedAgo: updatedAgo, refreshing: state.isRefreshing),
    );
  }
}

class _FreshPill extends StatelessWidget {
  const _FreshPill({required this.updatedAgo, required this.refreshing});

  final String updatedAgo;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.appColors;
    final ThemeData theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.successContainer,
          borderRadius: AppRadius.allPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (refreshing)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onSuccessContainer,
                ),
              )
            else
              Icon(Icons.check_circle_rounded,
                  size: 14, color: colors.onSuccessContainer),
            const SizedBox(width: AppSpacing.sm),
            Text(
              refreshing ? 'Updating rates…' : 'Rates updated $updatedAgo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSuccessContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({
    required this.offline,
    required this.message,
    required this.onRefresh,
    required this.onDismiss,
  });

  final bool offline;
  final String message;
  final Future<void> Function() onRefresh;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.appColors;
    final ThemeData theme = Theme.of(context);
    final Color bg = colors.warningContainer;
    final Color fg = colors.onWarningContainer;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.allLg),
      child: Row(
        children: <Widget>[
          Icon(
            offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
            size: 20,
            color: fg,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: fg),
            ),
          ),
          TextButton(
            onPressed: onRefresh,
            style: TextButton.styleFrom(
              foregroundColor: fg,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Retry'),
          ),
          IconButton(
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 18, color: fg),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
