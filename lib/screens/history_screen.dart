import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../services/storage_service.dart';
import 'bill_view_screen.dart';
import 'load_form_screen.dart';

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

  // Multi-select state, used to build a Load Form from several bills.
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

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

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _makeLoadForm() {
    final selectedBills =
        _bills.where((b) => _selectedIds.contains(b.id)).toList();
    Navigator.of(context)
        .push(
      MaterialPageRoute(builder: (_) => LoadFormScreen(bills: selectedBills)),
    )
        .then((_) {
      if (mounted) _cancelSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancel selection',
                onPressed: _cancelSelection,
              ),
              title: Text('${_selectedIds.length} selected'),
            )
          : AppBar(title: const Text('Past Bills')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
              ? const Center(child: Text('No saved bills yet'))
              : ListView.separated(
                  itemCount: _bills.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final bill = _bills[index];
                    final selected = _selectedIds.contains(bill.id);

                    final tile = ListTile(
                      leading: _selectionMode
                          ? Checkbox(
                              value: selected,
                              onChanged: (_) => _toggleSelection(bill.id),
                            )
                          : null,
                      title: Text(bill.shopName),
                      subtitle: Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(bill.date)),
                      trailing: Text(
                        _currency.format(bill.grandTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      selected: selected,
                      onTap: () {
                        if (_selectionMode) {
                          _toggleSelection(bill.id);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => BillViewScreen(bill: bill)),
                          );
                        }
                      },
                      onLongPress: () {
                        if (!_selectionMode) _enterSelectionMode(bill.id);
                      },
                    );

                    // Swipe-to-delete only makes sense outside selection mode.
                    if (_selectionMode) return tile;

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
                      child: tile,
                    );
                  },
                ),
      floatingActionButton: _selectionMode && _selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _makeLoadForm,
              icon: const Icon(Icons.grid_on),
              label: const Text('Make Load Form'),
            )
          : null,
    );
  }
}