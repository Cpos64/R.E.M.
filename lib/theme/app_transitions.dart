// lib/theme/app_transitions.dart
//
// Centralized navigation transitions so every screen push in the app feels
// consistent and "playful" instead of relying on the plain default
// MaterialPageRoute platform transition. Use `AppPageRoute` in place of
// `MaterialPageRoute` for full-screen pushes, and `showAnimatedModalBottomSheet`
// in place of `showModalBottomSheet` for sheets.
import 'package:flutter/material.dart';

/// Drop-in replacement for `MaterialPageRoute` that slides the new screen up
/// from the bottom while fading in, giving navigation a bit of "spring" /
/// game-like motion instead of the flat default push.
///
/// Usage:
/// ```dart
/// Navigator.push(context, AppPageRoute(builder: (_) => SettingsScreen()));
/// ```
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Same motion as [AppPageRoute] but used for named routes (via
/// `onGenerateRoute`), since `MaterialApp.routes` can't produce custom
/// PageRouteBuilders directly.
Route<dynamic> appRouteBuilder(
  RouteSettings settings,
  WidgetBuilder builder,
) {
  return AppPageRoute(builder: builder, settings: settings);
}

/// Shows a modal bottom sheet, matching the app's transparent/rounded-top
/// sheet convention used elsewhere. The sheet's *content* should wrap itself
/// (or key widgets inside it) with `.animate()` from `flutter_animate` for
/// an entrance "pop" — see `MultiDreamEntryModal` for the pattern — since
/// `showModalBottomSheet` itself only exposes a raw AnimationController for
/// custom transitions (fiddly to own/dispose correctly here).
Future<T?> showAnimatedModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color backgroundColor = Colors.transparent,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    builder: builder,
  );
}
