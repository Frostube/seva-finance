import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user.dart';
import 'user_service.dart';

class SubscriptionService with ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final UserService _userService;

  bool _isLoading = false;

  SubscriptionService(this._firestore, this._functions, this._userService);

  bool get isLoading => _isLoading;

  // Stripe Price IDs - these should match your Stripe dashboard
  static const String monthlyPriceId =
      'price_monthly_pro'; // Replace with actual Stripe price ID
  static const String annualPriceId =
      'price_annual_pro'; // Replace with actual Stripe price ID
  static const String scanPackPriceId =
      'price_scan_pack'; // Replace with actual Stripe price ID

  // Create checkout session for subscription
  Future<String?> createCheckoutSession({
    required String priceId,
    required String mode, // 'subscription' or 'payment'
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _userService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint(
          'SubscriptionService: Creating checkout session for user ${user.id}');

      // Call Cloud Function to create checkout session
      final callable = _functions.httpsCallable('createCheckoutSession');
      final result = await callable.call({
        'priceId': priceId,
        'mode': mode,
        'successUrl': successUrl ?? _getDefaultSuccessUrl(),
        'cancelUrl': cancelUrl ?? _getDefaultCancelUrl(),
        'customerEmail': user.email,
        'userId': user.id,
      });

      final sessionId = result.data['sessionId'] as String?;
      final checkoutUrl = result.data['url'] as String?;

      _isLoading = false;
      notifyListeners();

      debugPrint('SubscriptionService: Checkout session created: $sessionId');
      return checkoutUrl;
    } catch (e) {
      debugPrint('SubscriptionService: Error creating checkout session: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Launch Stripe checkout
  Future<bool> launchCheckout(String checkoutUrl) async {
    try {
      final uri = Uri.parse(checkoutUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        debugPrint('SubscriptionService: Checkout launched successfully');
        return true;
      } else {
        debugPrint('SubscriptionService: Failed to launch checkout');
        return false;
      }
    } catch (e) {
      debugPrint('SubscriptionService: Error launching checkout: $e');
      return false;
    }
  }

  // Subscribe to Pro Monthly
  Future<bool> subscribeToProMonthly() async {
    try {
      final checkoutUrl = await createCheckoutSession(
        priceId: monthlyPriceId,
        mode: 'subscription',
      );

      if (checkoutUrl != null) {
        return await launchCheckout(checkoutUrl);
      }

      return false;
    } catch (e) {
      debugPrint('SubscriptionService: Error subscribing to Pro Monthly: $e');
      return false;
    }
  }

  // Subscribe to Pro Annual
  Future<bool> subscribeToProAnnual() async {
    try {
      final checkoutUrl = await createCheckoutSession(
        priceId: annualPriceId,
        mode: 'subscription',
      );

      if (checkoutUrl != null) {
        return await launchCheckout(checkoutUrl);
      }

      return false;
    } catch (e) {
      debugPrint('SubscriptionService: Error subscribing to Pro Annual: $e');
      return false;
    }
  }

  // Buy scan pack
  Future<bool> buyScanPack() async {
    try {
      final checkoutUrl = await createCheckoutSession(
        priceId: scanPackPriceId,
        mode: 'payment',
      );

      if (checkoutUrl != null) {
        return await launchCheckout(checkoutUrl);
      }

      return false;
    } catch (e) {
      debugPrint('SubscriptionService: Error buying scan pack: $e');
      return false;
    }
  }

  // Create customer portal session
  Future<String?> createCustomerPortalSession() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _userService.currentUser;
      if (user == null || user.stripeCustomerId == null) {
        throw Exception('User not authenticated or no Stripe customer ID');
      }

      debugPrint(
          'SubscriptionService: Creating customer portal session for ${user.stripeCustomerId}');

      // Call Cloud Function to create customer portal session
      final callable = _functions.httpsCallable('createCustomerPortalSession');
      final result = await callable.call({
        'customerId': user.stripeCustomerId,
        'returnUrl': _getDefaultReturnUrl(),
      });

      final portalUrl = result.data['url'] as String?;

      _isLoading = false;
      notifyListeners();

      debugPrint('SubscriptionService: Customer portal session created');
      return portalUrl;
    } catch (e) {
      debugPrint(
          'SubscriptionService: Error creating customer portal session: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Launch customer portal
  Future<bool> launchCustomerPortal() async {
    try {
      final portalUrl = await createCustomerPortalSession();

      if (portalUrl != null) {
        final uri = Uri.parse(portalUrl);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          debugPrint(
              'SubscriptionService: Customer portal launched successfully');
          return true;
        } else {
          debugPrint('SubscriptionService: Failed to launch customer portal');
          return false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('SubscriptionService: Error launching customer portal: $e');
      return false;
    }
  }

  // Get subscription status
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    try {
      final user = _userService.currentUser;
      if (user == null) {
        return SubscriptionStatus.notAuthenticated;
      }

      if (user.hasActiveSubscription) {
        if (user.isTrialActive) {
          return SubscriptionStatus.trial;
        } else if (user.hasPaid) {
          return SubscriptionStatus.active;
        }
      }

      if (user.isTrialExpired) {
        return SubscriptionStatus.trialExpired;
      }

      return SubscriptionStatus.free;
    } catch (e) {
      debugPrint('SubscriptionService: Error getting subscription status: $e');
      return SubscriptionStatus.error;
    }
  }

  // Get subscription details
  Map<String, dynamic> getSubscriptionDetails() {
    final user = _userService.currentUser;
    if (user == null) return {};

    return {
      'planStatus': user.planStatus,
      'isPro': user.isPro,
      'hasPaid': user.hasPaid,
      'isTrialActive': user.isTrialActive,
      'isTrialExpired': user.isTrialExpired,
      'trialDaysRemaining': user.trialDaysRemaining,
      'trialStart': user.trialStart?.toIso8601String(),
      'subscriptionStatus': user.subscriptionStatus,
      'subscriptionStart': user.subscriptionStart?.toIso8601String(),
      'subscriptionEnd': user.subscriptionEnd?.toIso8601String(),
      'scanCountThisMonth': user.scanCountThisMonth,
    };
  }

  // Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _userService.currentUser;
      if (user == null || user.stripeSubscriptionId == null) {
        throw Exception('User not authenticated or no subscription ID');
      }

      debugPrint(
          'SubscriptionService: Canceling subscription ${user.stripeSubscriptionId}');

      // Call Cloud Function to cancel subscription
      final callable = _functions.httpsCallable('cancelSubscription');
      await callable.call({
        'subscriptionId': user.stripeSubscriptionId,
        'userId': user.id,
      });

      _isLoading = false;
      notifyListeners();

      debugPrint('SubscriptionService: Subscription canceled successfully');
      return true;
    } catch (e) {
      debugPrint('SubscriptionService: Error canceling subscription: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper methods for URLs
  String _getDefaultSuccessUrl() {
    return 'https://your-app.com/success'; // Replace with your app's success URL
  }

  String _getDefaultCancelUrl() {
    return 'https://your-app.com/cancel'; // Replace with your app's cancel URL
  }

  String _getDefaultReturnUrl() {
    return 'https://your-app.com/account'; // Replace with your app's account URL
  }

  // Pricing information
  static const Map<String, SubscriptionPlan> plans = {
    'monthly': SubscriptionPlan(
      id: 'monthly',
      name: 'Pro Monthly',
      price: 4.99,
      currency: 'USD',
      interval: 'month',
      priceId: monthlyPriceId,
      features: [
        'Unlimited receipt scanning',
        'AI-powered insights',
        'Advanced analytics',
        'Email notifications',
        'Data backup',
        'Priority support',
      ],
    ),
    'annual': SubscriptionPlan(
      id: 'annual',
      name: 'Pro Annual',
      price: 49.00,
      currency: 'USD',
      interval: 'year',
      priceId: annualPriceId,
      features: [
        'Unlimited receipt scanning',
        'AI-powered insights',
        'Advanced analytics',
        'Email notifications',
        'Data backup',
        'Priority support',
        'Save 17% vs monthly',
      ],
    ),
    'scan_pack': SubscriptionPlan(
      id: 'scan_pack',
      name: 'Scan Pack',
      price: 0.99,
      currency: 'USD',
      interval: 'one_time',
      priceId: scanPackPriceId,
      features: [
        '10 additional scans',
        'Valid for 30 days',
      ],
    ),
  };

  static List<SubscriptionPlan> get availablePlans => plans.values.toList();
  static SubscriptionPlan? getPlan(String planId) => plans[planId];
}

enum SubscriptionStatus {
  notAuthenticated,
  free,
  trial,
  trialExpired,
  active,
  canceled,
  pastDue,
  error,
}

class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String interval;
  final String priceId;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.interval,
    required this.priceId,
    required this.features,
  });

  String get displayPrice {
    if (interval == 'month') {
      return '\$${price.toStringAsFixed(2)}/month';
    } else if (interval == 'year') {
      return '\$${price.toStringAsFixed(2)}/year';
    } else {
      return '\$${price.toStringAsFixed(2)}';
    }
  }

  String get displayInterval {
    switch (interval) {
      case 'month':
        return 'Monthly';
      case 'year':
        return 'Annual';
      case 'one_time':
        return 'One-time';
      default:
        return interval;
    }
  }
}
