import 'package:flutter/material.dart';

class TransitionPlaceholder extends StatefulWidget {
  final Widget child;

  const TransitionPlaceholder({
    super.key,
    required this.child,
  });

  @override
  State<TransitionPlaceholder> createState() => _TransitionPlaceholderState();
}

class _TransitionPlaceholderState extends State<TransitionPlaceholder> {
  bool _isTransitionCompleted = false;
  Animation<double>? _animation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isTransitionCompleted) {
      final route = ModalRoute.of(context);
      if (route != null && route.animation != null) {
        _animation = route.animation;
        if (_animation!.isCompleted) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _isTransitionCompleted = true;
              });
            }
          });
        } else {
          _animation!.addStatusListener(_handleStatusChange);
        }
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _isTransitionCompleted = true;
            });
          }
        });
      }
    }
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _animation?.removeStatusListener(_handleStatusChange);
      Future.delayed(const Duration(milliseconds: 500 ), () {
        if (mounted) {
          setState(() {
            _isTransitionCompleted = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animation?.removeStatusListener(_handleStatusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isTransitionCompleted
          ? KeyedSubtree(
              key: const ValueKey('content'),
              child: widget.child,
            )
          : const SizedBox(
              key: ValueKey('empty'),
            ),
    );
  }
}
