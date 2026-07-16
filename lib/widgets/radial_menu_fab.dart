import 'package:flutter/material.dart';
import 'dart:math' as math;

class RadialMenuItem {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;
  final Color? iconColor;

  RadialMenuItem({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
    this.iconColor,
  });
}

class RadialMenuFab extends StatefulWidget {
  final List<RadialMenuItem> items;
  final IconData mainIcon;
  final VoidCallback? onMainTap;
  final double radius;

  const RadialMenuFab({
    super.key,
    required this.items,
    this.mainIcon = Icons.add,
    this.onMainTap,
    this.radius = 120.0,
  });

  @override
  State<RadialMenuFab> createState() => _RadialMenuFabState();
}

class _RadialMenuFabState extends State<RadialMenuFab> {
  OverlayEntry? _overlayEntry;
  bool _isOverlayOpen = false;
  final GlobalKey<_RadialMenuOverlayWidgetState> _overlayKey = GlobalKey();

  void _toggleOverlay(BuildContext context) {
    if (_isOverlayOpen) {
      _overlayKey.currentState?.closeMenu();
      return;
    }

    _isOverlayOpen = true;
    final renderBox = context.findRenderObject() as RenderBox;
    final fabPosition = renderBox.localToGlobal(renderBox.size.center(Offset.zero));

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return _RadialMenuOverlayWidget(
          key: _overlayKey,
          items: widget.items,
          mainIcon: widget.mainIcon,
          radius: widget.radius,
          fabPosition: fabPosition,
          onClosed: _removeOverlay,
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _isOverlayOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'radial_main',
      elevation: 6,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      onPressed: () => _toggleOverlay(context),
      child: Icon(widget.mainIcon),
    );
  }
}

class _RadialMenuOverlayWidget extends StatefulWidget {
  final List<RadialMenuItem> items;
  final IconData mainIcon;
  final double radius;
  final Offset fabPosition;
  final VoidCallback onClosed;

  const _RadialMenuOverlayWidget({
    super.key,
    required this.items,
    required this.mainIcon,
    required this.radius,
    required this.fabPosition,
    required this.onClosed,
  });

  @override
  State<_RadialMenuOverlayWidget> createState() => _RadialMenuOverlayWidgetState();
}

class _RadialMenuOverlayWidgetState extends State<_RadialMenuOverlayWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void closeMenu([VoidCallback? action]) {
    _controller.reverse().then((_) {
      if (action != null) action();
      widget.onClosed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => closeMenu(),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              color: Colors.black.withValues(alpha: 0.5 * _animation.value),
              child: Stack(
                children: [
                  // Radial items
                  ...List.generate(widget.items.length, (index) {
                    double startAngle = -math.pi; // Left
                    double endAngle = -math.pi / 2; // Top
                    
                    double angle;
                    if (widget.items.length == 1) {
                      angle = -math.pi * 3 / 4;
                    } else {
                      angle = startAngle + (endAngle - startAngle) * (index / (widget.items.length - 1));
                    }
                    
                    // Interpolate position from fab center to target
                    final targetPos = Offset(
                      widget.fabPosition.dx + widget.radius * math.cos(angle),
                      widget.fabPosition.dy + widget.radius * math.sin(angle),
                    );
                    
                    final currentPos = Offset.lerp(widget.fabPosition, targetPos, _animation.value)!;
                    
                    return Positioned(
                      left: currentPos.dx - 28, 
                      top: currentPos.dy - 28,
                      child: Transform.scale(
                        scale: _animation.value,
                        child: FloatingActionButton(
                          heroTag: 'radial_$index',
                          elevation: 4,
                          backgroundColor: widget.items[index].color ?? Theme.of(context).colorScheme.primary,
                          foregroundColor: widget.items[index].iconColor ?? Theme.of(context).colorScheme.onPrimary,
                          onPressed: () {
                            closeMenu(widget.items[index].onTap);
                          },
                          child: Icon(widget.items[index].icon),
                        ),
                      ),
                    );
                  }),
                  
                  // Tooltips
                  ...List.generate(widget.items.length, (index) {
                    double startAngle = -math.pi;
                    double endAngle = -math.pi / 2;
                    double angle = widget.items.length == 1
                        ? -math.pi * 3 / 4
                        : startAngle + (endAngle - startAngle) * (index / (widget.items.length - 1));
                        
                    final targetPos = Offset(
                      widget.fabPosition.dx + widget.radius * math.cos(angle),
                      widget.fabPosition.dy + widget.radius * math.sin(angle),
                    );
                    
                    final currentPos = Offset.lerp(widget.fabPosition, targetPos, _animation.value)!;

                    return Positioned(
                      left: currentPos.dx - 40,
                      top: currentPos.dy + 30, // below the button
                      width: 80,
                      child: Opacity(
                        opacity: _animation.value,
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  )
                                ]
                              ),
                              child: Text(
                                widget.items[index].tooltip,
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Main FAB button (centered) to close
                  Positioned(
                    left: widget.fabPosition.dx - 28,
                    top: widget.fabPosition.dy - 28,
                    child: Transform.rotate(
                      angle: _animation.value * math.pi / 4, // rotates to form an X if it was a +
                      child: FloatingActionButton(
                        heroTag: 'radial_main_active',
                        elevation: 6,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(
                          alpha: 1.0 - (0.6 * _animation.value),
                        ),
                        foregroundColor: Theme.of(context).colorScheme.onPrimary.withValues(
                          alpha: 1.0 - (0.3 * _animation.value),
                        ),
                        onPressed: () => closeMenu(),
                        child: Icon(widget.mainIcon),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
