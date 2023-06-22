import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

abstract class AnimationState {
  double currentButtonDistance;
  final TickerProvider vsync;
  final VoidCallback onUpdate;
  AnimationState(this.currentButtonDistance, this.vsync, this.onUpdate);
  void dispose();
}

class StretchingAnimationState extends AnimationState {
  AnimationController? _strechingAnimationController;

  StretchingAnimationState(super.currentButtonDistance, super.vsync, super.onUpdate);

  @override
  void dispose() {
    _strechingAnimationController?.dispose();
  }

  void createAnimation(
    double buttonDistanceUntilTear,
    double finalButtonDistance,
    double pixelsPerSecond,
  ) {
    _strechingAnimationController = AnimationController(
      vsync: vsync,
      upperBound: buttonDistanceUntilTear,
      lowerBound: buttonDistanceUntilTear - finalButtonDistance,
    )
      ..addListener(() {
        currentButtonDistance = buttonDistanceUntilTear - _strechingAnimationController!.value;
        onUpdate();
      })
      ..animateWith(GravitySimulation(
        1000,
        buttonDistanceUntilTear - currentButtonDistance,
        buttonDistanceUntilTear,
        pixelsPerSecond,
      ))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          stopAnimation();
        }
      });
  }

  void stopAnimation() {
    _strechingAnimationController?.dispose();
    _strechingAnimationController = null;
  }
}

mixin _ on AnimationController {}
class ButtonAnimationController = AnimationController with _;
class ButtonColorAnimationController = ButtonAnimationController with _;
class ButtonForwardAnimationController = ButtonAnimationController with _;
class ButtonBackwardAnimationController = ButtonAnimationController with _;

class TearedAnimationState extends AnimationState {
  ButtonAnimationController? _buttonAnimationController;
  ButtonAnimationController? get buttonAnimationController => _buttonAnimationController;

  AnimationController? _gumTearAnimationController;
  AnimationController? get gumTearAnimationController => _gumTearAnimationController;

  double menuOpacity = 0;
  double buttonColorChangeProgress = 0;

  TearedAnimationState(super.currentButtonDistance, super.vsync, super.onUpdate);

  bool get hasReturnedToInitialPosition =>
      _buttonAnimationController is ButtonBackwardAnimationController && _buttonAnimationController!.value == 1;

  void animateGumTear() {
    _gumTearAnimationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        onUpdate();
        if (_gumTearAnimationController!.value == 1) {
          _gumTearAnimationController!.dispose();
          _gumTearAnimationController = null;
        }
      });
    _gumTearAnimationController!.forward(from: 0);
  }

  void updateMenuOpacity(double buttonDistanceUntilTear, double finalButtonDistance) {
    menuOpacity =
        max(currentButtonDistance - buttonDistanceUntilTear, 0) / (finalButtonDistance - buttonDistanceUntilTear);
  }

  void animateButtonToFinalPoint(double buttonDistanceUntilTear, double finalButtonDistance) {
    if (currentButtonDistance == finalButtonDistance) {
      menuOpacity = 1;

      _animateButtonColor();
      return;
    }
    _buttonAnimationController = ButtonForwardAnimationController(
      vsync: vsync,
      upperBound: finalButtonDistance,
      lowerBound: currentButtonDistance,
    )..addListener(() {
        currentButtonDistance = _buttonAnimationController!.value;

        updateMenuOpacity(buttonDistanceUntilTear, finalButtonDistance);

        onUpdate();
        if (currentButtonDistance == finalButtonDistance) {
          _animateButtonColor();
        }
      });
    _buttonAnimationController!.animateTo(
      finalButtonDistance,
      curve: Curves.linear,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _animateButtonColor() {
    _buttonAnimationController?.dispose();
    _buttonAnimationController = ButtonColorAnimationController(vsync: vsync)
      ..addListener(() {
        buttonColorChangeProgress = _buttonAnimationController!.value;
        onUpdate();
        if (_buttonAnimationController!.value == 1) {
          _buttonAnimationController!.dispose();
          _buttonAnimationController = null;
        }
      });
    _buttonAnimationController!.animateTo(1, duration: const Duration(milliseconds: 300));
  }

  void animateBackToInitial() {
    _buttonAnimationController?.dispose();
    final previousPadding = currentButtonDistance;
    final previousMenuOpacity = menuOpacity;
    final previousButtonColorChangeProgress = buttonColorChangeProgress;
    _buttonAnimationController = ButtonBackwardAnimationController(vsync: vsync)
      ..addListener(() {
        final reverseProgress = 1 - _buttonAnimationController!.value;
        currentButtonDistance = previousPadding * reverseProgress;
        menuOpacity = previousMenuOpacity * reverseProgress;
        buttonColorChangeProgress = previousButtonColorChangeProgress * reverseProgress;
        onUpdate();
      });
    _buttonAnimationController!.animateTo(1, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _buttonAnimationController?.dispose();
    _gumTearAnimationController?.dispose();
  }
}
