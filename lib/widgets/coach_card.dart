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
  bool _isExpanded = false;

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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white.withOpacity(0.96)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
                    color: AppTheme.darkGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                // Text content with "Tip:" prefix
                Expanded(
                  child: RichText(
                    maxLines: _isExpanded ? null : 3,
                    overflow:
                        _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Tip: ',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkGreen,
                            height: 1.3,
                          ),
                        ),
                        TextSpan(
                          text: widget.tip.message,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                            height: 1.4,
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
            // See more / Learn more actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.tip.message.length > 140)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Text(
                      _isExpanded ? 'See less' : 'See more',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.darkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                if (widget.onLearnMore != null)
                  TextButton(
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
              ],
            ),
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
