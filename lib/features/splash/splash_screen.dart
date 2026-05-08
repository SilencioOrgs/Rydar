import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/rydar_logo.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _motionController;
  int _pageIndex = 0;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _motionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _pageIndex = index),
          children: [
            _WelcomePage(
              pageIndex: _pageIndex,
              motion: _motionController,
              onGetStarted: _nextPage,
              onContinue: _enterGuestMode,
            ),
            _TrackingPage(
              pageIndex: _pageIndex,
              motion: _motionController,
              onBack: _previousPage,
              onNext: _nextPage,
              onSkip: _enterGuestMode,
            ),
            _ReadyPage(
              pageIndex: _pageIndex,
              motion: _motionController,
              onBack: _previousPage,
              onContinue: _signInWithGoogle,
              onGuestContinue: _enterGuestMode,
              isSigningIn: _isSigningIn,
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    if (_pageIndex >= 2) {
      _enterGuestMode();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _enterGuestMode() {
    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) {
      return;
    }
    setState(() => _isSigningIn = true);
    try {
      await AuthService.instance.signInWithGoogle();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } on GoogleSignInException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.code != GoogleSignInExceptionCode.canceled) {
        _showSignInMessage(error.description ?? 'Google sign-in failed.');
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      _showSignInMessage(error.message ?? 'Firebase sign-in failed.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSignInMessage('Could not sign in with Google. Try again.');
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  void _showSignInMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.pageIndex,
    required this.motion,
    required this.onGetStarted,
    required this.onContinue,
  });

  final int pageIndex;
  final Animation<double> motion;
  final VoidCallback onGetStarted;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _GlowingRouteBackground(motion: motion)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.96),
                  Colors.black.withValues(alpha: 0.58),
                  Colors.black,
                ],
              ),
            ),
          ),
        ),
        _PageReveal(
          active: pageIndex == 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              children: [
                const Spacer(),
                AnimatedBuilder(
                  animation: motion,
                  builder: (context, child) {
                    final lift = math.sin(motion.value * math.pi * 2) * 4;
                    return Transform.translate(
                      offset: Offset(0, lift),
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.route_rounded,
                    color: AppColors.orange,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'RYDAR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 52,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Track every ride. Share every route.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedText, fontSize: 16),
                ),
                const Spacer(),
                _PrimaryOnboardingButton(
                  label: 'Get Started',
                  onPressed: onGetStarted,
                ),
                const SizedBox(height: 12),
                _TextOnboardingButton(
                  label: 'Continue as Guest',
                  onPressed: onContinue,
                ),
                const SizedBox(height: 22),
                _ProgressDots(activeIndex: pageIndex),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackingPage extends StatelessWidget {
  const _TrackingPage({
    required this.pageIndex,
    required this.motion,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  final int pageIndex;
  final Animation<double> motion;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OnboardingTopBar(onSkip: onSkip),
        Expanded(
          child: _PageReveal(
            active: pageIndex == 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                children: [
                  const Text(
                    'Ride Smarter',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track your route in real time',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 26,
                      height: 1.16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Record distance, speed, duration, and your full ride path with a clean GPS-powered map.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _MapMockup(motion: motion),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(
                        child: _TrackingFeature(
                          icon: Icons.route_rounded,
                          label: 'Distance',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _TrackingFeature(
                          icon: Icons.speed_rounded,
                          label: 'Speed',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _TrackingFeature(
                          icon: Icons.timer_rounded,
                          label: 'Duration',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        _OnboardingFooter(pageIndex: pageIndex, onBack: onBack, onNext: onNext),
      ],
    );
  }
}

class _ReadyPage extends StatelessWidget {
  const _ReadyPage({
    required this.pageIndex,
    required this.motion,
    required this.onBack,
    required this.onContinue,
    required this.onGuestContinue,
    required this.isSigningIn,
  });

  final int pageIndex;
  final Animation<double> motion;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onGuestContinue;
  final bool isSigningIn;

  @override
  Widget build(BuildContext context) {
    return _PageReveal(
      active: pageIndex == 2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.sizeOf(context).height -
                MediaQuery.paddingOf(context).vertical -
                52,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: motion,
                    builder: (context, child) {
                      final scale =
                          1 + math.sin(motion.value * math.pi * 2) * 0.02;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: const RydarLogo(size: 42),
                  ),
                ],
              ),
              const SizedBox(height: 42),
              const Text(
                'RYDAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ready to ride?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 44,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Start tracking your rides, save your routes, and create shareable ride cards.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              _LoginCard(
                onGoogleContinue: onContinue,
                isSigningIn: isSigningIn,
              ),
              const SizedBox(height: 30),
              _TextOnboardingButton(
                label: 'Continue as Guest',
                onPressed: onGuestContinue,
              ),
              const SizedBox(height: 8),
              const Text(
                'Guest mode lets you track rides locally without an account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedText, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _ProgressDots(activeIndex: pageIndex),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.onGoogleContinue, required this.isSigningIn});

  final VoidCallback onGoogleContinue;
  final bool isSigningIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'G',
              style: TextStyle(
                color: Color(0xFF1A73E8),
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sign in with Google',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 24,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use your Google account to keep rides, routes, and ride cards together.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          _GoogleOnboardingButton(
            onPressed: isSigningIn ? null : onGoogleContinue,
            isBusy: isSigningIn,
          ),
          const SizedBox(height: 14),
          const Text(
            'No email or password required.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFC8C6C5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: Color(0xFF242424))),
      ),
      child: Row(
        children: [
          const Icon(Icons.navigation_rounded, color: Color(0xFF777777)),
          const Spacer(),
          const Text(
            'RYDAR',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            child: const Text(
              'SKIP',
              style: TextStyle(
                color: Color(0xFF9A9A9A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({
    required this.pageIndex,
    required this.onBack,
    required this.onNext,
  });

  final int pageIndex;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              TextButton(
                onPressed: onBack,
                child: const Text(
                  'BACK',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              _CompactNextButton(onPressed: onNext),
            ],
          ),
          const SizedBox(height: 18),
          _ProgressDots(activeIndex: pageIndex),
        ],
      ),
    );
  }
}

class _PageReveal extends StatelessWidget {
  const _PageReveal({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: active ? Offset.zero : const Offset(0, 0.035),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0.72,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: active ? 1 : 0.985,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          child: child,
        ),
      ),
    );
  }
}

class _MapMockup extends StatelessWidget {
  const _MapMockup({required this.motion});

  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.08),
              blurRadius: 24,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: motion,
          builder: (context, _) {
            return CustomPaint(
              painter: _MapMockupPainter(progress: motion.value),
            );
          },
        ),
      ),
    );
  }
}

class _TrackingFeature extends StatelessWidget {
  const _TrackingFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.orange, size: 26),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryOnboardingButton extends StatelessWidget {
  const _PrimaryOnboardingButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [Text(label.toUpperCase())],
        ),
      ),
    );
  }
}

class _GoogleOnboardingButton extends StatelessWidget {
  const _GoogleOnboardingButton({required this.onPressed, this.isBusy = false});

  final VoidCallback? onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: BorderSide(color: AppColors.glassBorder(0.18)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        child: isBusy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.orange,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF1A73E8),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(child: Text('CONTINUE WITH GOOGLE')),
                ],
              ),
      ),
    );
  }
}

class _TextOnboardingButton extends StatelessWidget {
  const _TextOnboardingButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.orange,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _CompactNextButton extends StatelessWidget {
  const _CompactNextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      child: const Text('NEXT'),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: active ? 32 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.orange : AppColors.panelSoft,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _GlowingRouteBackground extends StatelessWidget {
  const _GlowingRouteBackground({required this.motion});

  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: motion,
      builder: (context, _) {
        return CustomPaint(
          painter: _GlowingRoutePainter(progress: motion.value),
        );
      },
    );
  }
}

class _GlowingRoutePainter extends CustomPainter {
  const _GlowingRoutePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.72,
        size.width * 0.32,
        size.height * 0.44,
        size.width * 0.52,
        size.height * 0.55,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.68,
        size.width * 0.78,
        size.height * 0.24,
        size.width,
        size.height * 0.12,
      );

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18
      ..color = AppColors.orange.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..color = AppColors.orange.withValues(alpha: 0.72);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    final metric = path.computeMetrics().first;
    final markerOffset = metric
        .getTangentForOffset(metric.length * progress)
        ?.position;
    if (markerOffset != null) {
      final pulse = 10 + (math.sin(progress * math.pi * 2) + 1) * 7;
      canvas.drawCircle(
        markerOffset,
        pulse,
        Paint()..color = AppColors.orange.withValues(alpha: 0.10),
      );
      canvas.drawCircle(
        markerOffset,
        5,
        Paint()..color = AppColors.orange.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlowingRoutePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _MapMockupPainter extends CustomPainter {
  const _MapMockupPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0B0C0C),
    );

    final streetPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF333535);
    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.14 + i * 0.11);
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 34), streetPaint);
    }
    for (var i = 0; i < 7; i++) {
      final x = size.width * (0.08 + i * 0.15);
      canvas.drawLine(Offset(x, 0), Offset(x + 42, size.height), streetPaint);
    }

    final route = Path()
      ..moveTo(size.width * 0.12, size.height * 0.82)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.66,
        size.width * 0.38,
        size.height * 0.9,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.2,
        size.width * 0.74,
        size.height * 0.36,
        size.width * 0.88,
        size.height * 0.18,
      );
    final routeGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 14
      ..color = AppColors.orange.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final routePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 5
      ..color = AppColors.orange;
    canvas.drawPath(route, routeGlow);
    final metric = route.computeMetrics().first;
    final routeProgress = (progress * 1.35).clamp(0.0, 1.0);
    canvas.drawPath(
      metric.extractPath(0, metric.length * routeProgress),
      routePaint,
    );

    final current = Offset(size.width * 0.88, size.height * 0.18);
    final pulse = 12 + (math.sin(progress * math.pi * 2) + 1) * 7;
    canvas.drawCircle(
      current,
      pulse,
      Paint()..color = AppColors.orange.withValues(alpha: 0.12),
    );
    canvas.drawCircle(current, 7, Paint()..color = AppColors.orange);
    canvas.drawCircle(
      current,
      17,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.orange.withValues(alpha: 0.5),
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _MapMockupPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
