import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/formatting.dart';
import '../../core/theme/app_spacing.dart';

/// One result card: flag + currency, the converted amount as the focal point,
/// and the rate used underneath so the number is never unexplained
/// (features.md F2.AC2). Tapping copies the amount — a small convenience, no
/// business logic.
class ConversionRow extends StatelessWidget {
  const ConversionRow({
    super.key,
    required this.code,
    required this.rate,
    required this.convertedAmount,
  });

  final String code;
  final double rate;
  final double convertedAmount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final ({String name, String flag}) info =
        kCurrencyInfo[code] ?? (name: code, flag: '\u{1F3F3}');
    final String amountText = formatMoney(convertedAmount, code);

    return Material(
      color: scheme.surface,
      borderRadius: AppRadius.allLg,
      child: InkWell(
        borderRadius: AppRadius.allLg,
        onTap: () {
          Clipboard.setData(ClipboardData(text: amountText));
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('Copied $amountText $code')),
            );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.allLg,
            border: Border.all(color: scheme.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: AppRadius.allMd,
                ),
                child: Text(info.flag, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(code, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(info.name, style: theme.textTheme.bodySmall),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    amountText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '1 $kBaseCurrency = ${formatRate(rate)} $code',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
