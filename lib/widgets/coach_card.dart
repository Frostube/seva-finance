import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/coach_service.dart';

class CoachCard extends StatefulWidget {
  final CoachTip tip;
  final VoidCallback onDismiss;
  final VoidCallback? onLearnMore;

  const CoachCard({
    super.key,
    required this.tip,
    required this.onDismiss,
    this.onLearnMore,
  });

  @override
  State<CoachCard> createState() => _CoachCardState();
}

class _CoachCardState extends State<CoachCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          // Main Column to hold all content
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Green lightbulb icon
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: const Color(0xFF4CAF50), // Green color
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                // Text content with "Tip:" prefix
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Tip: ',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        TextSpan(
                          text: widget.tip.message,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Small dismiss button
                GestureDetector(
                  onTap: () => _dismissWithAnimation(),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 1),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            // Add Learn more button if onLearnMore is provided
            if (widget.onLearnMore != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: widget.onLearnMore,
                  child: Text(
                    'Learn more',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.darkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _dismissWithAnimation() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }
}
