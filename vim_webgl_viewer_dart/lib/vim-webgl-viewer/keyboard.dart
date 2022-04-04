import 'dart:async';
import 'package:flutter/services.dart';
import 'package:three_dart/three_dart.dart' as THREE;

class KeyboardEvent {
  final bool isShiftPressed;
  final bool isCtrlPressed;

  const KeyboardEvent([
    this.isCtrlPressed = false,
    this.isShiftPressed = false,
  ]);
}

class SpeedUpKey extends KeyboardEvent {
  const SpeedUpKey(bool isCtrlPressed, bool isShiftPressed)
      : super(isCtrlPressed, isShiftPressed);
}

class SpeedDownKey extends KeyboardEvent {
  const SpeedDownKey(bool isCtrlPressed, bool isShiftPressed)
      : super(isCtrlPressed, isShiftPressed);
}

class OrbitKey extends KeyboardEvent {
  const OrbitKey(bool isCtrlPressed, bool isShiftPressed)
      : super(isCtrlPressed, isShiftPressed);
}

class HomeKey extends KeyboardEvent {
  const HomeKey(bool isCtrlPressed, bool isShiftPressed)
      : super(isCtrlPressed, isShiftPressed);
}

class ClearKey extends KeyboardEvent {
  const ClearKey(bool isCtrlPressed, bool isShiftPressed)
      : super(isCtrlPressed, isShiftPressed);
}

class SelectionKey extends KeyboardEvent {
  const SelectionKey(bool isCtrlPressed, bool isShiftPressed)
      : super(isCtrlPressed, isShiftPressed);
}

class MoveEvent extends KeyboardEvent {
  final THREE.Vector3 vector;

  const MoveEvent(bool isCtrlPressed, bool isShiftPressed, this.vector)
      : super(isCtrlPressed, isShiftPressed);
}

mixin Keyboard {
  static const double shiftMultiplier = 3.0;
  final _keyboard = StreamController<KeyboardEvent>();

  Stream<KeyboardEvent> get keyboard => _keyboard.stream;

  void closeKeyboard() => _keyboard.close();
  bool onKeyUp(RawKeyUpEvent event) => onKey(event, false);
  bool onKeyDown(RawKeyDownEvent event) => onKey(event, true);
  bool onKey(RawKeyEvent event, bool keyDown) {
    if (event.logicalKey == LogicalKeyboardKey.add ||
        event.logicalKey == LogicalKeyboardKey.numpadAdd) {
      if (!keyDown) {
        final key = SpeedUpKey(event.isControlPressed, event.isShiftPressed);
        _keyboard.add(key);
      }
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.minus ||
        event.logicalKey == LogicalKeyboardKey.numpadAdd) {
      if (!keyDown) {
        final key = SpeedDownKey(event.isControlPressed, event.isShiftPressed);
        _keyboard.add(key);
      }
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.f8 ||
        event.logicalKey == LogicalKeyboardKey.space) {
      if (!keyDown) {
        final key = OrbitKey(event.isControlPressed, event.isShiftPressed);
        _keyboard.add(key);
      }
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.home ||
        event.logicalKey == LogicalKeyboardKey.keyH) {
      if (!keyDown) {
        final key = HomeKey(event.isControlPressed, event.isShiftPressed);
        _keyboard.add(key);
      }
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (!keyDown) {
        final key = ClearKey(event.isControlPressed, event.isShiftPressed);
        _keyboard.add(key);
      }
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyZ ||
        event.logicalKey == LogicalKeyboardKey.keyF) {
      if (!keyDown) {
        final key = SelectionKey(event.isControlPressed, event.isShiftPressed);
        _keyboard.add(key);
      }
      return true;
    }
    if (!keyDown) {
      final key = KeyboardEvent(event.isControlPressed, event.isShiftPressed);
      _keyboard.add(key);
    }

    final isUp = event.logicalKey == LogicalKeyboardKey.keyW ||
        event.logicalKey == LogicalKeyboardKey.arrowUp;
    final isDown = event.logicalKey == LogicalKeyboardKey.keyS ||
        event.logicalKey == LogicalKeyboardKey.arrowDown;
    final isRight = event.logicalKey == LogicalKeyboardKey.keyD ||
        event.logicalKey == LogicalKeyboardKey.arrowRight;
    final isLeft = event.logicalKey == LogicalKeyboardKey.keyA ||
        event.logicalKey == LogicalKeyboardKey.arrowLeft;
    final isE = event.logicalKey == LogicalKeyboardKey.keyE;
    final isQ = event.logicalKey == LogicalKeyboardKey.keyQ;
    if (isUp || isDown || isRight || isLeft || isE || isQ) {
      final move = THREE.Vector3(
        (isRight ? 1 : 0) - (isLeft ? 1 : 0),
        (isE ? 1 : 0) - (isQ ? 1 : 0),
        (isUp ? 1 : 0) - (isDown ? 1 : 0),
      );
      final speed = event.isShiftPressed ? shiftMultiplier : 1;
      move.multiplyScalar(speed);

      _keyboard.add(MoveEvent(
        event.isControlPressed,
        event.isShiftPressed,
        keyDown ? move : THREE.Vector3(),
      ));
      return true;
    }
    return false;
  }
}
