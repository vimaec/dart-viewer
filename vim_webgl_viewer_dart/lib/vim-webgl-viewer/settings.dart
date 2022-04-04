import 'package:three_dart/three_dart.dart' as THREE;
import '../vim-loader/settings.dart';

class ColorRGB {
  final int r;
  final int g;
  final int b;

  const ColorRGB({
    this.r = 0xff,
    this.g = 0xff,
    this.b = 0xff,
  });
}

class ColorHSL {
  final double h;
  final double s;
  final double l;

  const ColorHSL({
    required this.h,
    required this.s,
    required this.l,
  });
}

//Plane under Scene related options
class GroundPlane {
  // Enables/Disables plane under scene
  final bool show;
  // Local or remote texture url for plane
  final String? texture;
  // Opacity of the plane
  final double opacity;
  // Color of the plane
  final ColorRGB color;
  // Actual size is SceneRadius*size
  final double size;

  const GroundPlane({
    this.show = false,
    this.texture,
    this.opacity = 1,
    this.color = const ColorRGB(r: 0xff, g: 0xff, b: 0xff),
    this.size = 3,
  });
}

//Dom canvas related options */
class Canvas {
  // Canvas dom model id. If none provided a new canvas will be created */
  final String? id;
  // Limits how often canvas will be resized if window is resized. */
  final double resizeDelay;

  const Canvas({
    this.id,
    this.resizeDelay = 200,
  });
}

/* Camera controls related options */
class CameraControls {
  /* <p>Set true to start in orbit mode.</p>
   * <p>Camera has two modes: First person and orbit</p>
   * <p>First person allows to moves the camera around freely</p>
   * <p>Orbit rotates the camera around a focus point</p> */
  final bool orbit;
  /* Camera speed is scaled according to SceneRadius/sceneReferenceSize */
  final double vimReferenceSize;
  /* Camera rotation speed factor */
  final double rotateSpeed;
  final double orbitSpeed;
  /* Camera movement speed factor */
  final double moveSpeed;

  const CameraControls({
    this.orbit = false,
    this.vimReferenceSize = 1,
    this.rotateSpeed = 1,
    this.orbitSpeed = 1,
    this.moveSpeed = 1,
  });
}

/* Camera related options */
class Camera {
  /* Near clipping plane distance */
  final double near;
  /* Far clipping plane distance */
  final double far;
  /* Fov angle in degrees */
  final double fov;
  /* Zoom level */
  final double zoom;
  /* See ControlOptions */
  final CameraControls controls;
  final bool showGizmo;

  const Camera({
    this.near = 0.01,
    this.far = 15000,
    this.fov = 50,
    this.zoom = 1,
    this.controls = const CameraControls(),
    this.showGizmo = true,
  });
}

class SunLight {
  final Vector3 position;
  final ColorHSL color;
  final double intensity;

  const SunLight({
    this.position = const Vector3(x: -47.0, y: 22, z: -45),
    // position: { x: 0, y: 0, z: -1000 },
    this.color = const ColorHSL(h: 0.1, s: 1, l: 0.95),
    // color: { h: 1, s: 1, l: 1 },
    this.intensity = 1,
  });
}

class SkyLight {
  final ColorHSL skyColor;
  final ColorHSL groundColor;
  final double intensity;

  const SkyLight({
    // skyColor: { h: 1, s: 1, l: 1 },
    this.skyColor = const ColorHSL(h: 0.6, s: 1, l: 0.6),
    this.groundColor = const ColorHSL(h: 0.095, s: 1, l: 0.75),
    // groundColor: { h: 1, s: 1, l: 1 },
    this.intensity = 0.6,
    // intensity: 1
  });
}

/* Viewer related options independant from vims */
class ViewerSettings {
  // Webgl canvas related options
  final Canvas canvas;
  // Three.js camera related options
  final Camera camera;
  // Plane under scene related options
  final GroundPlane groundPlane;
  // Skylight (hemisphere light) options
  final SkyLight skylight;
  // Sunlight (directional light) options
  final SunLight sunLight;

  const ViewerSettings({
    this.canvas = const Canvas(),
    this.camera = const Camera(),
    this.groundPlane = const GroundPlane(),
    this.skylight = const SkyLight(),
    this.sunLight = const SunLight(),
  });
}

extension ViewerSettingsExtensions on ViewerSettings {
  // Canvas
  double get canvasResizeDelay => canvas.resizeDelay;
  String? get canvasId => canvas.id;

  // Plane
  bool get groundPlaneShow => groundPlane.show;
  THREE.Color get groundPlaneColor => _toRGBColor(groundPlane.color);
  String? get groundPlaneTextureUrl => groundPlane.texture;
  double get groundPlaneOpacity => groundPlane.opacity;
  double get groundPlaneSize => groundPlane.size;

  // Skylight
  THREE.Color get skylightColor => _toHSLColor(skylight.skyColor);
  THREE.Color get skylightGroundColor => _toHSLColor(skylight.groundColor);
  double get skylightIntensity => skylight.intensity;

  // Sunlight
  THREE.Color get sunlightColor => _toHSLColor(sunLight.color);
  THREE.Vector3 get sunlightPosition => _toVec(sunLight.position);
  double get sunlightIntensity => sunLight.intensity;

  // Camera
  double get cameraNear => camera.near;
  double get cameraFar => camera.far;
  double get cameraFov => camera.fov;
  double get cameraZoom => camera.zoom;
  bool get cameraShowGizmo => camera.showGizmo;

  // Camera Controls
  bool get cameraIsOrbit => camera.controls.orbit;
  double get cameraMoveSpeed => camera.controls.moveSpeed;
  double get cameraRotateSpeed => camera.controls.rotateSpeed;
  double get cameraOrbitSpeed => camera.controls.orbitSpeed;
  double get cameraReferenceVimSize => camera.controls.vimReferenceSize;

  THREE.Color _toRGBColor(ColorRGB c) => THREE.Color.setRGB255(c.r, c.g, c.b);
  THREE.Color _toHSLColor(ColorHSL c) => THREE.Color()..setHSL(c.h, c.s, c.l);
  THREE.Vector3 _toVec(Vector3 v) => THREE.Vector3(v.x, v.y, v.z);
}
