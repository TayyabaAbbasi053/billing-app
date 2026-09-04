import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bill.dart';

/// Shows a pivot-style "load form" built from several selected bills:
/// shop names go down the side (rows), item names go across the top
/// (columns), each cell holds the quantity of that item bought from that
/// shop, and the bottom row totals each item's quantity across all shops.
///
/// If the same shop appears in more than one selected bill, its quantities
/// are combined into a single row rather than being shown twice.
class LoadFormScreen extends StatefulWidget {
  final List<Bill> bills;
  const LoadFormScreen({super.key, required this.bills});

  @override
  State<LoadFormScreen> createState() => _LoadFormScreenState();
}

class _LoadFormScreenState extends State<LoadFormScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _sharing = false;

  String _fmtQty(double value) {
    if (value == 0) return '-';
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  // ---- Shared data-crunching, computed once and reused by build() and
  // the share flow so on-screen and shared versions never drift apart. ----
  ({
    Map<String, Map<String, double>> shopItemQty,
    List<String> shops,
    List<String> itemNames,
    Map<String, double> columnTotals,
  }) _computeTable() {
    final Map<String, Map<String, double>> shopItemQty = {};
    final Set<String> itemNamesSet = {};

    for (final bill in widget.bills) {
      final shopMap = shopItemQty.putIfAbsent(bill.shopName, () => {});
      for (final item in bill.items) {
        shopMap[item.name] = (shopMap[item.name] ?? 0) + item.quantity;
        itemNamesSet.add(item.name);
      }
    }

    final shops = shopItemQty.keys.toList()..sort();
    final itemNames = itemNamesSet.toList()..sort();

    final Map<String, double> columnTotals = {
      for (final name in itemNames) name: 0,
    };
    for (final shop in shops) {
      for (final name in itemNames) {
        columnTotals[name] =
            (columnTotals[name] ?? 0) + (shopItemQty[shop]?[name] ?? 0);
      }
    }

    return (
      shopItemQty: shopItemQty,
      shops: shops,
      itemNames: itemNames,
      columnTotals: columnTotals,
    );
  }

  /// Builds just the DataTable (no scroll wrappers). Reused both for the
  /// on-screen scrollable preview and for the full, unconstrained capture
  /// used when sharing — so what gets shared always matches what exists,
  /// not just what's currently visible on screen.
  Widget _buildDataTable({
    required Map<String, Map<String, double>> shopItemQty,
    required List<String> shops,
    required List<String> itemNames,
    required Map<String, double> columnTotals,
  }) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFEFEFEF)),
      columns: [
        const DataColumn(
          label: Text('Shop', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...itemNames.map(
          (name) => DataColumn(
            label: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
        ),
      ],
      rows: [
        ...shops.map(
          (shop) => DataRow(
            cells: [
              DataCell(Text(shop)),
              ...itemNames.map(
                (name) => DataCell(
                  Text(_fmtQty(shopItemQty[shop]?[name] ?? 0)),
                ),
              ),
            ],
          ),
        ),
        // Bottom row: total quantity of each item across every shop in
        // the selection.
        DataRow(
          color: WidgetStateProperty.all(const Color(0xFFF7F7F5)),
          cells: [
            const DataCell(
              Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...itemNames.map(
              (name) => DataCell(
                Text(
                  _fmtQty(columnTotals[name] ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _shareAsImage({
    required Map<String, Map<String, double>> shopItemQty,
    required List<String> shops,
    required List<String> itemNames,
    required Map<String, double> columnTotals,
  }) async {
    setState(() => _sharing = true);
    try {
      // IMPORTANT: don't use _screenshotController.capture() here — that
      // only rasterizes what's currently painted in the visible viewport,
      // so any row/column scrolled off-screen (horizontally or vertically)
      // would be missing from the image. captureFromWidget() instead
      // renders an independent copy of the widget tree off-screen at its
      // natural, unconstrained size, so the ENTIRE table is captured no
      // matter how many rows/columns it has.
      final Uint8List bytes = await _screenshotController.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQuery.of(context),
            child: Material(
              color: Colors.white,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: _buildDataTable(
                  shopItemQty: shopItemQty,
                  shops: shops,
                  itemNames: itemNames,
                  columnTotals: columnTotals,
                ),
              ),
            ),
          ),
        ),
        delay: const Duration(milliseconds: 50),
        pixelRatio: 3,
      );

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/load_form_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Load Form');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final table = _computeTable();
    final hasData = table.shops.isNotEmpty && table.itemNames.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Load Form')),
      body: !hasData
          ? const Center(child: Text('Selected bills have no items'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: _buildDataTable(
                    shopItemQty: table.shopItemQty,
                    shops: table.shops,
                    itemNames: table.itemNames,
                    columnTotals: table.columnTotals,
                  ),
                ),
              ),
            ),
      floatingActionButton: !hasData
          ? null
          : FloatingActionButton.extended(
              onPressed: _sharing
                  ? null
                  : () => _shareAsImage(
                        shopItemQty: table.shopItemQty,
                        shops: table.shops,
                        itemNames: table.itemNames,
                        columnTotals: table.columnTotals,
                      ),
              icon: _sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.ios_share),
              label: Text(_sharing ? 'Preparing…' : 'Share as Image'),
            ),
    );
  }
}