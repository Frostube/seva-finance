import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';
import 'package:provider/provider.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const separator = ' '; // Use space as thousand separator

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is empty, return it as is
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all separators and any non-numeric characters except decimal point
    final cleanText = newValue.text
        .replaceAll(separator, '')
        .replaceAll(RegExp(r'[^\d.]'), '');

    // Ensure only one decimal point
    final parts = cleanText.split('.');
    if (parts.length > 2) {
      return oldValue;
    }

    // Parse the number
    final number = double.tryParse(cleanText);
    if (number == null) {
      return oldValue;
    }

    // Format the number with separators
    final formatter = NumberFormat.decimalPattern();
    final formattedText = formatter.format(number);

    // Calculate the new cursor position
    final oldLength = oldValue.text.length;
    final newLength = formattedText.length;
    final cursorPosition = newValue.selection.baseOffset + (newLength - oldLength);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: cursorPosition.clamp(0, formattedText.length),
      ),
    );
  }
}

class EditWalletScreen extends StatefulWidget {
  final Wallet wallet;
  final VoidCallback onWalletUpdated;

  const EditWalletScreen({
    super.key,
    required this.wallet,
    required this.onWalletUpdated,
  });

  @override
  State<EditWalletScreen> createState() => _EditWalletScreenState();
}

class _EditWalletScreenState extends State<EditWalletScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _budgetController;
  late TextEditingController _balanceController;
  late WalletService _walletService;
  bool _hasChanges = false;
  bool _isPrimary = false;
  String _selectedType = 'Personal';
  late Color _selectedColor;
  late IconData _selectedIcon;
  bool _isDeleting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<String> _walletTypes = [
    'Personal',
    'Vacation',
    'Kids',
    'Savings',
    'Other',
  ];

  final List<Color> _colorOptions = [
    const Color(0xFF1B4332), // Dark green
    const Color(0xFF40916C), // Forest green
    const Color(0xFF52B788), // Mint
    const Color(0xFF2D6A4F), // Pine
    const Color(0xFF1B1B1B), // Black
    const Color(0xFF2B2B2B), // Dark gray
    const Color(0xFF3B3B3B), // Gray
    const Color(0xFF4B4B4B), // Light gray
  ];

  final List<IconData> _iconOptions = [
    CupertinoIcons.money_dollar_circle_fill,
    CupertinoIcons.cart_fill,
    CupertinoIcons.car_fill,
    CupertinoIcons.house_fill,
    CupertinoIcons.gift_fill,
    CupertinoIcons.heart_fill,
    CupertinoIcons.person_2_fill,
    CupertinoIcons.bag_fill,
    CupertinoIcons.airplane,
    CupertinoIcons.game_controller_solid,
    CupertinoIcons.star_fill,
    CupertinoIcons.tag_fill,
  ];

  @override
  void initState() {
    super.initState();
    _walletService = Provider.of<WalletService>(context, listen: false);
    _nameController = TextEditingController(text: widget.wallet.name);
    _budgetController = TextEditingController(
      text: widget.wallet.budget != null && widget.wallet.budget! > 0
          ? NumberFormat.currency(symbol: '', decimalDigits: 0).format(widget.wallet.budget!)
          : '',
    );
    _balanceController = TextEditingController(
      text: widget.wallet.balance > 0
          ? NumberFormat.currency(symbol: '', decimalDigits: 0).format(widget.wallet.balance)
          : '',
    );
    _selectedType = widget.wallet.type ?? 'Personal';
    _selectedColor = Color(widget.wallet.colorValue);
    _selectedIcon = widget.wallet.icon ?? CupertinoIcons.money_dollar_circle_fill;
    _isPrimary = widget.wallet.isPrimary;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _balanceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _togglePrimary(bool value) async {
    if (value) {
      await _walletService.setPrimaryWallet(widget.wallet.id);
    }
    setState(() {
      _isPrimary = value;
      _markAsChanged();
    });
  }

  Future<void> _saveWallet() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a wallet name')),
      );
      return;
    }

    final budget = double.tryParse(
      _budgetController.text.replaceAll(RegExp(r'[^0-9]'), '')
    ) ?? 0.0;

    final balance = double.tryParse(
      _balanceController.text.replaceAll(RegExp(r'[^0-9]'), '')
    ) ?? 0.0;

    final updatedWallet = Wallet(
      id: widget.wallet.id,
      name: _nameController.text,
      balance: balance,
      budget: budget,
      isPrimary: _isPrimary,
      type: _selectedType,
      colorValue: _selectedColor.value,
      icon: _selectedIcon,
      createdAt: widget.wallet.createdAt,
    );

    await _walletService.updateWallet(updatedWallet);
    if (_isPrimary) {
      await _walletService.setPrimaryWallet(updatedWallet.id);
    }
    widget.onWalletUpdated();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _walletService.deleteWallet(widget.wallet.id);
      widget.onWalletUpdated();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete wallet')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Wallet',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this wallet? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete();
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Saved!',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF1B4332),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCard({
    required List<Widget> children,
    EdgeInsets? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? prefixText,
    TextInputType? keyboardType,
    required Function(String) onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      onChanged: (value) {
        // Format the value in real-time
        final formatter = ThousandsSeparatorInputFormatter();
        final newValue = formatter.formatEditUpdate(
          TextEditingValue(text: value),
          TextEditingValue(text: value),
        );
        if (newValue.text != value) {
          controller.value = newValue;
        }
        onChanged(value);
      },
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      ),
    );
  }

  Widget _buildWalletTypeSelector() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _walletTypes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = _walletTypes[index];
          final isSelected = type == _selectedType;
          
          return ChoiceChip(
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedType = type;
                _markAsChanged();
              });
              _animationController.forward().then((_) => _animationController.reverse());
            },
            label: Text(
              type,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            backgroundColor: Colors.grey[100],
            selectedColor: const Color(0xFF1B4332),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isSelected ? const Color(0xFF1B4332) : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _iconOptions.length,
      itemBuilder: (context, index) {
        final icon = _iconOptions[index];
        final isSelected = icon == _selectedIcon;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedIcon = icon;
              _markAsChanged();
            });
            _animationController.forward().then((_) => _animationController.reverse());
          },
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isSelected ? _scaleAnimation.value : 1.0,
                child: child,
              );
            },
            child: Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE9F1EC) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1B4332) : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF1B4332) : Colors.grey[600],
                size: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _colorOptions.length,
      itemBuilder: (context, index) {
        final color = _colorOptions[index];
        final isSelected = color == _selectedColor;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
              _markAsChanged();
            });
            _animationController.forward().then((_) => _animationController.reverse());
          },
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isSelected ? _scaleAnimation.value : 1.0,
                child: child,
              );
            },
            child: Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: isSelected
                  ? const Icon(
                      LucideIcons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryWalletToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _isPrimary ? const Color(0xFFE9F1EC) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPrimary ? const Color(0xFF1B4332) : Colors.grey[300]!,
          width: _isPrimary ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Set as Primary Wallet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _isPrimary ? const Color(0xFF1B4332) : Colors.grey[700],
            ),
          ),
          CupertinoSwitch(
            value: _isPrimary,
            onChanged: (value) {
              setState(() {
                _isPrimary = value;
                _markAsChanged();
              });
              _togglePrimary(value);
            },
            activeColor: const Color(0xFF1B4332),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
        ),
        title: Text(
          'Edit Wallet',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: () {
                _saveWallet();
                _showSuccessToast();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(44, 44),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B4332),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              children: [
                _buildSectionLabel('Wallet Name'),
                _buildTextField(
                  controller: _nameController,
                  hintText: 'Enter wallet name',
                  onChanged: (_) => _markAsChanged(),
                ),
                const SizedBox(height: 24),
                _buildSectionLabel('Wallet Type'),
                _buildWalletTypeSelector(),
              ],
            ),
            const SizedBox(height: 24),
            _buildCard(
              children: [
                _buildSectionLabel('Icon'),
                _buildIconGrid(),
                const SizedBox(height: 24),
                _buildSectionLabel('Color'),
                _buildColorGrid(),
              ],
            ),
            const SizedBox(height: 24),
            _buildCard(
              children: [
                _buildSectionLabel('Monthly Budget'),
                _buildTextField(
                  controller: _budgetController,
                  hintText: 'Enter monthly budget',
                  prefixText: '\$ ',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _markAsChanged(),
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Current Balance'),
                _buildTextField(
                  controller: _balanceController,
                  hintText: 'Enter current balance',
                  prefixText: '\$ ',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _markAsChanged(),
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                ),
                const SizedBox(height: 24),
                _buildPrimaryWalletToggle(),
              ],
            ),
            if (!widget.wallet.isPrimary) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: _isDeleting ? null : _showDeleteConfirmation,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      )
                    : Text(
                        'Delete Wallet',
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 