import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';
import '../monitoring/app_monitor.dart';
import 'app_empty_state.dart';
import 'app_shimmer_loader.dart';

/// The lifecycle state a feature screen is currently in.
enum FeatureStatus { loading, error, empty, content }

/// One scaffold for every top-level feature screen.
///
/// It owns the things every screen used to re-implement by hand:
///  * a consistent app bar (20px gutter, 20/700 title, optional subtitle,
///    leading avatar/back button, trailing badge, actions, tab bar),
///  * page background colour for light & dark mode,
///  * loading skeleton, error + retry, and empty states,
///  * a smooth cross-fade between those states,
///  * optional pull-to-refresh.
///
/// Usage:
/// ```dart
/// FeatureScaffold(
///   title: 'Notes',
///   status: state.toFeatureStatus(),
///   errorMessage: state is NotesError ? state.message : null,
///   onRetry: () => bloc.add(const LoadNotes()),
///   builder: (context) => NotesList(...),
/// )
/// ```
class FeatureScaffold extends StatelessWidget {
  /// Page title (rendered with `headlineMedium`, 20/700).
  final String? title;

  /// Optional small line rendered under the title (e.g. today's date).
  final String? subtitle;

  /// Widget rendered left of the title (e.g. profile avatar).
  final Widget? leading;

  /// Small widget rendered right after the title (e.g. a count badge).
  final Widget? titleTrailing;

  /// When set, a back button is shown and this callback is invoked on tap.
  final VoidCallback? onBack;

  /// Optional callback when tapping the title/leading area (e.g., to open Profile).
  final VoidCallback? onTitleTap;

  /// App bar actions. The last action sits on the 20px page gutter.
  final List<Widget> actions;

  /// Extra right padding for the action row. Use [AppSpacing.pageGutter] when
  /// the last action is a custom pill (no built-in 48px tap padding).
  final double actionsEndPadding;

  /// Optional tab bar / segmented control under the title.
  final PreferredSizeWidget? bottom;

  /// Hide the app bar entirely (the body is then wrapped in a [SafeArea]).
  final bool showAppBar;

  /// Current screen state.
  final FeatureStatus status;

  /// Builds the content. Only invoked when [status] is [FeatureStatus.content].
  final WidgetBuilder builder;

  /// Custom skeleton. Defaults to [FeatureLoadingView].
  final Widget? loading;

  /// Message shown for [FeatureStatus.error].
  final String? errorMessage;

  /// Retry callback for the error state.
  final VoidCallback? onRetry;

  /// Widget shown for [FeatureStatus.empty]. Defaults to a generic empty view.
  final Widget? empty;

  /// Enables pull-to-refresh on the content.
  final Future<void> Function()? onRefresh;

  /// Accent colour for the refresh indicator and default empty state.
  final Color accentColor;

  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const FeatureScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.titleTrailing,
    this.onBack,
    this.onTitleTap,
    this.actions = const [],
    this.actionsEndPadding = AppSpacing.pageGutter,
    this.bottom,
    this.showAppBar = true,
    this.status = FeatureStatus.content,
    required this.builder,
    this.loading,
    this.errorMessage,
    this.onRetry,
    this.empty,
    this.onRefresh,
    this.accentColor = AppColors.primary,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bg = backgroundColor ?? palette.scaffold;

    Widget body = FeatureStateView(
      status: status,
      builder: builder,
      loading: loading,
      errorMessage: errorMessage,
      onRetry: onRetry,
      empty: empty,
      accentColor: accentColor,
    );

    if (onRefresh != null && status == FeatureStatus.content) {
      body = RefreshIndicator(
        onRefresh: onRefresh!,
        color: accentColor,
        backgroundColor: palette.card,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: showAppBar ? _buildAppBar(context, bg) : null,
      body: showAppBar ? body : SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color bg) {
    final text = context.text;
    final palette = context.palette;
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    return AppBar(
      backgroundColor: bg,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: hasSubtitle ? 64 : 56,
      titleSpacing: onBack != null ? 0 : AppSpacing.pageGutter,
      actionsPadding: EdgeInsets.only(right: actionsEndPadding),
      leading: onBack == null
          ? null
          : IconButton(
              tooltip: 'Back',
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: palette.heading,
              ),
              onPressed: onBack,
            ),
      title: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            fit: titleTrailing == null ? FlexFit.tight : FlexFit.loose,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTitleTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AppText(
                        title!,
                        maxLines: 1,
                        style: text.headlineMedium?.copyWith(
                          fontSize: hasSubtitle ? 18.0 : 20.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.35,
                          height: 1.2,
                          color: palette.heading,
                        ),
                      ),
                    ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AppText(
                        subtitle!,
                        maxLines: 1,
                        style: text.labelMedium?.copyWith(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: palette.caption,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (titleTrailing != null) ...[
            AppSpacing.gapW8,
            Flexible(child: titleTrailing!),
          ],
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}

/// Cross-fades between loading / error / empty / content.
/// Can also be used on its own inside a section of a screen.
class FeatureStateView extends StatelessWidget {
  final FeatureStatus status;
  final WidgetBuilder builder;
  final Widget? loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget? empty;
  final Color accentColor;

  const FeatureStateView({
    super.key,
    required this.status,
    required this.builder,
    this.loading,
    this.errorMessage,
    this.onRetry,
    this.empty,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child;
    switch (status) {
      case FeatureStatus.loading:
        child = loading ?? const FeatureLoadingView();
        break;
      case FeatureStatus.error:
        child = FeatureErrorView(message: errorMessage, onRetry: onRetry);
        break;
      case FeatureStatus.empty:
        child =
            empty ??
            AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Nothing here yet',
              description: 'Items you add will show up here.',
              iconColor: accentColor,
            );
        break;
      case FeatureStatus.content:
        child = Builder(builder: builder);
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: KeyedSubtree(key: ValueKey(status), child: child),
    );
  }
}

/// Default calm skeleton: a stack of card placeholders on the page gutter.
class FeatureLoadingView extends StatelessWidget {
  final List<double> blockHeights;

  const FeatureLoadingView({
    super.key,
    this.blockHeights = const [140, 96, 120, 200],
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.xs,
        AppSpacing.pageGutter,
        AppSpacing.xl,
      ),
      itemCount: blockHeights.length,
      separatorBuilder: (_, _) => AppSpacing.gapH12,
      itemBuilder: (_, i) => AppShimmerLoader.card(height: blockHeights[i]),
    );
  }
}

/// Calm, centred user-friendly error state with plain-language explanation,
/// data-safety reassurance, and an optional retry button.
class FeatureErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const FeatureErrorView({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final friendly = AppMonitor.toUserFriendlyError(message);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: friendly.accentColor.withValues(
                    alpha: palette.isDark ? 0.20 : 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  friendly.icon,
                  size: 28,
                  color: friendly.accentColor,
                ),
              ),
              AppSpacing.gapH16,
              AppText(
                friendly.title,
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.heading,
                ),
              ),
              AppSpacing.gapH8,
              AppText(
                friendly.message,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(
                  color: palette.body,
                  height: 1.4,
                ),
              ),
              AppSpacing.gapH12,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted.withValues(
                    alpha: palette.isDark ? 0.50 : 0.75,
                  ),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 15,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: AppText.caption(
                        friendly.reassurance,
                        textAlign: TextAlign.center,
                        color: palette.caption,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRetry != null) ...[
                AppSpacing.gapH20,
                OutlinedButton.icon(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.heading,
                    side: BorderSide(color: palette.border),
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: text.labelLarge,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: AppText(friendly.actionLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Consistent section header: title on the left, caption or action on the right.
class FeatureSectionHeader extends StatelessWidget {
  final String title;
  final String? trailingText;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const FeatureSectionHeader({
    super.key,
    required this.title,
    this.trailingText,
    this.actionLabel,
    this.onAction,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 28),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                title,
                softWrap: true,
                style: text.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: context.palette.heading,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: text.labelLarge?.copyWith(fontSize: 13),
                ),
                child: AppText(actionLabel!),
              )
            else if (trailingText != null)
              AppText(
                trailingText!,
                style: text.labelMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Standard surface card: card colour, 16px radius, 1px hairline border.
class FeatureCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const FeatureCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
        side: BorderSide(color: borderColor ?? palette.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Compact accent pill for primary app-bar actions ("New Note", "New Task").
class FeatureHeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const FeatureHeaderButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.textWhite,
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: context.text.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: Icon(icon, size: 16),
        label: AppText(label),
      ),
    );
  }
}

/// Squircle icon action used in app bars (briefing, settings, lock, etc.).
class FeatureIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;

  const FeatureIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size(36, 36),
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: backgroundColor ?? palette.card,
        side: BorderSide(color: borderColor ?? palette.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      icon: Icon(icon, size: 18, color: color ?? palette.heading),
    );
  }
}
