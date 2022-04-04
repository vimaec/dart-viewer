/* @author VIM / https://vimaec.com
 @module viw-webgl-viewer */
library vieweroptions;

import 'package:three_dart/three_dart.dart' as THREE;
import '../vim-loader/vimSettings.dart';

class ColorRGB {
  final double r;
  final double g;
  final double b;

  const ColorRGB({
    required this.r,
    required this.g,
    required this.b,
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
  final num opacity;
  // Color of the plane
  final ColorRGB color;
  // Actual size is SceneRadius*size
  final num size;

  const GroundPlane({
    required this.show,
    required this.texture,
    required this.opacity,
    required this.color,
    required this.size,
  });
}

// Dom canvas related options */
class Canvas {
  // Canvas dom model id. If none provided a new canvas will be created */
  final String? id;
  // Limits how often canvas will be resized if window is resized. */
  final num resizeDelay;

  const Canvas({
    required this.id,
    required this.resizeDelay,
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
  final num vimReferenceSize;
  /* Camera rotation speed factor */
  final num rotateSpeed;
  final num orbitSpeed;
  /* Camera movement speed factor */
  final num moveSpeed;

  const CameraControls({
    required this.orbit,
    required this.vimReferenceSize,
    required this.rotateSpeed,
    required this.orbitSpeed,
    required this.moveSpeed,
  });
}

/* Camera related options */
class Camera {
  /* Near clipping plane distance */
  final num near;
  /* Far clipping plane distance */
  final num far;
  /* Fov angle in degrees */
  final num fov;
  /* Zoom level */
  final double zoom;
  /* See ControlOptions */
  final CameraControls controls;
  final bool showGizmo;

  const Camera({
    required this.near,
    required this.far,
    required this.fov,
    required this.zoom,
    required this.controls,
    required this.showGizmo,
  });
}

class SunLight {
  final Vector3 position;
  final ColorHSL color;
  final num intensity;

  const SunLight({
    required this.position,
    required this.color,
    required this.intensity,
  });
}

class SkyLight {
  final ColorHSL skyColor;
  final ColorHSL groundColor;
  final num intensity;

  const SkyLight({
    required this.skyColor,
    required this.groundColor,
    required this.intensity,
  });
}

/* Viewer related options independant from vims */
class Root {
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

  const Root({
    required this.canvas,
    required this.camera,
    required this.groundPlane,
    required this.skylight,
    required this.sunLight,
  });
}

class ViewerSettings {
  final Root options;

  ViewerSettings([Root? viewer])
      : options = viewer ??
            const Root(
              canvas: Canvas(id: null, resizeDelay: 200),
              camera: Camera(
                near: 0.01,
                far: 15000,
                fov: 50,
                zoom: 1,
                controls: CameraControls(
                  orbit: true,
                  vimReferenceSize: 1,
                  rotateSpeed: 1,
                  orbitSpeed: 1,
                  moveSpeed: 1,
                ),
                showGizmo: true,
              ),
              groundPlane: GroundPlane(
                show: true,
                texture: null,
                opacity: 1,
                color: ColorRGB(r: 0xff, g: 0xff, b: 0xff),
                size: 3,
              ),
              skylight: SkyLight(
                skyColor: ColorHSL(h: 0.6, s: 1, l: 0.6),
                groundColor: ColorHSL(h: 0.095, s: 1, l: 0.75),
                intensity: 0.6,
              ),
              sunLight: SunLight(
                position: Vector3(x: -47.0, y: 22, z: -45),
                color: ColorHSL(h: 0.1, s: 1, l: 0.95),
                intensity: 1,
              ),
            );

  // Canvas
  num get canvasResizeDelay => options.canvas.resizeDelay;
  String? get canvasId => options.canvas.id;
  // Plane
  bool get planeShow => options.groundPlane.show;
  THREE.Color get planeColor => _toRGBColor(options.groundPlane.color);
  String? get planeTextureUrl => options.groundPlane.texture;
  num get planeOpacity => options.groundPlane.opacity;
  num get planeSize => options.groundPlane.size;
  // Skylight
  THREE.Color get skylightColor => _toHSLColor(options.skylight.skyColor);
  THREE.Color get skylightGroundColor =>
      _toHSLColor(options.skylight.groundColor);
  num get skylightIntensity => options.skylight.intensity;
  // Sunlight
  THREE.Color get sunlightColor => _toHSLColor(options.sunLight.color);
  THREE.Vector3 get sunlightPosition => _toVec(options.sunLight.position);
  num get sunlightIntensity => options.sunLight.intensity;
  // Camera
  num get cameraNear => options.camera.near;
  num get cameraFar => options.camera.far;
  num get cameraFov => options.camera.fov;
  double get cameraZoom => options.camera.zoom;
  bool get cameraShowGizmo => options.camera.showGizmo;
  // Camera Controls
  bool get cameraIsOrbit => options.camera.controls.orbit;
  num get cameraMoveSpeed => options.camera.controls.moveSpeed;
  num get cameraRotateSpeed => options.camera.controls.rotateSpeed;
  num get cameraOrbitSpeed => options.camera.controls.orbitSpeed;
  num get cameraReferenceVimSize => options.camera.controls.vimReferenceSize;

  THREE.Color _toRGBColor(ColorRGB c) =>
      THREE.Color(c.r / 255, c.g / 255, c.b / 255);
  THREE.Color _toHSLColor(ColorHSL obj) =>
      THREE.Color().setHSL(obj.h, obj.s, obj.l);
  THREE.Vector3 _toVec(Vector3 obj) => THREE.Vector3(obj.x, obj.y, obj.z);
}
