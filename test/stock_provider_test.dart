import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:digital_life_care_app/providers/stock_provider.dart';

void main() {
  test('cancelOrder marks a pending order as cancelled when called by student', () async {
    final fakeFs = FakeFirebaseFirestore();
    final provider = StockProvider(firestore: fakeFs);

    // prepare a pending order
    final orderRef = await fakeFs.collection('orders').add({
      'studentId': 'student1',
      'status': 'pending',
      'items': [
        {'medicineId': 'm1', 'name': 'Med A', 'qty': 1}
      ],
      'createdAt': DateTime.now(),
    });

    // call cancel
    await provider.cancelOrder(orderRef.id, 'student1');

    final updated = await fakeFs.collection('orders').doc(orderRef.id).get();
    expect(updated.exists, true);
    expect(updated.data()?['status'], 'cancelled');
  });
}
