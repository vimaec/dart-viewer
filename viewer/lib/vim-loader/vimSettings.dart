/* @author VIM / https://vimaec.com
 @module viw-webgl-viewer */
library vimoptions;

import 'package:three_dart/three_dart.dart' as THREE;
import 'transparency.dart';

class Vector3 {
  final num x;
  final num y;
  final num z;

  const Vector3({
    required this.x,
    required this.y,
    required this.z,
  });
}

class Root {
  // Position offset for the vim
  final Vector3 position;
  // Rotation for the vim
  final Vector3 rotation;
  //Scale factor for the vim
  final num scale;
  //Defines how to draw or not to draw objects according to their transparency
  final Mode transparency;

  const Root({
    required this.position,
    required this.rotation,
    required this.scale,
    this.transparency = Mode.all,
  });

  Root.clone(Root op)
      : position = Vector3(
          x: op.position.x,
          y: op.position.y,
          z: op.position.z,
        ),
        rotation = Vector3(
          x: op.rotation.x,
          y: op.rotation.y,
          z: op.rotation.z,
        ),
        scale = op.scale,
        transparency = op.transparency;
}

/* <p>Wrapper around Vim Options.</p>
 * <p>Casts options values into related THREE.js type</p>
 * <p>Provides default values for options</p> */
class VimSettings {
  final Root _options;

  VimSettings([Root? options])
      : _options = options ??
            const Root(
              position: Vector3(x: 0, y: 0, z: 0),
              rotation: Vector3(x: 0, y: 0, z: 0),
              scale: 0.01,
              transparency: Mode.all,
            );

  Root get options => Root.clone(_options);
  THREE.Vector3 get position => _toVec(_options.position);
  THREE.Quaternion get rotation => _toQuaternion(_options.rotation);
  THREE.Vector3 get scale => _scalarToVec(_options.scale);
  Mode get transparency => _options.transparency;
  THREE.Matrix4 get matrix => THREE.Matrix4().compose(
        position,
        rotation,
        scale,
      );

  THREE.Vector3 _toVec(Vector3 obj) => THREE.Vector3(obj.x, obj.y, obj.z);
  THREE.Quaternion _toQuaternion(Vector3 rot) =>
      THREE.Quaternion().setFromEuler(_toEuler(_toVec(rot)), true);
  THREE.Vector3 _scalarToVec(num x) => THREE.Vector3(x, x, x);
  THREE.Euler _toEuler(THREE.Vector3 rot) => THREE.Euler(
      (rot.x * THREE.Math.PI) / 180,
      (rot.y * THREE.Math.PI) / 180,
      (rot.z * THREE.Math.PI) / 180);
}
