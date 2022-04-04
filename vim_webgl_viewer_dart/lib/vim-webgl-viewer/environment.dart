import 'package:three_dart/extra/console.dart';
import 'package:three_dart/three_dart.dart' as THREE;
import 'settings.dart';

class _GroundPlane {
  late final THREE.Mesh mesh;

  String? _source;
  double _size = 0.0;

  // disposable
  late final THREE.PlaneGeometry _geometry;
  late final THREE.MeshBasicMaterial _material;
  THREE.Texture? _texture;

  _GroundPlane([ViewerSettings? settings]) {
    final s = settings ?? const ViewerSettings();
    _geometry = THREE.PlaneGeometry();
    _material = THREE.MeshBasicMaterial({'transparent': true});
    mesh = THREE.Mesh(_geometry, _material);
    apply(s);
  }

  void apply(ViewerSettings settings) {
    _size = settings.groundPlaneSize;
    // Visibily
    mesh.visible = settings.groundPlaneShow;
    // Looks
    _applyTexture(settings.groundPlaneTextureUrl);
    _material.color.copy(settings.groundPlaneColor);
    _material.opacity = settings.groundPlaneOpacity;
  }

  void adaptToContent(THREE.Box3 box) {
    // Position
    final center = box.getCenter(THREE.Vector3());
    final position = THREE.Vector3(
      center.x,
      box.min.y - THREE.Math.abs(box.min.y) * 0.01,
      center.z,
    );
    mesh.position.copy(position);
    // Rotation
    // Face up, rotate by 270 degrees around x
    final euler = THREE.Euler(1.5 * THREE.Math.PI, 0, 0);
    final quaternion = THREE.Quaternion()..setFromEuler(euler);
    mesh.quaternion.copy(quaternion);

    // Scale
    final sphere = box.getBoundingSphere(THREE.Sphere());
    final size = sphere.radius * _size;
    final THREE.Vector3 scale = THREE.Vector3(1, 1, 1).multiplyScalar(size);
    mesh.scale.copy(scale);
  }

  void _applyTexture(String? texUrl) async {
    // Check for changes
    if (texUrl == _source) return;
    _source = texUrl;

    // dispose previous texture
    _texture?.dispose();
    _texture = null;
    // Bail if new texture url, is no texture
    if (texUrl == null) return;

    // load texture
    var manager = THREE.LoadingManager();
    final loader = THREE.TextureLoader(manager);
    loader.load(texUrl, (THREE.Texture texture) {
      // Apply texture
      _texture = texture;
      if (_texture == null) {
        console.error('Failed to load texture: $texUrl');
      } else {
        _material.map = _texture;
      }
    });
  }

  void dispose() {
    _geometry.dispose();
    _material.dispose();
    _texture?.dispose();
    //_geometry = null;
    //_material = null;
    //_texture = null;
  }
}

class Environment {
  late final THREE.HemisphereLight skyLight;
  late final THREE.DirectionalLight sunLight;
  late final _GroundPlane _groundPlane;

  THREE.Mesh get groundPlane => _groundPlane.mesh;
  // Returns all three objects composing the environment
  List<THREE.Object3D> get objects => [_groundPlane.mesh, skyLight, sunLight];

  Environment([ViewerSettings? settings]) {
    final s = settings ?? const ViewerSettings();
    _groundPlane = _GroundPlane(s);
    skyLight = THREE.HemisphereLight(s.skylightColor, s.skylightGroundColor);
    sunLight = THREE.DirectionalLight(s.sunlightColor);
    apply(s);
  }

  void apply(ViewerSettings settings) {
    // Plane
    _groundPlane.apply(settings);
    // Skylight
    skyLight.color?.copy(settings.skylightColor);
    skyLight.groundColor?.copy(settings.skylightGroundColor);
    skyLight.intensity = settings.skylightIntensity;
    // Sunlight
    sunLight.color?.copy(settings.sunlightColor);
    sunLight.position.copy(settings.sunlightPosition);
    sunLight.intensity = settings.sunlightIntensity;
  }

  // Adjust scale so that it matches box dimensions.
  void adaptToContent(THREE.Box3 box) {
    _groundPlane.adaptToContent(box);
  }

  void dispose() {
    sunLight.dispose();
    skyLight.dispose();
    _groundPlane.dispose();

    // this.sunLight = null;
    // this.skyLight = null;
    // this._groundPlane = null;
  }
}
