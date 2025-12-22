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
    'abh***@yahoo.com',
    'adi***@outlook.com',
    'aka***@gmail.com',
    'aks***@gmail.com',
    'ama***@gmail.com',
    'ank***@gmail.com',
    'anu***@gmail.com',
    'apa***@gmail.com',
    'ash***@gmail.com',
    'avi***@gmail.com',
    'ayush***@gmail.com',
    'bha***@gmail.com',
    'cha***@gmail.com',
    'dak***@gmail.com',
    'dev***@gmail.com',
    'dhi***@gmail.com',
    'ees***@gmail.com',
    'gau***@gmail.com',
    'har***@gmail.com',
    'him***@gmail.com',
    'ish***@gmail.com',
    'jai***@gmail.com',
    'jiv***@gmail.com',
    'kab***@gmail.com',
    'kan***@gmail.com',
    'kar***@gmail.com',
    'kus***@gmail.com',
    'lak***@gmail.com',
    'mad***@gmail.com',
    'may***@gmail.com',
    'nak***@gmail.com',
    'nav***@gmail.com',
    'nee***@gmail.com',
    'nih***@gmail.com',
    'nit***@gmail.com',
    'omk***@gmail.com',
    'par***@gmail.com',
    'pra***@gmail.com',
    'rag***@gmail.com',
    'ran***@gmail.com',
    'rit***@gmail.com',
    'sac***@gmail.com',
    'sah***@gmail.com',
    'sam***@gmail.com',
    'sar***@gmail.com',
    'shi***@gmail.com',
    'shr***@gmail.com',
    'sid***@gmail.com',
    'tar***@gmail.com',
    'uday***@gmail.com',
    'ujj***@gmail.com',
    'utk***@gmail.com',
    'var***@gmail.com',
    'ved***@gmail.com',
    'vin***@gmail.com',
    'yas***@gmail.com',
    'yuv***@gmail.com',
    'aar***@gmail.com',
    'adh***@gmail.com',
    'adv***@gmail.com',
    'ish***@gmail.com',
    'jia***@gmail.com',
    'kia***@gmail.com',
    'myr***@gmail.com',
    'nav***@gmail.com',
    'par***@gmail.com',
    'rad***@gmail.com',
    'ria***@gmail.com',
    'saa***@gmail.com',
    'tan***@gmail.com',
    'vanya***@gmail.com',
    'zoy***@gmail.com',
    'nit***@gmail.com',
    'pre***@gmail.com',
    'mon***@gmail.com',
    'son***@gmail.com',
    'kee***@gmail.com',
    'dee***@gmail.com',
    'lee***@gmail.com',
    'ree***@gmail.com',
  ];

  final List<double> _mockAmounts = [
    100.0,
    200.0,
    150.0,
    100.0,
    300.0,
    500.0,
    100.0,
    250.0,
  ];

  /// Get a single payout every few seconds for the ticker
  Stream<PayoutModel> getPayoutRotation() async* {
    while (true) {
      // 1. Fetch real payouts
      List<PayoutModel> pool = [];
      try {
        final realSnapshot = await _firestore
            .collection('withdrawals')
            .where('status', isEqualTo: 'completed')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();

        for (var doc in realSnapshot.docs) {
          final data = doc.data();
          final email = data['email'] as String?;
          final userId = data['userId'] as String;

          String displayId;
          if (email != null && email.contains('@')) {
            final parts = email.split('@');
            final name = parts[0];
            displayId =
                '${name.substring(0, min(2, name.length))}***@${parts[1]}';
          } else {
            displayId = 'User-${userId.substring(0, 4).toUpperCase()}***';
          }

          pool.add(
            PayoutModel(
              userName: displayId,
              amount: (data['amount'] as num).toDouble() / 1000.0,
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              isReal: true,
            ),
          );
        }
      } catch (e) {
        print('Error fetching real payouts: $e');
      }

      // 2. Add some mock payouts to the pool (total 50 in pool)
      final now = DateTime.now();
      while (pool.length < 50) {
        pool.add(
          PayoutModel(
            userName:
                _mockIdentifiers[_random.nextInt(_mockIdentifiers.length)],
            amount: _mockAmounts[_random.nextInt(_mockAmounts.length)],
            timestamp: now.subtract(
              Duration(minutes: _random.nextInt(1440)),
            ), // Last 24h
            isReal: false,
          ),
        );
      }

      // 3. Shuffle mock part but keep real ones scattered/front
      pool.shuffle();

      // 4. Yield them one by one
      for (var payout in pool) {
        yield payout;
        await Future.delayed(const Duration(seconds: 8)); // Gradual display
      }

      // After yielding entire pool, loop starts again with fresh real data
    }
  }

  /// Original stream for compatibility if needed
  Stream<List<PayoutModel>> getPayoutTicker() {
    return _firestore
        .collection('withdrawals')
        .where('status', isEqualTo: 'completed')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            return PayoutModel(
              userName: 'User***',
              amount: (data['amount'] as num).toDouble() / 1000.0,
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              isReal: true,
            );
          }).toList();

          // Add some mocks
          for (int i = 0; i < 10; i++) {
            list.add(
              PayoutModel(
                userName:
                    _mockIdentifiers[_random.nextInt(_mockIdentifiers.length)],
                amount: 100.0,
                timestamp: DateTime.now(),
              ),
            );
          }
          return list;
        });
  }
}
