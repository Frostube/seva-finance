import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/coach_service.dart';
import '../theme/app_theme.dart';

class DebugCoachScreen extends StatelessWidget {
  const DebugCoachScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Service Debug'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CoachService>(
        builder: (context, coachService, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coach Service Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('Loading: ${coachService.isLoading}'),
                        Text('Total Tips: ${coachService.tips.length}'),
                        Text('Unread Tips: ${coachService.unreadTips.length}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: coachService.isLoading
                      ? null
                      : () {
                          coachService.forceGenerateTips();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Force Generate Tips'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    coachService.loadCoachTips();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reload Tips'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    coachService.clearTips();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear Tips'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    // Test if the Firestore index is ready
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Testing Firestore index...'),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    try {
                      final user =
                          Provider.of<CoachService>(context, listen: false);
                      await user.loadCoachTips();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Firestore index is working!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Index error: $e'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Firestore Index'),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Tips',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: coachService.tips.isEmpty
                                ? const Center(
                                    child: Text('No tips available'),
                                  )
                                : ListView.builder(
                                    itemCount: coachService.tips.length,
                                    itemBuilder: (context, index) {
                                      final tip = coachService.tips[index];
                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          title: Text(tip.title),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(tip.message),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Type: ${tip.type.toString().split('.').last}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                              Text(
                                                'Priority: ${tip.priority.toString().split('.').last}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                              Text(
                                                'Read: ${tip.isRead}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (!tip.isRead)
                                                IconButton(
                                                  icon: const Icon(Icons.done),
                                                  onPressed: () {
                                                    coachService
                                                        .markTipAsRead(tip.id);
                                                  },
                                                ),
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () {
                                                  coachService
                                                      .dismissTip(tip.id);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
