import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

abstract class GumState {}

class GumStretchingState extends GumState {
  final double progressPixels;

  GumStretchingState(this.progressPixels);

  @override
  bool operator ==(Object? other) {
    return other is GumStretchingState && other.progressPixels == progressPixels;
  }

  @override
  int get hashCode => progressPixels.toInt();
}

class GumTornState extends GumState {
  final double tearingProgress;
  final double fadingProgress;
  GumTornState(this.tearingProgress, this.fadingProgress);

  @override
  bool operator ==(Object? other) {
    return other is GumTornState &&
        other.tearingProgress == tearingProgress &&
        other.fadingProgress == fadingProgress;
  }

  @override
  int get hashCode => Object.hash(tearingProgress, fadingProgress);
}

class GumPaint extends StatelessWidget {
  final GumState gumState;
  final double maxPixels;
  final double buttonDiameter;
  final ColorTween colorTween;
  final double bottomPadding;
  const GumPaint({
    super.key,
    required this.gumState,
    required this.maxPixels,
    required this.buttonDiameter,
    required this.colorTween,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GumPainter(this),
      size: Size(double.infinity, maxPixels + bottomPadding),
    );
  }
}

class _GumPainter extends CustomPainter {
  final GumPaint _widget;

  _GumPainter(this._widget);

  GumState get _gumState => _widget.gumState;
  double get _buttonDiameter => _widget.buttonDiameter;

  Paint _getGumPaint() => Paint()
    ..color = _widget.colorTween.end!
    ..style = PaintingStyle.fill;

  Paint getBackgroundPaint(double progress) {
    return Paint()..color = Color.lerp(Colors.transparent, _widget.colorTween.begin!, progress)!;
  }

  void connectBezierCurvesWithArc(
    double endY,
    Size size,
    double leftEndX,
    double secondLeftControlX,
    double secondControlY,
    Path path,
  ) {
    final arcCircleCenterY = endY +
        (size.width / 2 - leftEndX) * (leftEndX - secondLeftControlX) / (endY - secondControlY);

    final circleCenter = Offset(size.width / 2, arcCircleCenterY);
    final radius = sqrt(pow(circleCenter.dx - leftEndX, 2) + pow(circleCenter.dy - endY, 2));

    final rightEndY = size.width - leftEndX;

    path.arcToPoint(
      Offset(rightEndY, endY),
      largeArc: circleCenter.dy > endY,
      radius: Radius.circular(radius),
    );
  }

  Path _getGumPath(
    Offset firstLeftControl,
    Offset secondLeftControl,
    Offset leftDestinationPoint,
    Size size,
  ) {
    final secondRightControlX = size.width - secondLeftControl.dx;
    final firstRightControlX = size.width - firstLeftControl.dx;

    Path path = Path();
    path.moveTo(0, size.height);
    path.cubicTo(
      firstLeftControl.dx,
      firstLeftControl.dy,
      secondLeftControl.dx,
      secondLeftControl.dy,
      leftDestinationPoint.dx,
      leftDestinationPoint.dy,
    );

    connectBezierCurvesWithArc(
      leftDestinationPoint.dy,
      size,
      leftDestinationPoint.dx,
      secondLeftControl.dx,
      secondLeftControl.dy,
      path,
    );

    path.cubicTo(
      secondRightControlX,
      secondLeftControl.dy,
      firstRightControlX,
      firstLeftControl.dy,
      size.width,
      size.height,
    );
    return path;
  }

  void _paintStretch(Canvas canvas, Size size, double progressPixels) {
    if (progressPixels == 0) {
      return;
    }

    final progress = progressPixels / _widget.maxPixels;

    const cutProgressMaxBound = 0.8;

    final cutProgress = min(cutProgressMaxBound, progress);

    canvas.drawPaint(getBackgroundPaint(min(progress * 2, 1)));

    final path = _getGumPath(
      Offset(
        size.width / 2 - _buttonDiameter * lerpDouble(5, 1 / cutProgressMaxBound, cutProgress)!,
        size.height,
      ),
      Offset(
        size.width / 2 -
            _buttonDiameter * lerpDouble(1.5, -0.5 / cutProgressMaxBound, cutProgress)!,
        size.height - _buttonDiameter,
      ),
      Offset(
        size.width / 2 -
            _buttonDiameter * lerpDouble(0.75, 0.3 / cutProgressMaxBound, cutProgress)!,
        size.height -
            progressPixels -
            _buttonDiameter * lerpDouble(1.1, 0.3 / cutProgressMaxBound, cutProgress)! -
            _widget.bottomPadding +
            10,
      ),
      size,
    );

    canvas.drawPath(path, _getGumPaint());
  }

  void _paintTear(Canvas canvas, Size size, GumTornState gumTearedState) {
    if (gumTearedState.fadingProgress == 1) {
      return;
    }

    canvas.drawPaint(getBackgroundPaint(1 - gumTearedState.fadingProgress));

    if (gumTearedState.tearingProgress != 1) {
      final progress = gumTearedState.tearingProgress;

      final gumPath = _getGumPath(
        Offset(
          size.width / 2 - _buttonDiameter,
          size.height,
        ),
        Offset(
          size.width / 2 - _buttonDiameter / 2,
          size.height * lerpDouble(0.9, 1, progress)!,
        ),
        Offset(
          size.width / 2 - _buttonDiameter / 4,
          size.height * lerpDouble(0.5, 1, progress)!,
        ),
        size,
      );

      final gumPaint = _getGumPaint();
      gumPaint.color = gumPaint.color.withOpacity(1 - gumTearedState.fadingProgress);
      canvas.drawPath(gumPath, gumPaint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gumState = _gumState;
    if (gumState is GumStretchingState) {
      _paintStretch(canvas, size, gumState.progressPixels);
    } else if (gumState is GumTornState) {
      _paintTear(canvas, size, gumState);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
