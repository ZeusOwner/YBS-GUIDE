import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/route_names.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
    _startApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startApp() async {
    unawaited(_requestLocationPermission());
    await Future<void>.delayed(const Duration(milliseconds: 1900));

    if (!mounted) {
      return;
    }
    context.go(RouteNames.home);
  }

  Future<void> _requestLocationPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (_) {
      // Plugin calls can fail in widget tests or unsupported environments.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              Semantics(
                label: 'YBS Guide logo',
                image: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    AppConstants.ybsLogoAsset,
                    width: 112,
                    height: 112,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppConstants.appNameEn,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppConstants.appNameMm,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _MovingBus(controller: _controller),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Finding nearby YBS routes...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovingBus extends StatelessWidget {
  const _MovingBus({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BusTrackPainter(progress: controller.value),
            child: Align(
              alignment: Alignment(-1 + (controller.value * 2), -0.08),
              child: child,
            ),
          );
        },
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_filled_rounded,
            color: AppColors.primary,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _BusTrackPainter extends CustomPainter {
  const _BusTrackPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.26)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    final start = Offset(12, y);
    final end = Offset(size.width - 12, y);
    canvas.drawLine(start, end, trackPaint);
    canvas.drawLine(
      start,
      Offset(12 + (size.width - 24) * progress, y),
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BusTrackPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
