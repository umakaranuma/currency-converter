import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../controllers/converter_controller.dart';
import '../widgets/amount_input.dart';
import '../widgets/conversion_row.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/status_banner.dart';

/// The single screen. A gradient header sits behind a floating amount card;
/// below it the body swaps between skeleton / error / results driven purely by
/// [ConverterController] via [ListenableBuilder].
class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key, required this.controller});

  final ConverterController controller;

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppColors colors = context.appColors;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Layer 1: gradient wash at the top, plain surface beneath.
          Column(
            children: <Widget>[
              Container(
                height: 210,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[colors.gradientStart, colors.gradientEnd],
                  ),
                ),
              ),
              Expanded(child: ColoredBox(color: scheme.surfaceContainerLow)),
            ],
          ),

          // Layer 2: content.
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _HeaderBar(onRefresh: widget.controller.refresh),
                Padding(
                  padding: AppSpacing.screen,
                  child: AmountInput(
                    controller: _amountController,
                    onChanged: widget.controller.updateAmount,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListenableBuilder(
                    listenable: widget.controller,
                    builder: (BuildContext context, _) {
                      final ConverterState state = widget.controller.state;
                      return switch (state.status) {
                        ConverterStatus.loading => const _SkeletonBody(),
                        ConverterStatus.error => _ErrorBody(
                            error: state.error!,
                            onRetry: widget.controller.retry,
                          ),
                        ConverterStatus.ready => _ResultsBody(
                            state: state,
                            onRefresh: widget.controller.refresh,
                          ),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Title + subtitle on the gradient, with a refresh action.
class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.appColors;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Currency Converter',
                  style: text.titleLarge?.copyWith(color: colors.onGradient),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live USD exchange rates',
                  style: text.bodySmall?.copyWith(
                    color: colors.onGradient.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: Icon(Icons.refresh_rounded, color: colors.onGradient),
            tooltip: 'Refresh rates',
          ),
        ],
      ),
    );
  }
}

/// Small caps label above a section.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

/// Results list. Pull-to-refresh and the header button share one code path.
class _ResultsBody extends StatelessWidget {
  const _ResultsBody({required this.state, required this.onRefresh});

  final ConverterState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final Map<String, double> rates = state.rates ?? const <String, double>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StatusBanner(state: state, onRefresh: onRefresh),
        const _SectionLabel("YOU'LL RECEIVE"),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              itemCount: kTargetCurrencies.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int index) {
                final String code = kTargetCurrencies[index];
                return ConversionRow(
                  code: code,
                  rate: rates[code] ?? 0,
                  convertedAmount: state.conversions[code] ?? 0,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Placeholder rows shown during the very first load (features.md F5.AC1).
class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SectionLabel("YOU'LL RECEIVE"),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            itemCount: kTargetCurrencies.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (BuildContext context, _) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: AppRadius.allLg,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: const <Widget>[
                    ShimmerBox(width: 44, height: 44, radius: 12),
                    SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ShimmerBox(width: 46, height: 14),
                        SizedBox(height: 8),
                        ShimmerBox(width: 90, height: 11),
                      ],
                    ),
                    Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        ShimmerBox(width: 80, height: 16),
                        SizedBox(height: 8),
                        ShimmerBox(width: 64, height: 11),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Full-screen failure, only when there is nothing cached to fall back on
/// (features.md F6.AC2/AC4). Icon + copy differ by error type (rules.md R5.5).
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});

  final AppException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    final (IconData icon, String headline, String detail) = switch (error) {
      NetworkException() => (
          Icons.wifi_off_rounded,
          'You appear to be offline',
          'There are no saved rates yet, so nothing can be shown. '
              'Reconnect and try again.',
        ),
      ApiException() => (
          Icons.cloud_off_rounded,
          'Rates are unavailable',
          'The exchange-rate service is having problems right now. '
              'Please try again in a moment.',
        ),
      CacheMissException() => (
          Icons.error_outline_rounded,
          'Could not load rates',
          'The saved copy was unreadable and refreshing failed. '
              'Please try again.',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: scheme.onErrorContainer),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(headline, style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
