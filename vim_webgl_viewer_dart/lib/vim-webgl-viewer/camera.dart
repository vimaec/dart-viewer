import 'dart:core';
import 'package:three_dart/three_dart.dart' as THREE;
import '../vim-loader/object.dart';
import 'gizmos.dart';
import 'renderer.dart';
import 'settings.dart';

class Directions {
  static THREE.Vector3 forward = THREE.Vector3(0, 0, -1);
  static THREE.Vector3 back = THREE.Vector3(0, 0, 1);
  static THREE.Vector3 left = THREE.Vector3(-1, 0, 0);
  static THREE.Vector3 right = THREE.Vector3(1, 0, 0);
  static THREE.Vector3 up = THREE.Vector3(0, 1, 0);
  static THREE.Vector3 down = THREE.Vector3(0, -1, 0);
}

enum Axis { XY, XZ, X, Y, Z }

// Manages viewer camera movement and position
class Camera {
  final THREE.PerspectiveCamera camera;
  double speed = 0.0;

  final Renderer _renderer;
  //late final CameraGizmo _gizmo;

  final THREE.Vector3 _inputVelocity = THREE.Vector3(0, 0, 0);
  final THREE.Vector3 _velocity = THREE.Vector3(0, 0, 0);
  final THREE.Vector3 _impulse = THREE.Vector3(0, 0, 0);

  THREE.Vector3 _orbitalTarget = THREE.Vector3(0, 0, 0);
  final double _minOrbitalDistance = 0.02;
  late double _currentOrbitalDistance;
  late double _orbitalTargetDistance;

  double _lerpSecondsDuration = 0.0;
  double _lerpMsEndtime = 0.0;

  late bool _orbitMode = false;

  // Settings
  late double _vimReferenceSize;
  late double _sceneSizeMultiplier = 1;
  late double _velocityBlendFactor = 0.0001;
  late double _moveSpeed = 0.8;
  late double _rotateSpeed = 1;
  late double _orbitSpeed = 1;
  late double _wheelSpeed = 0.2;

  Camera(Renderer renderer, [ViewerSettings? settings])
      : camera = renderer.camera,
        _renderer = renderer
  //_gizmo = CameraGizmo()
  {
    final s = settings ?? const ViewerSettings();
    apply(s);
    THREE.Vector3 position = camera.position.clone();
    position = position.sub(_orbitalTarget);
    _currentOrbitalDistance = position.length();
    _orbitalTargetDistance = _currentOrbitalDistance;
    // _renderer.add(_gizmo.gizmos);
  }

  void dispose() {
    // this._gizmo.dispose();
    // this._gizmo = null
  }

  //Resets camera to default state.
  void reset() {
    camera.position.set(0, 0, -5);
    camera.lookAt(THREE.Vector3(0, 0, 1));

    _inputVelocity.set(0, 0, 0);
    _velocity.set(0, 0, 0);
    _impulse.set(0, 0, 0);

    _currentOrbitalDistance = 5;
    _orbitalTarget.set(0, 0, 0);
    _orbitalTargetDistance = _currentOrbitalDistance;
  }

  THREE.Vector3 get localVelocity {
    final THREE.Vector3 result = _velocity.clone();
    final THREE.Quaternion quat = camera.quaternion.clone();
    result.applyQuaternion(quat.invert());
    result.setZ(-result.z);
    result.multiplyScalar(1.0 / _speedMultiplier);
    return result;
  }

  // Set current velocity of the camera.
  set localVelocity(THREE.Vector3 vector) {
    final THREE.Vector3 move = vector.clone();
    move.setZ(-move.z);
    move.applyQuaternion(camera.quaternion);
    move.multiplyScalar(_speedMultiplier);
    _inputVelocity.copy(move);
  }

  // True: Camera orbit around target mode.
  // False: First person free camera mode.
  bool get orbitMode => _orbitMode;
  // True: Camera orbit around target mode.
  // False: First person free camera mode.
  set orbitMode(bool value) {
    _orbitMode = value;
    //_gizmo.show(value);
  }

  // Sets Orbit mode target and moves camera accordingly
  void target<T>(T target) {
    if (target is THREE.Vector3) {
      _orbitalTarget = target;
      _orbitalTargetDistance = camera.position.distanceTo(target);
      _startLerp(0.4);
    } else if (target is Object) {
      final position = target.getCenter();
      _orbitalTarget = position;
      _orbitalTargetDistance = camera.position.distanceTo(position);
      _startLerp(0.4);
    }
  }

  void frame<T>([T? target]) {
    if (target is Object) {
      _frameSphere(target.getBoundingSphere());
    } else if (target is THREE.Sphere) {
      _frameSphere(target);
    } else if (target == null) {
      _frameSphere(_renderer.getBoundingSphere());
    }
  }

  //Rotates the camera to look at target
  void lookAt<T>(T target) {
    if (target is THREE.Vector3) {
      camera.lookAt(target);
    } else if (target is Object) {
      camera.lookAt(target.getCenter());
    }
  }

  void apply(ViewerSettings settings) {
    // Mode
    orbitMode = settings.cameraIsOrbit;
    // Camera
    camera.fov = settings.cameraFov;
    camera.zoom = settings.cameraZoom;
    camera.near = settings.cameraNear;
    camera.far = settings.cameraFar;
    camera.updateProjectionMatrix();
    // Controls
    _moveSpeed = settings.cameraMoveSpeed;
    _rotateSpeed = settings.cameraRotateSpeed;
    _orbitSpeed = settings.cameraOrbitSpeed;
    // Gizmo
    //_gizmo.apply(settings);
    // Values
    _vimReferenceSize = settings.cameraReferenceVimSize;
  }

  // Adapts camera speed to be faster for large model and slower for small models.
  void adaptToContent() {
    final sphere = _renderer.getBoundingSphere() ?? THREE.Sphere();
    _sceneSizeMultiplier = sphere.radius / _vimReferenceSize;
    final tan = THREE.Math.tan((THREE.MathUtils.DEG2RAD * camera.fov) / 2.0);
    final gizmoSize = tan * (_sceneSizeMultiplier / 10.0);
    // _gizmo.setScale(gizmoSize);
    // _gizmo.show(orbitMode);
  }

  // Smoothly moves the camera in given direction for a short distance.
  void addImpulse(THREE.Vector3 impulse) {
    final THREE.Vector3 v = impulse.clone();
    final scalar = _speedMultiplier * _wheelSpeed;
    final THREE.Vector3 localImpulse = v.multiplyScalar(scalar);
    localImpulse.applyQuaternion(camera.quaternion);
    _impulse.add(localImpulse);
  }

  // Moves the camera along all three axes.
  void move3(THREE.Vector3 vector) {
    final THREE.Vector3 v = vector.clone();
    v.applyQuaternion(camera.quaternion);
    v.multiplyScalar(_speedMultiplier);

    _orbitalTarget.add(v);

    //_gizmo.show();
    if (!orbitMode) {
      camera.position.add(v);
    }
  }

  // Moves the camera along two axis
  void move2(THREE.Vector2 vector, Axis axes) {
    final direction = axes == Axis.XY
        ? THREE.Vector3(-vector.x, vector.y, 0)
        : axes == Axis.XZ
            ? THREE.Vector3(-vector.x, 0, vector.y)
            : null;
    if (direction != null) {
      move3(direction);
    }
  }

  // Moves the camera along one axis
  void move1(double amount, Axis axis) {
    final direction = THREE.Vector3(
      axis == Axis.X ? -amount : 0,
      axis == Axis.Y ? amount : 0,
      axis == Axis.Z ? amount : 0,
    );
    _currentOrbitalDistance += direction.z;
    move3(direction);
  }

  // Rotates the camera around the X or Y axis or both
  // @param vector where coordinates in range [-1, 1] for rotations of [-180, 180] degrees
  void rotate(THREE.Vector2 vector) {
    if (_isLerping) return;
    final euler = THREE.Euler(0, 0, 0, 'YXZ');
    euler.setFromQuaternion(camera.quaternion);

    // When moving the mouse one full sreen
    // Orbit will rotate 180 degree around the scene
    // Basic will rotate 180 degrees on itself
    const pi = THREE.Math.PI;
    final factor = orbitMode ? pi * _orbitSpeed : pi * _rotateSpeed;
    euler.y -= vector.x * factor;
    euler.x -= vector.y * factor;
    euler.z = 0;

    // Clamp X rotation to prevent performing a loop.
    const max = pi * 0.48;
    euler.x = THREE.Math.max(-max, THREE.Math.min(max, euler.x));

    camera.quaternion.setFromEuler(euler);

    if (!orbitMode) {
      final THREE.Vector3 offset = THREE.Vector3(0, 0, 1)
        ..applyQuaternion(camera.quaternion)
        ..multiplyScalar(_currentOrbitalDistance);
      final THREE.Vector3 pos = camera.position.clone();
      _orbitalTarget = pos.sub(offset);
    }
  }

  // Apply the camera frame update
  void update(num deltaTime) {
    final THREE.Vector3 targetVelocity = _inputVelocity.clone();
    // Update the camera velocity and position
    final invBlendFactor = THREE.Math.pow(_velocityBlendFactor, deltaTime);
    final blendFactor = 1.0 - invBlendFactor;

    _velocity.multiplyScalar(invBlendFactor);
    targetVelocity.multiplyScalar(blendFactor);
    _velocity.add(targetVelocity);

    _currentOrbitalDistance = _currentOrbitalDistance * invBlendFactor +
        _orbitalTargetDistance * blendFactor;

    final THREE.Vector3 v = _velocity.clone();
    final THREE.Vector3 positionDelta = v.multiplyScalar(deltaTime);
    final THREE.Vector3 i = _impulse.clone();
    final THREE.Vector3 impulse = i.multiplyScalar(blendFactor);
    positionDelta.add(impulse);

    final THREE.Vector3 orbitDelta = positionDelta.clone();
    if (orbitMode) {
      // compute local space forward component of movement
      final THREE.Quaternion q = camera.quaternion.clone();
      final inv = q.invert();
      final THREE.Vector3 l = positionDelta.clone();
      final local = l.applyQuaternion(inv);
      // remove z component
      orbitDelta.set(local.x, local.y, 0);
      // compute back to world space
      orbitDelta.applyQuaternion(camera.quaternion);

      // apply local space z to orbit distance,
      _currentOrbitalDistance = THREE.Math.max(
          _currentOrbitalDistance + local.z,
          _minOrbitalDistance * _sceneSizeMultiplier);
      _orbitalTargetDistance = _currentOrbitalDistance;
    }

    _impulse.multiplyScalar(invBlendFactor);
    camera.position.add(positionDelta);
    _orbitalTarget.add(orbitDelta);

    if (orbitMode) {
      final target = THREE.Vector3(0, 0, _currentOrbitalDistance);
      target.applyQuaternion(camera.quaternion);
      target.add(_orbitalTarget);

      if (_isLerping) {
        final frames = _lerpSecondsDuration / deltaTime;
        final alpha = 1 - THREE.Math.pow(0.01, 1.0 / frames);
        camera.position.lerp(target, alpha);
        //_gizmo.show(false);
      } else {
        camera.position.copy(target);
        if (_isSignificant(positionDelta)) {
          // _gizmo.show();
        }
      }
    }
    // _gizmo.setPosition(_orbitalTarget);
  }

  /*
   * Rotates the camera so that it looks at sphere
   * Adjusts distance so that the sphere is well framed
   */
  void _frameSphere(THREE.Sphere? sphere) {
    if (sphere != null) {
      final THREE.Vector3 center = sphere.center.clone();
      final shift = THREE.Vector3(0, sphere.radius, -2 * sphere.radius);
      camera.position.copy(center.add(shift));
      camera.lookAt(sphere.center);
      _orbitalTarget = sphere.center;
      final THREE.Vector3 orbit = _orbitalTarget.clone();
      final THREE.Vector3 sub = orbit.sub(camera.position);
      _currentOrbitalDistance = sub.length();
      _orbitalTargetDistance = _currentOrbitalDistance;
    } else {
      reset();
    }
  }

  double get _speedMultiplier =>
      THREE.Math.pow(1.25, speed) * _sceneSizeMultiplier * _moveSpeed;
  bool get _isLerping => DateTime.now().microsecondsSinceEpoch < _lerpMsEndtime;

  void _startLerp(double seconds) {
    _lerpMsEndtime = DateTime.now().microsecondsSinceEpoch + seconds * 1000;
    _lerpSecondsDuration = seconds;
  }

  bool _isSignificant(THREE.Vector3 vector) {
    // One hundreth of standard scene size per frame
    final min = (0.01 * _sceneSizeMultiplier) / 60.0;
    return THREE.Math.abs(vector.x) > min ||
        THREE.Math.abs(vector.y) > min ||
        THREE.Math.abs(vector.z) > min;
  }
}
