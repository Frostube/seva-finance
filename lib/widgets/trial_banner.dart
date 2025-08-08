import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../services/subscription_service.dart';

class TrialBanner extends StatelessWidget {
  final EdgeInsets? margin;
  final bool showOnlyWhenNearExpiry;

  const TrialBanner({
    super.key,
    this.margin,
    this.showOnlyWhenNearExpiry = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final user = userService.currentUser;
        if (user == null) return const SizedBox.shrink();

        // Only show for trial users
        if (!user.isTrialActive) return const SizedBox.shrink();

        final daysRemaining = user.trialDaysRemaining;

        // If showOnlyWhenNearExpiry is true, only show when 2 or fewer days remain
        if (showOnlyWhenNearExpiry && daysRemaining > 2) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: margin ?? const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getBrandGradient(daysRemaining),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getIcon(daysRemaining),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getTitle(daysRemaining),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getMessage(daysRemaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to learn more about features
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Learn more coming soon!')),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: const Text('Learn More'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final subscriptionService =
                          Provider.of<SubscriptionService>(context,
                              listen: false);
                      subscriptionService.subscribeToProMonthly();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                    child: const Text('Upgrade to Pro'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<Color> _getBrandGradient(int daysRemaining) {
    // Keep brand greens; only add subtle red tint for last day
    if (daysRemaining <= 1) {
      return [const Color(0xFF8B1D1D), const Color(0xFFB3261E)]; // critical
    }
    if (daysRemaining <= 3) {
      return [const Color(0xFF1B4332), const Color(0xFF2E7D32)];
    }
    return [const Color(0xFF1B4332), const Color(0xFF4CAF50)];
  }

  IconData _getIcon(int daysRemaining) {
    if (daysRemaining <= 1) {
      return Icons.warning;
    } else if (daysRemaining <= 3) {
      return Icons.access_time;
    } else {
      return Icons.star;
    }
  }

  String _getTitle(int daysRemaining) {
    if (daysRemaining <= 0) {
      return 'Trial Expired';
    } else if (daysRemaining == 1) {
      return 'Trial Ends Tomorrow';
    } else if (daysRemaining <= 3) {
      return 'Trial Ending Soon';
    } else {
      return 'Pro Trial Active';
    }
  }

  String _getMessage(int daysRemaining) {
    if (daysRemaining <= 0) {
      return 'Your 14-day trial has ended. Upgrade to Pro to continue enjoying unlimited features.';
    } else if (daysRemaining == 1) {
      return 'Your 14-day trial ends tomorrow. Lock in Pro to keep unlimited scans & AI insights.';
    } else if (daysRemaining <= 3) {
      return 'Your 14-day trial ends in $daysRemaining days. Upgrade now to avoid interruption.';
    } else {
      return 'You have $daysRemaining days left to enjoy unlimited Pro features.';
    }
  }
}

// Compact version for smaller spaces
class CompactTrialBanner extends StatelessWidget {
  const CompactTrialBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final user = userService.currentUser;
        if (user == null || !user.isTrialActive) return const SizedBox.shrink();

        final daysRemaining = user.trialDaysRemaining;

        // Only show when 3 or fewer days remain
        if (daysRemaining > 3) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: daysRemaining <= 1 ? Colors.red : Colors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                daysRemaining <= 1 ? Icons.warning : Icons.access_time,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                daysRemaining <= 1
                    ? 'Trial ends tomorrow'
                    : 'Trial ends in $daysRemaining days',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final subscriptionService =
                      Provider.of<SubscriptionService>(context, listen: false);
                  subscriptionService.subscribeToProMonthly();
                },
                child: const Text(
                  'Upgrade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Trial progress indicator
class TrialProgressIndicator extends StatelessWidget {
  const TrialProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final user = userService.currentUser;
        if (user == null || !user.isTrialActive) return const SizedBox.shrink();

        final daysRemaining = user.trialDaysRemaining;
        final progress = (14 - daysRemaining) / 14;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trial Progress',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  '$daysRemaining days left',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            daysRemaining <= 3 ? Colors.red : Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: daysRemaining <= 3 ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 4),
            Text(
              'Day ${14 - daysRemaining} of 14',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        );
      },
    );
  }
}
