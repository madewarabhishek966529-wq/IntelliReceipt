import 'package:equatable/equatable.dart';

enum ReceiptStatus { pending, processing, needsReview, completed, failed }

enum PaymentMethod { cash, card, upi, wallet, other }

ReceiptStatus receiptStatusFromString(String value) {
  switch (value) {
    case 'pending':
      return ReceiptStatus.pending;
    case 'processing':
      return ReceiptStatus.processing;
    case 'needs_review':
      return ReceiptStatus.needsReview;
    case 'completed':
      return ReceiptStatus.completed;
    case 'failed':
      return ReceiptStatus.failed;
    default:
      return ReceiptStatus.pending;
  }
}

PaymentMethod? paymentMethodFromString(String? value) {
  switch (value) {
    case 'cash':
      return PaymentMethod.cash;
    case 'card':
      return PaymentMethod.card;
    case 'upi':
      return PaymentMethod.upi;
    case 'wallet':
      return PaymentMethod.wallet;
    case 'other':
      return PaymentMethod.other;
    default:
      return null;
  }
}

class ReceiptItemEntity extends Equatable {
  final String id;
  final String? productId;
  final String rawText;
  final String displayName;
  final double quantity;
  final String? unit;
  final double? mrp;
  final double? discount;
  final double? tax;
  final double finalPrice;
  final double? aiConfidence;

  const ReceiptItemEntity({
    required this.id,
    this.productId,
    required this.rawText,
    required this.displayName,
    required this.quantity,
    this.unit,
    this.mrp,
    this.discount,
    this.tax,
    required this.finalPrice,
    this.aiConfidence,
  });

  @override
  List<Object?> get props => [
        id,
        productId,
        rawText,
        displayName,
        quantity,
        unit,
        mrp,
        discount,
        tax,
        finalPrice,
        aiConfidence,
      ];
}

class ReceiptEntity extends Equatable {
  final String id;
  final String? storeId;
  final String? imageUrl;
  final String? invoiceNumber;
  final DateTime? purchaseDate;
  final double? subtotal;
  final double? taxAmount;
  final double? discountAmount;
  final double? totalAmount;
  final PaymentMethod? paymentMethod;
  final ReceiptStatus status;
  final DateTime createdAt;
  final List<ReceiptItemEntity> items;

  const ReceiptEntity({
    required this.id,
    this.storeId,
    this.imageUrl,
    this.invoiceNumber,
    this.purchaseDate,
    this.subtotal,
    this.taxAmount,
    this.discountAmount,
    this.totalAmount,
    this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.items = const [],
  });

  bool get isProcessing =>
      status == ReceiptStatus.pending || status == ReceiptStatus.processing;

  @override
  List<Object?> get props => [
        id,
        storeId,
        imageUrl,
        invoiceNumber,
        purchaseDate,
        subtotal,
        taxAmount,
        discountAmount,
        totalAmount,
        paymentMethod,
        status,
        createdAt,
        items,
      ];
}
