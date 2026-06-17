import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill.dart';

/// Handles saving/loading bill history entirely on-device (no internet needed).
class StorageService {
  static const _key = 'saved_bills';

  static Future<List<Bill>> loadBills() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Bill.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveBill(Bill bill) async {
    final bills = await loadBills();
    bills.insert(0, bill); // newest first
    await _persist(bills);
  }

  static Future<void> deleteBill(String id) async {
    final bills = await loadBills();
    bills.removeWhere((b) => b.id == id);
    await _persist(bills);
  }

  static Future<void> _persist(List<Bill> bills) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(bills.map((b) => b.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
