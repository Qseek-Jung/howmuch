import 'package:flutter/material.dart';
import '../../../data/models/currency_model.dart';
import 'package:intl/intl.dart';

class ConvertCard extends StatefulWidget {
  final Currency currency;
  final double exchangeRate;
  final Function(double) onAmountChanged; // Returns amount in LOCAL currency
  final VoidCallback onAddToExpense;

  const ConvertCard({
    super.key,
    required this.currency,
    required this.exchangeRate,
    required this.onAmountChanged,
    required this.onAddToExpense,
  });

  @override
  State<ConvertCard> createState() => _ConvertCardState();
}

class _ConvertCardState extends State<ConvertCard> {
  String _inputAmount = "0";

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_inputAmount.length > 1) {
          _inputAmount = _inputAmount.substring(0, _inputAmount.length - 1);
        } else {
          _inputAmount = "0";
        }
      } else if (key == 'clear') {
        _inputAmount = "0";
      } else {
        if (_inputAmount == "0") {
          _inputAmount = key;
        } else if (_inputAmount.length < 9) {
          // Limit length
          _inputAmount += key;
        }
      }
      widget.onAmountChanged(double.tryParse(_inputAmount) ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    double amount = double.tryParse(_inputAmount) ?? 0;
    double krwAmount = amount * widget.exchangeRate;
    final currencyFormat = NumberFormat("#,##0", "en_US");

    return Column(
      children: [
        // Display Area
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Local Amount Input
              Text(
                '${widget.currency.code} (현지)',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                currencyFormat.format(amount),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.right,
              ),
              const Divider(height: 32),
              // KRW Output
              Text(
                'KRW (원화)',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '₩ ${currencyFormat.format(krwAmount.round())}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 8),
              Text(
                '적용 환율: ${widget.exchangeRate.toStringAsFixed(2)} KRW',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),

        // Keypad Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildKeypadRow(['7', '8', '9']),
              _buildKeypadRow(['4', '5', '6']),
              _buildKeypadRow(['1', '2', '3']),
              _buildKeypadRow(['C', '0', '⌫']),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: widget.onAddToExpense,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    "가계부에 등록",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) => _buildKey(key)).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: InkWell(
          onTap: () => _onKeyPress(
            key == '⌫' ? 'backspace' : (key == 'C' ? 'clear' : key),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: key == '⌫'
                ? const Icon(Icons.backspace_outlined, color: Colors.black54)
                : Text(
                    key,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
