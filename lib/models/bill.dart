class BillItem {
  final String name;
  final double quantity;
  final double price;

  BillItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'price': price,
      };

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        price: (json['price'] as num).toDouble(),
      );
}

class Bill {
  final String id;
  final String shopName;
  final DateTime date;
  final List<BillItem> items;

  Bill({
    required this.id,
    required this.shopName,
    required this.date,
    required this.items,
  });

  double get grandTotal =>
      items.fold(0.0, (sum, item) => sum + item.total);

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopName': shopName,
        'date': date.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id'] as String,
        shopName: json['shopName'] as String,
        date: DateTime.parse(json['date'] as String),
        items: (json['items'] as List)
            .map((i) => BillItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}
