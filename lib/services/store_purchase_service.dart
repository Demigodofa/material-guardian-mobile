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

class StoreProductQueryResult {
  const StoreProductQueryResult({
    required this.products,
    required this.notFoundIds,
    required this.errorMessage,
  });

  final List<StoreProductSnapshot> products;
  final List<String> notFoundIds;
  final String? errorMessage;
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

class StoreRestoreResult {
  const StoreRestoreResult({required this.updates, required this.errorMessage});

  final List<StorePurchaseUpdate> updates;
  final String? errorMessage;
}

abstract class StorePurchaseService {
  Stream<List<StorePurchaseUpdate>> get purchaseUpdates;

  Future<bool> isAvailable();

  Future<StoreProductQueryResult> queryProducts(Set<String> productIds);

  Future<void> buyProduct(String productId);

  Future<void> completePurchase(String productId);

  Future<StoreRestoreResult> restorePurchases();

  void dispose();
}

class InAppStorePurchaseService implements StorePurchaseService {
  InAppStorePurchaseService({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance {
    _purchaseUpdatesController =
        StreamController<List<StorePurchaseUpdate>>.broadcast();
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
  Completer<List<StorePurchaseUpdate>>? _pendingRestoreCompleter;
  List<StorePurchaseUpdate> _pendingRestoreUpdates = <StorePurchaseUpdate>[];
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
  Future<StoreProductQueryResult> queryProducts(Set<String> productIds) async {
    if (productIds.isEmpty) {
      return const StoreProductQueryResult(
        products: <StoreProductSnapshot>[],
        notFoundIds: <String>[],
        errorMessage: null,
      );
    }

    final response = await _inAppPurchase.queryProductDetails(productIds);
    for (final product in response.productDetails) {
      _productDetailsById[product.id] = product;
    }

    return StoreProductQueryResult(
      products: response.productDetails
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
          .toList(growable: false),
      notFoundIds: List<String>.unmodifiable(response.notFoundIDs),
      errorMessage: response.error?.message,
    );
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
  Future<StoreRestoreResult> restorePurchases() async {
    if (!kIsWeb && Platform.isAndroid) {
      final addition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      final directUpdates = response.pastPurchases
          .map(
            (purchaseDetails) => _toStorePurchaseUpdate(
              purchaseDetails,
              forcedStatus: 'restored',
            ),
          )
          .toList(growable: false);
      final errorMessage = response.error?.message.trim().isNotEmpty == true
          ? response.error!.message
          : response.error?.details?.toString();
      if (errorMessage != null && errorMessage.isNotEmpty) {
        return StoreRestoreResult(
          updates: directUpdates,
          errorMessage: errorMessage,
        );
      }
      if (directUpdates.isNotEmpty) {
        return StoreRestoreResult(updates: directUpdates, errorMessage: null);
      }
      final streamedUpdates = await _restorePurchasesFromStream();
      return StoreRestoreResult(updates: streamedUpdates, errorMessage: null);
    }

    await _inAppPurchase.restorePurchases();
    return const StoreRestoreResult(
      updates: <StorePurchaseUpdate>[],
      errorMessage: null,
    );
  }

  @override
  void dispose() {
    unawaited(_purchaseSubscription.cancel());
    unawaited(_purchaseUpdatesController.close());
  }

  void _onPurchaseDetails(List<PurchaseDetails> purchaseDetailsList) {
    final updates = purchaseDetailsList
        .map((purchaseDetails) => _toStorePurchaseUpdate(purchaseDetails))
        .toList(growable: false);

    _purchaseUpdatesController.add(updates);
    final restoreCompleter = _pendingRestoreCompleter;
    if (restoreCompleter != null && !restoreCompleter.isCompleted) {
      if (updates.isNotEmpty) {
        _pendingRestoreUpdates = <StorePurchaseUpdate>[
          ..._pendingRestoreUpdates,
          ...updates,
        ];
      }
      restoreCompleter.complete(
        List<StorePurchaseUpdate>.unmodifiable(_pendingRestoreUpdates),
      );
    }
  }

  Future<List<StorePurchaseUpdate>> _restorePurchasesFromStream() async {
    final existingCompleter = _pendingRestoreCompleter;
    if (existingCompleter != null) {
      return existingCompleter.future;
    }

    final completer = Completer<List<StorePurchaseUpdate>>();
    _pendingRestoreCompleter = completer;
    _pendingRestoreUpdates = <StorePurchaseUpdate>[];
    try {
      await _inAppPurchase.restorePurchases();
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            List<StorePurchaseUpdate>.unmodifiable(_pendingRestoreUpdates),
      );
    } finally {
      if (identical(_pendingRestoreCompleter, completer)) {
        _pendingRestoreCompleter = null;
        _pendingRestoreUpdates = <StorePurchaseUpdate>[];
      }
    }
  }

  StorePurchaseUpdate _toStorePurchaseUpdate(
    PurchaseDetails purchaseDetails, {
    String? forcedStatus,
  }) {
    _latestPurchaseDetailsByProductId[purchaseDetails.productID] =
        purchaseDetails;

    final provider = purchaseDetails is GooglePlayPurchaseDetails
        ? 'google'
        : 'apple';
    final providerTransactionRef = purchaseDetails is GooglePlayPurchaseDetails
        ? purchaseDetails.billingClientPurchase.orderId
        : purchaseDetails.purchaseID;
    final providerOriginalRef = purchaseDetails is GooglePlayPurchaseDetails
        ? purchaseDetails.billingClientPurchase.purchaseToken
        : purchaseDetails.purchaseID;

    return StorePurchaseUpdate(
      productId: purchaseDetails.productID,
      purchaseId: purchaseDetails.purchaseID,
      status: forcedStatus ?? purchaseDetails.status.name,
      provider: provider,
      pendingCompletePurchase: purchaseDetails.pendingCompletePurchase,
      verificationServerData:
          purchaseDetails.verificationData.serverVerificationData,
      verificationLocalData:
          purchaseDetails.verificationData.localVerificationData,
      verificationSource: purchaseDetails.verificationData.source,
      transactionDate: purchaseDetails.transactionDate == null
          ? null
          : DateTime.tryParse(purchaseDetails.transactionDate!) ??
                DateTime.fromMillisecondsSinceEpoch(
                  int.tryParse(purchaseDetails.transactionDate!) ?? 0,
                ),
      providerTransactionRef: providerTransactionRef,
      providerOriginalRef: providerOriginalRef,
      errorMessage: purchaseDetails.error?.message,
    );
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
  Future<StoreProductQueryResult> queryProducts(Set<String> productIds) async =>
      const StoreProductQueryResult(
        products: <StoreProductSnapshot>[],
        notFoundIds: <String>[],
        errorMessage: null,
      );

  @override
  Future<void> buyProduct(String productId) async {
    throw UnsupportedError('Store purchases are unavailable on this platform.');
  }

  @override
  Future<void> completePurchase(String productId) async {}

  @override
  Future<StoreRestoreResult> restorePurchases() async =>
      const StoreRestoreResult(
        updates: <StorePurchaseUpdate>[],
        errorMessage: null,
      );

  @override
  void dispose() {}
}
