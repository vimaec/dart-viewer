import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as THREE;
import '../vim-loader/vim.dart';
import '../vim-loader/settings.dart';
import '../vim-webgl-viewer/renderer.dart';
import '../vim-webgl-viewer/gl.dart';
import 'environment.dart';
import 'input.dart';
import 'keyboard.dart';
import 'mouse.dart';
import 'raycaster.dart';
import 'selection.dart';
import 'store.dart';
import 'settings.dart';
import 'camera.dart' as vimcamera;
import '../vim-loader/object.dart';
import 'touch.dart';

/// Control thç canvas and the objects on it
class Viewer extends Input with Store, Raycaster {
  final THREE.Clock _clock = THREE.Clock();
  KeyboardEvent _lastKey = const KeyboardEvent();

  final Renderer renderer;
  final FlutterGlPlugin gl;
  final ViewerSettings settings;
  final vimcamera.Camera camera;
  final Selection selection;
  final Environment environment;

  void close() {
    closeKeyboard();
    closeTouch();
    closeMouse();
  }

  void dispose() {
    close();
    // this._loader.dispose()
    // this._environment.dispose()
    // this.selection.clear()
    // this._camera.dispose()
    // this.renderer.dispose()
    // this.inputs.unregister()
    // this._vims.forEach((v) => v?.dispose())
    // this._vims = []
    // this._disposed = true
  }

  bool loadVim(Vim vim, VimSettings settings) {
    //if (containsVim(vim)) return false;
    //state.camera.frame();
    onVimLoaded(vim, settings);
    return true;
  }

  void onVimLoaded(Vim vim, VimSettings settings) {
    addVim(vim);
    //vim.applySettings(settings);
    renderer.add(vim.scene);
    environment.adaptToContent(renderer.getBoundingBox());
    camera.adaptToContent();

    camera.frame();
  }

  void unloadVim(Vim vim) {
    removeVim(vim);
    renderer.remove(vim.scene);
    vim.dispose();
    if (selection.object?.vim == vim) {
      selection.clear();
    }
  }

  // void fitToCanvas(double width, double height) {
  //   renderer.renderer.setSize(width, height, false);

  //   camera.camera.aspect = width / height;
  //   camera.camera.updateProjectionMatrix();
  // }

  void filterVim(Vim vim, List<Object>? objects) {
    // final instances = objects?.flatMap(o => o?.instances)
    //   .filter((i): i is number => i !== undefined);

    // this.unloadVim(vim);
    // vim.filter(instances);
    // this.onVimLoaded(vim, vim.settings);
  }

  Viewer(this.gl, this.renderer, this.settings)
      : camera = vimcamera.Camera(renderer, settings),
        selection = Selection(renderer),
        environment = Environment(settings)..objects.forEach(renderer.add) {
    keyboard.listen((event) {
      _lastKey = event;
      if (event is SpeedUpKey) {
        _onSpeedUpEvent(event);
      } else if (event is SpeedDownKey) {
        _onSpeedDownEvent(event);
      } else if (event is OrbitKey) {
        _onOrbitEvent(event);
      } else if (event is HomeKey) {
        _onHomeEvent(event);
      } else if (event is ClearKey) {
        _onClearEvent(event);
      } else if (event is SelectionKey) {
        _onSelectionEvent(event);
      } else if (event is MoveEvent) {
        _onMoveEvent(event);
      }
    });
    mouse.listen((event) {
      if (event is MouseMoveEvent) {
        _onMouseMoveEvent(event);
      } else if (event is MouseWheelEvent) {
        _onMouseWheelEvent(event);
      } else if (event is MouseDownEvent) {
        _onMouseDownEvent(event);
      } else if (event is MouseUpEvent) {
        _onMouseUpEvent(event);
      } else if (event is MouseClickEvent) {
        _onMouseClickEvent(event);
      }
    });
    touch.listen((event) {
      if (event is TouchClickEvent) {
        _onTap(event);
      } else if (event is TouchDragEvent) {
        _onTouchDrag(event);
      } else if (event is TouchDoubleDragEvent) {
        _onTouchDoubleDrag(event);
      } else if (event is TouchPinchOrSpreadEvent) {
        _onTouchPinchOrSpread(event);
      }
    });

    _animate();
  }

  void _onTap(TouchClickEvent event) {
    _onMouseClickEvent(MouseClickEvent(event.position, false, 0));
  }

  void _onTouchDrag(TouchDragEvent event) {
    camera.rotate(event.delta);
  }

  void _onTouchDoubleDrag(TouchDoubleDragEvent event) {
    camera.move2(event.delta, vimcamera.Axis.XY);
  }

  void _onTouchPinchOrSpread(TouchPinchOrSpreadEvent event) {
    camera.move1(event.delta, vimcamera.Axis.Z);
  }

  void _onMouseMoveEvent(MouseMoveEvent event) {
    final width = renderer.renderer.width; //THREE.Vector2
    final height = renderer.renderer.height;
    final delta = THREE.Vector2(event.delta.x / width, event.delta.y / height);
    if (event.buttons == 2) {
      // right button
      camera.move2(delta, vimcamera.Axis.XY);
    } else if (event.buttons == 4) {
      // Midle button
      camera.move2(delta, vimcamera.Axis.XZ);
    } else {
      // left button
      camera.rotate(delta);
    }
  }

  void _onMouseWheelEvent(MouseWheelEvent event) {
    final scrollValue = event.scrollDelta.y / 300.0;
    // Value of event.deltaY will change from browser to browser
    // https://stackoverflow.com/questions/38942821/wheel-event-javascript-give-inconsistent-values
    // Thus we only use the direction of the value
    //THREE.Math.sign(event.scrollDelta.dy);
    if (_lastKey.isCtrlPressed) {
      camera.speed -= scrollValue;
    } else if (camera.orbitMode) {
      final impulse = THREE.Vector3(0, 0, scrollValue);
      camera.addImpulse(impulse);
      //state.camera.updateOrbitalDistance(-event.scrollValue)
    } else {
      final impulse = THREE.Vector3(0, 0, scrollValue);
      camera.addImpulse(impulse);
    }
  }

  void _onMouseDownEvent(MouseDownEvent event) {
    // Manually set the focus since calling preventDefault above
    // prevents the browser from setting it automatically.
    //state.renderer.canvas.focus();
    //print("mouse down");
  }

  void _onMouseUpEvent(MouseUpEvent event) {
    //print("mouse up");
  }

  void _onMouseClickEvent(MouseClickEvent event) {
    final hit = screenRaycast(renderer, camera, event.position);
    hit.doubleClick = event.doubleClick;
    _defaultOnClick(hit);
  }

  void _defaultOnClick(RaycastResult hit) {
    //console.info(hit);
    if (hit.object == null) return;
    selection.select(hit.object);
    camera.target(hit.object!.getCenter());
    if (hit.doubleClick) camera.frame(hit.object);
    //console.info(hit.object!.bimElement);
  }

  void _onSpeedUpEvent(SpeedUpKey event) {
    camera.speed += 1;
  }

  void _onSpeedDownEvent(SpeedDownKey event) {
    camera.speed -= 1;
  }

  void _onOrbitEvent(OrbitKey event) {
    camera.orbitMode = !camera.orbitMode;
  }

  void _onHomeEvent(HomeKey event) {
    camera.frame();
  }

  void _onClearEvent(ClearKey event) {
    selection.clear();
  }

  void _onSelectionEvent(SelectionKey event) {
    if (selection.object != null) {
      camera.frame(selection.object!);
    }
  }

  void _onMoveEvent(MoveEvent event) {
    camera.localVelocity = event.vector;
  }

  void _animate() async {
    //loop
    SchedulerBinding.instance?.scheduleFrameCallback((d) => _animate());

    // Camera
    try {
      camera.update(_clock.getDelta());
      // Rendering
      if (vimCount > 0) {
        await gl.render(renderer);
      }
    } catch (e) {
      print(e);
    }
  }
}
