import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:three_dart/three_dart.dart' as THREE;

class MouseEvent {
  final int buttons;
  const MouseEvent(this.buttons);
}

class MouseMoveEvent extends MouseEvent {
  final THREE.Vector2 delta;

  const MouseMoveEvent(this.delta, int buttons) : super(buttons);
}

class MouseWheelEvent extends MouseEvent {
  final THREE.Vector2 scrollDelta;

  const MouseWheelEvent(this.scrollDelta, int buttons) : super(buttons);
}

class MouseDownEvent extends MouseEvent {
  const MouseDownEvent(int buttons) : super(buttons);
}

class MouseUpEvent extends MouseEvent {
  const MouseUpEvent(int buttons) : super(buttons);
}

class MouseClickEvent extends MouseEvent {
  final bool doubleClick;
  final THREE.Vector2 position;

  const MouseClickEvent(this.position, this.doubleClick, int buttons)
      : super(buttons);
}

mixin Mouse {
  final _mouse = StreamController<MouseEvent>();
  bool _isMouseDown = false;
  bool _hasMouseMoved = false;

  Stream<MouseEvent> get mouse => _mouse.stream;

  void closeMouse() => _mouse.close();
  void onMouseMove(PointerMoveEvent event) {
    if (!_isMouseDown) return;

    // https://github.com/mrdoob/three.js/blob/master/examples/jsm/controls/PointerLockControls.js
    final deltaX = event.delta.dx;
    final deltaY = event.delta.dy;
    // final mdq = MediaQuery.of(context);
    final delta = THREE.Vector2(deltaX, deltaY);

    _hasMouseMoved =
        _hasMouseMoved || THREE.Math.abs(deltaX) + THREE.Math.abs(deltaY) > 3;

    _mouse.add(MouseMoveEvent(delta, event.buttons));
  }

  void onMouseWheel(PointerScrollEvent event) {
    final delta = THREE.Vector2(event.scrollDelta.dx, event.scrollDelta.dy);

    _mouse.add(MouseWheelEvent(delta, event.buttons));
  }

  void onMouseDown(PointerDownEvent event) {
    _isMouseDown = true;
    _hasMouseMoved = false;

    _mouse.add(MouseDownEvent(event.buttons));
  }

  void onMouseUp(PointerEvent event) {
    if (_isMouseDown && !_hasMouseMoved) {
      final position = THREE.Vector2(event.position.dx, event.position.dy);
      _onMouseClick(position, false, event.buttons);
    }
    _isMouseDown = false;
    _mouse.add(MouseUpEvent(event.buttons));
  }

  void _onDoubleClick(event, int buttons) {
    _onMouseClick(THREE.Vector2(event.offsetX, event.offsetY), true, buttons);
  }

  void _onMouseClick(THREE.Vector2 position, bool doubleClick, int buttons) {
    _mouse.add(MouseClickEvent(position, doubleClick, buttons));
  }
}
