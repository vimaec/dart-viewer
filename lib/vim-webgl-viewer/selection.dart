import 'package:three_dart/three_dart.dart' as THREE;
import '../vim-webgl-viewer/renderer.dart';
import '../vim-loader/object.dart';

// Provides basic selection mechanic in viewer
class Selection {
  // Dependencies
  final Renderer _renderer;
  // State
  Object? _object;
  // Disposable State
  THREE.LineSegments? _highligt;

  Selection(this._renderer);

  //Returns selected object.
  Object? get object => _object;

  // Select given object
  void select(Object? object) {
    clear();

    if (object != null) {
      _object = object;
      _highligt = object.createWireframe();
      _renderer.add(_highligt!);
    }
  }

  // Clear selection and related highlights
  void clear() {
    _object = null;

    if (_highligt != null) {
      _highligt!.geometry?.dispose();
      _renderer.remove(_highligt!);
      _highligt = null;
    }
  }
}
