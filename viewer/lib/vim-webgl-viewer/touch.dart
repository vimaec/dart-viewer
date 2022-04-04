import 'package:three_dart/three_dart.dart' as THREE;
import 'dart:async';
import 'package:flutter/widgets.dart';

class TouchEvent {
  const TouchEvent();
}

class TouchClickEvent extends TouchEvent {
  final bool doubleTap;
  final THREE.Vector2 position;

  const TouchClickEvent(this.position, this.doubleTap);
}

class TouchDragEvent extends TouchEvent {
  final THREE.Vector2 delta;

  const TouchDragEvent(this.delta);
}

class TouchDoubleDragEvent extends TouchEvent {
  final THREE.Vector2 delta;

  const TouchDoubleDragEvent(this.delta);
}

class TouchPinchOrSpreadEvent extends TouchEvent {
  final double delta;

  const TouchPinchOrSpreadEvent(this.delta);
}

mixin Touch {
  static const int TAP_DURATION_MS = 500;
  final Map<int, THREE.Vector2> _pointerMap = {};
  final _touch = StreamController<TouchEvent>();
  // State
  THREE.Vector2? _touchStart;
  // When one touch occurs this is the value, when two or more touches occur it is the average of the first two.
  THREE.Vector2? _touchStart1;
  // The first touch when multiple touches occur, otherwise left undefined
  THREE.Vector2? _touchStart2;
  // The second touch when multiple touches occur, otherwise left undefined
  int? _touchStartTime; // In ms since epoch
  //THREE.Vector2? _average = null;

  Stream<TouchEvent> get touch => _touch.stream;

  int get touchCount => _pointerMap.values.length;
  Map<int, THREE.Vector2> get pointers => _pointerMap;
  //THREE.Vector2? get average => _avg(_pointerMap);

  // THREE.Vector2? get touchStart => _touchStart;
  // THREE.Vector2? get touchFirst => _touchStart1;
  // THREE.Vector2? get touchSecond => _touchStart2;

  void closeTouch() => _touch.close();

  void reset() {
    _touchStart = _touchStart1 = _touchStart2 = _touchStartTime = null;
    _pointerMap.clear();
  }

  void _onTap(THREE.Vector2 position) {
    _touch.add(TouchClickEvent(position, false));
  }

  void onTouchStart(PointerDownEvent event) {
    print("onTouchStart ${event.pointer} ${event.buttons}");
    final pointer = event.localPosition.toVector();
    final id = event.pointer;
    _pointerMap[id] = pointer;

    _touchStartTime = DateTime.now().millisecondsSinceEpoch;
    if (touchCount == 1) {
      _touchStart = _pointerMap.values.first;
      _touchStart1 = _touchStart2 = null;
    } else if (touchCount == 2) {
      _touchStart1 = _pointerMap.values.first;
      _touchStart2 = _pointerMap.values.elementAt(1);
      _touchStart = _average(_touchStart1, _touchStart2);
    }
  }

  void _onDrag(THREE.Vector2 delta) {
    _touch.add(TouchDragEvent(delta));
  }

  void _onDoubleDrag(THREE.Vector2 delta) {
    _touch.add(TouchDoubleDragEvent(delta));
  }

  void _onPinchOrSpread(double delta) {
    _touch.add(TouchPinchOrSpreadEvent(delta));
  }

  // Called when any of the inputs update position
  void onTouchMove(PointerMoveEvent event, double width, double height) {
    print("onTouchMove ${event.pointer} ${event.buttons}");
    if (_pointerMap.isEmpty) return;
    if (_touchStart == null) return;

    final id = event.pointer;
    final to = event.localPosition.toVector();
    final from = _pointerMap[id];
    _pointerMap[id] = to;

    if (touchCount == 1) {
      final pos = _pointerMap.values.first;
      final delta = pos
          .clone()
          .sub(_touchStart!)
          .multiply(THREE.Vector2(1 / width, 1 / height));

      _touchStart = pos;
      _onDrag(delta);
      return;
    }

    if (_touchStart1 == null || _touchStart2 == null) return;
    if (touchCount >= 2) {
      final p1 = _pointerMap.values.first;
      final p2 = _pointerMap.values.elementAt(1);
      final p = _average(p1, p2)!;
      //final [width, height] = _renderer.getContainerSize()
      final moveDelta = _touchStart!.clone().sub(p).multiply(
          // -1 to invert movement
          THREE.Vector2(-1 / width, -1 / height));

      final zoom = p1.distanceTo(p2);
      final prevZoom = _touchStart1!.distanceTo(_touchStart2!);
      final min = THREE.Math.min(width, height);
      // -1 to invert movement
      final zoomDelta = (zoom - prevZoom) / -min;

      _touchStart = p;
      _touchStart1 = p1;
      _touchStart2 = p2;

      if (moveDelta.length() > THREE.Math.abs(zoomDelta)) {
        _onDoubleDrag(moveDelta);
      } else {
        _onPinchOrSpread(zoomDelta);
      }
    }
    //_touch.add(TouchMoveEvent(id, from, to));
  }

  /// Called when a input is removed from the screen
  void onTouchEnd(PointerEvent event) {
    print("onTouchEnd ${event.pointer} ${event.buttons}");
    final id = event.pointer;
    _pointerMap.remove(id);

    if (_isSingleTouch()) {
      final current = DateTime.now().millisecondsSinceEpoch;
      final touchDurationMs = current - _touchStartTime!;
      if (touchDurationMs < TAP_DURATION_MS) {
        _onTap(_touchStart!);
      }
    }
    reset();
  }

  bool _isSingleTouch() =>
      _touchStart != null &&
      _touchStartTime != null &&
      _touchStart1 == null &&
      _touchStart2 == null;

  static THREE.Vector2? _average(THREE.Vector2? p1, THREE.Vector2? p2) {
    if (p1 == null && p2 == null) return null;
    if (p1 == null) return p2;
    if (p2 == null) return p1;

    return p1.clone().lerp(p2, 0.5);
  }
}

extension _Offset on Offset {
  THREE.Vector2 toVector() => THREE.Vector2(dx, dy);
}
