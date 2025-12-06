import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockCategory {
  final String id;
  final String name;

  StockCategory({required this.id, required this.name});

  factory StockCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockCategory(id: doc.id, name: data['name'] ?? '');
  }
}

class Medicine {
  final String id;
  final String categoryId;
  final String name;
  final String form;
  final String unit;
  final num quantity;
  final num pricePerUnit;
  final bool isFree;
  final num lowStockThreshold;

  Medicine({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.form,
    required this.unit,
    required this.quantity,
    required this.pricePerUnit,
    required this.isFree,
    required this.lowStockThreshold,
  });

  factory Medicine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Medicine(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      name: data['name'] ?? '',
      form: data['form'] ?? '',
      unit: data['unit'] ?? '',
      quantity: data['quantity'] ?? 0,
      pricePerUnit: data['pricePerUnit'] ?? 0,
      isFree: data['isFree'] ?? false,
      lowStockThreshold: data['lowStockThreshold'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'categoryId': categoryId,
        'name': name,
        'form': form,
        'unit': unit,
        'quantity': quantity,
        'pricePerUnit': pricePerUnit,
        'isFree': isFree,
        'lowStockThreshold': lowStockThreshold,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class OrderItem {
  final String medicineId;
  final String name;
  final num qty;

  OrderItem({required this.medicineId, required this.name, required this.qty});

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        medicineId: m['medicineId'] ?? '',
        name: m['name'] ?? '',
        qty: m['qty'] ?? 0,
      );
}

class StockOrder {
  final String id;
  final String studentId;
  final String status;
  final List<OrderItem> items;

  StockOrder({required this.id, required this.studentId, required this.status, required this.items});

  factory StockOrder.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final items = <OrderItem>[];
    if (d['items'] is List) {
      for (var it in d['items']) {
        if (it is Map<String, dynamic>) items.add(OrderItem.fromMap(it));
      }
    }
    return StockOrder(id: doc.id, studentId: d['studentId'] ?? '', status: d['status'] ?? 'pending', items: items);
  }
}

class StockProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  StockProvider({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Categories
  Stream<List<StockCategory>> streamCategories() {
    return _firestore.collection('stock_categories').orderBy('name').snapshots().map((s) => s.docs.map((d) => StockCategory.fromFirestore(d)).toList());
  }

  Future<DocumentReference> addCategory(String name) async {
    return await _firestore.collection('stock_categories').add({'name': name, 'createdAt': FieldValue.serverTimestamp()});
  }

  // Medicines
  Stream<List<Medicine>> streamMedicines(String categoryId) {
    return _firestore
        .collection('medicines')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => Medicine.fromFirestore(d)).toList());
  }

  Future<void> addMedicine(Medicine m) async {
    await _firestore.collection('medicines').add(m.toFirestore());
  }

  Future<void> updateMedicine(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('medicines').doc(id).update(updates);
  }

  Future<void> deleteMedicine(String id) async {
    await _firestore.collection('medicines').doc(id).delete();
  }

  // Orders
  Stream<List<StockOrder>> streamPendingOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => StockOrder.fromFirestore(d)).toList());
  }

  /// Stream orders that have any of the provided statuses (e.g., ['pending','accepted']).
  Stream<List<StockOrder>> streamOrdersByStatuses(List<String> statuses) {
    if (statuses.isEmpty) return const Stream.empty();
    return _firestore
        .collection('orders')
        .where('status', whereIn: statuses)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => StockOrder.fromFirestore(d)).toList());
  }

  /// Accepts an order.
  ///
  /// If [decrementNow] is true the method will check stock and decrement
  /// quantities inside a transaction and mark the order as `dispatched`.
  /// If false, the order will be marked `accepted` and stock will not be
  /// changed now (stock should be decremented later on dispatch).
  Future<void> acceptOrder(String orderId, String hwId, {bool decrementNow = true}) async {
    final orderRef = _firestore.collection('orders').doc(orderId);

    if (decrementNow) {
      // Perform transactional decrement and mark dispatched
      await _firestore.runTransaction((tx) async {
        final orderSnap = await tx.get(orderRef);
        if (!orderSnap.exists) throw Exception('Order not found');
        final order = StockOrder.fromFirestore(orderSnap);

        // Check stock for each item
        for (var item in order.items) {
          final medRef = _firestore.collection('medicines').doc(item.medicineId);
          final medSnap = await tx.get(medRef);
          if (!medSnap.exists) throw Exception('Medicine ${item.name} not found');
          final med = Medicine.fromFirestore(medSnap);
          if (med.quantity < item.qty) {
            throw Exception('Insufficient stock for ${med.name}');
          }
        }

        // Decrement stock
        for (var item in order.items) {
          final medRef = _firestore.collection('medicines').doc(item.medicineId);
          final medSnap = await tx.get(medRef);
          final med = Medicine.fromFirestore(medSnap);
          final newQty = (med.quantity - item.qty).toDouble();
          tx.update(medRef, {'quantity': newQty, 'updatedAt': FieldValue.serverTimestamp()});
        }

        // Update order: dispatched
        tx.update(orderRef, {'status': 'dispatched', 'hwId': hwId, 'updatedAt': FieldValue.serverTimestamp()});
      });
    } else {
      // Just mark accepted; decrement later on dispatch
      await orderRef.update({'status': 'accepted', 'hwId': hwId, 'updatedAt': FieldValue.serverTimestamp()});
    }

    notifyListeners();
  }

  /// Dispatch an already accepted order: will decrement stock inside a transaction
  /// and mark the order as `dispatched`.
  Future<void> dispatchOrder(String orderId, String hwId) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    await _firestore.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) throw Exception('Order not found');
      final order = StockOrder.fromFirestore(orderSnap);

      // Check stock for each item
      for (var item in order.items) {
        final medRef = _firestore.collection('medicines').doc(item.medicineId);
        final medSnap = await tx.get(medRef);
        if (!medSnap.exists) throw Exception('Medicine ${item.name} not found');
        final med = Medicine.fromFirestore(medSnap);
        if (med.quantity < item.qty) {
          throw Exception('Insufficient stock for ${med.name}');
        }
      }

      // Decrement stock
      for (var item in order.items) {
        final medRef = _firestore.collection('medicines').doc(item.medicineId);
        final medSnap = await tx.get(medRef);
        final med = Medicine.fromFirestore(medSnap);
        final newQty = (med.quantity - item.qty).toDouble();
        tx.update(medRef, {'quantity': newQty, 'updatedAt': FieldValue.serverTimestamp()});
      }

      // Update order: dispatched
      tx.update(orderRef, {'status': 'dispatched', 'hwId': hwId, 'updatedAt': FieldValue.serverTimestamp()});
    });

    notifyListeners();
  }

  Future<void> declineOrder(String orderId, String hwId) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    await orderRef.update({'status': 'declined', 'hwId': hwId, 'updatedAt': FieldValue.serverTimestamp()});
    notifyListeners();
  }

  /// Cancel an order by the student (sets status to 'cancelled').
  Future<void> cancelOrder(String orderId, String studentId) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    final snap = await orderRef.get();
    if (!snap.exists) throw Exception('Order not found');
    final data = snap.data() as Map<String, dynamic>;
    if ((data['studentId'] ?? '') != studentId) throw Exception('Not authorized to cancel this order');
    if ((data['status'] ?? 'pending') != 'pending') throw Exception('Only pending orders can be cancelled');
    await orderRef.update({'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()});
    notifyListeners();
  }

  Future<void> placeOrder(Map<String, dynamic> orderData) async {
    await _firestore.collection('orders').add({...orderData, 'createdAt': FieldValue.serverTimestamp(), 'status': 'pending'});
  }
}
