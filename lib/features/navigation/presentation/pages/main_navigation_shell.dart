import 'dart:async';
import 'package:daily_life_os/config/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../quick_capture/presentation/widgets/floating_quick_ball.dart';
import '../../../quick_capture/presentation/widgets/quick_capture_sheet.dart';
import '../../../../di/injection_container.dart';
import '../../../command_palette/presentation/widgets/global_command_palette_sheet.dart';
import '../../../money/presentation/pages/money_manager_page.dart';
import '../../../notes/presentation/pages/notes_page.dart';
import '../../../planner/presentation/pages/planner_page.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../today_hub/presentation/pages/today_hub_page.dart';
import '../../../vault/presentation/pages/vault_page.dart';
import '../../domain/entities/navigation_tab_entity.dart';
import '../bloc/navigation_bloc.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late final NavigationBloc _navigationBloc;
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    _navigationBloc = sl<NavigationBloc>();
  }

  @override
  void dispose() {
    _navigationBloc.close();
    super.dispose();
  }

  Future<void> _openQuickCapture(
    BuildContext context,
    QuickCaptureMode mode,
  ) async {
    unawaited(HapticFeedback.selectionClick());
    final result = await QuickCaptureSheet.show(context, mode: mode);
    if (!mounted) return;
    _navigationBloc.add(const RefreshCapturedModules());
    if (result != null && context.mounted) {
      SnackbarUtils.showAction(
        context,
        message: '${StringConstants.quickCaptureSavedPrefix} ${result.summary}',
        actionLabel: StringConstants.viewAction,
        onAction: () =>
            _navigationBloc.add(SelectNavigationTab(result.targetTabIndex)),
      );
    }
  }

  Future<void> _openCommandPalette(BuildContext context) async {
    await GlobalCommandPaletteSheet.show(
      context,
      onNavigateTab: (index) => _navigationBloc.add(SelectNavigationTab(index)),
      onOpenQuickCapture: (mode) => _openQuickCapture(context, mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return BlocProvider<NavigationBloc>.value(
      value: _navigationBloc,
      child: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, navState) {
          final gen = navState.captureRefreshGeneration;
          final currentIndex = navState.currentIndex;
          final isInMoneyMode = navState.isInMoneyMode;
          _visitedTabs.add(currentIndex);

          final pages = <Widget>[
            TodayHubPage(
              key: ValueKey('today_$gen'),
              onNavigateToTab: (index) =>
                  _navigationBloc.add(SelectNavigationTab(index)),
              onOpenQuickCapture: (mode) => _openQuickCapture(context, mode),
            ),
            _visitedTabs.contains(1)
                ? PlannerPage(key: ValueKey('planner_$gen'))
                : const SizedBox.shrink(),
            _visitedTabs.contains(2)
                ? MoneyManagerPage(
                    key: ValueKey('money_$gen'),
                    onExitMoney: () =>
                        _navigationBloc.add(const ExitMoneyNavigationMode()),
                  )
                : const SizedBox.shrink(),
            _visitedTabs.contains(3)
                ? NotesPage(key: ValueKey('notes_$gen'))
                : const SizedBox.shrink(),
            _visitedTabs.contains(4)
                ? const VaultPage()
                : const SizedBox.shrink(),
          ];

          return Scaffold(
            backgroundColor: palette.scaffold,
            body: Stack(
              children: [
                IndexedStack(index: currentIndex, children: pages),

                // Movable, minimizable Floating Quick-Capture Ball & Capsule
                // (hidden while inside Money or when disabled in Profile preferences)
                if (!isInMoneyMode)
                  Positioned.fill(
                    child: BlocBuilder<ProfileBloc, ProfileState>(
                      bloc: sl.isRegistered<ProfileBloc>()
                          ? sl<ProfileBloc>()
                          : null,
                      buildWhen: (prev, curr) =>
                          prev.profile.showFloatingQuickBall !=
                          curr.profile.showFloatingQuickBall,
                      builder: (context, profileState) {
                        if (!profileState.profile.showFloatingQuickBall) {
                          return const SizedBox.shrink();
                        }
                        return FloatingQuickBall(
                          onSelectMode: (mode) =>
                              _openQuickCapture(context, mode),
                          onOpenSpotlight: () => _openCommandPalette(context),
                        );
                      },
                    ),
                  ),
              ],
            ),
            // Main 5-tab bar closes/hides when entering Money; Money renders its own
            // bottom bar and pressing Back restores the main bar.
            bottomNavigationBar: isInMoneyMode
                ? null
                : Container(
                    decoration: BoxDecoration(
                      color: palette.card,
                      border: Border(top: BorderSide(color: palette.divider)),
                      boxShadow: palette.isDark
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.04),
                                blurRadius: 14,
                                offset: const Offset(0, -3),
                              ),
                            ],
                    ),
                    child: BottomNavigationBar(
                      key: const ValueKey('main_bottom_nav_bar'),
                      currentIndex: currentIndex,
                      onTap: (index) {
                        unawaited(HapticFeedback.selectionClick());
                        _navigationBloc.add(SelectNavigationTab(index));
                      },
                      type: BottomNavigationBarType.fixed,
                      elevation: 0,
                      backgroundColor: palette.card,
                      selectedItemColor: NavigationTabEntity.activeColorFor(
                        currentIndex,
                      ),
                      unselectedItemColor: palette.caption,
                      selectedLabelStyle: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      items: NavigationTabEntity.tabs.map((tab) {
                        final activeColor = NavigationTabEntity.activeColorFor(
                          tab.index,
                        );
                        return BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Icon(tab.icon, size: 22),
                          ),
                          activeIcon: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: activeColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              tab.activeIcon,
                              size: 22,
                              color: activeColor,
                            ),
                          ),
                          label: tab.label,
                        );
                      }).toList(),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
