import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../services/storage_service.dart';
import 'bill_view_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Bill> _bills = [];
  bool _loading = true;
  final _currency =
      NumberFormat.currency(locale: 'en_US', symbol: 'Rs ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bills = await StorageService.loadBills();
    setState(() {
      _bills = bills;
      _loading = false;
    });
  }

  Future<void> _delete(Bill bill) async {
    await StorageService.deleteBill(bill.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Past Bills')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
              ? const Center(child: Text('No saved bills yet'))
              : ListView.separated(
                  itemCount: _bills.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final bill = _bills[index];
                    return Dismissible(
                      key: ValueKey(bill.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _delete(bill),
                      child: ListTile(
                        title: Text(bill.shopName),
                        subtitle: Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(bill.date)),
                        trailing: Text(
                          _currency.format(bill.grandTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => BillViewScreen(bill: bill)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
