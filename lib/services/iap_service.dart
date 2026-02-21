// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'package:extropos/services/license_service.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPService {
  static final IAPService instance = IAPService._internal();
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  final List<PurchaseDetails> _purchases = [];
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Product IDs - MUST match Google Play Console
  static const String productLifetime = 'extropos_lifetime_license';
  static const String paramCloud6Mo = 'extropos_cloud_6mo'; // Subscription
  static const String paramCloud1Yr = 'extropos_cloud_1yr'; // Subscription

  static const List<String> _productIds = [
    productLifetime,
    paramCloud6Mo,
    paramCloud1Yr,
  ];

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      final Stream<List<PurchaseDetails>> purchaseUpdated =
          _iap.purchaseStream;
      _subscription = purchaseUpdated.listen(
        _onPurchaseUpdate,
        onDone: _onPurchaseDone,
        onError: _onPurchaseError,
      );
      await _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(_productIds.toSet());
    if (response.notFoundIDs.isNotEmpty) {
      if (kDebugMode) {
        print('Products not found: ${response.notFoundIDs}');
      }
    }
    _products = response.productDetails;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    _purchases.addAll(purchaseDetailsList);
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        // Show pending UI
      } else {
        if (purchase.status == PurchaseStatus.error) {
           if (kDebugMode) print('Purchase error: ${purchase.error}');
        } else if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          
          _verifyPurchase(purchase).then((valid) {
            if (valid) {
              _handleSuccessfulPurchase(purchase);
            }
          });
        }
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // In production, verify the signature with your backend
    return true; 
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    if (purchase.productID == productLifetime) {
      // Activate Lifetime
      await LicenseService.instance.activateViaIAP(
        purchaseToken: purchase.purchaseID ?? 'iap_token',
        isLifetime: true,
      );
    } else {
      // Activate Subscription
       await LicenseService.instance.activateViaIAP(
        purchaseToken: purchase.purchaseID ?? 'iap_token',
        isLifetime: false,
      );
    }
  }

  void _onPurchaseDone() {
    _subscription.cancel();
  }

  void _onPurchaseError(dynamic error) {
    if (kDebugMode) {
      print('🔴 IAP Error: $error');
      print('🔴 Error Type: ${error.runtimeType}');
      print('🔴 Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> buyLifetime() async {
    if (!_isAvailable) {
      throw Exception('Google Play Billing is not available on this device');
    }
    if (_products.isEmpty) {
      throw Exception('Products not loaded. Please restart the app.');
    }
    
    final ProductDetails? product = _products.where((p) => p.id == productLifetime).firstOrNull;
    if (product == null) {
      if (kDebugMode) {
        print('Available products: ${_products.map((p) => p.id).join(", ")}');
      }
      throw Exception('Lifetime product not found in Google Play Console. Please ensure product ID "$productLifetime" is configured.');
    }
    
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!result) {
      throw Exception('Failed to initiate purchase');
    }
  }
  
  Future<void> buyCloud6Mo() async {
    if (!_isAvailable) {
      throw Exception('Google Play Billing is not available on this device');
    }
    if (_products.isEmpty) {
      throw Exception('Products not loaded. Please restart the app.');
    }
    
    final ProductDetails? product = _products.where((p) => p.id == paramCloud6Mo).firstOrNull;
    if (product == null) {
      if (kDebugMode) {
        print('Available products: ${_products.map((p) => p.id).join(", ")}');
      }
      throw Exception('6-month subscription not found in Google Play Console. Please ensure product ID "$paramCloud6Mo" is configured.');
    }
    
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam); // For simplicity, treating as non-consumable
    if (!result) {
      throw Exception('Failed to initiate purchase');
    }
  }
  
  Future<void> buyCloud1Yr() async {
    if (!_isAvailable) {
      throw Exception('Google Play Billing is not available on this device');
    }
    if (_products.isEmpty) {
      throw Exception('Products not loaded. Please restart the app.');
    }
    
    final ProductDetails? product = _products.where((p) => p.id == paramCloud1Yr).firstOrNull;
    if (product == null) {
      if (kDebugMode) {
        print('Available products: ${_products.map((p) => p.id).join(", ")}');
      }
      throw Exception('1-year subscription not found in Google Play Console. Please ensure product ID "$paramCloud1Yr" is configured.');
    }
    
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam); // For simplicity
    if (!result) {
      throw Exception('Failed to initiate purchase');
    }
  }
  
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }
  
  void dispose() {
    _subscription.cancel();
  }
}
