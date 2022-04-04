import 'dart:typed_data';

import 'package:flutter_gl/native-array/index.dart';
import 'package:three_dart/three_dart.dart' as THREE;
import 'package:three_dart/three_dart.dart';
import './vim.dart';
import './mesh.dart';
import './geometry.dart';
import 'document.dart';

class MeshNumber {
  final THREE.Mesh mesh;
  int index;

  MeshNumber(this.mesh, this.index);
}

//High level api to interact with the loaded vim geometry and data.
class Object {
  final Vim vim;
  final int element;
  final List<int> instances;

  THREE.Color? _color;
  THREE.Box3? _boundingBox;
  bool _visible = true;
  List<MeshNumber>? _meshes;

  Object(
    this.vim,
    this.element,
    this.instances, [
    List<MeshNumber> meshes = const <MeshNumber>[],
  ]) : _meshes = meshes;

  // Internal - Replace this object meshes and apply color as needed.
  void updateMeshes(List<MeshNumber>? meshes) {
    _meshes = meshes;
    if (meshes == null) return;
    // if there was a color override reapply to new meshes.
    if (color != null) {
      color = _color;
    }
  }

  //Returns Bim data for the element associated with this object.
  EntityTable get bimElement => vim.document.getElement(element);

  // Returns the bounding box of the object from cache or computed if needed.
  THREE.Box3 getBoundingBox() {
    if (_boundingBox != null) return _boundingBox!;

    final geometry = vim.document.g3d.createGeometryFromInstances(instances);
    geometry.applyMatrix4(vim.matrix);
    geometry.computeBoundingBox();
    _boundingBox = geometry.boundingBox;
    geometry.dispose();
    return _boundingBox ?? THREE.Box3();
  }

  // Returns the center position of this object
  // @param target Vector3 where to copy data. A new instance is created if none provided.
  THREE.Vector3 getCenter([THREE.Vector3? target]) {
    final vector = target ?? THREE.Vector3();
    return getBoundingBox().getCenter(vector);
  }

  // Returns the bounding sphere of the object from cache or computed if needed.
  THREE.Sphere getBoundingSphere([THREE.Sphere? target]) {
    final sphere = target ?? THREE.Sphere();
    return getBoundingBox().getBoundingSphere(sphere);
  }

  // Creates a new three wireframe Line object from the object geometry
  THREE.LineSegments createWireframe() {
    final builder = Builder.defaultBuilder();
    final wireframe = builder.createWireframe(vim.document.g3d, instances);
    wireframe.applyMatrix4(vim.matrix);
    return wireframe;
  }

  // Changes the display color of this object.
  THREE.Color? get color => _color;
  set color(THREE.Color? c) {
    if (_color == null || c == null
        ? _color == null && c == null
        : _color?.equals(c) ?? false) return;
    _color = c;
    _applyColor(c);
  }

  void _applyColor(THREE.Color? color) {
    if (_meshes == null) return;
    final meshes = _meshes!;
    for (int m = 0; m < meshes.length; m++) {
      final meshIndex = meshes[m];
      if (meshIndex.mesh.userData['merged'] == true) {
        _applyMergedColor(meshIndex.mesh, meshIndex.index, color);
      } else {
        _applyInstancedColor(
            meshIndex.mesh as THREE.InstancedMesh, meshIndex.index, color);
      }
    }
  }

  //Toggles visibility of this object.
  bool get visible => _visible;

  set visible(bool value) {
    if (_visible == value) return;
    _visible = value;
    _applyVisible(value);
  }

  void _applyVisible(bool value) {
    if (_meshes == null) return;
    final meshes = _meshes!;
    for (int m = 0; m < meshes.length; m++) {
      final meshIndex = meshes[m];
      if (meshIndex.mesh.userData['merged'] == true) {
        _applyMergedVisible(meshIndex.mesh, meshIndex.index, value);
      } else {
        _applyInstancedVisible(
            meshIndex.mesh as THREE.InstancedMesh, meshIndex.index, value);
      }
    }
  }

  // @param index index of the merged mesh instance
  // @returns inclusive first index of the index buffer related to given merged mesh index
  int _getMergedMeshStart(THREE.Mesh mesh, int index) {
    final List<int> submeshes = mesh.userData['submeshes'];
    return submeshes[index];
  }

  // @param index index of the merged mesh instance
  // @returns return the last+1 index of the index buffer related to given merged mesh index
  int _getMergedMeshEnd(THREE.Mesh mesh, int index) {
    final List<int> submeshes = mesh.userData['submeshes'];
    return index + 1 < submeshes.length
        ? submeshes[index + 1]
        : mesh.geometry?.getIndex()!.count ?? 0;
  }

/*
   * Writes new color to the appropriate section of merged mesh color buffer.
   * @param index index of the merged mesh instance
   * @param color rgb representation of the color to apply
   */
  void _applyMergedVisible(THREE.Mesh mesh, int index, bool show) {
    final g = mesh.geometry!;
    Float32BufferAttribute? attribute = g.getAttribute('ignoreVertex');
    if (attribute == null && g.index != null) {
      attribute = Float32BufferAttribute(Float32Array(g.index!.count * 3), 1);
    }
    g.setAttribute('ignoreVertex', attribute);

    final start = _getMergedMeshStart(mesh, index);
    final end = _getMergedMeshEnd(mesh, index);
    final THREE.BufferAttribute indices = g.getIndex()!;

    for (int i = start; i < end; i++) {
      final int v = indices.getX(i)!.toInt();
      attribute!.setX(v, show ? 0 : 1);
    }
    attribute!.needsUpdate = true;
  }

  /*
   * Adds an ignoreInstance buffer to the instanced mesh and sets values to 1 to hide instances
   * @param index index of the instanced instance
   */
  void _applyInstancedVisible(
      THREE.InstancedMesh mesh, int index, bool visible) {
    final g = mesh.geometry!;
    InstancedBufferAttribute? attribute = g.getAttribute('ignoreInstance');
    if (attribute == null && mesh.count != null) {
      attribute = InstancedBufferAttribute(Float32Array(mesh.count!), 1);
      g.setAttribute('ignoreInstance', attribute);
    }

    attribute!.setX(index, visible ? 0 : 1);
    attribute.needsUpdate = true;
  }

  /*
   * Writes new color to the appropriate section of merged mesh color buffer.
   * @param index index of the merged mesh instance
   * @param color rgb representation of the color to apply
   */
  void _applyMergedColor(THREE.Mesh mesh, int index, THREE.Color? color) {
    if (color == null) {
      _resetMergedColor(mesh, index);
      return;
    }

    final start = _getMergedMeshStart(mesh, index);
    final end = _getMergedMeshEnd(mesh, index);

    final g = mesh.geometry!;
    final THREE.Float32BufferAttribute colors = g.getAttribute('color');
    final THREE.Float32BufferAttribute uvs = g.getAttribute('uv');
    final THREE.BufferAttribute indices = g.getIndex()!;

    for (int i = start; i < end; i++) {
      final int v = indices.getX(i)!.toInt();
      // alpha is left to its current value
      colors.setXYZ(v, color.r, color.g, color.b);
      uvs.setY(v, 0);
    }
    colors.needsUpdate = true;
    uvs.needsUpdate = true;
  }

  // Repopulates the color buffer of the merged mesh from original g3d data.
  // @param index index of the merged mesh instance
  void _resetMergedColor(THREE.Mesh mesh, int index) {
    //if (mesh.geometry == null) return;
    final g = mesh.geometry!;
    final THREE.Float32BufferAttribute colors = g.getAttribute('color');
    final THREE.Float32BufferAttribute uvs = g.getAttribute('uv');
    final THREE.BufferAttribute indices = g.getIndex()!;
    var mergedIndex = _getMergedMeshStart(mesh, index);

    final instance = vim.scene.getInstanceFromMesh(mesh, index);
    final g3d = vim.document.g3d;
    final g3dMesh = g3d.instanceMeshes[instance];
    final subStart = g3d.getMeshSubmeshStart(g3dMesh);
    final subEnd = g3d.getMeshSubmeshEnd(g3dMesh);

    for (int sub = subStart; sub < subEnd; sub++) {
      final start = g3d.getSubmeshIndexStart(sub);
      final end = g3d.getSubmeshIndexEnd(sub);
      final color = g3d.getSubmeshColor(sub);
      for (int i = start; i < end; i++) {
        final int v = indices.getX(mergedIndex)!.toInt();
        colors.setXYZ(v, color[0], color[1], color[2]);
        uvs.setY(v, 1);
        mergedIndex++;
      }
    }
    colors.needsUpdate = true;
    uvs.needsUpdate = true;
  }

  /*
   * Adds an instanceColor buffer to the instanced mesh and sets new color for given instance
   * @param index index of the instanced instance
   * @param color rgb representation of the color to apply
   */
  void _applyInstancedColor(
      THREE.InstancedMesh mesh, int index, THREE.Color? color) {
    if (mesh.instanceColor == null) {
      _addColorAttributes(mesh);
    }
    final g = mesh.geometry!;
    final InstancedBufferAttribute ignoreVertexColor =
        g.getAttribute('ignoreVertexColor');
    if (color != null) {
      // Set instance to use instance color provided
      mesh.instanceColor?.setXYZ(index, color.r, color.g, color.b);
      ignoreVertexColor.setX(index, 1);
    } else {
      // Revert to vertex color
      ignoreVertexColor.setX(index, 0);
    }

    // Set attributes dirty
    ignoreVertexColor.needsUpdate = true;
    mesh.instanceColor?.needsUpdate = true;
    // mesh.material = new THREE.MeshBasicMaterial({ color: new THREE.Color(0, 1, 0) })
  }

  void _addColorAttributes(THREE.InstancedMesh mesh) {
    final count = mesh.instanceMatrix.count;
    // Add color instance attribute
    final colors = Float32Array(count * 3);
    mesh.instanceColor = THREE.InstancedBufferAttribute(colors, 3);

    // Add custom ignoreVertexColor instance attribute
    final ignoreVertexColor = Float32Array(count);
    mesh.geometry?.setAttribute('ignoreVertexColor',
        THREE.InstancedBufferAttribute(ignoreVertexColor, 1));
  }
}
