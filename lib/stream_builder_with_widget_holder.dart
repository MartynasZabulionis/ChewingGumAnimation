import 'dart:async';
import 'package:flutter/material.dart';

class StreamBuilderWithCachedChild<StreamValue> extends StatefulWidget {
  final Widget Function() childBuilder;
  final StreamValue initialValue;
  final Stream<StreamValue> stream;
  final Widget Function(BuildContext context, Widget child, StreamValue value) builder;
  const StreamBuilderWithCachedChild({
    super.key,
    required this.childBuilder,
    required this.builder,
    required this.stream,
    required this.initialValue,
  });

  @override
  State<StreamBuilderWithCachedChild<StreamValue>> createState() => _StreamBuilderWithCachedChildState<StreamValue>();
}

class _StreamBuilderWithCachedChildState<StreamValue> extends State<StreamBuilderWithCachedChild<StreamValue>> {
  Widget _child = const SizedBox();

  late StreamValue _value;

  StreamSubscription? _subscription;

  var _didReassemble = false;

  @override
  void reassemble() {
    _didReassemble = true;
    super.reassemble();
  }

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _child = widget.childBuilder();
    _subscribe();
  }

  void _subscribe() {
    _subscription = widget.stream.listen((event) {
      setState(() {
        _value = event;
      });
    });
  }

  @override
  void didUpdateWidget(covariant StreamBuilderWithCachedChild<StreamValue> oldWidget) {
    if (widget.stream != oldWidget.stream) {
      _subscription?.cancel();
      _subscribe();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_didReassemble) {
      _child = widget.childBuilder();
      _didReassemble = false;
    }
    return widget.builder(context, _child, _value);
  }
}
