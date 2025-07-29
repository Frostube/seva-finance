import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/help_service.dart';
import '../screens/help_faqs_screen.dart';

class HelpIcon extends StatefulWidget {
  final String tooltipKey;
  final String? faqId; // Optional FAQ ID to link to specific FAQ
  final double size;
  final Color? color;

  const HelpIcon({
    super.key,
    required this.tooltipKey,
    this.faqId,
    this.size = 24.0,
    this.color,
  });

  @override
  State<HelpIcon> createState() => _HelpIconState();
}

class _HelpIconState extends State<HelpIcon> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _showTooltip,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: Icon(
            LucideIcons.helpCircle,
            size: widget.size,
            color: widget.color ?? Colors.grey[500],
          ),
        ),
      ),
    );
  }

  void _showTooltip() async {
    // Hide any existing tooltip
    _hideTooltip();

    final helpService = HelpService();
    await helpService.loadHelpContent();

    final tooltipText = helpService.getTooltip(widget.tooltipKey);
    if (tooltipText == null) return;

    _overlayEntry = _createOverlayEntry(tooltipText);
    Overlay.of(context).insert(_overlayEntry!);

    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _hideTooltip();
    });
  }

  OverlayEntry _createOverlayEntry(String text) {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 280,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-130, 25), // Position below the icon
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: TooltipBubble(
              text: text,
              onLearnMore: widget.faqId != null
                  ? () {
                      _hideTooltip();
                      _navigateToFAQ();
                    }
                  : null,
              onClose: _hideTooltip,
            ),
          ),
        ),
      ),
    );
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _navigateToFAQ() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HelpFAQsScreen(
          initialFAQId: widget.faqId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }
}

class TooltipBubble extends StatelessWidget {
  final String text;
  final VoidCallback? onLearnMore;
  final VoidCallback onClose;

  const TooltipBubble({
    super.key,
    required this.text,
    this.onLearnMore,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Prevent closing when tapping inside
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: onClose,
                    child: Icon(
                      LucideIcons.x,
                      size: 24.0,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Tooltip text
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                ),

                // Learn more button (if provided)
                if (onLearnMore != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onLearnMore,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Learn more',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF1B4332),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.arrowRight,
                          size: 20.0,
                          color: const Color(0xFF1B4332),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Triangle pointer
          Positioned(
            top: -5,
            left: 140,
            child: CustomPaint(
              painter: TrianglePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 10);
    path.lineTo(10, 10);
    path.lineTo(5, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
