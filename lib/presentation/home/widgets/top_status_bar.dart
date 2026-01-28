import 'package:flutter/material.dart';

class TopStatusBar extends StatelessWidget {
  final String countryName;
  final String currencyCode;
  final DateTime localTime;
  final bool isOffline;
  final bool isMyRate;
  final double? myRateMultiplier;
  final VoidCallback onToggleRate;

  const TopStatusBar({
    super.key,
    required this.countryName,
    required this.currencyCode,
    required this.localTime,
    this.isOffline = false,
    this.isMyRate = false,
    this.myRateMultiplier,
    required this.onToggleRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    '$currencyCode $countryName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '현지 ${localTime.hour}:${localTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          Row(
            children: [
              if (isOffline)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                ),
              InkWell(
                onTap: onToggleRate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isMyRate ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isMyRate ? Colors.blue : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isMyRate ? '내 환율' : '실시간',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMyRate ? Colors.blue[800] : Colors.black,
                        ),
                      ),
                      if (isMyRate && myRateMultiplier != null)
                        Text(
                          ' x${myRateMultiplier!.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 10),
                        ),
                    ],
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
