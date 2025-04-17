import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';
import '../screens/edit_wallet_screen.dart';
import 'package:intl/intl.dart';

class WalletManagementScreen extends StatefulWidget {
  const WalletManagementScreen({super.key});

  @override
  State<WalletManagementScreen> createState() => _WalletManagementScreenState();
}

class _WalletManagementScreenState extends State<WalletManagementScreen> {
  late WalletService _walletService;
  List<Wallet> _wallets = [];

  @override
  void initState() {
    super.initState();
    _walletService = Provider.of<WalletService>(context, listen: false);
    _loadWallets();
  }

  void _loadWallets() {
    setState(() {
      _wallets = _walletService.getAllWallets();
    });
  }

  void _setPrimaryWallet(String walletId) async {
    await _walletService.setPrimaryWallet(walletId);
    _loadWallets();
  }

  void _showWalletActions(BuildContext context, Wallet wallet) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          if (!wallet.isPrimary)
            CupertinoActionSheetAction(
              onPressed: () {
                _setPrimaryWallet(wallet.id);
                Navigator.pop(context);
              },
              child: const Text('Set as Primary'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showEditWalletModal(context, wallet);
            },
            child: const Text('Edit'),
          ),
          if (!wallet.isPrimary)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                await _walletService.deleteWallet(wallet.id);
                _loadWallets();
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showAddWalletModal(BuildContext parentContext) {
    final TextEditingController nameController = TextEditingController();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          0, 0, 0, MediaQuery.of(sheetCtx).viewInsets.bottom
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        color: Colors.grey[600],
                      ),
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                  Text(
                    'New Wallet',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Create',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        color: const Color(0xFF1B4332),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () async {
                      if (nameController.text.isNotEmpty) {
                        final newWallet = Wallet(
                          id: DateTime.now().toString(),
                          name: nameController.text,
                          balance: 0.0,
                          isPrimary: _wallets.isEmpty,
                          createdAt: DateTime.now().toString().split(' ')[0],
                          colorValue: const Color(0xFF1E1E1E).value,
                        );
                        await _walletService.addWallet(newWallet);
                        _loadWallets();
                        Navigator.pop(sheetCtx); // Close the bottom sheet
                        // Navigate to Edit Wallet screen using parent context
                        Navigator.of(parentContext).push(
                          MaterialPageRoute(
                            builder: (_) => EditWalletScreen(
                              wallet: newWallet,
                              onWalletUpdated: _loadWallets,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                style: GoogleFonts.inter(
                  fontSize: 17,
                ),
                decoration: InputDecoration(
                  hintText: 'Wallet Name',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 17,
                    color: Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1B4332)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditWalletModal(BuildContext context, Wallet wallet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditWalletScreen(
          wallet: wallet,
          onWalletUpdated: _loadWallets,
        ),
      ),
    );
  }

  Widget _buildWallet(Wallet wallet) {
    return GestureDetector(
      onTap: () async {
        if (!wallet.isPrimary) {
          await _walletService.setPrimaryWallet(wallet.id);
          _loadWallets();
          // Show confirmation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${wallet.name} set as primary wallet',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: const Color(0xFF1B4332),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(wallet.colorValue),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(wallet.colorValue).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (wallet.isPrimary)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.star_fill,
                        size: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Primary',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: wallet.isPrimary ? 48 : 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  CupertinoIcons.ellipsis,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
                onPressed: () => _showWalletActions(context, wallet),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getWalletIcon(wallet.name),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        wallet.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    NumberFormat.currency(
                      symbol: '\$',
                      decimalDigits: wallet.balance.truncateToDouble() == wallet.balance ? 0 : 2,
                    ).format(wallet.balance),
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (wallet.budget != null && wallet.budget! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Budget: ${NumberFormat.currency(
                        symbol: '\$',
                        decimalDigits: wallet.budget!.truncateToDouble() == wallet.budget ? 0 : 2,
                      ).format(wallet.budget!)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Created ${wallet.createdAt}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWalletIcon(String label) {
    switch (label.toLowerCase()) {
      case 'main wallet':
        return CupertinoIcons.money_dollar_circle_fill;
      case 'groceries':
        return CupertinoIcons.cart_fill;
      case 'kid\'s wallet':
        return CupertinoIcons.person_2_fill;
      default:
        return CupertinoIcons.money_dollar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Wallets',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          if (_wallets.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _wallets.length; i++) ...[
                    _buildWallet(_wallets[i]),
                    if (i < _wallets.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Divider(height: 1),
                      ),
                  ],
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No wallets yet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _showAddWalletModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add New Wallet',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F1EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.info_circle,
                        color: Color(0xFF1B4332),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Create virtual wallets to organize your expenses',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: const Color(0xFF1B4332),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
} 