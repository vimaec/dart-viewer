import 'dart:async';
import 'package:three_dart/three_dart.dart' as THREE;
import 'settings.dart';

class CameraGizmo {
  // Dependencies
  //final Renderer _renderer;
  // Settings
  double _scale = 1.0;
  double _fov = 50;
  // Resources
  late THREE.BufferGeometry _box;
  late THREE.BufferGeometry _wireframe;
  late THREE.Material _material;
  late THREE.Material _materialAlways;
  late final THREE.Group _gizmos;
  // State
  Timer? _timeout;
  //bool _active = false;

  THREE.Group get gizmos => _gizmos;

  CameraGizmo([ViewerSettings? settings]) {
    final s = settings ?? const ViewerSettings();
    final gizmos = _createGizmo();
    _gizmos = gizmos;
    setScale(_scale);
    apply(s);
  }

  void show([bool show = true]) {
    //if (!_active) return;
    //if (_gizmos == null) _createGizmo();

    _timeout?.cancel();
    _timeout = null;
    _gizmos.visible = show;
    // Hide after one second since last request
    if (show) {
      _timeout = Timer(
        const Duration(milliseconds: 1000),
        () => _gizmos.visible = false,
      );
    }
  }

  void setPosition(THREE.Vector3 position) {
    _gizmos.position.copy(position);
  }

  void apply(ViewerSettings settings) {
    _gizmos.visible = settings.cameraShowGizmo;
    _fov = settings.cameraFov;
  }

  void setScale([double scale = 1]) {
    _gizmos.scale.set(scale, scale, scale);
    _scale = scale;
  }

  THREE.Group _createGizmo() {
    _box = THREE.SphereGeometry(1);
    _wireframe = THREE.WireframeGeometry(_box);
    _material = THREE.LineBasicMaterial({
      'depthTest': true,
      'opacity': 0.5,
      'color': THREE.Color.fromHex(0x0000ff),
      'transparent': true
    });
    _materialAlways = THREE.LineBasicMaterial({
      'depthTest': true,
      'opacity': 0.5,
      'color': THREE.Color.fromHex(0x0000ff),
      'transparent': true
    });
    // Add to scene as group
    final gizmos = THREE.Group();
    gizmos.add(THREE.LineSegments(_wireframe, _material));
    gizmos.add(THREE.LineSegments(_wireframe, _materialAlways));
    gizmos.visible = false;
    return gizmos;
  }

  void dispose() {
    _box.dispose();
    _wireframe.dispose();
    _material.dispose();
    _materialAlways.dispose();
    // this._box = null;
    // this._wireframe = null;
    // this._material = null;
    // this._materialAlways = null;

    // if (_gizmos != null) {
    //   _renderer.remove(_gizmos);
    //   _gizmos = null;
    // }
  }
}
