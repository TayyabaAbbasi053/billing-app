import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bill.dart';
import '../widgets/dashed_divider.dart';

class BillViewScreen extends StatefulWidget {
  final Bill bill;
  const BillViewScreen({super.key, required this.bill});

  @override
  State<BillViewScreen> createState() => _BillViewScreenState();
}

class _BillViewScreenState extends State<BillViewScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final _currency =
      NumberFormat.currency(locale: 'en_US', symbol: 'Rs ', decimalDigits: 0);
  final _plainNumber = NumberFormat.decimalPattern('en_US');
  bool _sharing = false;

  String _formatPercent(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

  Future<void> _shareAsImage() async {
    setState(() => _sharing = true);
    try {
      final Uint8List? bytes =
          await _screenshotController.capture(pixelRatio: 3);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bill_${widget.bill.id}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${widget.bill.shopName} - Bill',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(bill.date);
    final hasTax = bill.taxPercent > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Bill')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Screenshot(
          controller: _screenshotController,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  bill.shopName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const DashedDivider(),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 8),
                    Expanded(
                        flex: 2,
                        child: Text('Qty',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right)),
                    SizedBox(width: 8),
                    Expanded(
                        flex: 3,
                        child: Text('Price (Rs)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right)),
                    SizedBox(width: 8),
                    Expanded(
                        flex: 3,
                        child: Text('Total (Rs)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right)),
                  ],
                ),
                const SizedBox(height: 8),
                const DashedDivider(),
                const SizedBox(height: 8),
                ...bill.items.map((item) {
                  final qtyText = item.quantity % 1 == 0
                      ? item.quantity.toStringAsFixed(0)
                      : item.quantity.toStringAsFixed(2);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(item.name)),
                        const SizedBox(width: 8),
                        Expanded(
                            flex: 2,
                            child: Text(qtyText, textAlign: TextAlign.right)),
                        const SizedBox(width: 8),
                        Expanded(
                            flex: 3,
                            child: Text(_plainNumber.format(item.price),
                                textAlign: TextAlign.right)),
                        const SizedBox(width: 8),
                        Expanded(
                            flex: 3,
                            child: Text(_plainNumber.format(item.total),
                                textAlign: TextAlign.right)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                const DashedDivider(),
                const SizedBox(height: 12),
                if (hasTax) ...[
                  Row(
                    children: [
                      const Expanded(child: Text('Subtotal')),
                      Text('Rs ${_plainNumber.format(bill.subtotal)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                          child:
                              Text('Tax (${_formatPercent(bill.taxPercent)}%)')),
                      Text('Rs ${_plainNumber.format(bill.taxAmount)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    const Expanded(
                      child: Text('TOTAL',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    Text(
                      _currency.format(bill.grandTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thank you!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sharing ? null : _shareAsImage,
        icon: _sharing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.ios_share),
        label: Text(_sharing ? 'Preparing…' : 'Share as Image'),
      ),
    );
  }
}