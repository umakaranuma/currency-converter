import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../controllers/converter_controller.dart';
import '../widgets/amount_input.dart';
import '../widgets/conversion_row.dart';
import '../widgets/status_banner.dart';

/// The single screen. Owns only widget-local concerns (the text field); all
/// app state comes from [ConverterController] via [ListenableBuilder].
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
    // Kick off the first (cache-first) load.
    widget.controller.load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USD Currency Converter'),
        actions: <Widget>[
          IconButton(
            onPressed: widget.controller.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh rates',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (BuildContext context, _) {
          final ConverterState state = widget.controller.state;
          return switch (state.status) {
            ConverterStatus.loading => const _LoadingView(),
            ConverterStatus.error => _ErrorView(
                error: state.error!,
                onRetry: widget.controller.retry,
              ),
            ConverterStatus.ready => _ReadyView(
                state: state,
                amountController: _amountController,
                onAmountChanged: widget.controller.updateAmount,
                onRefresh: widget.controller.refresh,
              ),
          };
        },
      ),
    );
  }
}

/// First-load spinner — only shown when there is nothing cached to display yet
/// (features.md F5.AC1).
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Fetching exchange rates…'),
        ],
      ),
    );
  }
}

/// Full-screen error, shown only when we have no rates at all to fall back on
/// (features.md F6.AC2/AC4). Copy differs by error type (rules.md R5.5).
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final AppException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String headline) = switch (error) {
      NetworkException() => (
          Icons.wifi_off,
          'No internet connection and no saved rates yet.',
        ),
      ApiException() => (
          Icons.cloud_off,
          'The rates service is having problems. Please try again.',
        ),
      CacheMissException() => (
          Icons.error_outline,
          'Could not load rates and there is no saved copy. Please try again.',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The working screen: input, freshness banner, and the five conversion rows.
class _ReadyView extends StatelessWidget {
  const _ReadyView({
    required this.state,
    required this.amountController,
    required this.onAmountChanged,
    required this.onRefresh,
  });

  final ConverterState state;
  final TextEditingController amountController;
  final ValueChanged<String> onAmountChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final Map<String, double> rates = state.rates ?? const <String, double>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: AmountInput(
            controller: amountController,
            onChanged: onAmountChanged,
          ),
        ),
        StatusBanner(state: state, onRefresh: onRefresh),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: kTargetCurrencies.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
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
