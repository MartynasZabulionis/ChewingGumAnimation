import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gum/stream_builder_with_widget_holder.dart';

import 'animation_states.dart';
import 'gum_paint.dart';

class GumAnimation extends StatefulWidget {
  final double buttonDiameter;
  final Widget initialScreen;
  final Widget menuList;
  final Color mainColor;
  final Color finalColor;
  final double bottomPadding;
  const GumAnimation({
    super.key,
    required this.buttonDiameter,
    required this.initialScreen,
    required this.menuList,
    required this.mainColor,
    required this.finalColor,
    required this.bottomPadding,
  });

  @override
  State<GumAnimation> createState() => _GumAnimationState();
}

class _GumAnimationState extends State<GumAnimation> with TickerProviderStateMixin {
  double buttonDistanceUntilTear = 0;
  double finalButtonDistance = 0;

  final _animationStateDispatcher = StreamController<AnimationState>.broadcast(sync: true);

  late var _animationState = _getAnimationInitialState();

  AnimationState _getAnimationInitialState() {
    return StretchingAnimationState(
      0,
      this,
      () {
        _animationStateDispatcher.add(_animationState);
        _checkIfTear(isDragged: false);
      },
    );
  }

  void _checkIfTear({required bool isDragged}) {
    if (_animationState.currentButtonDistance >= buttonDistanceUntilTear) {
      _tear(isDragged: isDragged);
    }
  }

  void _setNewAnimationState(AnimationState state) {
    _animationState.dispose();
    _animationState = state;
    _animationStateDispatcher.add(_animationState);
  }

  void _tear({required bool isDragged}) {
    final newState = TornAnimationState(
      _animationState.currentButtonDistance,
      this,
      () {
        _animationStateDispatcher.add(_animationState);

        if ((_animationState as TornAnimationState).downwardAnimationProgress == 1) {
          _setNewAnimationState(_getAnimationInitialState());
        }
      },
    );
    _setNewAnimationState(newState);
    newState.animateGumTear();

    if (!isDragged) {
      newState.animateButtonToFinalPoint(buttonDistanceUntilTear, finalButtonDistance);
    }
  }

  late var _colorTween = ColorTween(begin: widget.mainColor, end: widget.finalColor);

  @override
  void dispose() {
    _animationState.dispose();
    _animationStateDispatcher.close();
    super.dispose();
  }

  final _menuListKey = GlobalKey();

  void _setTearDistanceIfNeeded() {
    if (buttonDistanceUntilTear == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        buttonDistanceUntilTear = _menuListKey.currentContext!.size!.height;

        // This is needed for release build
        if (buttonDistanceUntilTear == 0) {
          _setTearDistanceIfNeeded();
          return;
        }

        finalButtonDistance = buttonDistanceUntilTear + 50;
      });
    }
  }

  @override
  void didUpdateWidget(covariant GumAnimation oldWidget) {
    if (oldWidget.menuList != widget.menuList) {
      buttonDistanceUntilTear = 0;
    }
    _colorTween = ColorTween(begin: widget.mainColor, end: widget.finalColor);
    super.didUpdateWidget(oldWidget);
  }

  GumState _stateToGumState(AnimationState state) {
    if (state is StretchingAnimationState) {
      return GumStretchingState(state.currentButtonDistance);
    }
    state as TornAnimationState;
    return GumTornState(
      state.gumTearingProgress,
      state.downwardAnimationProgress,
    );
  }

  double _stateToMenuOpacity(AnimationState state) {
    if (state is TornAnimationState) {
      return state.menuOpacity;
    }
    return 0;
  }

  bool _stateToInitialScreenIgnorePoint(AnimationState state) {
    return state is! StretchingAnimationState || state.currentButtonDistance > 0;
  }

  bool _stateToButtonIgnorePoint(AnimationState state) {
    return state is TornAnimationState &&
        (state.buttonAnimationType == ButtonAnimationType.upward ||
            state.buttonAnimationType == ButtonAnimationType.upward);
  }

  double _stateToButtonColorProgress(AnimationState state) {
    return state is TornAnimationState ? state.buttonColorChangeProgress : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    _setTearDistanceIfNeeded();

    return Stack(
      alignment: Alignment.bottomCenter,
      // Give children tight constraints so that RenderStack doesn't relayout & repaint
      // when some child rebuilds
      fit: StackFit.expand,
      children: [
        StreamBuilderWithCachedChild(
          initialValue: _stateToInitialScreenIgnorePoint(_animationState),
          stream: _animationStateDispatcher.stream.map(_stateToInitialScreenIgnorePoint).distinct(),
          builder: (context, child, ignoring) {
            return IgnorePointer(
              ignoring: ignoring,
              child: child,
            );
          },
          childBuilder: () => widget.initialScreen,
        ),
        ...[
          IgnorePointer(
            ignoring: true,
            child: StreamBuilder<GumState>(
                initialData: _stateToGumState(_animationState),
                stream: _animationStateDispatcher.stream.map(_stateToGumState).distinct(),
                builder: (context, snapshot) {
                  return GumPaint(
                    gumState: snapshot.data!,
                    maxPixels: buttonDistanceUntilTear,
                    buttonDiameter: widget.buttonDiameter,
                    colorTween: _colorTween,
                    bottomPadding: widget.bottomPadding,
                  );
                }),
          ),
          StreamBuilderWithCachedChild(
            initialValue: _stateToMenuOpacity(_animationState),
            stream: _animationStateDispatcher.stream.map(_stateToMenuOpacity).distinct(),
            builder: (context, child, opacity) {
              return IgnorePointer(
                ignoring: opacity != 1,
                child: Opacity(
                  key: _menuListKey,
                  opacity: opacity,
                  child: child,
                ),
              );
            },
            childBuilder: () => widget.menuList,
          ),
          StreamBuilderWithCachedChild(
            initialValue: _stateToButtonIgnorePoint(_animationState),
            stream: _animationStateDispatcher.stream.map(_stateToButtonIgnorePoint).distinct(),
            builder: (context, child, ignoring) {
              return IgnorePointer(
                ignoring: ignoring,
                child: child,
              );
            },
            childBuilder: () {
              return StreamBuilderWithCachedChild(
                initialValue: _animationState.currentButtonDistance,
                stream:
                    _animationStateDispatcher.stream.map((e) => e.currentButtonDistance).distinct(),
                builder: (context, child, currentButtonDistance) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: widget.bottomPadding + currentButtonDistance),
                    child: child,
                  );
                },
                childBuilder: () {
                  return GestureDetector(
                    onPanDown: (details) {
                      final state = _animationState;
                      if (state is StretchingAnimationState) {
                        state.stopAnimation();
                      } else if (state is TornAnimationState) {
                        state.animateBackToInitial();
                      }
                    },
                    onPanUpdate: (details) {
                      final state = _animationState;
                      if (state is TornAnimationState &&
                          state.buttonAnimationType == ButtonAnimationType.downward) {
                        return;
                      }

                      state.currentButtonDistance -= details.delta.dy;
                      if (state.currentButtonDistance < 0) {
                        state.currentButtonDistance = 0;
                      } else if (state.currentButtonDistance > finalButtonDistance) {
                        state.currentButtonDistance = finalButtonDistance;
                      }

                      if (state is TornAnimationState) {
                        state.updateMenuOpacity(buttonDistanceUntilTear, finalButtonDistance);
                      }
                      _animationStateDispatcher.add(state);
                      if (state is StretchingAnimationState) {
                        _checkIfTear(isDragged: true);
                      }
                    },
                    onPanEnd: (details) {
                      final state = _animationState;
                      final pixelsPerSecond = details.velocity.pixelsPerSecond.dy;
                      if (state is StretchingAnimationState) {
                        state.createAnimation(
                          buttonDistanceUntilTear,
                          finalButtonDistance,
                          pixelsPerSecond,
                        );
                      } else if (state is TornAnimationState &&
                          state.buttonColorChangeProgress == 0) {
                        if (pixelsPerSecond <= 0) {
                          state.animateButtonToFinalPoint(
                              buttonDistanceUntilTear, finalButtonDistance);
                        } else {
                          state.animateBackToInitial();
                        }
                      }
                    },
                    child: StreamBuilder(
                        initialData: _stateToButtonColorProgress(_animationState),
                        stream: _animationStateDispatcher.stream
                            .map(_stateToButtonColorProgress)
                            .distinct(),
                        builder: (context, snapshot) {
                          final progress = snapshot.data!;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.square(
                                dimension: widget.buttonDiameter,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: _colorTween.lerp(progress),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.add,
                                color: _colorTween.lerp(1 - progress),
                              )
                            ],
                          );
                        }),
                  );
                },
              );
            },
          ),
        ].map((e) {
          return RepaintBoundary(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: e,
            ),
          );
        })
      ],
    );
  }
}
