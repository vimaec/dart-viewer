import 'package:three_dart/three_dart.dart' as THREE;
import '../vim-loader/scene.dart';

class Renderer {
  final THREE.WebGLRenderer renderer;
  //final FlutterGlPlugin glPlugin;
  //late final THREE.WebGLMultisampleRenderTarget renderTarget;
  //HTMLCanvasElement canvas;
  //late dynamic canvas;
  final THREE.PerspectiveCamera camera;
  final int? sourceTexture;
  final THREE.Scene scene;
  THREE.Box3? _boundingBox;

  Renderer(this.renderer, [this.sourceTexture])
      : camera = THREE.PerspectiveCamera(),
        scene = THREE.Scene() {
    fitToCanvas(
      renderer.width.toDouble(),
      renderer.height.toDouble(),
    );
  }

  void dispose() {
    // clear();

    // _unregisterResize();
    // _unregisterResize = undefined;

    // renderer.clear();
    // renderer.forceContextLoss();
    // renderer.dispose();
    // renderer = null;

    // if (_ownedCanvas) canvas.remove();
  }

  // Returns the bounding sphere encompasing all rendererd objects.
  // @param target sphere in which to copy result, a new instance is created if undefined.
  THREE.Sphere? getBoundingSphere([THREE.Sphere? target]) {
    final targetSphere = target ?? THREE.Sphere();
    return _boundingBox?.getBoundingSphere(targetSphere);
  }

  // Returns the bounding box encompasing all rendererd objects.
  // @param target box in which to copy result, a new instance is created if undefined.
  THREE.Box3 getBoundingBox([THREE.Box3? target]) {
    final targetBox = target ?? THREE.Box3();
    final box =
        _boundingBox == null ? targetBox : targetBox.copy(_boundingBox!);
    return box;
  }

  // Render what is in camera.
  void render() => renderer.render(scene, camera);

  void add<T>(T target) {
    if (target is Scene) {
      _addScene(target);
    } else if (target is THREE.Object3D) {
      scene.add(target);
    }
  }

  void remove<T>(T target) {
    if (target is Scene) {
      for (int i = 0; i < target.meshes.length; i++) {
        scene.remove(target.meshes[i]);
      }
    } else if (target is THREE.Object3D) {
      scene.remove(target);
    }
  }

  void clear() {
    scene.clear();
    _boundingBox = null;
  }

  void _addScene(Scene scn) {
    scn.meshes.forEach(scene.add);
    _boundingBox = _boundingBox != null
        ? _boundingBox!.union(scn.boundingBox!)
        : scn.boundingBox?.clone();
  }

  // private setOnResize (callback, timeout) {
  //   let timerId
  //   const onResize = function () {
  //     if (timerId !== undefined) {
  //       clearTimeout(timerId)
  //       timerId = undefined
  //     }
  //     timerId = setTimeout(function () {
  //       timerId = undefined
  //       callback()
  //     }, timeout)
  //   }
  //   window.addEventListener('resize', onResize)
  //   this._unregisterResize = () =>
  //     window.removeEventListener('resize', onResize)
  // }

  void fitToCanvas(double width, double height) {
    renderer.setSize(width, height, false);
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
  }
}
