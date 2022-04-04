/*
 * Provides methods to create BufferGeometry from g3d geometry data.
 * @module vim-loader
 */
library geometry;

import 'dart:typed_data';
import 'package:flutter_gl/native-array/index.dart';
import 'package:three_dart/three_dart.dart' as THREE;
import './g3d.dart';
import 'transparency.dart';

extension G3dExtensions on G3d {
/*
 * Creates a BufferGeometry with all given instances merged
 * @param instances indices of the instances from the g3d to merge
 * @returns a BufferGeometry
 */
  THREE.BufferGeometry createGeometryFromInstances(List<int> instances) {
    final merger = Merger.fromInstances(this, instances, Mode.all);
    return merger.toBufferGeometry();
  }

  /*
 * Creates a BufferGeometry from a given mesh index in the g3d
 * @param mesh mesh index in the g3d
 * @param useAlpha specify to use RGB or RGBA for colors
 */
  THREE.BufferGeometry createGeometryFromMesh(int mesh, bool useAlpha) {
    final colors = createVertexColors(mesh, useAlpha);

    return createGeometryFromArrays(
        Float32Array.from(positions.sublist(
          getMeshVertexStart(mesh) * 3,
          getMeshVertexEnd(mesh) * 3,
        )),
        Uint32Array.from(indices.sublist(
          getMeshIndexStart(mesh),
          getMeshIndexEnd(mesh),
        )),
        Float32Array.from(colors),
        useAlpha ? 4 : 3);
  }

  /*
 * Expands submesh colors into vertex colors as RGB or RGBA
 */
  Float32List createVertexColors(int mesh, bool useAlpha) {
    final colorSize = useAlpha ? 4 : 3;
    final result = Float32List(getMeshVertexCount(mesh) * colorSize);
    final subStart = getMeshSubmeshStart(mesh);
    final subEnd = getMeshSubmeshEnd(mesh);
    for (int submesh = subStart; submesh < subEnd; submesh++) {
      final color = getSubmeshColor(submesh);
      final start = getSubmeshIndexStart(submesh);
      final end = getSubmeshIndexEnd(submesh);
      for (int i = start; i < end; i++) {
        final v = indices[i] * colorSize;
        result[v] = color[0];
        result[v + 1] = color[1];
        result[v + 2] = color[2];
        if (useAlpha) {
          result[v + 3] = color[3];
        }
      }
    }
    return result;
  }

/*
 * Creates a BufferGeometry from given geometry data arrays
 * @param vertices vertex data with 3 number per vertex (XYZ)
 * @param indices index data with 3 indices per face
 * @param vertexColors color data with 3 or 4 number per vertex. RBG or RGBA
 * @param colorSize specify whether to treat colors as RGB or RGBA
 * @param uvs uv data with 2 number per vertex (XY)
 * @returns a BufferGeometry
 */
  static THREE.BufferGeometry createGeometryFromArrays(
    Float32Array vertices,
    Uint32Array indices, [
    Float32Array? vertexColors,
    int colorSize = 3,
    Float32Array? uvs,
  ]) {
    final geometry = THREE.BufferGeometry();
    // Vertices
    final position = THREE.Float32BufferAttribute(vertices, 3);
    geometry.setAttribute('position', position);
    // Indices
    geometry.setIndex(THREE.Uint32BufferAttribute(indices, 1));
    // Colors with alpha if transparent
    if (vertexColors != null) {
      final color = THREE.Float32BufferAttribute(vertexColors, colorSize);
      geometry.setAttribute('color', color);
      if (uvs != null) {
        final uv = THREE.Float32BufferAttribute(uvs, 2);
        geometry.setAttribute('uv', uv);
      }
    }
    return geometry;
  }

  THREE.Matrix4 getInstanceMatrix(int index, [THREE.Matrix4? target]) {
    final matrix = target ?? THREE.Matrix4();
    final matrixAsArray = getInstanceTransform(index);
    matrix.fromArray(matrixAsArray);
    return matrix;
  }
}

// Helper to merge many instances/meshes from a g3d direcly into a BufferGeometry
class Merger {
  final G3d _g3d;
  final int _colorSize;

  final List<int> _meshes;
  final Uint32Array _indices;
  final Float32Array _vertices;
  final Float32Array _colors;
  final Float32Array _uvs;

  final List<int> _instances;
  final List<int> _submeshes;

  static int _getColorSize(Mode mode) => mode.useAlpha() ? 4 : 3;

  Merger({
    required G3d g3d,
    required Mode transparency,
    required List<int> instances,
    required List<int> meshes,
    required int indexCount,
    required int vertexCount,
  })  : _g3d = g3d,
        _colorSize = _getColorSize(transparency),
        _instances = instances,
        _meshes = meshes,
        _indices = Uint32Array(indexCount),
        _vertices = Float32Array(vertexCount * G3d.POSITION_SIZE),
        _colors = Float32Array(vertexCount * _getColorSize(transparency)),
        _uvs = Float32Array(vertexCount * 2),
        _submeshes = List.filled(instances.length, 0);

  List<int> get instances => _instances;
  List<int> get submeshes => _submeshes;

  // Prepares a merge of all meshes referenced by only one instance.
  factory Merger.fromUniqueMeshes(G3d g3d, Mode transparency) {
    int vertexCount = 0;
    int indexCount = 0;
    final instances = <int>[];
    final meshes = <int>[];

    final meshCount = g3d.meshCount;
    for (int mesh = 0; mesh < meshCount; mesh++) {
      final meshInstances = g3d.meshInstances[mesh];
      if (meshInstances == null || meshInstances.length != 1) continue;
      if (!transparency.match(g3d.meshTransparent[mesh])) continue;

      vertexCount += g3d.getMeshVertexCount(mesh);
      indexCount += g3d.getMeshIndexCount(mesh);
      instances.add(meshInstances.first);
      meshes.add(mesh);
    }
    return Merger(
      g3d: g3d,
      transparency: transparency,
      instances: instances,
      meshes: meshes,
      indexCount: indexCount,
      vertexCount: vertexCount,
    );
  }
  // Prepares a merge of all meshes referenced by given instances.
  factory Merger.fromInstances(
    G3d g3d,
    List<int> instances,
    Mode transparency,
  ) {
    int vertexCount = 0;
    int indexCount = 0;
    final instancesFiltered = <int>[];
    final meshes = <int>[];
    for (int i = 0; i < instances.length; i++) {
      final instance = instances[i];
      final mesh = g3d.instanceMeshes[instance];
      if (mesh < 0) continue;
      if (!transparency.match(g3d.meshTransparent[mesh])) continue;

      vertexCount += g3d.getMeshVertexCount(mesh);
      indexCount += g3d.getMeshIndexCount(mesh);
      instancesFiltered.add(instance);
      meshes.add(mesh);
    }
    return Merger(
      g3d: g3d,
      transparency: transparency,
      instances: instancesFiltered,
      meshes: meshes,
      indexCount: indexCount,
      vertexCount: vertexCount,
    );
  }

  /* Concatenates the arrays of each of the (instance,matrix) pairs into large arrays
   * Vertex position is transformed with the relevent matrix at it is copied
   * Index is offset to match the vertices in the concatenated vertex buffer
   * Color is expanded from submehes to vertex color into a concatenated array
   * UVs are used to track which instance eache vertex came from
   * Returns a BufferGeometry from the concatenated array */
  void _merge() {
    int index = 0;
    int vertex = 0;
    int uv = 0;
    int offset = 0;

    // matrix and vector is reused to avoid needless allocations
    final matrix = THREE.Matrix4();
    final vector = THREE.Vector3();

    for (int i = 0; i < _instances.length; i++) {
      final mesh = _meshes[i];
      final instance = _instances[i];
      _submeshes[i] = index;

      // Copy all indices to merge array
      final indexStart = _g3d.getMeshIndexStart(mesh);
      final indexEnd = _g3d.getMeshIndexEnd(mesh);
      for (int i = indexStart; i < indexEnd; i++) {
        _indices[index++] = _g3d.indices[i] + offset;
      }

      // Copy all colors to merged array
      final subStart = _g3d.getMeshSubmeshStart(mesh);
      final subEnd = _g3d.getMeshSubmeshEnd(mesh);
      for (int sub = subStart; sub < subEnd; sub++) {
        final startIndex = _g3d.getSubmeshIndexStart(sub);
        final endIndex = _g3d.getSubmeshIndexEnd(sub);

        final subColor = _g3d.getSubmeshColor(sub);
        for (int i = startIndex; i < endIndex; i++) {
          final v = (_g3d.indices[i] + offset) * _colorSize;
          _colors[v] = subColor[0];
          _colors[v + 1] = subColor[1];
          _colors[v + 2] = subColor[2];
          if (_colorSize > 3) {
            _colors[v + 3] = subColor[3];
          }
        }
      }

      // Apply Matrices and copy vertices to merged array
      _g3d.getInstanceMatrix(instance.toInt(), matrix);
      final vertexStart = _g3d.getMeshVertexStart(mesh);
      final vertexEnd = _g3d.getMeshVertexEnd(mesh);

      for (int p = vertexStart; p < vertexEnd; p++) {
        vector.fromArray(_g3d.positions, p * G3d.POSITION_SIZE);
        vector.applyMatrix4(matrix);
        vector.toArray(_vertices.toDartList(), vertex);

        vertex += G3d.POSITION_SIZE;
        // Fill uvs with instances at the same time as vertices. Used for picking
        _uvs[uv++] = instance.toDouble();
        _uvs[uv++] = 1; //instance.toDouble();
      }
      // Keep offset for next mesh
      offset += vertexEnd - vertexStart;
    }
  }

  THREE.BufferGeometry toBufferGeometry() {
    _merge();
    final geometry = G3dExtensions.createGeometryFromArrays(
      _vertices,
      _indices,
      _colors,
      _colorSize,
      _uvs,
    );
    return geometry;
  }
}
