import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'common_widgets.dart';

/// Animated list item
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AnimatedListItem({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}

/// Swipeable list item
class SwipeableListItem extends StatelessWidget {
  final Widget child;
  final List<SwipeAction> actions;
  final double actionExtentRatio;

  const SwipeableListItem({
    super.key,
    required this.child,
    required this.actions,
    this.actionExtentRatio = 0.25,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      background: Container(
        color: actions.isNotEmpty ? actions.first.backgroundColor : Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          actions.isNotEmpty ? actions.first.icon : Icons.delete,
          color: Colors.white,
        ),
      ),
      secondaryBackground: actions.length > 1
          ? Container(
              color: actions[1].backgroundColor,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Icon(
                actions[1].icon,
                color: Colors.white,
              ),
            )
          : null,
      confirmDismiss: (direction) async {
        final action = direction == DismissDirection.startToEnd
            ? actions.first
            : (actions.length > 1 ? actions[1] : actions.first);

        if (action.confirmationRequired) {
          return await _showConfirmDialog(context, action);
        }

        action.onPressed();
        return false; // Don't dismiss automatically
      },
      child: child,
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context, SwipeAction action) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action.confirmTitle ?? 'Confirm Action'),
        content: Text(action.confirmMessage ?? 'Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              action.onPressed();
            },
            child: Text(
              'Confirm',
              style: TextStyle(color: action.backgroundColor),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
}

/// Swipe action model
class SwipeAction {
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final bool confirmationRequired;
  final String? confirmTitle;
  final String? confirmMessage;

  const SwipeAction({
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
    this.confirmationRequired = false,
    this.confirmTitle,
    this.confirmMessage,
  });
}

/// Expandable list item
class ExpandableListItem extends StatefulWidget {
  final Widget title;
  final Widget content;
  final bool initiallyExpanded;
  final Duration duration;

  const ExpandableListItem({
    super.key,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<ExpandableListItem> createState() => _ExpandableListItemState();
}

class _ExpandableListItemState extends State<ExpandableListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: widget.title),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: widget.duration,
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _animation,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: widget.content,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable list item
class SelectableListItem<T> extends StatelessWidget {
  final T item;
  final bool isSelected;
  final Widget Function(T) itemBuilder;
  final ValueChanged<T>? onTap;
  final ValueChanged<bool>? onSelectionChanged;

  const SelectableListItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.itemBuilder,
    this.onTap,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      onTap: () {
        if (onTap != null) {
          onTap!(item);
        }
        if (onSelectionChanged != null) {
          onSelectionChanged!(!isSelected);
        }
      },
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (onSelectionChanged != null) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: onSelectionChanged,
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(child: itemBuilder(item)),
              if (isSelected && onSelectionChanged == null)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grouped list view
class GroupedListView<T, G> extends StatelessWidget {
  final List<T> items;
  final G Function(T) groupBy;
  final Widget Function(G) groupHeaderBuilder;
  final Widget Function(T) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  const GroupedListView({
    super.key,
    required this.items,
    required this.groupBy,
    required this.groupHeaderBuilder,
    required this.itemBuilder,
    this.controller,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final groupedItems = <G, List<T>>{};

    for (final item in items) {
      final group = groupBy(item);
      groupedItems.putIfAbsent(group, () => []).add(item);
    }

    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final group = groupedItems.keys.elementAt(index);
        final groupItems = groupedItems[group]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: groupHeaderBuilder(group),
            ),
            ...groupItems.map(itemBuilder),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

/// Infinite scroll list view
class InfiniteScrollListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final Future<List<T>> Function() onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  const InfiniteScrollListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.hasMore,
    required this.isLoading,
    this.controller,
    this.padding,
  });

  @override
  State<InfiniteScrollListView<T>> createState() => _InfiniteScrollListViewState<T>();
}

class _InfiniteScrollListViewState<T> extends State<InfiniteScrollListView<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoading) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < widget.items.length) {
          return widget.itemBuilder(widget.items[index]);
        } else {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}

/// Sortable list view
class SortableListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T, int) itemBuilder;
  final ValueChanged<List<T>>? onReorder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  const SortableListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onReorder,
    this.controller,
    this.padding,
  });

  @override
  State<SortableListView<T>> createState() => _SortableListViewState<T>();
}

class _SortableListViewState<T> extends State<SortableListView<T>> {
  late List<T> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(SortableListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _items = List.from(widget.items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      scrollController: widget.controller,
      padding: widget.padding,
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return widget.itemBuilder(_items[index], index);
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });

        if (widget.onReorder != null) {
          widget.onReorder!(_items);
        }
      },
    );
  }
}

/// Grid item widget
class GridItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double aspectRatio;

  const GridItem({
    super.key,
    required this.child,
    this.onTap,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: CustomCard(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Staggered grid view
class StaggeredGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsetsGeometry? padding;

  const StaggeredGridView({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: 0.8, // Adjust as needed
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}