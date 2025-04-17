import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/payment_method.dart';
import '../services/payment_method_service.dart';
import 'package:uuid/uuid.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final PaymentMethodService paymentMethodService;

  const PaymentMethodsScreen({
    Key? key,
    required this.paymentMethodService,
  }) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late List<PaymentMethod> _paymentMethods;
  String _selectedIcon = '0xf43a'; // Default to credit card icon

  final List<({String name, IconData icon})> _defaultIcons = [
    (name: 'Wallet', icon: CupertinoIcons.creditcard),
    (name: 'Cash', icon: CupertinoIcons.money_dollar),
    (name: 'Savings', icon: CupertinoIcons.money_dollar_circle),
    (name: 'Bank', icon: CupertinoIcons.building_2_fill),
    (name: 'Shopping', icon: CupertinoIcons.bag_fill),
    (name: 'Budget', icon: CupertinoIcons.square_stack_3d_up_fill),
  ];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  void _loadPaymentMethods() {
    setState(() {
      _paymentMethods = widget.paymentMethodService.paymentMethods;
    });
  }

  void _showAddWalletModal() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController lastFourController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            0, 0, 0, MediaQuery.of(context).viewInsets.bottom
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
                      onPressed: () => Navigator.pop(context),
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
                        'Save',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: const Color(0xFF1B4332),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          final method = PaymentMethod(
                            id: const Uuid().v4(),
                            name: nameController.text,
                            icon: _selectedIcon,
                            lastFourDigits: lastFourController.text.isEmpty 
                                ? null 
                                : lastFourController.text,
                          );
                          widget.paymentMethodService.addPaymentMethod(method);
                          _loadPaymentMethods();
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Name Field
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: GoogleFonts.inter(fontSize: 17),
                  decoration: InputDecoration(
                    hintText: 'Wallet Name (e.g., Groceries, Travel)',
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
                  ),
                ),
                const SizedBox(height: 16),
                // Optional Reference Number
                TextField(
                  controller: lastFourController,
                  style: GoogleFonts.inter(fontSize: 17),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: 'Reference Number (optional)',
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
                  ),
                ),
                const SizedBox(height: 16),
                // Icon Selection
                Text(
                  'Choose Icon',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _defaultIcons.map((iconData) {
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            _selectedIcon = iconData.icon.codePoint.toString();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedIcon == iconData.icon.codePoint.toString()
                                ? const Color(0xFFE9F1EC)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedIcon == iconData.icon.codePoint.toString()
                                  ? const Color(0xFF1B4332)
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                iconData.icon,
                                size: 24,
                                color: const Color(0xFF1B4332),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                iconData.name,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          // Wallets List
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
            child: Column(
              children: _paymentMethods.map((method) {
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F1EC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          IconData(int.parse(method.icon ?? '0xf43a'), fontFamily: CupertinoIcons.iconFont),
                          size: 20,
                          color: const Color(0xFF1B4332),
                        ),
                      ),
                      title: Text(
                        method.name,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: method.lastFourDigits != null
                          ? Text(
                              'Ref: ${method.lastFourDigits}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            )
                          : null,
                      trailing: IconButton(
                        icon: const Icon(CupertinoIcons.ellipsis),
                        onPressed: () {
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) => CupertinoActionSheet(
                              actions: [
                                CupertinoActionSheetAction(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // TODO: Implement edit
                                  },
                                  child: const Text('Edit'),
                                ),
                                CupertinoActionSheetAction(
                                  isDestructiveAction: true,
                                  onPressed: () {
                                    widget.paymentMethodService
                                        .deletePaymentMethod(method.id);
                                    _loadPaymentMethods();
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
                        },
                      ),
                    ),
                    if (_paymentMethods.last != method)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Add Wallet Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _showAddWalletModal,
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