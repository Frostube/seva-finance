import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/help_service.dart';

class HelpFAQsScreen extends StatefulWidget {
  final String? initialFAQId; // ID of FAQ to scroll to initially

  const HelpFAQsScreen({
    super.key,
    this.initialFAQId,
  });

  @override
  State<HelpFAQsScreen> createState() => _HelpFAQsScreenState();
}

class _HelpFAQsScreenState extends State<HelpFAQsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _faqKeys = {};

  List<FAQ> _allFAQs = [];
  List<FAQ> _filteredFAQs = [];
  Map<String, List<FAQ>> _groupedFAQs = {};
  List<String> _topics = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFAQs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFAQs() async {
    final helpService = HelpService();
    await helpService.loadHelpContent();

    setState(() {
      _allFAQs = helpService.getAllFAQs();
      _filteredFAQs = _allFAQs;
      _topics = helpService.getTopics();
      _groupedFAQs = _groupFAQsByTopic(_filteredFAQs);
      _isLoading = false;
    });

    // Create keys for all FAQs
    for (final faq in _allFAQs) {
      _faqKeys[faq.id] = GlobalKey();
    }

    // Scroll to initial FAQ if provided
    if (widget.initialFAQId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFAQ(widget.initialFAQId!);
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFAQs = _allFAQs;
      } else {
        final helpService = HelpService();
        _filteredFAQs = helpService.searchFAQs(query);
      }
      _groupedFAQs = _groupFAQsByTopic(_filteredFAQs);
    });
  }

  Map<String, List<FAQ>> _groupFAQsByTopic(List<FAQ> faqs) {
    final Map<String, List<FAQ>> grouped = {};
    for (final faq in faqs) {
      if (!grouped.containsKey(faq.topic)) {
        grouped[faq.topic] = [];
      }
      grouped[faq.topic]!.add(faq);
    }
    return grouped;
  }

  void _scrollToFAQ(String faqId) {
    final key = _faqKeys[faqId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Help & FAQs',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B4332),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1B4332)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF1B4332),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: Colors.grey[500],
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),

        // Results count
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredFAQs.length} result${_filteredFAQs.length != 1 ? 's' : ''} found',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),

        // FAQ List
        Expanded(
          child: _filteredFAQs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _groupedFAQs.keys.length,
                  itemBuilder: (context, index) {
                    final topic = _groupedFAQs.keys.elementAt(index);
                    final faqs = _groupedFAQs[topic]!;
                    return _buildTopicSection(topic, faqs);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.searchX,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicSection(String topic, List<FAQ> faqs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic Header
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            topic,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B4332),
            ),
          ),
        ),

        // FAQ Items
        ...faqs.map((faq) => FAQItem(
              key: _faqKeys[faq.id],
              faq: faq,
              isHighlighted: widget.initialFAQId == faq.id,
            )),
      ],
    );
  }
}

class FAQItem extends StatefulWidget {
  final FAQ faq;
  final bool isHighlighted;

  const FAQItem({
    super.key,
    required this.faq,
    this.isHighlighted = false,
  });

  @override
  State<FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<FAQItem> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isHighlighted;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isHighlighted
            ? const Color(0xFF1B4332).withOpacity(0.05)
            : Colors.white,
        border: Border.all(
          color: widget.isHighlighted
              ? const Color(0xFF1B4332).withOpacity(0.2)
              : Colors.grey[200]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Question Header
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Answer (Collapsible)
          SizeTransition(
            sizeFactor: _animation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.faq.answer,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
