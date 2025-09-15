import 'package:flutter/material.dart';

class DoseCalculatorSheet extends StatefulWidget {
  const DoseCalculatorSheet({super.key});

  @override
  State<DoseCalculatorSheet> createState() => _DoseCalculatorSheetState();
}

class _DoseCalculatorSheetState extends State<DoseCalculatorSheet> {
  final _weightCtrl = TextEditingController();
  final _doseCtrl = TextEditingController(text: '5'); // mg/kg
  String _result = '-';

  void _calc() {
    final w = double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 0;
    final d = double.tryParse(_doseCtrl.text.replaceAll(',', '.')) ?? 0;
    final total = w * d;
    setState(
        () => _result = total == 0 ? '-' : '${total.toStringAsFixed(2)} mg');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Cálculo de dosis', style: t.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _doseCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dosis (mg/kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Resultado: $_result', style: t.titleMedium),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(onPressed: _calc, child: const Text('Calcular')),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  _weightCtrl.clear();
                  _doseCtrl.text = '5';
                  setState(() => _result = '-');
                },
                child: const Text('Limpiar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
