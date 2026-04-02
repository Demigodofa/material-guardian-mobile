import 'dart:async';

import 'package:flutter/material.dart';

import '../app/brand_assets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _title = 'Brought to you by:';
  static const _titleColor = Color(0xFF1C2430);

  bool _showLogo = false;
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_runSequence());
  }

  Future<void> _runSequence() async {
    await _fadeIn(const Duration(milliseconds: 350));
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await _fadeOut(const Duration(milliseconds: 250));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) {
      return;
    }
    setState(() {
      _showLogo = true;
      _opacity = 0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 16));
    await _fadeIn(const Duration(milliseconds: 450));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await _fadeOut(const Duration(milliseconds: 350));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      widget.onFinished();
    }
  }

  Future<void> _fadeIn(Duration duration) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _opacity = 1;
    });
    await Future<void>.delayed(duration);
  }

  Future<void> _fadeOut(Duration duration) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _opacity = 0;
    });
    await Future<void>.delayed(duration);
  }

  @override
  Widget build(BuildContext context) {
    final logoWidget = Image.asset(
      BrandAssets.weldersHelperLogo512,
      width: 220,
      height: 220,
      fit: BoxFit.contain,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: _showLogo
              ? logoWidget
              : const Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _titleColor,
                    fontSize: 26,
                    height: 30 / 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
