import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';
import 'edit_wallet_screen.dart';

class WalletManagementScreen extends StatelessWidget {
  const WalletManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Wallets'),
      ),
      body: Consumer<WalletService>(
        builder: (context, walletService, child) {
          final wallets = walletService.wallets;
          
          if (wallets.isEmpty) {
            return const Center(
              child: Text('No wallets yet. Create one by tapping the + button.'),
            );
          }

          return ListView.builder(
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return ListTile(
                title: Text(wallet.name),
                subtitle: Text('\$${wallet.balance.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditWalletScreen(
                              wallet: wallet,
                              onWalletUpdated: () {
                                // Refresh the wallet list
                                walletService.notifyListeners();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Wallet'),
                            content: Text('Are you sure you want to delete ${wallet.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await walletService.deleteWallet(wallet.id);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Create a new empty wallet for the edit screen
          final newWallet = Wallet(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: '',
            balance: 0,
            budget: 0,
            isPrimary: false,
            colorValue: Colors.blue.value,
            createdAt: DateTime.now().toIso8601String(),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditWalletScreen(
                wallet: newWallet,
                onWalletUpdated: () {
                  // Refresh the wallet list
                  Provider.of<WalletService>(context, listen: false).notifyListeners();
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 