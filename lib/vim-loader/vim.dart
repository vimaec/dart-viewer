import 'package:three_dart/extra/console.dart';
import 'package:three_dart/three_dart.dart' as THREE;
import 'object.dart';
import 'document.dart';
import 'scene.dart';
import 'settings.dart';

/*
 * Container for the built three meshes and the vim data from which it was built.
 * Maps between BIM data and Three objects
 * Provides an interface to access BIM data.
 */
class Vim {
  final Document document;
  final VimSettings settings;
  Scene scene;
  int index = -1;

  final Map<int, List<int>> _elementToInstance;
  final Map<int, List<int>> _elementIdToElements;
  final Map<int, Object> _elementToObject = <int, Object>{};

  Vim(
    this.document,
    this.scene, [
    VimSettings? options,
  ])  : settings = options ?? const VimSettings(),
        _elementToInstance = _mapElementToInstance(document),
        _elementIdToElements = _mapElementIdToElement(document) {
    scene.setVim(this);
    applySettings(settings);
  }

  void dispose() {
    scene.dispose();
    _elementIdToElements.clear();
    _elementToObject.clear();
  }

  void filter(List<int>? instances) {
    scene.dispose();
    scene = Scene.fromG3d(document.g3d, settings.transparency, instances);
    scene.applyMatrix4(settings.matrix);
    scene.setVim(this);
    for (var pair in _elementToObject.entries) {
      pair.value.updateMeshes(_getMeshesFromElement(pair.key));
    }
  }

  static Map<int, List<int>> _mapElementToInstance(Document document) {
    final map = <int, List<int>>{};
    final instanceCount = document.instanceCount;

    for (int instance = 0; instance < instanceCount; instance++) {
      final element = document.getElementFromInstance(instance);
      if (element == null) continue;

      final instances = map[element];
      if (instances != null) {
        instances.add(instance);
      } else {
        map[element] = [instance];
      }
    }
    return map;
  }

  static Map<int, List<int>> _mapElementIdToElement(Document document) {
    final map = <int, List<int>>{};
    final t = document.elementTable;
    final ids = t == null ? null : document.getIntColumn(t, 'Id');
    if (ids == null) return map;

    bool negativeReported = false;
    //bool duplicateReported = false;
    for (int element = 0; element < ids.length; element++) {
      final id = ids[element].toInt();
      if (id < 0) {
        if (!negativeReported) {
          console.error('Ignoring negative element ids. Check source data.');
          negativeReported = true;
        }
        continue;
      }

      if (!map.containsKey(id)) {
        map[id] = [element];
      } else {
        map[id]?.add(element);
      }
    }
    return map;
  }

  void applySettings(VimSettings settings) {
    settings = settings;
    scene.applyMatrix4(settings.matrix);
  }

  THREE.Matrix4 get matrix => settings.matrix;

  Object? getObjectFromMesh(THREE.Mesh mesh, int index) {
    final element = _getElementFromMesh(mesh, index);
    return getObjectFromElement(element);
  }

  Object? getObjectFromInstance(int instance) {
    final element = document.getElementFromInstance(instance);
    return element == null ? null : getObjectFromElement(element);
  }

  Iterable<Object>? getObjectFromElementId(int id) {
    final elements = _elementIdToElements[id];
    return elements?.map((e) => getObjectFromElement(e));
  }

  Object getObjectFromElement(int index) {
    if (_elementToObject.containsKey(index)) {
      return _elementToObject[index]!;
    }
    final instances = _elementToInstance[index] ?? <int>[];
    final meshes = _getMeshesFromInstances(instances);

    final result = Object(this, index, instances, meshes);
    _elementToObject[index] = result;
    return result;
  }

  Stream<Object> getAllObjects() async* {
    final first = document.entities[Document.TABLE_ELEMENT];
    final elements = first?.values.elementAt(1) as List?;
    final elementCount = elements?.length ?? 0; //first[1].length
    for (int i = 0; i < elementCount; i++) {
      yield getObjectFromElement(i);
    }
  }

  List<MeshNumber> _getMeshesFromElement(int index) {
    final instances = _elementToInstance[index];
    return _getMeshesFromInstances(instances ?? <int>[]);
  }

  List<MeshNumber> _getMeshesFromInstances(List<int> instances) {
    final meshes = <MeshNumber>[];
    if (instances.isEmpty) return meshes;
    for (int i = 0; i < instances.length; i++) {
      final instance = instances[i];
      if (instance < 0) continue;
      final meshIndex = scene.getMeshFromInstance(instance);
      if (meshIndex == null) continue;
      meshes.add(meshIndex);
    }
    return meshes;
  }

  // Get the element index related to given mesh
  int _getElementFromMesh(THREE.Mesh? mesh, int index) {
    if (mesh == null || index < 0) return -1;
    final instance = scene.getInstanceFromMesh(mesh, index);
    return document.getElementFromInstance(instance) ?? -1;
  }
}
