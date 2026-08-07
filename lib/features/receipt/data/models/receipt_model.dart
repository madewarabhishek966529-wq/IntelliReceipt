import '../../domain/entities/receipt_entity.dart';

class ReceiptItemModel extends ReceiptItemEntity {
  const ReceiptItemModel({
    required super.id,
    super.productId,
    required super.rawText,
    required super.displayName,
    required super.quantity,
    super.unit,
    super.mrp,
    super.discount,
    super.tax,
    required super.finalPrice,
    super.aiConfidence,
  });

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return ReceiptItemModel(
      id: json['id'].toString(),
      productId: json['product_id']?.toString(),
      rawText: json['raw_text'] as String,
      displayName: json['display_name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String?,
      mrp: (json['mrp'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      tax: (json['tax'] as num?)?.toDouble(),
      finalPrice: (json['final_price'] as num).toDouble(),
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
    );
  }
}

class ReceiptModel extends ReceiptEntity {
  const ReceiptModel({
    required super.id,
    super.storeId,
    super.imageUrl,
    super.invoiceNumber,
    super.purchaseDate,
    super.subtotal,
    super.taxAmount,
    super.discountAmount,
    super.totalAmount,
    super.paymentMethod,
    required super.status,
    required super.createdAt,
    super.items,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id'].toString(),
      storeId: json['store_id']?.toString(),
      imageUrl: json['image_url'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'] as String)
          : null,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      paymentMethod: paymentMethodFromString(json['payment_method'] as String?),
      status: receiptStatusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => ReceiptItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
