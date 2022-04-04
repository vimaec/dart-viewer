import 'package:three_dart/three_dart.dart' as THREE;
import 'transparency.dart';

class Vector3 {
  final double x;
  final double y;
  final double z;

  const Vector3({
    this.x = 0,
    this.y = 0,
    this.z = 0,
  });
}

class VimSettings {
  // Position offset for the vim
  final Vector3 _position;
  // Rotation for the vim
  final Vector3 _rotation;
  //Scale factor for the vim
  final double _scale;
  //Defines how to draw or not to draw objects according to their transparency
  final Mode _transparency;

  const VimSettings([
    this._position = const Vector3(),
    this._rotation = const Vector3(x: 270),
    this._scale = 1,
    this._transparency = Mode.all,
  ]);

  VimSettings.clone(VimSettings op)
      : _position = Vector3(
          x: op._position.x,
          y: op._position.y,
          z: op._position.z,
        ),
        _rotation = Vector3(
          x: op._rotation.x,
          y: op._rotation.y,
          z: op._rotation.z,
        ),
        _scale = op._scale,
        _transparency = op._transparency;
}

// Wrapper around Vim Options.
// Casts options values into related THREE.js type
// Provides default values for options
extension VimSettingsExtension on VimSettings {
  THREE.Vector3 get position => _toVec(_position);
  THREE.Quaternion get rotation => _toQuaternion(_rotation);
  THREE.Vector3 get scale => _scalarToVec(_scale);
  THREE.Matrix4 get matrix =>
      THREE.Matrix4()..compose(position, rotation, scale);
  Mode get transparency => _transparency;

  THREE.Vector3 _toVec(Vector3 obj) => THREE.Vector3(obj.x, obj.y, obj.z);
  THREE.Quaternion _toQuaternion(Vector3 rot) =>
      THREE.Quaternion()..setFromEuler(_toEuler(_toVec(rot)));
  THREE.Vector3 _scalarToVec(double x) => THREE.Vector3(x, x, x);
  THREE.Euler _toEuler(THREE.Vector3 rot) => THREE.Euler(
        (rot.x * THREE.Math.PI) / 180.0,
        (rot.y * THREE.Math.PI) / 180.0,
        (rot.z * THREE.Math.PI) / 180.0,
      );
}
