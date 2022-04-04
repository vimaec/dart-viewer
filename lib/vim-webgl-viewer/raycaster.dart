import 'package:three_dart/three_dart.dart' as THREE;
import '../vim-loader/vim.dart';
import '../vim-loader/object.dart';
import 'camera.dart';
import 'renderer.dart';
import 'store.dart';

typedef ThreeIntersectionList = List<THREE.Intersection>;

//<THREE.Object3D<THREE.Event>>[]
class _RayData {
  final THREE.Intersection? hit;
  final Object? obj;

  _RayData([this.hit, this.obj]);
}

// Highlevel aggregate of information about a raycast result
class RaycastResult {
  final THREE.Vector2 mousePosition;
  bool doubleClick = false;
  Object? object;
  final ThreeIntersectionList intersections;
  late final THREE.Intersection? firstHit;

  RaycastResult(this.mousePosition, this.intersections) {
    final hitObj = _getFirstVimHit(intersections);
    firstHit = hitObj.hit;
    object = hitObj.obj;
  }

  static _RayData _getFirstVimHit(ThreeIntersectionList intersections) {
    for (int i = 0; i < intersections.length; i++) {
      final obj = _getVimObjectFromHit(intersections[i]);
      if (obj != null && obj.visible) return _RayData(intersections[i], obj);
    }
    return _RayData();
  }

  static Object? _getVimObjectFromHit(THREE.Intersection hit) {
    final vim = hit.object.userData['vim'] as Vim?;
    if (vim == null) return null;

    if (hit.object.userData['merged'] == true) {
      final instance = THREE.Math.round(hit.uv.x);
      return vim.getObjectFromInstance(instance);
    } else if (hit.instanceId >= 0) {
      return vim.getObjectFromMesh(
        hit.object as THREE.InstancedMesh,
        hit.instanceId.toInt(),
      );
    }
  }

  // Convenience functions and mnemonics
  bool get isHit => firstHit != null;
  num? get distance => firstHit?.distance;
  THREE.Vector3? get position => firstHit?.point;
  int? get threeId => firstHit?.object.id;
  num? get faceIndex => firstHit?.faceIndex;
}

mixin Raycaster on Store {
  //final Viewer _viewer;
  final THREE.Raycaster _raycaster = THREE.Raycaster();

  // Raycast projecting a ray from camera position to screen position
  RaycastResult screenRaycast(
    Renderer renderer,
    Camera camera,
    THREE.Vector2 position,
  ) {
    //console.time('raycast');
    final intersections = _raycast(renderer, camera, position);
    //console.timeEnd('raycast')
    final ray = RaycastResult(position, intersections);
    final hit = ray.firstHit;

    if (hit != null) {
      final vim = hit.object.userData['vim'] as Vim;

      // Merged meshes have g3d intance index of each face encoded in uvs
      if (hit.object.userData['merged'] == true) {
        //&& hit.uv != null
        final instance = THREE.Math.round(hit.uv.x);
        ray.object = vim.getObjectFromInstance(instance);
      } else if (hit.instanceId >= 0) {
        ray.object = vim.getObjectFromMesh(
          hit.object as THREE.InstancedMesh,
          hit.instanceId.toInt(),
        );
      }
    }
    return ray;
  }

  ThreeIntersectionList _raycast(
    Renderer renderer,
    Camera camera,
    THREE.Vector2 position,
  ) {
    final height = renderer.renderer.height;
    final width = renderer.renderer.width;
    final x = (position.x / width) * 2 - 1;
    final y = -(position.y / height) * 2 + 1;
    _raycaster.setFromCamera(THREE.Vector2(x, y), camera.camera);
    final objects = renderer.scene.children.whereType<THREE.Mesh>();
    return _raycaster.intersectObjects(objects.toList(), false);
  }
}
