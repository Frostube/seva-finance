import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class Transaction {
  final String name;
  final String date;
  final String amount;
  final String type;
  final Color avatarColor;
  final String description;
  final DateTime timestamp;

  Transaction({
    required this.name,
    required this.date,
    required this.amount,
    required this.type,
    required this.avatarColor,
    required this.description,
    required this.timestamp,
  });
}

class RecentActivityScreen extends StatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  State<RecentActivityScreen> createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Income', 'Transfer', 'Expenses'];
  
  late List<Transaction> _transactions;
  late List<Transaction> _filteredTransactions;

  @override
  void initState() {
    super.initState();
    _transactions = [
      Transaction(
        name: 'Dribbble',
        date: 'Today, 16:32',
        amount: '-\$120.00',
        type: 'Transfer',
        avatarColor: Colors.pink,
        description: 'Monthly Subscription',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Transaction(
        name: 'Wilson Mango',
        date: 'Today, 10:12',
        amount: '-\$240.00',
        type: 'Transfer',
        avatarColor: Colors.orange,
        description: 'Project Payment',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      Transaction(
        name: 'Abram Botosh',
        date: 'Yesterday',
        amount: '+\$450.00',
        type: 'Income',
        avatarColor: Colors.blue,
        description: 'Design Services',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Transaction(
        name: 'Spotify',
        date: '2 days ago',
        amount: '-\$9.99',
        type: 'Expenses',
        avatarColor: Colors.green,
        description: 'Premium Subscription',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Transaction(
        name: 'Amazon',
        date: '3 days ago',
        amount: '-\$156.84',
        type: 'Expenses',
        avatarColor: Colors.orange,
        description: 'Electronics Purchase',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Transaction(
        name: 'Sarah Wilson',
        date: '4 days ago',
        amount: '+\$280.00',
        type: 'Income',
        avatarColor: Colors.purple,
        description: 'Freelance Payment',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
    _filterTransactions();
  }

  void _filterTransactions() {
    if (_selectedFilter == 'All') {
      _filteredTransactions = List.from(_transactions);
    } else {
      _filteredTransactions = _transactions
          .where((transaction) => transaction.type == _selectedFilter)
          .toList();
    }
    setState(() {});
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFilter = label);
          _filterTransactions();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.darkGreen : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.darkGreen : AppTheme.darkGreen.withOpacity(0.2),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : AppTheme.darkGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: transaction.avatarColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  transaction.name[0],
                  style: GoogleFonts.inter(
                    color: transaction.avatarColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.darkGreen.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.date,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.darkGreen.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.amount,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: transaction.amount.startsWith('+') ? Colors.green : AppTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: transaction.type == 'Income' 
                      ? Colors.green.withOpacity(0.1)
                      : AppTheme.paleGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.type,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: transaction.type == 'Income' ? Colors.green : AppTheme.darkGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
        title: Text(
          'Recent Activity',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.search),
            color: AppTheme.darkGreen,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.slider_horizontal_3),
            color: AppTheme.darkGreen,
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters
                    .map((filter) => Padding(
                          padding: EdgeInsets.only(
                            right: filter != _filters.last ? 12 : 0,
                          ),
                          child: _buildFilterChip(filter),
                        ))
                    .toList(),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _filteredTransactions.isEmpty
                ? Center(
                    child: Text(
                      'No transactions found',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    key: ValueKey<String>(_selectedFilter),
                    padding: const EdgeInsets.all(24),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) => _buildTransactionItem(_filteredTransactions[index]),
                  ),
            ),
          ),
        ],
      ),
    );
  }
} 