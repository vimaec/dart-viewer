import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../vim-webgl-viewer/keyboard.dart';
import '../vim-webgl-viewer/mouse.dart';
import '../vim-webgl-viewer/touch.dart';

class Input with Mouse, Keyboard, Touch {
  void onPointerSignal(PointerSignalEvent details, Size size) {
    if (details is PointerScrollEvent) {
      final resolver = GestureBinding.instance?.pointerSignalResolver;
      resolver?.register(details, (PointerSignalEvent event) {
        if (event is PointerScrollEvent) {
          if (event.kind == PointerDeviceKind.mouse) {
            onMouseWheel(event);
          }
        }
      });
    }
  }

  void onPointerMove(PointerMoveEvent event, Size size) {
    if (event.kind == PointerDeviceKind.mouse) {
      onMouseMove(event);
    } else {
      onTouchMove(event, size.width, size.height);
    }
  }

  void onPointerDown(PointerDownEvent event, Size size) {
    if (event.kind == PointerDeviceKind.mouse) {
      onMouseDown(event);
    } else {
      onTouchStart(event);
    }
  }

  void onPointerUp(PointerUpEvent event, Size size) {
    if (event.kind == PointerDeviceKind.mouse) {
      onMouseUp(event);
    } else {
      onTouchEnd(event);
    }
  }

  void onPointerCancel(PointerCancelEvent event, Size size) {
    if (event.kind == PointerDeviceKind.mouse) {
      onMouseUp(event);
    } else {
      onTouchEnd(event);
    }
  }

  KeyEventResult onFocusKey(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      return onKeyDown(event) ? KeyEventResult.handled : KeyEventResult.ignored;
    } else if (event is RawKeyUpEvent) {
      return onKeyUp(event) ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }
}
