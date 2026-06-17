import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../services/storage_service.dart';
import 'bill_view_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _shopNameController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();

  final List<BillItem> _items = [];

  final _currency =
      NumberFormat.currency(locale: 'en_US', symbol: 'Rs ', decimalDigits: 0);

  double get _grandTotal => _items.fold(0.0, (sum, item) => sum + item.total);

  void _addItem() {
    final name = _itemNameController.text.trim();
    final qty = double.tryParse(_qtyController.text.trim());
    final price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty || qty == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill item name, quantity and price correctly')),
      );
      return;
    }

    setState(() {
      _items.add(BillItem(name: name, quantity: qty, price: price));
      _itemNameController.clear();
      _qtyController.clear();
      _priceController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _generateBill() async {
    final shopName = _shopNameController.text.trim();
    if (shopName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the shop name')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }

    final bill = Bill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      shopName: shopName,
      date: DateTime.now(),
      items: List.of(_items),
    );

    await StorageService.saveBill(bill);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BillViewScreen(bill: bill)),
    );

    setState(() {
      _items.clear();
    });
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _itemNameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Past Bills',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _shopNameController,
              textCapitalization: TextCapitalization.words,
              style: theme.textTheme.titleLarge,
              decoration: const InputDecoration(
                labelText: 'Shop Name',
                prefixIcon: Icon(Icons.storefront),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _itemNameController,
                    decoration: const InputDecoration(labelText: 'Item Name'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Quantity'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Price'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _addItem,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      'No items added yet',
                      style:
                          theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final qtyText = item.quantity % 1 == 0
                          ? item.quantity.toStringAsFixed(0)
                          : item.quantity.toStringAsFixed(2);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name),
                        subtitle:
                            Text('$qtyText x ${_currency.format(item.price)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_currency.format(item.total),
                                style: theme.textTheme.titleMedium),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14)),
                        Text(
                          _currency.format(_grandTotal),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.black,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onPressed: _generateBill,
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Generate Bill'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
