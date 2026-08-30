import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme/app_spacing.dart';
import '../controllers/converter_controller.dart';

/// Add or remove target currencies. Selection changes are pushed straight into
/// [ConverterController] (which persists them); this screen holds only the
/// search query as local state.
class CurrencyPickerPage extends StatefulWidget {
  const CurrencyPickerPage({super.key, required this.controller});

  final ConverterController controller;

  @override
  State<CurrencyPickerPage> createState() => _CurrencyPickerPageState();
}

class _CurrencyPickerPageState extends State<CurrencyPickerPage> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) =>
      setState(() => _query = value.trim().toLowerCase());

  void _clearQuery() {
    _search.clear();
    _onQueryChanged('');
  }

  bool _matches(String code) {
    if (_query.isEmpty) return true;
    final ({String name, String flag}) info = kCurrencyInfo[code]!;
    return code.toLowerCase().contains(_query) ||
        info.name.toLowerCase().contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> results =
        kSupportedCurrencies.where(_matches).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currencies'),
        actions: <Widget>[
          TextButton(
            onPressed: widget.controller.resetCurrencies,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: TextField(
              controller: _search,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search name or code',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _clearQuery,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Clear search',
                      ),
              ),
            ),
          ),
          const _BaseRow(),
          const Divider(height: 1),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (BuildContext context, _) {
                final List<String> selected =
                    widget.controller.state.selected;
                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      'No currency matches "$_query"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  itemCount: results.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String code = results[index];
                    final ({String name, String flag}) info =
                        kCurrencyInfo[code]!;
                    final bool isOn = selected.contains(code);
                    final bool isLast = isOn && selected.length == 1;
                    return SwitchListTile.adaptive(
                      value: isOn,
                      onChanged: (bool want) => want
                          ? widget.controller.addCurrency(code)
                          : widget.controller.removeCurrency(code),
                      secondary: Text(info.flag,
                          style: const TextStyle(fontSize: 22)),
                      title: Text(code,
                          style: theme.textTheme.titleMedium),
                      subtitle: Text(
                        isLast ? '${info.name} · keep at least one' : info.name,
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The base currency is always shown and cannot be toggled.
class _BaseRow extends StatelessWidget {
  const _BaseRow();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ({String name, String flag}) info = kCurrencyInfo[kBaseCurrency]!;
    return ListTile(
      leading: Text(info.flag, style: const TextStyle(fontSize: 22)),
      title: Text(kBaseCurrency, style: theme.textTheme.titleMedium),
      subtitle: Text(info.name, style: theme.textTheme.bodySmall),
      trailing: Chip(
        label: const Text('Base'),
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
    );
  }
}
