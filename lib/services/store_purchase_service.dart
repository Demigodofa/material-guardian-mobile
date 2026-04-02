import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

class StoreProductSnapshot {
  const StoreProductSnapshot({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.rawPrice,
  });

  final String id;
  final String title;
  final String description;
  final String price;
  final String currencyCode;
  final double rawPrice;
}

class StorePurchaseUpdate {
  const StorePurchaseUpdate({
    required this.productId,
    required this.purchaseId,
    required this.status,
    required this.provider,
    required this.pendingCompletePurchase,
    required this.verificationServerData,
    required this.verificationLocalData,
    required this.verificationSource,
    required this.transactionDate,
    required this.providerTransactionRef,
    required this.providerOriginalRef,
    required this.errorMessage,
  });

  final String productId;
  final String? purchaseId;
  final String status;
  final String provider;
  final bool pendingCompletePurchase;
  final String verificationServerData;
  final String verificationLocalData;
  final String verificationSource;
  final DateTime? transactionDate;
  final String? providerTransactionRef;
  final String? providerOriginalRef;
  final String? errorMessage;

  bool get isPending => status == 'pending';
  bool get isPurchased => status == 'purchased';
  bool get isRestored => status == 'restored';
  bool get isError => status == 'error';
  bool get isCanceled => status == 'canceled';
}

abstract class StorePurchaseService {
  Stream<List<StorePurchaseUpdate>> get purchaseUpdates;

  Future<bool> isAvailable();

  Future<List<StoreProductSnapshot>> queryProducts(Set<String> productIds);

  Future<void> buyProduct(String productId);

  Future<void> completePurchase(String productId);

  Future<void> restorePurchases();

  void dispose();
}

class InAppStorePurchaseService implements StorePurchaseService {
  InAppStorePurchaseService({
    InAppPurchase? inAppPurchase,
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance {
    _purchaseUpdatesController = StreamController<List<StorePurchaseUpdate>>.broadcast();
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseDetails,
      onError: (Object error, StackTrace stackTrace) {
        _purchaseUpdatesController.add(<StorePurchaseUpdate>[
          StorePurchaseUpdate(
            productId: '',
            purchaseId: null,
            status: 'error',
            provider: _defaultProvider,
            pendingCompletePurchase: false,
            verificationServerData: '',
            verificationLocalData: '',
            verificationSource: '',
            transactionDate: null,
            providerTransactionRef: null,
            providerOriginalRef: null,
            errorMessage: error.toString(),
          ),
        ]);
      },
    );
  }

  final InAppPurchase _inAppPurchase;
  final Map<String, ProductDetails> _productDetailsById =
      <String, ProductDetails>{};
  final Map<String, PurchaseDetails> _latestPurchaseDetailsByProductId =
      <String, PurchaseDetails>{};
  late final StreamController<List<StorePurchaseUpdate>>
  _purchaseUpdatesController;
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  static String get _defaultProvider {
    if (!kIsWeb && Platform.isAndroid) {
      return 'google';
    }
    if (!kIsWeb && Platform.isIOS) {
      return 'apple';
    }
    return 'unknown';
  }

  @override
  Stream<List<StorePurchaseUpdate>> get purchaseUpdates =>
      _purchaseUpdatesController.stream;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) {
      return false;
    }
    return _inAppPurchase.isAvailable();
  }

  @override
  Future<List<StoreProductSnapshot>> queryProducts(Set<String> productIds) async {
    if (productIds.isEmpty) {
      return const <StoreProductSnapshot>[];
    }

    final response = await _inAppPurchase.queryProductDetails(productIds);
    for (final product in response.productDetails) {
      _productDetailsById[product.id] = product;
    }

    return response.productDetails
        .map(
          (product) => StoreProductSnapshot(
            id: product.id,
            title: product.title,
            description: product.description,
            price: product.price,
            currencyCode: product.currencyCode,
            rawPrice: product.rawPrice,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> buyProduct(String productId) async {
    final productDetails = _productDetailsById[productId];
    if (productDetails == null) {
      throw StateError('Store product $productId has not been loaded.');
    }

    final purchaseParam = PurchaseParam(productDetails: productDetails);
    final accepted = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
    if (!accepted) {
      throw StateError('The store did not accept the purchase request.');
    }
  }

  @override
  Future<void> completePurchase(String productId) async {
    final purchaseDetails = _latestPurchaseDetailsByProductId[productId];
    if (purchaseDetails == null) {
      return;
    }

    if (!purchaseDetails.pendingCompletePurchase) {
      return;
    }

    await _inAppPurchase.completePurchase(purchaseDetails);
  }

  @override
  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  @override
  void dispose() {
    unawaited(_purchaseSubscription.cancel());
    unawaited(_purchaseUpdatesController.close());
  }

  void _onPurchaseDetails(List<PurchaseDetails> purchaseDetailsList) {
    final updates = purchaseDetailsList
        .map((purchaseDetails) {
          _latestPurchaseDetailsByProductId[purchaseDetails.productID] =
              purchaseDetails;

          final provider =
              purchaseDetails is GooglePlayPurchaseDetails ? 'google' : 'apple';
          final providerTransactionRef =
              purchaseDetails is GooglePlayPurchaseDetails
              ? purchaseDetails.billingClientPurchase.orderId
              : purchaseDetails.purchaseID;
          final providerOriginalRef =
              purchaseDetails is GooglePlayPurchaseDetails
              ? purchaseDetails.billingClientPurchase.purchaseToken
              : purchaseDetails.purchaseID;

          return StorePurchaseUpdate(
            productId: purchaseDetails.productID,
            purchaseId: purchaseDetails.purchaseID,
            status: purchaseDetails.status.name,
            provider: provider,
            pendingCompletePurchase: purchaseDetails.pendingCompletePurchase,
            verificationServerData:
                purchaseDetails.verificationData.serverVerificationData,
            verificationLocalData:
                purchaseDetails.verificationData.localVerificationData,
            verificationSource: purchaseDetails.verificationData.source,
            transactionDate: purchaseDetails.transactionDate == null
                ? null
                : DateTime.tryParse(
                    purchaseDetails.transactionDate!,
                  ) ??
                      DateTime.fromMillisecondsSinceEpoch(
                        int.tryParse(purchaseDetails.transactionDate!) ?? 0,
                      ),
            providerTransactionRef: providerTransactionRef,
            providerOriginalRef: providerOriginalRef,
            errorMessage: purchaseDetails.error?.message,
          );
        })
        .toList(growable: false);

    _purchaseUpdatesController.add(updates);
  }
}

class NoopStorePurchaseService implements StorePurchaseService {
  const NoopStorePurchaseService();

  @override
  Stream<List<StorePurchaseUpdate>> get purchaseUpdates =>
      const Stream<List<StorePurchaseUpdate>>.empty();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<List<StoreProductSnapshot>> queryProducts(Set<String> productIds) async =>
      const <StoreProductSnapshot>[];

  @override
  Future<void> buyProduct(String productId) async {
    throw UnsupportedError('Store purchases are unavailable on this platform.');
  }

  @override
  Future<void> completePurchase(String productId) async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  void dispose() {}
}
