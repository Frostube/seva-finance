import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/feature_gate_service.dart';
import '../services/subscription_service.dart';
import '../services/user_service.dart';
import '../models/feature_flag.dart';
import '../theme/app_theme.dart';

class ProGate extends StatefulWidget {
  final String feature;
  final Widget child;
  final Widget? fallback;
  final bool showUpgradePrompt;
  final String? customMessage;

  const ProGate({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
    this.showUpgradePrompt = true,
    this.customMessage,
  });

  @override
  State<ProGate> createState() => _ProGateState();
}

class _ProGateState extends State<ProGate> {
  @override
  Widget build(BuildContext context) {
    return Consumer<FeatureGateService>(
      builder: (context, featureGateService, child) {
        final accessResult =
            featureGateService.checkFeatureAccess(widget.feature);

        if (accessResult.hasAccess) {
          return widget.child;
        }

        // Show fallback if provided
        if (widget.fallback != null) {
          return widget.fallback!;
        }

        // Show upgrade prompt
        if (widget.showUpgradePrompt) {
          return Center(
            child: _buildUpgradePrompt(context, accessResult),
          );
        }

        // Default: show empty container
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildUpgradePrompt(
      BuildContext context, FeatureAccessResult accessResult) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 12),
          Text(
            accessResult.featureFlag?.name ?? 'Premium Feature',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.customMessage ?? accessResult.statusMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (accessResult.isProOnly)
            _buildProOnlyPrompt(context)
          else if (accessResult.isLimitExceeded)
            _buildLimitExceededPrompt(context, accessResult),
        ],
      ),
    );
  }

  Widget _buildProOnlyPrompt(BuildContext context) {
    return Column(
      children: [
        Text(
          'Upgrade to Pro to unlock this feature',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            // TODO: Navigate to upgrade screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Upgrade screen coming soon!')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Upgrade to Pro'),
        ),
      ],
    );
  }

  Widget _buildLimitExceededPrompt(
      BuildContext context, FeatureAccessResult accessResult) {
    return Column(
      children: [
        Text(
          'You\'ve used ${accessResult.currentUsage}/${accessResult.limit} this month',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  final subscriptionService =
                      Provider.of<SubscriptionService>(context, listen: false);
                  subscriptionService.buyScanPack();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Buy More'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to upgrade screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Upgrade screen coming soon!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Upgrade'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Helper widget for showing feature usage
class FeatureUsageIndicator extends StatelessWidget {
  final String feature;
  final Widget child;

  const FeatureUsageIndicator({
    super.key,
    required this.feature,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FeatureGateService>(
      builder: (context, featureGateService, child) {
        final accessResult = featureGateService.checkFeatureAccess(feature);

        if (!accessResult.hasAccess || accessResult.limit == null) {
          return this.child;
        }

        return Stack(
          children: [
            this.child,
            if (accessResult.limit != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getUsageColor(
                        accessResult.currentUsage, accessResult.limit!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${accessResult.currentUsage}/${accessResult.limit}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _getUsageColor(int current, int limit) {
    final percent = current / limit;
    if (percent >= 1.0) return Colors.red;
    if (percent >= 0.8) return Colors.orange;
    return Colors.green;
  }
}

// Helper widget for showing Pro badge
class ProBadge extends StatelessWidget {
  final bool showOnlyIfPro;

  const ProBadge({
    super.key,
    this.showOnlyIfPro = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FeatureGateService>(
      builder: (context, featureGateService, child) {
        final userService = Provider.of<UserService>(context, listen: false);
        final user = userService.currentUser;

        if (user == null) return const SizedBox.shrink();

        final hasActiveSubscription = user.hasActiveSubscription;

        if (showOnlyIfPro && !hasActiveSubscription) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasActiveSubscription
                  ? [Colors.purple, Colors.blue]
                  : [Colors.orange, Colors.red],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasActiveSubscription ? Icons.star : Icons.access_time,
                color: Colors.white,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                hasActiveSubscription ? 'PRO' : 'TRIAL',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
