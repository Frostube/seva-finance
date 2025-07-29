import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/user_service.dart';
import '../services/subscription_service.dart';
import '../services/feature_gate_service.dart';
import '../models/user.dart' as app_user;
import '../widgets/trial_banner.dart';
import '../widgets/pro_gate.dart';

class PlanManagementScreen extends StatefulWidget {
  const PlanManagementScreen({super.key});

  @override
  State<PlanManagementScreen> createState() => _PlanManagementScreenState();
}

class _PlanManagementScreenState extends State<PlanManagementScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Plan & Billing'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer3<UserService, SubscriptionService, FeatureGateService>(
        builder: (context, userService, subscriptionService, featureGateService,
            child) {
          final user = userService.currentUser;

          if (user == null) {
            return const Center(
              child: Text('Please sign in to view your plan'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trial Banner
                if (user.isTrialActive)
                  const TrialBanner(
                    margin: EdgeInsets.only(bottom: 16),
                    showOnlyWhenNearExpiry: false,
                  ),

                // Plan Status Card
                _buildPlanStatusCard(context, user),
                const SizedBox(height: 24),

                // Usage Overview
                _buildUsageOverview(context, featureGateService, user),
                const SizedBox(height: 24),

                // Available Plans
                if (!user.hasPaid)
                  _buildAvailablePlans(context, subscriptionService),

                // Subscription Management
                if (user.hasPaid)
                  _buildSubscriptionManagement(
                      context, subscriptionService, user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanStatusCard(BuildContext context, app_user.User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPlanColor(user),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPlanIcon(user),
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user.planStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (user.isTrialActive) const ProBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getPlanTitle(user),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getPlanDescription(user),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Trial Progress or Subscription Info
          if (user.isTrialActive)
            const TrialProgressIndicator()
          else if (user.hasPaid)
            _buildSubscriptionInfo(user)
          else
            _buildFreeInfo(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfo(app_user.User user) {
    final formatter = DateFormat('MMM dd, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user.subscriptionStart != null)
          _buildInfoRow('Started', formatter.format(user.subscriptionStart!)),
        if (user.subscriptionEnd != null)
          _buildInfoRow('Renews', formatter.format(user.subscriptionEnd!)),
        if (user.subscriptionStatus != null)
          _buildInfoRow('Status', user.subscriptionStatus!.toUpperCase()),
      ],
    );
  }

  Widget _buildFreeInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Plan Type', 'Free'),
        _buildInfoRow('Features', 'Limited usage'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageOverview(BuildContext context,
      FeatureGateService featureGateService, app_user.User user) {
    if (user.hasActiveSubscription) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pro Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureRow(Icons.camera_alt, 'Receipt Scanning', 'Unlimited'),
            _buildFeatureRow(Icons.analytics, 'AI Insights', 'Unlimited'),
            _buildFeatureRow(
                Icons.bar_chart, 'Advanced Analytics', 'Unlimited'),
            _buildFeatureRow(Icons.email, 'Email Notifications', 'Enabled'),
            _buildFeatureRow(Icons.backup, 'Data Backup', 'Automatic'),
          ],
        ),
      );
    }

    final usageStats = featureGateService.getUsageStats();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usage This Month',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...usageStats.entries.map((entry) {
            final stats = entry.value;
            if (stats.limit == null) return const SizedBox.shrink();

            return _buildUsageRow(stats);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageRow(FeatureUsageStats stats) {
    final percent = stats.usagePercent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stats.featureName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${stats.currentUsage}/${stats.limit}',
                style: TextStyle(
                  color: stats.isAtLimit ? Colors.red : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey[200],
            color: stats.isAtLimit
                ? Colors.red
                : stats.isNearLimit
                    ? Colors.orange
                    : Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlans(
      BuildContext context, SubscriptionService subscriptionService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upgrade to Pro',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...SubscriptionService.availablePlans
            .where((plan) => plan.id != 'scan_pack')
            .map((plan) {
          return _buildPlanCard(context, plan, subscriptionService);
        }).toList(),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan,
      SubscriptionService subscriptionService) {
    final isRecommended = plan.id == 'annual';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isRecommended ? Border.all(color: Colors.blue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isRecommended)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.displayPrice,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          ...plan.features.map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(feature),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _subscribeToPlan(plan.id, subscriptionService),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRecommended ? Colors.blue : Colors.grey[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Subscribe to ${plan.displayInterval}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionManagement(BuildContext context,
      SubscriptionService subscriptionService, app_user.User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () => _manageSubscription(subscriptionService),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Manage Subscription'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () => _cancelSubscription(subscriptionService),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red,
              ),
              child: const Text('Cancel Subscription'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribeToPlan(
      String planId, SubscriptionService subscriptionService) async {
    setState(() => _isLoading = true);

    try {
      bool success = false;

      switch (planId) {
        case 'monthly':
          success = await subscriptionService.subscribeToProMonthly();
          break;
        case 'annual':
          success = await subscriptionService.subscribeToProAnnual();
          break;
      }

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start subscription process'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _manageSubscription(
      SubscriptionService subscriptionService) async {
    setState(() => _isLoading = true);

    try {
      final success = await subscriptionService.launchCustomerPortal();

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open subscription management'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelSubscription(
      SubscriptionService subscriptionService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your subscription? You will lose access to Pro features at the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final success = await subscriptionService.cancelSubscription();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Subscription canceled successfully'
                  : 'Failed to cancel subscription',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getPlanColor(app_user.User user) {
    if (user.hasActiveSubscription && user.hasPaid) return Colors.purple;
    if (user.isTrialActive) return Colors.orange;
    return Colors.grey;
  }

  IconData _getPlanIcon(app_user.User user) {
    if (user.hasActiveSubscription && user.hasPaid) return Icons.star;
    if (user.isTrialActive) return Icons.access_time;
    return Icons.account_circle;
  }

  String _getPlanTitle(app_user.User user) {
    if (user.hasActiveSubscription && user.hasPaid) return 'Pro Subscriber';
    if (user.isTrialActive) return 'Pro Trial Active';
    return 'Free Plan';
  }

  String _getPlanDescription(app_user.User user) {
    if (user.hasActiveSubscription && user.hasPaid) {
      return 'You have full access to all Pro features';
    }
    if (user.isTrialActive) {
      return 'Enjoying unlimited Pro features during your trial';
    }
    return 'Limited features - upgrade to unlock more';
  }
}
