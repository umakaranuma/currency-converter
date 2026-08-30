import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/theme/app_spacing.dart';

/// The hero input card: a large, friendly USD amount field with the base
/// currency shown as a fixed pill (features.md F1). Input is restricted to
/// digits and a single decimal point; all parsing happens in the controller.
class AmountInput extends StatelessWidget {
  const AmountInput({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final ({String name, String flag}) usd = kCurrencyInfo[kBaseCurrency]!;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.allXl,
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'AMOUNT TO CONVERT',
                style: theme.textTheme.labelMedium,
              ),
              const Spacer(),
              _CurrencyPill(flag: usd.flag, code: kBaseCurrency),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                r'$',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    _SingleDecimalPointFormatter(),
                  ],
                  style: theme.textTheme.displaySmall,
                  cursorColor: scheme.primary,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: theme.textTheme.displaySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill({required this.flag, required this.code});

  final String flag;
  final String code;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadius.allPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            code,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

/// Rejects a keystroke that would introduce a second decimal point.
class _SingleDecimalPointFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if ('.'.allMatches(newValue.text).length > 1) return oldValue;
    return newValue;
  }
}
