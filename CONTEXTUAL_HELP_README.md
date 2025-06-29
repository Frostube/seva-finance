# Contextual Help & FAQs Implementation

This document outlines the implementation of the Contextual Help & FAQs feature in SevaFinance.

## 🎯 Features Implemented

✅ **Inline Help Tooltips**
- Question mark icons next to form labels
- Contextual tooltip bubbles with helpful explanations
- Auto-dismiss after 5 seconds or on outside click
- Optional "Learn more" links to specific FAQs

✅ **Centralized Help & FAQs Screen** 
- Searchable FAQ database
- Categorized Q&A sections  
- Collapsible FAQ items with smooth animations
- Real-time search filtering

✅ **JSON-based Content Management**
- All help content stored in `assets/help/faqs.json`
- Easy to update without code changes
- Supports tooltips and structured FAQs

✅ **Navigation Integration**
- Help & FAQs accessible from Profile screen
- Direct navigation from tooltips to specific FAQs
- Smooth page transitions and scroll-to-FAQ functionality

## 📁 Files Added/Modified

### New Files
- `assets/help/faqs.json` - Help content database
- `lib/services/help_service.dart` - Content management service  
- `lib/widgets/help_icon.dart` - Tooltip component
- `lib/screens/help_faqs_screen.dart` - Main help screen

### Modified Files
- `pubspec.yaml` - Added help assets
- `lib/main.dart` - Initialize help service at startup
- `lib/screens/profile_screen.dart` - Added Help & FAQs menu item
- `lib/screens/add_expense_screen.dart` - Added help icons to form fields
- `lib/screens/dashboard_screen.dart` - Added help icons to Goal/Alert buttons

## 🔧 Usage

### Adding Help Icons to Forms

```dart
import '../widgets/help_icon.dart';

// Basic help icon
HelpIcon(
  tooltipKey: 'category',
  size: 16,
)

// Help icon with FAQ link
HelpIcon(
  tooltipKey: 'category',
  faqId: 'getting_started_1',
  size: 16,
)

// In form fields with custom colors
Row(
  children: [
    Text('Category'),
    SizedBox(width: 6),
    HelpIcon(
      tooltipKey: 'category',
      faqId: 'getting_started_1', 
      size: 14,
      color: Colors.grey[500],
    ),
  ],
)
```

### Managing Help Content

Edit `assets/help/faqs.json` to add/modify tooltips and FAQs:

```json
{
  "tooltips": {
    "new_concept": "Explanation of new concept..."
  },
  "faqs": [
    {
      "id": "new_faq_1",
      "topic": "New Topic",
      "question": "How do I...?", 
      "answer": "You can do this by..."
    }
  ]
}
```

### Available Tooltip Keys

- `category` - Expense categorization
- `budget` - Budget setting
- `recurring` - Recurring transactions
- `wallet` - Wallet balance
- `savings_goal` - Savings goals
- `spending_alert` - Spending alerts
- `insights` - AI insights
- `analytics` - Financial analytics
- `receipt_scan` - Receipt scanning
- `export` - Data export

## 📱 User Experience

1. **Contextual Help Flow**
   - User sees "?" icon next to labels
   - Taps icon → tooltip appears with explanation
   - Optionally taps "Learn more" → navigates to FAQ screen
   - FAQ screen auto-scrolls to relevant question

2. **FAQ Discovery**
   - Access via Profile → Help & FAQs
   - Search functionality for quick answers
   - Categorized sections for browsing
   - Collapsible Q&A format

3. **Mobile Optimizations**
   - Touch-friendly help icons (minimum 44px tap target)
   - Overlay tooltips positioned to avoid screen edges
   - Smooth animations and transitions
   - Auto-dismiss for better UX

## 🎨 Design Consistency

- Uses app's existing color scheme (`Color(0xFF1B4332)`)
- Consistent with Google Fonts Inter typography
- Matches existing button and card styles
- Proper spacing and visual hierarchy

## 🔄 Future Enhancements

- **Analytics**: Track which help topics are accessed most
- **Dynamic Content**: Load FAQs from Firestore for real-time updates
- **Multilingual**: Support for multiple languages
- **Interactive Tours**: Step-by-step guided tutorials
- **Contextual Suggestions**: Show relevant help based on user actions

## 🧪 Testing

Run the test file to verify implementation:

```bash
flutter run test_help_system.dart
```

This provides a standalone test environment for help icons and FAQ screen functionality.

## 📋 Acceptance Criteria Status

✅ Every "?" icon shows correct tooltip on tap  
✅ Tooltips auto-dismiss on outside tap  
✅ "Learn more" links navigate to matching FAQ  
✅ Help & FAQs screen loads and displays grouped items  
✅ Search bar filters FAQ items in real-time  
✅ All text is editable via JSON (no hard-coded strings)

The Contextual Help & FAQs feature is now fully implemented and ready for user testing! 