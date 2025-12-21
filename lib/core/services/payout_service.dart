import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutModel {
  final String userName;
  final double amount;
  final DateTime timestamp;
  final bool isReal;

  PayoutModel({
    required this.userName,
    required this.amount,
    required this.timestamp,
    this.isReal = false,
  });
}

class PayoutService {
  static final PayoutService _instance = PayoutService._internal();
  factory PayoutService() => _instance;
  PayoutService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  final List<String> _mockIdentifiers = [
    'san***@gmail.com',
    'anj***@gmail.com',
    'rah***@gmail.com',
    'pri***@gmail.com',
    'vik***@gmail.com',
    'sne***@gmail.com',
    'ami***@gmail.com',
    'dee***@gmail.com',
    'roh***@gmail.com',
    'kav***@gmail.com',
    'raj***@gmail.com',
    'mee***@gmail.com',
    'sur***@gmail.com',
    'poo***@gmail.com',
    'arj***@gmail.com',
    'sun***@gmail.com',
    'vij***@gmail.com',
    'div***@gmail.com',
    'man***@gmail.com',
    'swa***@gmail.com',
  ];

  final List<double> _mockAmounts = [100.0, 200.0, 150.0, 100.0, 300.0, 500.0];

  /// Get a stream of recent payouts (Real + Mock)
  Stream<List<PayoutModel>> getPayoutTicker() {
    // Real payouts stream
    final realPayoutsStream = _firestore
        .collection('withdrawals')
        .where('status', isEqualTo: 'completed')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();

    return realPayoutsStream.map((snapshot) {
      final List<PayoutModel> payouts = [];

      // 1. Add real payouts
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String;
        final email = data['email'] as String?;

        String displayId;
        if (email != null && email.contains('@')) {
          final parts = email.split('@');
          final name = parts[0];
          displayId =
              '${name.substring(0, min(3, name.length))}***@${parts[1]}';
        } else {
          displayId = 'User-${userId.substring(0, 4).toUpperCase()}***';
        }

        payouts.add(
          PayoutModel(
            userName: displayId,
            amount: (data['amount'] as num).toDouble() / 1000.0, // AC to INR
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            isReal: true,
          ),
        );
      }

      // 2. Add high-quality mock payouts to fill space and look trustworthy
      // We generate mock payouts that look like they happened recently
      final now = DateTime.now();
      for (int i = 0; i < 15; i++) {
        final mockId =
            _mockIdentifiers[_random.nextInt(_mockIdentifiers.length)];
        final mockAmount = _mockAmounts[_random.nextInt(_mockAmounts.length)];
        final mockTime = now.subtract(
          Duration(
            minutes: _random.nextInt(60 * 24), // Last 24 hours
          ),
        );

        payouts.add(
          PayoutModel(
            userName: mockId,
            amount: mockAmount,
            timestamp: mockTime,
            isReal: false,
          ),
        );
      }

      // 3. Sort by time
      payouts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return payouts;
    });
  }
}
