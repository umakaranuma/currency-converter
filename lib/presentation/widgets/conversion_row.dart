import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/formatting.dart';

/// One currency line: converted amount on top, the rate used underneath so the
/// number is never unexplained (features.md F2.AC2).
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
    return ListTile(
      leading: CircleAvatar(child: Text(code)),
      title: Text(
        '${formatMoney(convertedAmount, code)} $code',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      subtitle: Text('1 $kBaseCurrency = ${formatRate(rate)} $code'),
    );
  }
}
