import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';

/// The USD amount field. Restricts input to digits and a single decimal point;
/// all parsing/validation of the resulting string happens in the controller
/// (features.md F1).
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              _SingleDecimalPointFormatter(),
            ],
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: r'$ ',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Fixed, non-editable base-currency label (F1.AC4).
        Text(
          kBaseCurrency,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
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
