library mesh;

import 'package:three_dart/three_dart.dart' as THREE;
import './g3d.dart';
import './geometry.dart';
import 'materials.dart';
import 'transparency.dart';

/*
 * Builds meshes from the g3d and BufferGeometry
 * Allows to reuse the same material for all new built meshes
 */
class Builder {
  static Builder? _defaultBuilder;
  final Library materials;

  Builder([Library? mat]) : materials = mat ?? Library.defaultLibrary();

  factory Builder.defaultBuilder() =>
      _defaultBuilder ?? (_defaultBuilder = Builder());

  /*
   * Creates Instanced Meshes from the g3d data
   * @param transparency Specify wheter color is RBG or RGBA and whether material is opaque or transparent
   * @param instances instance indices from the g3d for which meshes will be created.
   *  If undefined, all multireferenced meshes will be created.
   * @returns an array of THREE.InstancedMesh
   */
  List<THREE.InstancedMesh> createInstancedMeshes(
    G3d g3d,
    Mode transparency,
    List<int>? instances,
  ) {
    final result = <THREE.InstancedMesh>[];
    final set = instances?.toSet();
    for (int mesh = 0; mesh < g3d.meshCount; mesh++) {
      var meshInstances = g3d.meshInstances[mesh];
      if (meshInstances == null) continue;
      meshInstances = set != null
          ? meshInstances.where((i) => set.contains(i)).toList()
          : meshInstances;
      if (meshInstances.length <= 1) continue;
      if (!transparency.match(g3d.meshTransparent[mesh])) continue;

      final useAlpha = transparency.useAlpha() && g3d.meshTransparent[mesh];
      final geometry = g3d.createGeometryFromMesh(mesh, useAlpha);
      final resultMesh =
          createInstancedMesh(geometry, g3d, meshInstances, useAlpha);
      result.add(resultMesh);
    }
    return result;
  }

  /*
   * Creates a InstancedMesh from g3d data and given instance indices
   * @param geometry Geometry to use in the mesh
   * @param instances Instance indices for which matrices will be applied to the mesh
   * @param useAlpha Specify whether to use RGB or RGBA
   * @returns a THREE.InstancedMesh
   */
  THREE.InstancedMesh createInstancedMesh(
    THREE.BufferGeometry geometry,
    G3d g3d,
    List<int> instances,
    bool useAlpha,
  ) {
    final material = useAlpha ? materials.transparent : materials.opaque;
    final result = THREE.InstancedMesh(geometry, material, instances.length);
    for (int i = 0; i < instances.length; i++) {
      final matrix = g3d.getInstanceMatrix(instances[i]);
      result.setMatrixAt(i, matrix);
    }
    result.userData['instances'] = instances;
    return result;
  }

  /*
   * Create a merged mesh from g3d instance indices
   * @param transparency Specify wheter color is RBG or RGBA and whether material is opaque or transparent
   * @param instances g3d instance indices to be included in the merged mesh. All mergeable meshes if undefined.
   * @returns a THREE.Mesh
   */
  THREE.Mesh createMergedMesh(
    G3d g3d,
    Mode transparency,
    List<int>? instances,
  ) {
    final merger = instances != null
        ? Merger.fromInstances(g3d, instances, transparency)
        : Merger.fromUniqueMeshes(g3d, transparency);
    final geometry = merger.toBufferGeometry();
    final material =
        transparency.useAlpha() ? materials.transparent : materials.opaque;
    final mesh = THREE.Mesh(geometry, material);
    mesh.userData['merged'] = true;
    mesh.userData['instances'] = merger.instances;
    mesh.userData['submeshes'] = merger.submeshes;
    return mesh;
  }

  /*
     * Create a wireframe mesh from g3d instance indices
     * @param instances g3d instance indices to be included in the merged mesh. All mergeable meshes if undefined.
     * @returns a THREE.Mesh
     */
  THREE.LineSegments createWireframe(G3d g3d, List<int> instances) {
    final geometry = g3d.createGeometryFromInstances(instances);
    final wireframe = THREE.WireframeGeometry(geometry);
    return THREE.LineSegments(wireframe, materials.wireframe);
  }

  void dispose() {
    _defaultBuilder = null;
  }
}
