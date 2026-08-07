import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../datasources/receipt_remote_datasource.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  final ReceiptRemoteDataSource remoteDataSource;

  ReceiptRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, (String id, ReceiptStatus status)>> uploadReceipt(File file) async {
    try {
      final result = await remoteDataSource.uploadReceipt(file);
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, ReceiptEntity>> getReceipt(String id) async {
    try {
      final receipt = await remoteDataSource.getReceipt(id);
      return Right(receipt);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, (List<ReceiptEntity> items, int total)>> listReceipts({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final (items, total) = await remoteDataSource.listReceipts(page: page, pageSize: pageSize);
      return Right((items.cast<ReceiptEntity>(), total));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, ReceiptItemEntity>> updateReceiptItem({
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
      final item = await remoteDataSource.updateReceiptItem(
        receiptId: receiptId,
        itemId: itemId,
        displayName: displayName,
        quantity: quantity,
        mrp: mrp,
        discount: discount,
        tax: tax,
        finalPrice: finalPrice,
      );
      return Right(item);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
