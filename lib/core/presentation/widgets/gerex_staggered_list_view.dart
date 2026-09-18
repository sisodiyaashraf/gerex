import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// Inherited Widget to auto-inject stagger indices down the element tree
class StaggerIndexProvider extends InheritedWidget {
  final int index;

  const StaggerIndexProvider({
    super.key,
    required this.index,
    required super.child,
  });

  static int? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StaggerIndexProvider>()?.index;
  }

  @override
  bool updateShouldNotify(StaggerIndexProvider oldWidget) {
    return oldWidget.index != index;
  }
}

class GerexStaggeredListView extends StatefulWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final bool enableParallax;
  final double estimatedItemHeight;
  final Future<void> Function()? onRefresh;
  final ScrollPhysics physics;
  final EdgeInsetsGeometry padding;

  const GerexStaggeredListView({
    super.key,
    required this.children,
    this.controller,
    this.enableParallax = true,
    this.estimatedItemHeight = 96.0,
    this.onRefresh,
    this.physics = const BouncingScrollPhysics(),
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<GerexStaggeredListView> createState() => _GerexStaggeredListViewState();
}

class _GerexStaggeredListViewState extends State<GerexStaggeredListView> {
  late ScrollController _scrollController;
  bool _isLocalController = false;
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _scrollController = widget.controller!;
    } else {
      _scrollController = ScrollController();
      _isLocalController = true;
    }
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      _scrollOffsetNotifier.value = _scrollController.offset;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollOffsetNotifier.dispose();
    if (_isLocalController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listView = ListView.builder(
      controller: _scrollController,
      physics: widget.physics,
      padding: widget.padding,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        final child = widget.children[index];
        
        // Wrap child with index injector
        final staggerWrapped = StaggerIndexProvider(
          index: index,
          child: child,
        );

        if (!widget.enableParallax) {
          return staggerWrapped;
        }

        // Return cheap mathematical parallax item wrapper with ValueNotifier
        return _ParallaxItem(
          index: index,
          scrollOffsetNotifier: _scrollOffsetNotifier,
          estimatedItemHeight: widget.estimatedItemHeight,
          enableParallax: widget.enableParallax,
          child: staggerWrapped,
        );
      },
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        backgroundColor: AppColors.bgDarkPrimary,
        color: AppColors.accentEmeraldLight,
        strokeWidth: 2.5,
        child: listView,
      );
    }

    return listView;
  }
}

// Stateless mathematical parallax depth calculations avoiding expensive listeners and layout queries
class _ParallaxItem extends StatelessWidget {
  final int index;
  final ValueNotifier<double> scrollOffsetNotifier;
  final Widget child;
  final double estimatedItemHeight;
  final bool enableParallax;

  const _ParallaxItem({
    required this.index,
    required this.scrollOffsetNotifier,
    required this.child,
    required this.estimatedItemHeight,
    required this.enableParallax,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableParallax) {
      return child;
    }

    final double viewportHeight = MediaQuery.of(context).size.height;
    final double maxDistance = viewportHeight / 2;
    final double itemTop = index * estimatedItemHeight;
    final double itemCenter = itemTop + (estimatedItemHeight / 2);

    return ValueListenableBuilder<double>(
      valueListenable: scrollOffsetNotifier,
      builder: (context, scrollOffset, childWidget) {
        // Viewport scroll center position
        final double viewportCenter = scrollOffset + (viewportHeight / 2);
        
        // Absolute distance from screen center
        final double distanceFromCenter = (itemCenter - viewportCenter).abs();
        
        // Fraction goes from 0.0 (exact center) to 1.0 (screen edges)
        final double fraction = (distanceFromCenter / maxDistance).clamp(0.0, 1.0);

        // Scale from 1.0 (center) down to 0.96 (edge) - max 4% reduction
        final double scale = 1.0 - (fraction * 0.04);
        
        // Fade from 1.0 (center) down to 0.60 (edge)
        final double opacity = 1.0 - (fraction * 0.40);

        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: Opacity(
            opacity: opacity,
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}
