# Browser Push Notifications Setup Guide

## Overview

This guide explains how to set up and deploy the Browser Push Notifications feature for SevaFinance. This feature sends timely, actionable alerts to users' browsers even when the app isn't open.

## Features Implemented

✅ **Service Worker & FCM Integration**
- Updated `firebase-messaging-sw.js` with click action handling
- Foreground message handling in web app
- VAPID key configuration

✅ **Permission & Token Management**
- Push notification service with permission requests
- Token storage in Firestore
- Settings UI with toggles and preferences

✅ **Cloud Functions**
- Budget watcher (hourly checks)
- Bill reminder (daily checks)
- Spending alert (6-hourly checks)
- Test notification function

✅ **Settings UI**
- Notification preferences screen
- Budget threshold configuration
- Individual notification type toggles

✅ **Routing Handler**
- URL parameter handling for notification clicks
- Deep linking to relevant screens

## Setup Instructions

### 1. Firebase Configuration

#### Generate VAPID Keys
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **seva-finance-app** project
3. Click the **⚙️ Settings** gear icon → **Project settings**
4. Go to **Cloud Messaging** tab
5. Scroll down to **Web configuration** section
6. If you see "No key pairs", click **Generate key pair**
7. Copy the **Key pair** value (starts with `BA...` or `BB...`)

#### Update VAPID Key ⚠️ CRITICAL STEP
Replace the placeholder in `lib/services/push_notification_service.dart`:
```dart
// BEFORE (placeholder - won't work):
static const String _vapidKey = 'REPLACE_WITH_YOUR_ACTUAL_VAPID_KEY_FROM_FIREBASE_CONSOLE';

// AFTER (your real key from Firebase):
static const String _vapidKey = 'BA1Yzs7_your_actual_key_here_XYZ123';
```

**🚨 Without this step, you'll get "applicationServerKey is not valid" errors!**

### 2. Firestore Security Rules

Update your `firestore.rules` to allow push token storage:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow push token updates
      allow update: if request.auth != null && request.auth.uid == userId &&
        resource.data.keys().hasAny(['pushToken', 'pushEnabled', 'tokenUpdatedAt', 'notificationPreferences']);
    }
  }
}
```

### 3. Deploy Cloud Functions

#### Install Dependencies
```bash
cd functions
npm install
```

#### Configure Functions
Update timezone in `functions/index.js` if needed:
```javascript
.timeZone('America/New_York') // Change to your timezone
```

Update the app URL in click actions:
```javascript
click_action: 'https://YOUR-ACTUAL-DOMAIN.web.app/dashboard?highlight=budget'
```

#### Deploy
```bash
firebase deploy --only functions
```

### 4. Test the Implementation

#### Enable Notifications
1. Go to Account → Notification Settings
2. Toggle "Push Notifications" ON
3. Allow permission when prompted
4. Configure preferences (budget threshold, notification types)

#### Test Notifications
1. Use the "Send Test Notification" button in settings
2. Check that notifications appear in the notifications screen
3. For browser push testing, trigger the cloud functions manually

#### Manual Cloud Function Testing
```bash
# Test budget watcher
firebase functions:shell
> budgetWatcher()

# Test bill reminder  
> billReminder()

# Test spending alert
> spendingAlert()
```

### 5. Production Deployment

#### Update URLs
Replace all instances of `seva-finance-app.web.app` in:
- `functions/index.js` (click_action URLs)
- `web/firebase-messaging-sw.js` (if hardcoded)

#### Set Proper Timezone
Update timezone in all Cloud Functions to match your target audience.

#### Enable Functions Scheduler
Ensure Cloud Scheduler API is enabled in Google Cloud Console.

## Usage Examples

### Budget Alert Notification
- **Trigger**: User spending reaches 80% of category budget
- **Timing**: Checked hourly
- **Click Action**: Opens dashboard with budget section highlighted

### Bill Reminder Notification  
- **Trigger**: Recurring transaction due tomorrow
- **Timing**: Daily at 9 AM
- **Click Action**: Opens dashboard with bills highlighted

### Spending Alert Notification
- **Trigger**: Daily spending 50% above user's average
- **Timing**: Checked every 6 hours
- **Click Action**: Opens expenses view for that day

## User Data Model

The notifications system stores this data structure in Firestore:

```javascript
// /users/{userId}
{
  pushToken: "fcm_token_string",
  pushEnabled: true,
  tokenUpdatedAt: timestamp,
  platform: "web",
  notificationPreferences: {
    budgetThreshold: 0.8,      // 80% threshold
    billReminders: true,
    budgetAlerts: true,
    spendingAlerts: true,
    updatedAt: timestamp
  }
}
```

## Troubleshooting

### Notifications Not Appearing
1. Check browser permissions: `chrome://settings/content/notifications`
2. Verify VAPID key is correct
3. Check Firebase console for token registration
4. Test foreground vs background message handling

### Cloud Functions Not Triggering
1. Check Cloud Scheduler is enabled
2. Verify function deployment: `firebase functions:list`
3. Check function logs: `firebase functions:log`
4. Ensure users have `pushEnabled: true` in Firestore

### Click Actions Not Working
1. Verify service worker is registered
2. Check click_action URLs are correct
3. Test URL parameter parsing
4. Verify message passing between service worker and app

### Development vs Production
- Use Firebase emulator suite for local testing
- Test with actual FCM tokens in development
- Monitor Cloud Function execution in Firebase console

## Security Considerations

1. **Token Management**: Tokens are automatically removed when notifications are disabled
2. **Permission Validation**: All Cloud Functions verify user authentication
3. **Rate Limiting**: Functions have built-in error handling and user filtering
4. **Data Privacy**: Only essential data is included in notification payloads

## Performance Optimization

1. **Batch Processing**: Cloud Functions process multiple users efficiently
2. **Error Handling**: Failed notifications don't block other users
3. **Caching**: User preferences are cached for faster processing
4. **Scheduling**: Functions run at optimal times to reduce resource usage

## Monitoring & Analytics

Monitor your push notification performance:

1. **Firebase Console**: Message delivery rates
2. **Cloud Functions Logs**: Execution success/failure
3. **User Engagement**: Track notification click-through rates
4. **Error Monitoring**: Set up alerts for function failures

## Future Enhancements

Possible improvements for future versions:

1. **Advanced Scheduling**: User-specific timing preferences
2. **Rich Notifications**: Images and action buttons
3. **Notification History**: Track user notification interactions
4. **A/B Testing**: Different notification formats
5. **Smart Batching**: Combine multiple alerts into single notification

## Support

For issues with this implementation:

1. Check Firebase Console for error logs
2. Verify Firestore data structure matches expectations
3. Test in different browsers and devices
4. Use browser developer tools to debug service worker issues

---

*This implementation follows the specifications provided and includes all required functionality for browser push notifications in the SevaFinance app.* 