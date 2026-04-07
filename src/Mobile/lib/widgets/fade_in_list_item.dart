import 'package:flutter/material.dart';

class FadeInListItem extends StatefulWidget {
  const FadeInListItem({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<FadeInListItem> createState() => _FadeInListItemState();
}

class _FadeInListItemState extends State<FadeInListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final ms = (280 + (widget.index % 14) * 38).clamp(240, 720);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.07),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
