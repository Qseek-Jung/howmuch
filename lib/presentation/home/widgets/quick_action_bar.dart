import 'package:flutter/material.dart';

class QuickActionBar extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onVoice;
  final VoidCallback onDutchPay;

  const QuickActionBar({
    super.key,
    required this.onCamera,
    required this.onVoice,
    required this.onDutchPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.camera_alt_outlined, "스캔", onCamera),
          _buildActionButton(Icons.mic_none_outlined, "음성", onVoice),
          _buildActionButton(Icons.people_outline, "팁·n빵", onDutchPay),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(icon, color: Colors.black87, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
