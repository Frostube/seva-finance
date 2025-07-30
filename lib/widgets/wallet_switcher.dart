import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';
import '../screens/linked_cards_screen.dart';

class WalletSwitcher extends StatefulWidget {
  final Wallet? selectedWallet;
  final Function(Wallet) onWalletSelected;
  final WalletService walletService;

  const WalletSwitcher({
    Key? key,
    required this.selectedWallet,
    required this.onWalletSelected,
    required this.walletService,
  }) : super(key: key);

  @override
  State<WalletSwitcher> createState() => _WalletSwitcherState();
}

class _WalletSwitcherState extends State<WalletSwitcher> {
  void _showWalletSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final allWallets = widget.walletService.wallets;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Switch Wallet',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allWallets.length + 2,
                  itemBuilder: (context, index) {
                    if (index < allWallets.length) {
                      final wallet = allWallets[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F1EC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            wallet.icon,
                            color: const Color(0xFF1B4332),
                          ),
                        ),
                        title: Text(
                          wallet.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: widget.selectedWallet?.id == wallet.id
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF1B4332),
                              )
                            : null,
                        onTap: () {
                          widget.onWalletSelected(wallet);
                          Navigator.pop(context);
                        },
                      );
                    } else if (index == allWallets.length) {
                      return const Divider(height: 1);
                    } else {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9F1EC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Color(0xFF1B4332),
                              ),
                            ),
                            title: Text(
                              'Create New Wallet',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LinkedCardsScreen(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9F1EC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.settings,
                                color: Color(0xFF1B4332),
                              ),
                            ),
                            title: Text(
                              'Manage Wallets',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LinkedCardsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showWalletSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE9F1EC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.selectedWallet != null) ...[
              Icon(
                widget.selectedWallet!.icon,
                color: const Color(0xFF1B4332),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                widget.selectedWallet!.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1B4332),
                ),
              ),
            ] else ...[
              const Icon(
                Icons.help_outline,
                color: Color(0xFF1B4332),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Select Wallet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1B4332),
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF1B4332),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
