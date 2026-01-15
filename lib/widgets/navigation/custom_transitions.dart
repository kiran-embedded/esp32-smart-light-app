import 'package:flutter/material.dart';

/// 1. CLASSIC IOS SLIDE (Refined for heavy, premium feel)
class IOSTransitionBuilder extends PageTransitionsBuilder {
  const IOSTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Parallax logic for outgoing page can be added if we controlled the secondary animation deeper,
    // but for incoming, we use a distinct shadow and slide.
    final primaryTranslation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Cubic(0.25, 1.0, 0.35, 1.0), // Apple-style Spring
          ),
        );

    return SlideTransition(
      position: primaryTranslation,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: -10,
              offset: const Offset(-20, 0),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// 2. MAGNETIC PULL (Elastic Scale - Snappy)
class MagneticPullTransitionBuilder extends PageTransitionsBuilder {
  const MagneticPullTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut, // TRUE Bounciness
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn)),
        child: child,
      ),
    );
  }
}

/// 3. GRAVITY DROP (Vertical Bounce - Heavy)
class GravityDropTransitionBuilder extends PageTransitionsBuilder {
  const GravityDropTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.0, -0.6), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.bounceOut, // Explicit Bounce
            ),
          ),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

/// 4. BUTTER ZOOM (Ultra Smooth - "Liquid" feel)
/// 4. BUTTER ZOOM (Ultra Smooth - "Liquid" feel)
class NebulaZoomTransitionBuilder extends PageTransitionsBuilder {
  const NebulaZoomTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.fastLinearToSlowEaseIn, // The "Butter" Curve
        ),
      ),
      child: FadeTransition(
        opacity: animation, // Linear fade is smoothest here
        child: child,
      ),
    );
  }
}

/// 5. FLUID FADE (Ghost / Drift)
class NebulaFadeUpwardsTransitionBuilder extends PageTransitionsBuilder {
  const NebulaFadeUpwardsTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Slight vertical drift + slow fade
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuad)),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      ),
    );
  }
}
