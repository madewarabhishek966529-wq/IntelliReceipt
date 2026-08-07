import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/receipt_entity.dart';
import '../models/receipt_model.dart';

abstract class ReceiptRemoteDataSource {
  Future<(String id, ReceiptStatus status)> uploadReceipt(File file);
  Future<ReceiptModel> getReceipt(String id);
  Future<(List<ReceiptModel> items, int total)> listReceipts({
    required int page,
    required int pageSize,
  });
  Future<ReceiptItemModel> updateReceiptItem({
    required String receiptId,
    required String itemId,
    String? displayName,
    double? quantity,
    double? mrp,
    double? discount,
    double? tax,
    double? finalPrice,
  });
}

class ReceiptRemoteDataSourceImpl implements ReceiptRemoteDataSource {
  final Dio dio;

  ReceiptRemoteDataSourceImpl({required this.dio});

  @override
  Future<(String id, ReceiptStatus status)> uploadReceipt(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await dio.post(ApiEndpoints.receiptUpload, data: formData);
      final id = response.data['id'].toString();
      final status = receiptStatusFromString(response.data['status'] as String);
      return (id, status);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<ReceiptModel> getReceipt(String id) async {
    try {
      final response = await dio.get(ApiEndpoints.receiptById(id));
      return ReceiptModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<(List<ReceiptModel> items, int total)> listReceipts({
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await dio.get(ApiEndpoints.receipts, queryParameters: {
        'page': page,
        'page_size': pageSize,
      });
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>)
          .map((e) => ReceiptModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items, data['total'] as int);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<ReceiptItemModel> updateReceiptItem({
    required String receiptId,
    required String itemId,
    String? displayName,
    double? quantity,
    double? mrp,
    double? discount,
    double? tax,
    double? finalPrice,
  }) async {
    try {
      final response = await dio.patch(
        '${ApiEndpoints.receiptById(receiptId)}/items/$itemId',
        data: {
          if (displayName != null) 'display_name': displayName,
          if (quantity != null) 'quantity': quantity,
          if (mrp != null) 'mrp': mrp,
          if (discount != null) 'discount': discount,
          if (tax != null) 'tax': tax,
          if (finalPrice != null) 'final_price': finalPrice,
        },
      );
      return ReceiptItemModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Exception _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkException();
    }
    final status = e.response?.statusCode;
    final message = (e.response?.data is Map)
        ? (e.response?.data['detail']?.toString() ?? 'Server error')
        : 'Server error';
    if (status == 401 || status == 403) {
      return UnauthorizedException(message);
    }
    return ServerException(message, statusCode: status);
  }
}
