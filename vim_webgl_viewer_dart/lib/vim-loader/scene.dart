/*
 * Scene is the highest level organization of three geometry of the vim loader.
 * @module vim-loader
 */

import 'package:three_dart/three_dart.dart' as THREE;
import './g3d.dart';
import './mesh.dart';
import 'object.dart';
import 'transparency.dart';
import 'vim.dart';

/*
 * A Scene regroups many THREE.Meshes
 * It keep tracks of the global bounding box as Meshes are added
 * It keeps a map from g3d instance indices to THREE.Mesh and vice versa
 */
class Scene {
  List<THREE.Mesh> meshes = [];
  THREE.Box3? boundingBox = THREE.Box3();
  final Map<int, MeshNumber> _instanceToThreeMesh = {};
  final Map<int, List<int>> _threeMeshIdToInstances = {};

  Scene._();

  /*
   * Returns the THREE.Mesh in which this instance is represented along with index
   * For merged mesh, index refers to submesh index
   * For instanced mesh, index refers to instance index.
   */
  MeshNumber? getMeshFromInstance(int instance) =>
      _instanceToThreeMesh[instance];

  /*
   * Returns the index of the g3d instance that from which this mesh instance was created
   * @param mesh a mesh created by the vim loader
   * @param index if merged mesh the index into the merged mesh, if instance mesh the instance index.
   * @returns a g3d instance index.
   */
  int getInstanceFromMesh(THREE.Mesh mesh, int index) {
    if (index < 0) return -1;
    final instances = _threeMeshIdToInstances[mesh.id];
    return instances == null ? -1 : instances[index];
  }

  /*
   * Applies given transform matrix to all THREE.Meshes and bounding box.
   */
  void applyMatrix4(THREE.Matrix4 matrix) {
    for (int m = 0; m < meshes.length; m++) {
      meshes[m].matrixAutoUpdate = false;
      meshes[m].matrix.copy(matrix);
    }
    boundingBox?.applyMatrix4(matrix);
  }

  // Sets vim index for this scene and all its THREE.Meshes.
  void setVim(Vim vim) {
    for (int m = 0; m < meshes.length; m++) {
      meshes[m].userData['vim'] = vim;
    }
  }

  /* Add an instanced mesh to the Scene and recomputes fields as needed.
   * @param mesh Is expected to have userData.instances = number[]
   * where numbers are the indices of the g3d instances that went into creating the mesh */
  Scene addMergedMesh(THREE.Mesh mesh) {
    final List<int>? instances = mesh.userData['instances'];
    if (instances == null) {
      throw Exception('Expected mesh to have userdata instances : List<int>');
    }
    for (int i = 0; i < instances.length; i++) {
      final instance = instances[i].toInt();
      _instanceToThreeMesh[instance] = MeshNumber(mesh, i);
    }
    final geometry = mesh.geometry!;
    geometry.computeBoundingBox();
    final box = geometry.boundingBox!;
    boundingBox = boundingBox?.union(box) ?? box.clone();

    _threeMeshIdToInstances[mesh.id] = instances;
    meshes.add(mesh);
    return this;
  }

  /* Add an instanced mesh to the Scene and recomputes fields as needed.
   * @param mesh Is expected to have userData.instances = number[]
   * where numbers are the indices of the g3d instances that went into creating the mesh */
  Scene addInstancedMesh(THREE.InstancedMesh mesh) {
    _registerInstancedMesh(mesh);
    meshes.add(mesh);
    return this;
  }

  /*
   * Creates a Scene from given mesh array. Keeps a reference to the array.
   * @param meshes members are expected to have userData.instances = number[]
   * where numbers are the indices of the g3d instances that went into creating each mesh
   */
  factory Scene.fromInstancedMeshes(List<THREE.InstancedMesh> meshes) {
    final scene = Scene._();

    for (int m = 0; m < meshes.length; m++) {
      scene._registerInstancedMesh(meshes[m]);
    }
    scene.meshes = meshes;
    return scene;
  }

  void _registerInstancedMesh(THREE.InstancedMesh mesh) {
    final List<int>? instances = mesh.userData['instances'];
    if (instances == null || instances.isEmpty) {
      throw Exception(
          'Expected mesh to have userdata instances : number[] with at least one member');
    }
    if (mesh.count == 0) {
      throw Exception('Expected mesh to have at least one instance');
    }
    for (int i = 0; i < instances.length; i++) {
      _instanceToThreeMesh[instances[i]] = MeshNumber(mesh, i);
    }
    final box = _computeIntancedMeshBoundingBox(mesh);
    boundingBox = boundingBox?.union(box!) ?? box?.clone();
    _threeMeshIdToInstances[mesh.id] = instances;
  }

  /*
  * Adds the content of other Scene to this Scene and recomputes fields as needed.
  */
  Scene merge(Scene other) {
    other.meshes.forEach(meshes.add);
    other._instanceToThreeMesh.forEach((key, value) {
      _instanceToThreeMesh[key] = value;
    });
    other._threeMeshIdToInstances.forEach((key, value) {
      _threeMeshIdToInstances[key] = value;
    });
    final union = boundingBox?.union(other.boundingBox!);
    boundingBox = union ?? other.boundingBox?.clone();
    return this;
  }

  void dispose() {
    for (int i = 0; i < meshes.length; i++) {
      meshes[i].geometry?.dispose();
    }
    meshes.length = 0;
    _instanceToThreeMesh.clear();
    _threeMeshIdToInstances.clear();
  }

  /*
   * Computes the bounding box around all instances in world position of an InstancedMesh.
   */
  THREE.Box3? _computeIntancedMeshBoundingBox(THREE.InstancedMesh mesh) {
    THREE.Box3? result;
    final geometry = mesh.geometry!;
    final matrix = THREE.Matrix4();
    final box = THREE.Box3();
    geometry.computeBoundingBox();

    for (int i = 0; i < mesh.count!; i++) {
      mesh.getMatrixAt(i, matrix);
      box.copy(geometry.boundingBox!);
      box.applyMatrix4(matrix);
      result = result != null ? result.union(box) : box.clone();
    }
    return result;
  }

  /* Creates a new Scene from a g3d by merging mergeble meshes and instancing instantiable meshes
   * @param transparency Specify whether color is RBG or RGBA and whether material is opaque or transparent
   * @param instances g3d instance indices to be included in the Scene. All if undefined. */
  factory Scene.fromG3d(
    G3d g3d,
    Mode transparency,
    List<int>? instances,
  ) {
    final scene = Scene._();
    // Add shared geometry
    final shared = Scene.fromInstanciableMeshes(
      g3d,
      transparency,
      instances,
    );
    scene.merge(shared);
    // Add opaque geometry
    if (transparency != Mode.transparentOnly) {
      final opaque = Scene.fromMergeableMeshes(
        g3d,
        transparency == Mode.allAsOpaque ? Mode.allAsOpaque : Mode.opaqueOnly,
        instances,
      );
      scene.merge(opaque);
    }
    // Add transparent geometry
    if (transparency.useAlpha()) {
      final transparent = Scene.fromMergeableMeshes(
        g3d,
        Mode.transparentOnly,
        instances,
      );
      scene.merge(transparent);
    }
    return scene;
  }

  /*
   * Creates a Scene from instantiable meshes from the g3d
   * @param transparency Specify whether color is RBG or RGBA and whether material is opaque or transparent
   * @param instances g3d instance indices to be included in the Scene. All if undefined.
   * @param builder optional builder to reuse the same materials
   */
  factory Scene.fromInstanciableMeshes(
    G3d g3d,
    Mode transparency,
    List<int>? instances, [
    Builder? builder,
  ]) {
    final mb = builder ?? Builder.defaultBuilder();
    final meshes = mb.createInstancedMeshes(g3d, transparency, instances);
    return Scene.fromInstancedMeshes(meshes);
  }

  // g3d instance indices to be included in the merged mesh. All mergeable meshes if undefined.
  /*
   * Creates a Scene from mergeable meshes from the g3d
   * @param transparency Specify whether color is RBG or RGBA and whether material is opaque or transparent
   * @param instances g3d instance indices to be included in the Scene. All if undefined.
   * @param builder optional builder to reuse the same materials
   */
  factory Scene.fromMergeableMeshes(
    G3d g3d,
    Mode transparency,
    List<int>? instances, [
    Builder? builder,
  ]) {
    final mb = builder ?? Builder.defaultBuilder();
    final mesh = mb.createMergedMesh(g3d, transparency, instances);
    return Scene._().addMergedMesh(mesh);
  }
}
