import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../daily/presentation/daily_view_screen.dart';
import '../../friends/presentation/friends_list_screen.dart';

class AppShellController {
  const AppShellController({
    required this.currentIndex,
    required this.animateToPage,
  });

  final int currentIndex;
  final void Function(int index) animateToPage;

  void showDaily() => animateToPage(0);

  void showFriends() => animateToPage(1);
}

class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final AppShellController controller;

  static AppShellController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppShellScope>();
    assert(scope != null, 'No AppShellScope found in context');
    return scope!.controller;
  }

  static AppShellController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) {
    return controller.currentIndex != oldWidget.controller.currentIndex;
  }
}

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key, required this.child});

  /// Router child — expected to be a no-op page for the base routes.
  /// Kept in the tree (offstage) to respect GoRouter’s builder contract.
  final Widget child;

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  late final PageController _pageController;
  bool _isInitialized = false;
  bool _isSyncingFromRouter = false;

  int _currentIndex = 0;

  static int _indexForPath(String path) {
    if (path.startsWith('/friends')) return 1;
    return 0;
  }

  static String _pathForIndex(int index) {
    return index == 1 ? '/friends' : '/';
  }

  void _syncWithRouterPath(String path) {
    final desiredIndex = _indexForPath(path);
    if (desiredIndex == _currentIndex) return;

    _isSyncingFromRouter = true;
    setState(() => _currentIndex = desiredIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_pageController.hasClients) return;
      _pageController.jumpToPage(desiredIndex);
    });
  }

  void _animateToPage(int index) {
    if (!_pageController.hasClients) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final path = GoRouterState.of(context).uri.path;

    if (!_isInitialized) {
      _currentIndex = _indexForPath(path);
      _pageController = PageController(initialPage: _currentIndex);
      _isInitialized = true;
      return;
    }

    // Only auto-sync for the base page namespaces.
    if (path == '/' || path.startsWith('/friends')) {
      _syncWithRouterPath(path);
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _pageController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppShellController(
      currentIndex: _currentIndex,
      animateToPage: _animateToPage,
    );

    final path = GoRouterState.of(context).uri.path;
    final isBaseLocation = path == '/' || path == '/friends';
    final routerCanPop = GoRouter.of(context).canPop();
    final indicatorLabel = context.l10n.shellPageIndicatorSemantics(
      _currentIndex == 0 ? context.l10n.dailyTitle : context.l10n.friendsTitle,
    );

    return AppShellScope(
      controller: controller,
      child: PopScope(
        canPop: routerCanPop || _currentIndex == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (routerCanPop) return;
          if (_currentIndex != 1) return;
          _animateToPage(0);
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);

                if (_isSyncingFromRouter) {
                  _isSyncingFromRouter = false;
                  return;
                }

                final target = _pathForIndex(index);
                if (path != target) context.go(target);
              },
              itemCount: 2,
              itemBuilder: (context, index) {
                return switch (index) {
                  0 => const DailyViewScreen(),
                  1 => const FriendsListScreen(),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Semantics(
                    label: indicatorLabel,
                    child: ExcludeSemantics(
                      child: _TwoDotIndicator(activeIndex: _currentIndex),
                    ),
                  ),
                ),
              ),
            ),
            // Render overlay routes (friends detail, settings, etc.) above the
            // shell without interfering with swipe gestures on base pages.
            Offstage(offstage: isBaseLocation, child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _TwoDotIndicator extends StatelessWidget {
  const _TwoDotIndicator({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = scheme.primary;
    final inactiveColor = scheme.onSurfaceVariant.withValues(alpha: 0.5);

    Widget dot({required bool isActive}) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? activeColor : inactiveColor,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(isActive: activeIndex == 0),
        const SizedBox(width: 8),
        dot(isActive: activeIndex == 1),
      ],
    );
  }
}
