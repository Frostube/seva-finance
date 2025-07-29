const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe?.secret_key || process.env.STRIPE_SECRET_KEY);

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

// ============= STRIPE INTEGRATION FUNCTIONS =============

/**
 * Create Stripe Checkout Session
 */
exports.createCheckoutSession = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const { priceId, mode, successUrl, cancelUrl, customerEmail } = data;

  if (!priceId || !mode) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
  }

  try {
    console.log(`Creating checkout session for user ${userId}, price ${priceId}, mode ${mode}`);

    // Check if customer already exists
    let customerId = null;
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (userDoc.exists) {
      const userData = userDoc.data();
      customerId = userData.stripeCustomerId;
    }

    // Create customer if doesn't exist
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: customerEmail,
        metadata: {
          userId: userId,
        },
      });
      customerId = customer.id;

      // Save customer ID to user document
      await db.collection('users').doc(userId).update({
        stripeCustomerId: customerId,
      });

      console.log(`Created new Stripe customer ${customerId} for user ${userId}`);
    }

    const sessionParams = {
      customer: customerId,
      payment_method_types: ['card'],
      mode: mode,
      success_url: successUrl || 'https://your-app.com/success?session_id={CHECKOUT_SESSION_ID}',
      cancel_url: cancelUrl || 'https://your-app.com/cancel',
      metadata: {
        userId: userId,
      },
    };

    if (mode === 'subscription') {
      sessionParams.line_items = [{
        price: priceId,
        quantity: 1,
      }];
      sessionParams.subscription_data = {
        metadata: {
          userId: userId,
        },
      };
    } else {
      sessionParams.line_items = [{
        price: priceId,
        quantity: 1,
      }];
    }

    const session = await stripe.checkout.sessions.create(sessionParams);

    console.log(`Created checkout session ${session.id} for user ${userId}`);

    return {
      sessionId: session.id,
      url: session.url,
    };
  } catch (error) {
    console.error('Error creating checkout session:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create checkout session');
  }
});

/**
 * Create Customer Portal Session
 */
exports.createCustomerPortalSession = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { customerId, returnUrl } = data;

  if (!customerId) {
    throw new functions.https.HttpsError('invalid-argument', 'Customer ID is required');
  }

  try {
    console.log(`Creating customer portal session for customer ${customerId}`);

    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: returnUrl || 'https://your-app.com/account',
    });

    console.log(`Created customer portal session ${session.id}`);

    return {
      url: session.url,
    };
  } catch (error) {
    console.error('Error creating customer portal session:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create customer portal session');
  }
});

/**
 * Cancel Subscription
 */
exports.cancelSubscription = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const { subscriptionId } = data;

  if (!subscriptionId) {
    throw new functions.https.HttpsError('invalid-argument', 'Subscription ID is required');
  }

  try {
    console.log(`Canceling subscription ${subscriptionId} for user ${userId}`);

    const subscription = await stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: true,
    });

    // Update user in Firestore
    await db.collection('users').doc(userId).update({
      subscriptionStatus: 'cancel_at_period_end',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Subscription ${subscriptionId} scheduled for cancellation`);

    return {
      success: true,
      subscription: {
        id: subscription.id,
        status: subscription.status,
        cancel_at_period_end: subscription.cancel_at_period_end,
        current_period_end: subscription.current_period_end,
      },
    };
  } catch (error) {
    console.error('Error canceling subscription:', error);
    throw new functions.https.HttpsError('internal', 'Failed to cancel subscription');
  }
});

/**
 * Stripe Webhook Handler
 */
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const endpointSecret = functions.config().stripe?.webhook_secret || process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  console.log(`Received Stripe webhook: ${event.type}`);

  try {
    switch (event.type) {
      case 'checkout.session.completed':
        await handleCheckoutSessionCompleted(event.data.object);
        break;

      case 'invoice.payment_succeeded':
        await handleInvoicePaymentSucceeded(event.data.object);
        break;

      case 'invoice.payment_failed':
        await handleInvoicePaymentFailed(event.data.object);
        break;

      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(event.data.object);
        break;

      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });
  } catch (error) {
    console.error('Error handling webhook:', error);
    res.status(500).send('Webhook handling failed');
  }
});

/**
 * Handle successful checkout session
 */
async function handleCheckoutSessionCompleted(session) {
  console.log('Handling checkout session completed:', session.id);

  const userId = session.metadata.userId;
  if (!userId) {
    console.error('No userId in checkout session metadata');
    return;
  }

  try {
    const updateData = {
      stripeCustomerId: session.customer,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (session.mode === 'subscription') {
      // Handle subscription
      const subscription = await stripe.subscriptions.retrieve(session.subscription);
      
      updateData.isPro = true;
      updateData.hasPaid = true;
      updateData.stripeSubscriptionId = subscription.id;
      updateData.subscriptionStatus = subscription.status;
      updateData.subscriptionStart = admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_start * 1000));
      updateData.subscriptionEnd = admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_end * 1000));

      console.log(`Activated subscription for user ${userId}: ${subscription.id}`);
    } else {
      // Handle one-time payment (e.g., scan pack)
      console.log(`Processed one-time payment for user ${userId}`);
      // Could increment scan count or other one-time benefits here
    }

    await db.collection('users').doc(userId).update(updateData);

    // Fire analytics event
    await db.collection('users').doc(userId).collection('analytics').add({
      event_name: session.mode === 'subscription' ? 'subscription_started' : 'one_time_payment',
      parameters: {
        session_id: session.id,
        amount_total: session.amount_total,
        currency: session.currency,
      },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

  } catch (error) {
    console.error('Error handling checkout session:', error);
  }
}

/**
 * Handle successful invoice payment
 */
async function handleInvoicePaymentSucceeded(invoice) {
  console.log('Handling invoice payment succeeded:', invoice.id);

  if (invoice.subscription) {
    const subscription = await stripe.subscriptions.retrieve(invoice.subscription);
    const customerId = subscription.customer;
    
    // Find user by customer ID
    const usersSnapshot = await db.collection('users')
      .where('stripeCustomerId', '==', customerId)
      .limit(1)
      .get();

    if (!usersSnapshot.empty) {
      const userId = usersSnapshot.docs[0].id;
      
      await db.collection('users').doc(userId).update({
        subscriptionStatus: subscription.status,
        subscriptionEnd: admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_end * 1000)),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Updated subscription for user ${userId} after successful payment`);
    }
  }
}

/**
 * Handle failed invoice payment
 */
async function handleInvoicePaymentFailed(invoice) {
  console.log('Handling invoice payment failed:', invoice.id);

  if (invoice.subscription) {
    const subscription = await stripe.subscriptions.retrieve(invoice.subscription);
    const customerId = subscription.customer;
    
    // Find user by customer ID
    const usersSnapshot = await db.collection('users')
      .where('stripeCustomerId', '==', customerId)
      .limit(1)
      .get();

    if (!usersSnapshot.empty) {
      const userId = usersSnapshot.docs[0].id;
      
      await db.collection('users').doc(userId).update({
        subscriptionStatus: subscription.status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Updated subscription status for user ${userId} after failed payment`);
      
      // Could send notification to user about failed payment
    }
  }
}

/**
 * Handle subscription updates
 */
async function handleSubscriptionUpdated(subscription) {
  console.log('Handling subscription updated:', subscription.id);

  const customerId = subscription.customer;
  
  // Find user by customer ID
  const usersSnapshot = await db.collection('users')
    .where('stripeCustomerId', '==', customerId)
    .limit(1)
    .get();

  if (!usersSnapshot.empty) {
    const userId = usersSnapshot.docs[0].id;
    
    const updateData = {
      subscriptionStatus: subscription.status,
      subscriptionEnd: admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_end * 1000)),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // If subscription is canceled or unpaid, disable Pro
    if (['canceled', 'unpaid', 'past_due'].includes(subscription.status)) {
      updateData.isPro = false;
    } else if (subscription.status === 'active') {
      updateData.isPro = true;
    }

    await db.collection('users').doc(userId).update(updateData);

    console.log(`Updated subscription for user ${userId}: ${subscription.status}`);
  }
}

/**
 * Handle subscription deletion
 */
async function handleSubscriptionDeleted(subscription) {
  console.log('Handling subscription deleted:', subscription.id);

  const customerId = subscription.customer;
  
  // Find user by customer ID
  const usersSnapshot = await db.collection('users')
    .where('stripeCustomerId', '==', customerId)
    .limit(1)
    .get();

  if (!usersSnapshot.empty) {
    const userId = usersSnapshot.docs[0].id;
    
    await db.collection('users').doc(userId).update({
      isPro: false,
      subscriptionStatus: 'canceled',
      stripeSubscriptionId: null,
      subscriptionEnd: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Deactivated subscription for user ${userId}`);
  }
}

/**
 * Trial Expiry Checker - runs daily
 */
exports.trialExpiryChecker = functions.pubsub
  .schedule('every day 00:00')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    console.log('Trial Expiry Checker function started');
    
    try {
      const now = new Date();
      const fourteenDaysAgo = new Date(now.getTime() - (14 * 24 * 60 * 60 * 1000));
      
      // Get users whose trial started 14+ days ago and haven't paid
      const usersSnapshot = await db.collection('users')
        .where('isPro', '==', true)
        .where('hasPaid', '==', false)
        .where('trialStart', '<=', admin.firestore.Timestamp.fromDate(fourteenDaysAgo))
        .get();
      
      console.log(`Found ${usersSnapshot.size} users with expired trials`);
      
      const batch = db.batch();
      
      usersSnapshot.docs.forEach(userDoc => {
        const userRef = db.collection('users').doc(userDoc.id);
        batch.update(userRef, {
          isPro: false,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        // Log analytics event
        const analyticsRef = db.collection('users').doc(userDoc.id).collection('analytics').doc();
        batch.set(analyticsRef, {
          event_name: 'trial_expired',
          parameters: {
            trial_start: userDoc.data().trialStart,
            trial_end: admin.firestore.Timestamp.fromDate(now),
          },
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      
      await batch.commit();
      
      console.log(`Expired ${usersSnapshot.size} user trials`);
      return null;
    } catch (error) {
      console.error('Trial Expiry Checker function error:', error);
      throw error;
    }
  });

/**
 * Monthly Usage Reset - runs on the 1st of each month
 */
exports.monthlyUsageReset = functions.pubsub
  .schedule('0 0 1 * *')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    console.log('Monthly Usage Reset function started');
    
    try {
      // Reset scan counts for all users
      const usersSnapshot = await db.collection('users').get();
      
      console.log(`Resetting usage for ${usersSnapshot.size} users`);
      
      const batch = db.batch();
      
      usersSnapshot.docs.forEach(userDoc => {
        const userRef = db.collection('users').doc(userDoc.id);
        batch.update(userRef, {
          scanCountThisMonth: 0,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        // Reset usage data
        const usageRef = db.collection('users').doc(userDoc.id).collection('usage').doc('current');
        batch.set(usageRef, {}, { merge: false }); // Clear all usage data
      });
      
      await batch.commit();
      
      console.log(`Reset usage for ${usersSnapshot.size} users`);
      return null;
    } catch (error) {
      console.error('Monthly Usage Reset function error:', error);
      throw error;
    }
  }); 