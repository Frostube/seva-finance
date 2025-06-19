import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/onboarding_service.dart';
import 'package:provider/provider.dart';

class OnboardingTourOverlay extends StatefulWidget {
  final Widget child;
  final List<TourStep> tourSteps;
  final VoidCallback? onTourComplete;
  final VoidCallback? onTourSkip;

  const OnboardingTourOverlay({
    Key? key,
    required this.child,
    required this.tourSteps,
    this.onTourComplete,
    this.onTourSkip,
  }) : super(key: key);

  @override
  State<OnboardingTourOverlay> createState() => _OnboardingTourOverlayState();
}

class _OnboardingTourOverlayState extends State<OnboardingTourOverlay>
    with TickerProviderStateMixin {
  late AnimationController _overlayController;
  late AnimationController _spotlightController;
  late Animation<double> _overlayAnimation;
  late Animation<double> _spotlightAnimation;

  GlobalKey overlayKey = GlobalKey();
  bool _isVisible = false;
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();

    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _spotlightController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeInOut,
    ));

    _spotlightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _spotlightController,
      curve: Curves.elasticOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfShouldShowTour();
    });
  }

  void _checkIfShouldShowTour() {
    final onboardingService =
        Provider.of<OnboardingService>(context, listen: false);
    if (onboardingService.shouldShowOnboarding && widget.tourSteps.isNotEmpty) {
      _showTour();
    }
  }

  void _showTour() {
    setState(() {
      _isVisible = true;
      _currentStepIndex = 0;
    });

    _overlayController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      _spotlightController.forward();
    });

    final onboardingService =
        Provider.of<OnboardingService>(context, listen: false);
    onboardingService.startOnboarding();
  }

  void _hideTour() {
    _overlayController.reverse().then((_) {
      setState(() {
        _isVisible = false;
      });
    });
    _spotlightController.reverse();
  }

  void _nextStep() {
    final onboardingService =
        Provider.of<OnboardingService>(context, listen: false);

    if (_currentStepIndex < widget.tourSteps.length - 1) {
      onboardingService
          .completeStep(widget.tourSteps[_currentStepIndex].stepName);
      onboardingService.nextStep();

      setState(() {
        _currentStepIndex++;
      });

      // Execute step action if defined (e.g., navigate to different screen)
      final nextStep = widget.tourSteps[_currentStepIndex];
      nextStep.onStepAction?.call();

      // Animate spotlight to new position with delay to allow navigation
      Future.delayed(const Duration(milliseconds: 100), () {
        _spotlightController.reset();
        _spotlightController.forward();
      });
    } else {
      _completeTour();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      final onboardingService =
          Provider.of<OnboardingService>(context, listen: false);
      onboardingService.previousStep();

      setState(() {
        _currentStepIndex--;
      });

      // Animate spotlight to new position
      _spotlightController.reset();
      _spotlightController.forward();
    }
  }

  void _completeTour() {
    final onboardingService =
        Provider.of<OnboardingService>(context, listen: false);
    onboardingService
        .completeStep(widget.tourSteps[_currentStepIndex].stepName);
    onboardingService.completeOnboarding();

    _hideTour();
    widget.onTourComplete?.call();
  }

  void _skipTour() {
    final onboardingService =
        Provider.of<OnboardingService>(context, listen: false);
    onboardingService.skipOnboarding();

    _hideTour();
    widget.onTourSkip?.call();
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _spotlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingService>(
      builder: (context, onboardingService, child) {
        // Re-check if tour should show when onboarding service state changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isVisible &&
              onboardingService.shouldShowOnboarding &&
              widget.tourSteps.isNotEmpty) {
            _showTour();
          }
        });

        return Stack(
          children: [
            widget.child,
            if (_isVisible) ...[
              _buildOverlay(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOverlay() {
    final currentStep = widget.tourSteps[_currentStepIndex];

    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _overlayAnimation.value,
          child: _TourOverlayContent(
            key: overlayKey,
            tourStep: currentStep,
            currentStepIndex: _currentStepIndex,
            totalSteps: widget.tourSteps.length,
            spotlightAnimation: _spotlightAnimation,
            onNext: _nextStep,
            onPrevious: _previousStep,
            onComplete: _completeTour,
            onSkip: _skipTour,
          ),
        );
      },
    );
  }
}

class _TourOverlayContent extends StatelessWidget {
  final TourStep tourStep;
  final int currentStepIndex;
  final int totalSteps;
  final Animation<double> spotlightAnimation;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const _TourOverlayContent({
    Key? key,
    required this.tourStep,
    required this.currentStepIndex,
    required this.totalSteps,
    required this.spotlightAnimation,
    required this.onNext,
    required this.onPrevious,
    required this.onComplete,
    required this.onSkip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Focus(
        autofocus: true,
        onKey: (node, event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              onSkip();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: CustomPaint(
          painter: _SpotlightPainter(
            targetRect: tourStep.targetRect,
            animation: spotlightAnimation,
          ),
          child: Stack(
            children: [
              // Semi-transparent overlay with better visibility
              Container(
                color: Colors.black.withOpacity(0.85),
              ),
              // Tooltip
              _buildTooltip(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTooltip(BuildContext context) {
    return AnimatedBuilder(
      animation: spotlightAnimation,
      builder: (context, child) {
        final tooltipPosition = _calculateTooltipPosition(context);

        return Positioned(
          left: tooltipPosition.dx,
          top: tooltipPosition.dy,
          child: Transform.scale(
            scale: spotlightAnimation.value,
            child: Stack(
              children: [
                // Pointer arrow pointing to the spotlight
                _buildPointerArrow(context, tooltipPosition),
                // Main tooltip
                Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 320,
                      maxHeight: 400,
                    ),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress indicator
                        if (totalSteps > 1) ...[
                          Row(
                            children: [
                              ...List.generate(totalSteps, (index) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: index <= currentStepIndex
                                        ? const Color(0xFF1B4332)
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                              const Spacer(),
                              Text(
                                'Step ${currentStepIndex + 1} of $totalSteps',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Title
                        Text(
                          tourStep.title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B4332),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Text(
                          tourStep.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Skip button
                            TextButton(
                              onPressed: onSkip,
                              child: Text(
                                'Skip Tour',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            // Navigation buttons - proper constraint handling
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (currentStepIndex > 0) ...[
                                  SizedBox(
                                    width: 60,
                                    child: OutlinedButton(
                                      onPressed: onPrevious,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: Colors.grey[300]!),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text(
                                        'Back',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                SizedBox(
                                  width: 80,
                                  child: ElevatedButton(
                                    onPressed: currentStepIndex < totalSteps - 1
                                        ? onNext
                                        : onComplete,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B4332),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      currentStepIndex < totalSteps - 1
                                          ? 'Next'
                                          : 'Got it!',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Offset _calculateTooltipPosition(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final targetRect = tourStep.targetRect;

    // Tooltip dimensions
    const tooltipWidth = 320.0;
    const tooltipHeight = 200.0;
    const padding = 20.0;

    // Calculate spotlight radius to avoid overlap
    final spotlightRadius = targetRect.shortestSide / 2 +
        20; // Slightly larger than actual spotlight

    // Try positions in order of preference: below, above, right, left
    List<Offset> candidatePositions = [
      // Below the spotlight
      Offset(
        targetRect.center.dx - tooltipWidth / 2,
        targetRect.center.dy + spotlightRadius + padding,
      ),
      // Above the spotlight
      Offset(
        targetRect.center.dx - tooltipWidth / 2,
        targetRect.center.dy - spotlightRadius - tooltipHeight - padding,
      ),
      // Right of the spotlight
      Offset(
        targetRect.center.dx + spotlightRadius + padding,
        targetRect.center.dy - tooltipHeight / 2,
      ),
      // Left of the spotlight
      Offset(
        targetRect.center.dx - spotlightRadius - tooltipWidth - padding,
        targetRect.center.dy - tooltipHeight / 2,
      ),
    ];

    // Find the first position that fits on screen
    for (Offset position in candidatePositions) {
      bool fitsHorizontally = position.dx >= padding &&
          position.dx + tooltipWidth <= screenSize.width - padding;
      bool fitsVertically =
          position.dy >= padding + 50 && // Account for status bar
              position.dy + tooltipHeight <=
                  screenSize.height - padding - 100; // Account for nav bar

      if (fitsHorizontally && fitsVertically) {
        return position;
      }
    }

    // Fallback: force position that doesn't overlap (even if partially off-screen)
    double x = targetRect.center.dx - tooltipWidth / 2;
    double y = targetRect.center.dy + spotlightRadius + padding;

    // Clamp to screen bounds
    x = x.clamp(padding, screenSize.width - tooltipWidth - padding);

    // If still would go off bottom, force it above
    if (y + tooltipHeight > screenSize.height - 100) {
      y = targetRect.center.dy - spotlightRadius - tooltipHeight - padding;
    }

    // Final clamp for Y
    y = y.clamp(50, screenSize.height - tooltipHeight - 100);

    return Offset(x, y);
  }

  Widget _buildPointerArrow(BuildContext context, Offset tooltipPosition) {
    final targetRect = tourStep.targetRect;
    final targetCenter = targetRect.center;
    final tooltipCenter = Offset(
      tooltipPosition.dx + 160, // Half of tooltip width
      tooltipPosition.dy + 100, // Half of tooltip height
    );

    // Calculate arrow position and direction
    final dx = targetCenter.dx - tooltipCenter.dx;
    final dy = targetCenter.dy - tooltipCenter.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance < 50)
      return const SizedBox.shrink(); // Too close, don't show arrow

    // Normalize direction vector
    final dirX = dx / distance;
    final dirY = dy / distance;

    // Position arrow at edge of tooltip pointing toward target
    final arrowX = tooltipCenter.dx + dirX * 150; // Position at tooltip edge
    final arrowY = tooltipCenter.dy + dirY * 90;

    return Positioned(
      left: arrowX - 15, // Center the arrow icon
      top: arrowY - 15,
      child: Transform.rotate(
        angle: atan2(dy, dx), // Point arrow toward target
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF40916C),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_forward,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final Animation<double> animation;

  _SpotlightPainter({
    required this.targetRect,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Larger radius to accommodate FAB and avoid covering content
    final baseRadius = targetRect.shortestSide / 2 + 15;
    final animatedRadius = baseRadius * animation.value;

    // Clear circular area for the spotlight
    final spotlightPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    canvas.drawCircle(
      targetRect.center,
      animatedRadius,
      spotlightPaint,
    );

    // Draw visible border around the spotlight for clarity
    if (animation.value > 0.3) {
      final borderPaint = Paint()
        ..color = const Color(0xFF40916C).withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawCircle(
        targetRect.center,
        animatedRadius + 2,
        borderPaint,
      );

      // Add a subtle outer glow
      final glowPaint = Paint()
        ..color = const Color(0xFF40916C).withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(
        targetRect.center,
        animatedRadius + 5,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TourStep {
  final String stepName;
  final String title;
  final String description;
  final Rect targetRect;
  final GlobalKey? targetKey;
  final VoidCallback? onStepAction;

  TourStep({
    required this.stepName,
    required this.title,
    required this.description,
    required this.targetRect,
    this.targetKey,
    this.onStepAction,
  });

  // Helper method to create TourStep from GlobalKey
  static TourStep fromKey({
    required String stepName,
    required String title,
    required String description,
    required GlobalKey targetKey,
  }) {
    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      final offset = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      return TourStep(
        stepName: stepName,
        title: title,
        description: description,
        targetRect:
            Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
        targetKey: targetKey,
      );
    }

    // Fallback if we can't get the position
    return TourStep(
      stepName: stepName,
      title: title,
      description: description,
      targetRect: const Rect.fromLTWH(100, 100, 100, 50),
      targetKey: targetKey,
    );
  }
}
