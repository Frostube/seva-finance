const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Budget Watcher Cloud Function
 * Runs hourly to check budget thresholds and send notifications
 */
exports.budgetWatcher = functions.pubsub
  .schedule('every 1 hours')
  .timeZone('America/New_York') // Adjust to your timezone
  .onRun(async (context) => {
    console.log('Budget Watcher function started');
    
    try {
      // Get all users with push notifications enabled
      const usersSnapshot = await db.collection('users')
        .where('pushEnabled', '==', true)
        .get();
      
      console.log(`Found ${usersSnapshot.size} users with push notifications enabled`);
      
      const notifications = [];
      
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const pushToken = userData.pushToken;
        const preferences = userData.notificationPreferences || {};
        
        if (!pushToken || !preferences.budgetAlerts) {
          continue;
        }
        
        const budgetThreshold = preferences.budgetThreshold || 0.8;
        
        try {
          // Get user's current month analytics
          const analyticsDoc = await db.collection('analytics').doc(userId).get();
          if (!analyticsDoc.exists) continue;
          
          const analytics = analyticsDoc.data();
          const mtdByCategory = analytics.mtdByCategory || {};
          
          // Get user's budgets
          const budgetsSnapshot = await db.collection('users').doc(userId)
            .collection('budgets').get();
          
          for (const budgetDoc of budgetsSnapshot.docs) {
            const budget = budgetDoc.data();
            const category = budget.category;
            const budgetAmount = budget.amount;
            const spent = mtdByCategory[category] || 0;
            const percentage = spent / budgetAmount;
            
            // Check if threshold is exceeded
            if (percentage >= budgetThreshold) {
              notifications.push({
                token: pushToken,
                notification: {
                  title: 'Budget Alert 📊',
                  body: `You've used ${Math.round(percentage * 100)}% of your ${category} budget (\$${spent.toFixed(0)} of \$${budgetAmount.toFixed(0)})`,
                },
                data: {
                  type: 'budget_alert',
                  category: category,
                  percentage: percentage.toString(),
                  click_action: 'https://seva-finance-app.web.app/dashboard?highlight=budget&category=' + encodeURIComponent(category),
                  priority: percentage >= 0.9 ? 'high' : 'normal',
                }
              });
            }
          }
        } catch (error) {
          console.error(`Error processing user ${userId}:`, error);
        }
      }
      
      // Send all notifications
      if (notifications.length > 0) {
        console.log(`Sending ${notifications.length} budget notifications`);
        
        for (const notification of notifications) {
          try {
            await messaging.send(notification);
          } catch (error) {
            console.error('Error sending notification:', error);
          }
        }
      }
      
      console.log('Budget Watcher function completed');
      return null;
    } catch (error) {
      console.error('Budget Watcher function error:', error);
      throw error;
    }
  });

/**
 * Bill Reminder Cloud Function
 * Runs daily to check for upcoming recurring transactions
 */
exports.billReminder = functions.pubsub
  .schedule('every day 09:00')
  .timeZone('America/New_York') // Adjust to your timezone
  .onRun(async (context) => {
    console.log('Bill Reminder function started');
    
    try {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(0, 0, 0, 0);
      
      const dayAfterTomorrow = new Date(tomorrow);
      dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 1);
      
      // Get all users with push notifications enabled
      const usersSnapshot = await db.collection('users')
        .where('pushEnabled', '==', true)
        .get();
      
      console.log(`Found ${usersSnapshot.size} users with push notifications enabled`);
      
      const notifications = [];
      
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const pushToken = userData.pushToken;
        const preferences = userData.notificationPreferences || {};
        
        if (!pushToken || !preferences.billReminders) {
          continue;
        }
        
        try {
          // Get user's recurring transactions due tomorrow
          const recurringSnapshot = await db.collection('users').doc(userId)
            .collection('recurringTransactions')
            .where('nextOccurrence', '>=', admin.firestore.Timestamp.fromDate(tomorrow))
            .where('nextOccurrence', '<', admin.firestore.Timestamp.fromDate(dayAfterTomorrow))
            .get();
          
          for (const recurringDoc of recurringSnapshot.docs) {
            const recurring = recurringDoc.data();
            
            notifications.push({
              token: pushToken,
              notification: {
                title: 'Bill Reminder 💳',
                body: `${recurring.description || recurring.category} is due tomorrow (\$${recurring.amount.toFixed(2)})`,
              },
              data: {
                type: 'bill_reminder',
                recurringId: recurringDoc.id,
                amount: recurring.amount.toString(),
                click_action: 'https://seva-finance-app.web.app/dashboard?highlight=bills&id=' + recurringDoc.id,
                priority: 'normal',
              }
            });
          }
        } catch (error) {
          console.error(`Error processing user ${userId}:`, error);
        }
      }
      
      // Send all notifications
      if (notifications.length > 0) {
        console.log(`Sending ${notifications.length} bill reminder notifications`);
        
        for (const notification of notifications) {
          try {
            await messaging.send(notification);
          } catch (error) {
            console.error('Error sending notification:', error);
          }
        }
      }
      
      console.log('Bill Reminder function completed');
      return null;
    } catch (error) {
      console.error('Bill Reminder function error:', error);
      throw error;
    }
  });

/**
 * Spending Alert Cloud Function
 * Checks for unusual spending patterns and sends alerts
 */
exports.spendingAlert = functions.pubsub
  .schedule('every 6 hours')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    console.log('Spending Alert function started');
    
    try {
      const today = new Date();
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      
      // Get all users with push notifications enabled
      const usersSnapshot = await db.collection('users')
        .where('pushEnabled', '==', true)
        .get();
      
      const notifications = [];
      
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const pushToken = userData.pushToken;
        const preferences = userData.notificationPreferences || {};
        
        if (!pushToken || !preferences.spendingAlerts) {
          continue;
        }
        
        try {
          // Get user's analytics
          const analyticsDoc = await db.collection('analytics').doc(userId).get();
          if (!analyticsDoc.exists) continue;
          
          const analytics = analyticsDoc.data();
          const dailyAverage = analytics.dailyAverage || 0;
          
          // Get today's spending
          const expensesSnapshot = await db.collection('users').doc(userId)
            .collection('expenses')
            .where('date', '>=', admin.firestore.Timestamp.fromDate(yesterday))
            .where('date', '<', admin.firestore.Timestamp.fromDate(today))
            .get();
          
          let todaySpending = 0;
          expensesSnapshot.forEach(doc => {
            todaySpending += doc.data().amount;
          });
          
          // Check if today's spending is significantly higher than average
          const threshold = dailyAverage * 1.5; // 50% above average
          if (todaySpending > threshold && todaySpending > 20) { // Minimum $20 to avoid small amount alerts
            const percentage = Math.round(((todaySpending - dailyAverage) / dailyAverage) * 100);
            
            notifications.push({
              token: pushToken,
              notification: {
                title: 'Spending Alert 💸',
                body: `Today's spending: \$${todaySpending.toFixed(0)} ↑ vs \$${dailyAverage.toFixed(0)} average (+${percentage}%)`,
              },
              data: {
                type: 'spending_alert',
                amount: todaySpending.toString(),
                average: dailyAverage.toString(),
                click_action: 'https://seva-finance-app.web.app/dashboard?highlight=expenses&date=' + today.toISOString().split('T')[0],
                priority: percentage > 100 ? 'high' : 'normal',
              }
            });
          }
        } catch (error) {
          console.error(`Error processing user ${userId}:`, error);
        }
      }
      
      // Send all notifications
      if (notifications.length > 0) {
        console.log(`Sending ${notifications.length} spending alert notifications`);
        
        for (const notification of notifications) {
          try {
            await messaging.send(notification);
          } catch (error) {
            console.error('Error sending notification:', error);
          }
        }
      }
      
      console.log('Spending Alert function completed');
      return null;
    } catch (error) {
      console.error('Spending Alert function error:', error);
      throw error;
    }
  });

/**
 * Test notification function for development
 */
exports.testNotification = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const userId = context.auth.uid;
  
  try {
    // Get user's push token
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();
    const pushToken = userData?.pushToken;
    
    if (!pushToken) {
      throw new functions.https.HttpsError('failed-precondition', 'User does not have push notifications enabled');
    }
    
    const message = {
      token: pushToken,
      notification: {
        title: 'Test Notification 🧪',
        body: 'This is a test notification from SevaFinance!',
      },
      data: {
        type: 'test',
        click_action: 'https://seva-finance-app.web.app/dashboard',
        priority: 'normal',
      }
    };
    
    await messaging.send(message);
    
    return { success: true, message: 'Test notification sent successfully' };
  } catch (error) {
    console.error('Error sending test notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send test notification');
  }
}); 