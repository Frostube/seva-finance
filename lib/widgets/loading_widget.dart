import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class LoadingWidget extends StatefulWidget {
  final double? radius;
  final Color? color;
  final bool showText;

  const LoadingWidget({
    Key? key,
    this.radius,
    this.color,
    this.showText = true,
  }) : super(key: key);

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget> {
  static const List<String> _loadingMessages = [
    "Hold on, good stuff coming your way.",
    "Building your experience… stay tuned.",
    "Loading content",
    "Almost there…",
    "Working on it…",
    "Getting things ready…",
    "Just a moment…",
    "Preparing your data…",
  ];

  late String _currentMessage;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _currentMessage = _getRandomMessage();

    if (widget.showText) {
      _startMessageRotation();
    }
  }

  String _getRandomMessage() {
    return _loadingMessages[_random.nextInt(_loadingMessages.length)];
  }

  void _startMessageRotation() {
    // Change message every 2-4 seconds with randomness
    Future.delayed(Duration(seconds: 2 + _random.nextInt(3)), () {
      if (mounted) {
        setState(() {
          String newMessage;
          do {
            newMessage = _getRandomMessage();
          } while (
              newMessage == _currentMessage && _loadingMessages.length > 1);
          _currentMessage = newMessage;
        });
        _startMessageRotation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoActivityIndicator(
          radius: widget.radius ?? 10.0,
          color: widget.color,
        ),
        if (widget.showText) ...[
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _currentMessage,
              key: ValueKey(_currentMessage),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

class CenterLoadingWidget extends StatelessWidget {
  final double? radius;
  final Color? color;
  final bool showText;

  const CenterLoadingWidget({
    Key? key,
    this.radius,
    this.color,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingWidget(
        radius: radius,
        color: color,
        showText: showText,
      ),
    );
  }
}
