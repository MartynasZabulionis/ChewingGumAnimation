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

enum ButtonAnimationType {
  color,
  upward,
  downward,
}

class ButtonAnimationController extends AnimationController {
  final ButtonAnimationType type;

  ButtonAnimationController({
    required this.type,
    required super.vsync,
    super.lowerBound = 0.0,
    super.upperBound = 1.0,
  });
}

class TornAnimationState extends AnimationState {
  ButtonAnimationController? _buttonAnimationController;

  ButtonAnimationType? get buttonAnimationType {
    return _buttonAnimationController?.type;
  }

  AnimationController? _gumTearAnimationController;

  double _gumTearProgress = 0;
  double get gumTearingProgress => _gumTearProgress;

  double _menuOpacity = 0;
  double get menuOpacity => _menuOpacity;

  double _buttonColorChangeProgress = 0;
  double get buttonColorChangeProgress => _buttonColorChangeProgress;

  double get downwardAnimationProgress =>
      buttonAnimationType == ButtonAnimationType.downward ? _buttonAnimationController!.value : 0;

  TornAnimationState(
    super.currentButtonDistance,
    super.vsync,
    super.onUpdate,
  );

  bool get hasReturnedToInitialPosition =>
      buttonAnimationType == ButtonAnimationType.downward && _buttonAnimationController!.value == 1;

  void animateGumTear() {
    _gumTearAnimationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        _gumTearProgress = _gumTearAnimationController!.value;
        onUpdate();
        if (_gumTearProgress == 1) {
          _gumTearAnimationController!.dispose();
          _gumTearAnimationController = null;
        }
      });
    _gumTearAnimationController!.forward(from: 0);
  }

  void updateMenuOpacity(double buttonDistanceUntilTear, double finalButtonDistance) {
    _menuOpacity = max(currentButtonDistance - buttonDistanceUntilTear, 0) /
        (finalButtonDistance - buttonDistanceUntilTear);
  }

  void animateButtonToFinalPoint(double buttonDistanceUntilTear, double finalButtonDistance) {
    if (currentButtonDistance == finalButtonDistance) {
      _menuOpacity = 1;

      _animateButtonColor();
      return;
    }
    _buttonAnimationController = ButtonAnimationController(
      type: ButtonAnimationType.upward,
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
    _buttonAnimationController = ButtonAnimationController(
      type: ButtonAnimationType.color,
      vsync: vsync,
    )..addListener(() {
        _buttonColorChangeProgress = _buttonAnimationController!.value;
        onUpdate();
        if (_buttonAnimationController!.value == 1) {
          _buttonAnimationController!.dispose();
          _buttonAnimationController = null;
        }
      });
    _buttonAnimationController!.animateTo(1, duration: const Duration(milliseconds: 300));
  }

  void animateBackToInitial() {
    final previousButtonDistance = currentButtonDistance;
    final previousMenuOpacity = menuOpacity;
    final previousButtonColorChangeProgress = buttonColorChangeProgress;

    _buttonAnimationController?.dispose();
    _buttonAnimationController = ButtonAnimationController(
      type: ButtonAnimationType.downward,
      vsync: vsync,
    )..addListener(() {
        final reverseProgress = 1 - _buttonAnimationController!.value;
        currentButtonDistance = previousButtonDistance * reverseProgress;
        _menuOpacity = previousMenuOpacity * reverseProgress;
        _buttonColorChangeProgress = previousButtonColorChangeProgress * reverseProgress;
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
