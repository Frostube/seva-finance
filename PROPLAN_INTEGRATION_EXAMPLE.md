# ProPlan Integration Example: Receipt Scanning

This document shows how to integrate the ProGate widget with your existing receipt scanning feature to implement usage limits and upgrade prompts.

## Step 1: Update the Expenses Screen FAB

Wrap the receipt scanning FloatingActionButton with ProGate to control access:

### Before (in `lib/screens/expenses_screen.dart`):
```dart
FloatingActionButton.extended(
  heroTag: 'scan_receipt',
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OcrScreen()),
    );
    if (result == true) {
      _refreshScreen();
    }
  },
  // ... rest of FAB
)
```

### After (Updated `lib/screens/expenses_screen.dart`):
```dart
// Add this import at the top
import '../widgets/pro_gate.dart';

// Then wrap your FAB:
ProGate(
  featureKey: 'receipt_scanning', // This matches the feature flag
  child: FloatingActionButton.extended(
    heroTag: 'scan_receipt',
    onPressed: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OcrScreen()),
      );
      if (result == true) {
        _refreshScreen();
      }
    },
    backgroundColor: Colors.transparent,
    elevation: 0,
    label: const Row(
      children: [
        Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 16),
        SizedBox(width: 8),
        Text(
          'Scan Receipt',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  ),
)
```

## Step 2: Add Usage Tracking to OCR Process

In `lib/screens/review_receipt_screen.dart`, track feature usage when a receipt is successfully processed:

### Add to the save expense method:
```dart
// Add this import at the top
import 'package:provider/provider.dart';
import '../services/feature_gate_service.dart';

// In the _saveExpense method, after successful save:
Future<void> _saveExpense() async {
  // ... existing validation code ...

  try {
    // ... existing expense creation and save code ...
    
    await expenseService.addExpense(newExpense);

    // 🎯 NEW: Track feature usage for ProPlan
    final featureGateService = Provider.of<FeatureGateService>(context, listen: false);
    await featureGateService.incrementUsage('receipt_scanning');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense saved from receipt!', style: GoogleFonts.inter())
        ),
      );
      Navigator.of(context).pop(true); // OCR Screen
      Navigator.of(context).pop(true); // Expenses Screen
    }
  } catch (e) {
    // ... existing error handling ...
  }
}
```

## Step 3: Show Usage Status in OCR Screen

Add a usage indicator to the OCR screen to show remaining scans:

### Add to `lib/screens/ocr_screen.dart`:
```dart
// Add these imports at the top
import 'package:provider/provider.dart';
import '../services/feature_gate_service.dart';
import '../services/user_service.dart';
import '../widgets/trial_banner.dart';

// Add this method to _OcrScreenState:
Widget _buildUsageIndicator() {
  return Consumer2<FeatureGateService, UserService>(
    builder: (context, featureGateService, userService, child) {
      final user = userService.currentUser;
      if (user == null) return const SizedBox();

      final accessResult = featureGateService.checkFeatureAccess('receipt_scanning');
      
      if (user.hasActiveSubscription) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.purple, size: 16),
              const SizedBox(width: 8),
              Text(
                'Pro: Unlimited Receipt Scans',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
        );
      }

      if (accessResult.featureFlag != null && accessResult.limit != null) {
        final remaining = accessResult.limit! - accessResult.currentUsage;
        final isLow = remaining <= 1;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isLow ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLow ? Colors.orange.withOpacity(0.3) : Colors.blue.withOpacity(0.3)
            ),
          ),
          child: Row(
            children: [
              Icon(
                isLow ? Icons.warning : Icons.camera_alt,
                color: isLow ? Colors.orange.shade700 : Colors.blue.shade700,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '$remaining of ${accessResult.limit} scans remaining this month',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isLow ? Colors.orange.shade700 : Colors.blue.shade700,
                ),
              ),
            ],
          ),
        );
      }

      return const SizedBox();
    },
  );
}
```

### Then add it to your build method:
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      // ... existing app bar
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 🎯 NEW: Add usage indicator at the top
            _buildUsageIndicator(),
            
            // ... rest of your existing widgets
            if (_selectedImage == null && _selectedPdf == null && _pdfBytes == null && !_isProcessingPdf)
              Expanded(
                child: Column(
                  // ... existing content
                ),
              ),
            // ... rest of build method
          ],
        ),
      ),
    ),
  );
}
```

## Step 4: Add Trial Banner to Main Screen

Show trial status prominently on the main dashboard:

### Add to `lib/screens/main_screen.dart`:
```dart
// Add these imports
import '../widgets/trial_banner.dart';
import '../services/user_service.dart';

// In your main screen body, add the trial banner:
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // 🎯 NEW: Trial banner at the top
        Consumer<UserService>(
          builder: (context, userService, child) {
            final user = userService.currentUser;
            if (user != null && user.isTrialActive) {
              return TrialBanner(user: user);
            }
            return const SizedBox();
          },
        ),
        
        // Your existing main content
        Expanded(
          child: _screens[_selectedIndex],
        ),
      ],
    ),
    // ... rest of scaffold
  );
}
```

## Step 5: Add Plan Management to Settings

Add a "Manage Subscription" option to your account/settings screen:

### Add to your account screen:
```dart
ListTile(
  leading: const Icon(Icons.star),
  title: const Text('Manage Subscription'),
  subtitle: Consumer<UserService>(
    builder: (context, userService, child) {
      final user = userService.currentUser;
      if (user?.hasActiveSubscription == true) {
        return const Text('Pro Plan Active');
      } else if (user?.isTrialActive == true) {
        return const Text('Trial Active');
      }
      return const Text('Free Plan');
    },
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlanManagementScreen(),
      ),
    );
  },
),
```

## Result: Complete ProPlan Integration

After implementing these changes:

1. **Feature Gate Protection**: Receipt scanning is limited to 3 scans/month for free users
2. **Usage Tracking**: Each successful receipt scan decrements the usage counter
3. **Visual Indicators**: Users see their remaining scan count
4. **Upgrade Prompts**: When limit is reached, ProGate shows upgrade options
5. **Trial Benefits**: Trial users get unlimited scans during their 14-day trial
6. **Subscription Management**: Easy access to plan management from settings

### Testing the Integration

1. Create a new user → Gets 14-day trial with unlimited scans
2. Wait for trial to expire (or manually set trial end date in past)
3. Try to scan receipts → Should work for 3 scans, then show upgrade prompt
4. Subscribe to Pro → Unlimited scans resume

This creates a smooth freemium experience that encourages upgrades while providing real value in the free tier! 