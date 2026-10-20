import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final VoidCallback? onLoadMore;
  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final bool hasMore;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final EdgeInsetsGeometry? padding;
  final Widget? separator;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.onRefresh,
    this.isLoading = false,
    this.hasMore = false,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.padding,
    this.separator,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoading && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.items.isEmpty) {
      return widget.loadingWidget ??
          const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (widget.errorWidget != null && widget.items.isEmpty) {
      return widget.errorWidget!;
    }

    if (widget.items.isEmpty) {
      return widget.emptyWidget ??
          const Center(
            child: Text('No items found',
                style: TextStyle(color: AppColors.textCaption)),
          );
    }

    Widget listView = ListView.separated(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(16),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      separatorBuilder: (context, index) =>
          widget.separator ?? const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        color: AppColors.primary,
        child: listView,
      );
    }

    return listView;
  }
}
