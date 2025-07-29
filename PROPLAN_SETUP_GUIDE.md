# ProPlan Integration Setup Guide

## 🎉 Setup Complete!

Your SevaFinance app has been successfully set up with the ProPlan freemium integration! Here's what's been implemented:

## ✅ Features Implemented

### 1. **Core ProPlan Features**
- ✅ 14-day free trial (auto-granted to new users)
- ✅ Feature gating system with usage limits
- ✅ Stripe integration for subscriptions
- ✅ Trial expiry automation
- ✅ Monthly usage resets
- ✅ Plan management dashboard

### 2. **Data Models**
- ✅ Enhanced User model with ProPlan fields
- ✅ FeatureFlag system for feature control
- ✅ Hive adapters for local storage

### 3. **Core Services**
- ✅ UserService (auto-grants trials, manages subscriptions)
- ✅ FeatureGateService (feature access control)
- ✅ SubscriptionService (Stripe integration)

### 4. **UI Components**
- ✅ ProGate widget (feature wrapper with upgrade prompts)
- ✅ Trial banners (countdown, progress indicators)
- ✅ Plan management screen (subscription dashboard)

### 5. **Cloud Functions**
- ✅ Stripe webhook handlers
- ✅ Trial expiry automation
- ✅ Monthly usage reset scheduler

## 🔧 Next Steps (Required)

### 1. **Stripe Configuration**
1. Create a Stripe account at https://stripe.com
2. Get your API keys from the Stripe dashboard
3. Update `functions/index.js` with your Stripe keys:
   ```javascript
   const stripe = require('stripe')('sk_test_your_secret_key_here');
   ```

### 2. **Create Stripe Products**
Create these products in your Stripe dashboard:
- **Pro Monthly**: $4.99/month
- **Pro Annual**: $49/year  
- **Scan Pack**: $0.99 one-time

### 3. **Update Price IDs**
Replace the placeholder price IDs in `lib/services/subscription_service.dart`:
```dart
// Replace these with your actual Stripe Price IDs
static const String _proMonthlyPriceId = 'price_your_monthly_price_id';
static const String _proAnnualPriceId = 'price_your_annual_price_id';
static const String _scanPackPriceId = 'price_your_scan_pack_price_id';
```

### 4. **Deploy Firebase Functions**
```bash
cd functions
npm install
firebase deploy --only functions
```

### 5. **Configure Stripe Webhook**
1. In your Stripe dashboard, go to Webhooks
2. Add endpoint: `https://your-project-id.cloudfunctions.net/stripeWebhook`
3. Select these events:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`

## 🏗️ Architecture Overview

### Trial System
- New users automatically get 14-day Pro trial
- Trial status tracked in user model
- Automatic Pro feature access during trial

### Feature Gating
- Features defined in FeatureFlag model
- ProGate widget controls access
- Usage tracking for free tier limits

### Subscription Flow
1. User clicks upgrade → Stripe checkout
2. Webhook updates user status
3. Feature gates automatically adjust

## 📱 Usage in Your App

### 1. **Wrap Features with ProGate**
```dart
ProGate(
  featureKey: 'receipt_scanning',
  child: YourFeatureWidget(),
)
```

### 2. **Show Trial Banners**
```dart
// In your main screen
if (user.isTrialActive) 
  TrialBanner(user: user)
```

### 3. **Navigate to Plan Management**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PlanManagementScreen(),
  ),
);
```

## 🔥 Predefined Feature Gates

Ready-to-use feature gates:
- **receipt_scanning**: 3 scans/month (free)
- **ai_insights**: Pro only
- **advanced_analytics**: Pro only
- **csv_export**: 1 export/month (free)
- **custom_categories**: Pro only
- **budget_templates**: Pro only

## 🚀 Test Your Implementation

1. **Sign up a new user** → Should auto-get 14-day trial
2. **Try gated features** → Should show Pro access during trial
3. **Check plan management** → Should show trial countdown
4. **Test upgrade flow** → Should redirect to Stripe checkout

## 📊 Analytics Events

The system automatically tracks:
- `trial_granted`
- `subscription_activated`
- `subscription_cancelled`
- `feature_gate_triggered`
- `upgrade_prompt_shown`

## 🎯 Feature Flags Configuration

Feature flags are automatically created with these defaults:
- **Receipt Scanning**: 3/month free, unlimited Pro
- **AI Insights**: Pro only
- **Advanced Analytics**: Pro only
- **CSV Export**: 1/month free, unlimited Pro
- **Custom Categories**: Pro only
- **Budget Templates**: Pro only

## 🔧 Customization

### Adding New Features
1. Add to `FeatureFlags.getDefaultFeatureFlags()`
2. Wrap UI with `ProGate` widget
3. Features auto-sync to Firestore

### Changing Limits
Update the feature flags in `lib/models/feature_flag.dart`

### Custom Upgrade Prompts
Modify the `ProGate` widget in `lib/widgets/pro_gate.dart`

## 🚨 Important Notes

1. **Stripe Test Mode**: Start with test keys for development
2. **Webhooks**: Essential for subscription status updates
3. **Trial Expiry**: Runs daily via Cloud Functions
4. **Usage Reset**: Monthly reset via Cloud Functions

## 📞 Support

If you encounter any issues:
1. Check Firebase Functions logs
2. Verify Stripe webhook configuration
3. Ensure all price IDs are correctly set
4. Test with Stripe test cards

## 🎉 You're Ready!

Your ProPlan integration is complete and ready for testing! The system will automatically:
- Grant 14-day trials to new users
- Track usage and enforce limits
- Handle subscription upgrades
- Manage trial expiry

Start by creating a new user account to see the trial system in action! 