/*
 * G3D is a simple, efficient, generic binary format for storing and transmitting geometry.
 * The G3D format is designed to be used either as a serialization format or as an in-memory data structure.
 * See https://github.com/vimaec/g3d
 * @module vim-loader
 */
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_gl/native-array/index.dart';

import './bfast.dart';

class G3dAttributeDescriptor {
  // original descriptor string
  final String description;
  // Indicates the part of the geometry that this attribute is associated with
  final String association;
  // the role of the attribute
  final String semantic;
  // each attribute type should have it's own index ( you can have uv0, uv1, etc. )
  final String attributeTypeIndex;
  // the type of individual values (e.g. int32, float64)
  final String dataType;
  // how many values associated with each element (e.g. UVs might be 2, geometry might be 3, quaternions 4, matrices 9 or 16)
  final int dataArity;

  G3dAttributeDescriptor({
    required this.description,
    required this.association,
    required this.semantic,
    required this.attributeTypeIndex,
    required this.dataType,
    required this.dataArity,
  }) : assert(
            description.startsWith('g3d:'), '$description must start with g3d');

  factory G3dAttributeDescriptor.fromString(String descriptor) {
    final desc = descriptor.split(':');
    if (desc.length != 6) {
      throw Exception('$descriptor, must have 6 components delimited by :');
    }
    return G3dAttributeDescriptor(
        description: descriptor,
        association: desc[1],
        semantic: desc[2],
        attributeTypeIndex: desc[3],
        dataType: desc[4],
        dataArity: int.parse(desc[5]));
  }

  bool matches(G3dAttributeDescriptor other) {
    bool match(String a, String b) => a == '*' || b == '*' || a == b;
    return match(association, other.association) &&
        match(semantic, other.semantic) &&
        match(attributeTypeIndex, other.attributeTypeIndex) &&
        match(dataType, other.dataType);
  }
}

class G3dAttribute {
  final G3dAttributeDescriptor descriptor;
  final Uint8List bytes;
  final NativeArray data;

  G3dAttribute({
    required this.descriptor,
    required this.bytes,
  }) : data = bytes.castData(descriptor.dataType);

  G3dAttribute.fromString(String descriptor, Uint8List buffer)
      : this(
            descriptor: G3dAttributeDescriptor.fromString(descriptor),
            bytes: buffer);
}

/*
 * G3D is a simple, efficient, generic binary format for storing and transmitting geometry.
 * The G3D format is designed to be used either as a serialization format or as an in-memory data structure.
 * See https://github.com/vimaec/g3d
 */
class AbstractG3d {
  final String meta;
  final List<G3dAttribute> attributes;

  const AbstractG3d({
    required this.meta,
    required this.attributes,
  });

  G3dAttribute? findAttribute(String filter) {
    final descriptor = G3dAttributeDescriptor.fromString(filter);
    for (int i = 0; i < attributes.length; ++i) {
      final attribute = attributes[i];
      if (attribute.descriptor.matches(descriptor)) {
        return attribute;
      }
    }
    return null;
  }

  // Given a BFAST container (header/names/buffers) constructs a G3D data structure
  factory AbstractG3d.fromBfast(BFast bfast) {
    if (bfast.buffers.length < 2) {
      throw Exception('G3D requires at least two BFast buffers');
    }
    // Parse first buffer as Meta
    final metaBuffer = bfast.buffers.first;
    if (bfast.names.first != 'meta') {
      throw Exception(
          "First G3D buffer must be named 'meta', but was named: ${bfast.names.first}");
    }
    const utf8 = Utf8Codec();
    final meta = utf8.decode(metaBuffer, allowMalformed: true);
    // Parse remaining buffers as Attributes
    var attributes = <G3dAttribute>[];
    final descriptors = bfast.buffers.length - 1;
    for (int i = 0; i < descriptors; ++i) {
      final attribute = G3dAttribute.fromString(
        bfast.names[i + 1],
        bfast.buffers[i + 1],
      );
      attributes.add(attribute);
    }
    return AbstractG3d(meta: meta, attributes: attributes);
  }
}

/*
 * See https://github.com/vimaec/vim#vim-geometry-attributes
 */
class VimG3dA {
  static final positions =
      G3dAttributeDescriptor.fromString('g3d:vertex:position:0:float32:3');
  static final indices =
      G3dAttributeDescriptor.fromString('g3d:corner:index:0:int32:1');
  static final instanceMeshes =
      G3dAttributeDescriptor.fromString('g3d:instance:mesh:0:int32:1');
  static final instanceTransforms =
      G3dAttributeDescriptor.fromString('g3d:instance:transform:0:float32:16');
  static final meshSubmeshes =
      G3dAttributeDescriptor.fromString('g3d:mesh:submeshoffset:0:int32:1');
  static final submeshIndexOffsets =
      G3dAttributeDescriptor.fromString('g3d:submesh:indexoffset:0:int32:1');
  static final submeshMaterials =
      G3dAttributeDescriptor.fromString('g3d:submesh:material:0:int32:1');
  static final materialColors =
      G3dAttributeDescriptor.fromString('g3d:material:color:0:float32:4');
}

/*
 * A G3d with specific attributes according to the VIM format specification.
 * See https://github.com/vimaec/vim#vim-geometry-attributes for the vim specification.
 * See https://github.com/vimaec/g3d for the g3d specification.
 */
class G3d {
  late final Float32Array positions;
  late final Uint32Array indices;

  late final Int32Array instanceMeshes;
  late final Float32Array instanceTransforms;
  late final Int32Array meshSubmeshes;
  late final Int32Array submeshIndexOffsets;
  late final Int32Array submeshMaterials;
  late final Float32Array materialColors;

  // computed fields
  late final Int32List meshVertexOffsets;
  late final Map<int, List<int>> meshInstances;
  late final List<bool> meshTransparent;

  final AbstractG3d rawG3d;

  static const MATRIX_SIZE = 16;
  static const COLOR_SIZE = 4;
  static const POSITION_SIZE = 3;
  static final DEFAULT_COLOR = Float32List.fromList([1, 1, 1, 1]);
  static const MAX_SAFE_INTEGER = 9007199254740991;

  factory G3d.fromBfast(BFast bfast) => G3d(AbstractG3d.fromBfast(bfast));
  G3d(AbstractG3d g3d) : rawG3d = g3d {
    Int32Array? _instances;
    for (int i = 0; i < g3d.attributes.length; ++i) {
      final attribute = g3d.attributes[i];
      if (attribute.descriptor.matches(VimG3dA.positions)) {
        positions = attribute.data as Float32Array;
      } else if (attribute.descriptor.matches(VimG3dA.indices)) {
        //TODO: ??/
        indices = Uint32Array.from(attribute.data.toDartList() as List<int>);
      } else if (attribute.descriptor.matches(VimG3dA.meshSubmeshes)) {
        meshSubmeshes = attribute.data as Int32Array;
      } else if (attribute.descriptor.matches(VimG3dA.submeshIndexOffsets)) {
        submeshIndexOffsets = attribute.data as Int32Array;
      } else if (attribute.descriptor.matches(VimG3dA.submeshMaterials)) {
        submeshMaterials = attribute.data as Int32Array;
      } else if (attribute.descriptor.matches(VimG3dA.materialColors)) {
        materialColors = attribute.data as Float32Array;
      } else if (attribute.descriptor.matches(VimG3dA.instanceMeshes)) {
        _instances = attribute.data as Int32Array;
      } else if (attribute.descriptor.matches(VimG3dA.instanceTransforms)) {
        instanceTransforms = attribute.data as Float32Array;
      }
    }
    instanceMeshes = _instances ?? Int32Array(0);
    meshVertexOffsets = _computeMeshVertexOffsets();
    _rebaseIndices();
    meshInstances = _computeMeshInstances();
    meshTransparent = _computeMeshIsTransparent();
  }

  Int32List _computeMeshVertexOffsets() {
    final result = Int32List(meshCount);
    for (int m = 0; m < result.length; m++) {
      int minValue = MAX_SAFE_INTEGER;
      final start = getMeshIndexStart(m);
      final end = getMeshIndexEnd(m);
      for (int i = start; i < end; i++) {
        minValue = min(minValue, indices[i]);
      }
      result[m] = minValue;
    }
    return result;
  }

  void _rebaseIndices() {
    for (int m = 0; m < meshCount; m++) {
      final offset = meshVertexOffsets[m];
      final start = getMeshIndexStart(m);
      final end = getMeshIndexEnd(m);
      for (int i = start; i < end; i++) {
        indices[i] -= offset;
      }
    }
  }

  Map<int, List<int>> _computeMeshInstances() {
    var result = <int, List<int>>{};
    for (int i = 0; i < instanceMeshes.length; i++) {
      final mesh = instanceMeshes[i];
      if (mesh >= 0) {
        final instanceIndices = result[mesh];
        if (instanceIndices != null) {
          instanceIndices.add(i);
        } else {
          result[mesh] = [i];
        }
      }
    }
    return result;
  }

  List<bool> _computeMeshIsTransparent() {
    final result = List.filled(meshCount, false);
    for (int m = 0; m < result.length; m++) {
      final subStart = getMeshSubmeshStart(m);
      final subEnd = getMeshSubmeshEnd(m);
      for (int s = subStart; s < subEnd; s++) {
        //final material = submeshMaterials[s];
        var material = submeshMaterials[s];
        material = material < 0 ? -material : material;
        final alpha = materialColors[material * COLOR_SIZE + COLOR_SIZE - 1];
        result[m] = result[m] || alpha < 1;
      }
    }
    return result;
  }

  // ------------- All -----------------
  int get vertexCount => positions.length ~/ POSITION_SIZE;

  // ------------- Meshes -----------------
  int get meshCount => meshSubmeshes.length;
  int getMeshIndexStart(int mesh) =>
      getSubmeshIndexStart(getMeshSubmeshStart(mesh));
  int getMeshIndexEnd(int mesh) =>
      getSubmeshIndexEnd(getMeshSubmeshEnd(mesh) - 1);
  int getMeshIndexCount(int mesh) =>
      getMeshIndexEnd(mesh) - getMeshIndexStart(mesh);
  int getMeshVertexStart(int mesh) => meshVertexOffsets[mesh];
  int getMeshVertexEnd(int mesh) => mesh < meshVertexOffsets.length - 1
      ? meshVertexOffsets[mesh + 1]
      : vertexCount;
  int getMeshVertexCount(int mesh) =>
      getMeshVertexEnd(mesh) - getMeshVertexStart(mesh);
  int getMeshSubmeshStart(int mesh) => meshSubmeshes[mesh];
  int getMeshSubmeshEnd(int mesh) => mesh < meshSubmeshes.length - 1
      ? meshSubmeshes[mesh + 1]
      : submeshIndexOffsets.length;
  int getMeshSubmeshCount(int mesh) =>
      getMeshSubmeshEnd(mesh) - getMeshSubmeshStart(mesh);

  // ------------- Submeshes -----------------
  int getSubmeshIndexStart(int submesh) => submeshIndexOffsets[submesh];
  int getSubmeshIndexEnd(int submesh) =>
      submesh < submeshIndexOffsets.length - 1
          ? submeshIndexOffsets[submesh + 1]
          : indices.length;
  int getSubmeshIndexCount(int submesh) =>
      getSubmeshIndexEnd(submesh) - getSubmeshIndexStart(submesh);
  List<double> getSubmeshColor(int submesh) =>
      getMaterialColor(submeshMaterials[submesh]);

  // ------------- Instances -----------------
  int get instanceCount => instanceMeshes.length;
  List<double> getInstanceTransform(int instance) => instanceTransforms.sublist(
      instance * MATRIX_SIZE, (instance + 1) * MATRIX_SIZE);

  // ------------- Material -----------------
  int get materialCount => materialColors.length ~/ COLOR_SIZE;
  List<double> getMaterialColor(int material) => material < 0
      ? DEFAULT_COLOR
      : materialColors.sublist(
          material * COLOR_SIZE, (material + 1) * COLOR_SIZE);

  void validate() {
    void isPresent(NativeArray attribute, String label) {
      if (attribute.lengthInBytes == 0) {
        throw Exception('Missing Attribute Buffer: $label');
      }
    }

    isPresent(positions, 'position');
    isPresent(indices, 'indices');
    isPresent(instanceMeshes, 'instanceMeshes');
    isPresent(instanceTransforms, 'instanceTransforms');
    isPresent(meshSubmeshes, 'meshSubmeshes');
    isPresent(submeshIndexOffsets, 'submeshIndexOffset');
    isPresent(submeshMaterials, 'submeshMaterial');
    isPresent(materialColors, 'materialColors');
    // Basic
    if (positions.length % POSITION_SIZE != 0) {
      throw Exception(
          'Invalid position buffer, must be divisible by $POSITION_SIZE');
    }
    if (indices.length % 3 != 0) {
      throw Exception('Invalid Index Count, must be divisible by 3');
    }
    for (int i = 0; i < indices.length; i++) {
      if (indices[i] < 0 || indices[i] >= positions.length) {
        throw Exception('Vertex index out of bound');
      }
    }
    // Instances
    if (instanceMeshes.length != instanceTransforms.length ~/ MATRIX_SIZE) {
      throw Exception('Instance buffers mismatched');
    }
    if (instanceTransforms.length % MATRIX_SIZE != 0) {
      throw Exception(
          'Invalid InstanceTransform buffer, must respect arity $MATRIX_SIZE');
    }
    for (int i = 0; i < instanceMeshes.length; i++) {
      if (instanceMeshes[i] >= meshSubmeshes.length) {
        throw Exception('Instance Mesh Out of range.');
      }
    }
    // Meshes
    for (int i = 0; i < meshSubmeshes.length; i++) {
      if (meshSubmeshes[i] < 0 ||
          meshSubmeshes[i] >= submeshIndexOffsets.length) {
        throw Exception('MeshSubmeshOffset out of bound at');
      }
    }
    for (int i = 0; i < meshSubmeshes.length - 1; i++) {
      if (meshSubmeshes[i] >= meshSubmeshes[i + 1]) {
        throw Exception('MeshSubmesh out of sequence.');
      }
    }
    // Submeshes
    if (submeshIndexOffsets.length != submeshMaterials.length) {
      throw Exception('Mismatched submesh buffers');
    }
    for (int i = 0; i < submeshIndexOffsets.length; i++) {
      if (submeshIndexOffsets[i] < 0 ||
          submeshIndexOffsets[i] >= indices.length) {
        throw Exception('SubmeshIndexOffset out of bound');
      }
    }
    for (int i = 0; i < submeshIndexOffsets.length; i++) {
      if (submeshIndexOffsets[i] % 3 != 0) {
        throw Exception('Invalid SubmeshIndexOffset, must be divisible by 3');
      }
    }
    for (int i = 0; i < submeshIndexOffsets.length - 1; i++) {
      if (submeshIndexOffsets[i] >= submeshIndexOffsets[i + 1]) {
        throw Exception('SubmeshIndexOffset out of sequence.');
      }
    }

    for (int i = 0; i < submeshMaterials.length; i++) {
      if (submeshMaterials[i] >= materialColors.length) {
        throw Exception('submeshMaterial out of bound');
      }
    }
    // Materials
    if (materialColors.length % COLOR_SIZE != 0) {
      throw Exception(
          'Invalid material color buffer, must be divisible by $COLOR_SIZE');
    }
  }
}

extension Uint8ListExtensions on Uint8List {
  // Converts a VIM attribute into a typed array from its raw data
  NativeArray castData(String dataType) {
    switch (dataType) {
      case 'float':
      case 'float32':
        return Float32Array.from(buffer.asFloat32List(
          offsetInBytes,
          lengthInBytes ~/ 4,
        ));
      case 'double':
      case 'numeric': // legacy (vim0.9)
      case 'float64':
        return Float64Array.from(buffer.asFloat64List(
          offsetInBytes,
          lengthInBytes ~/ 8,
        ));
      case 'byte':
        return Int8Array.from(buffer.asInt8List());
      //return this;
      case 'int8':
        return Uint8Array.from(this);
      case 'int16':
        return Int16Array.from(buffer.asInt16List(
          offsetInBytes,
          lengthInBytes ~/ 2,
        ));
      case 'string': // i.e. indices into the string table
      case 'index':
      case 'int':
      case 'properties': // legacy (vim0.9)
      case 'int32':
        return Int32Array.from(buffer.asInt32List(
          offsetInBytes,
          lengthInBytes ~/ 4,
        ));
      // case "int64": return new Int64Array(data.buffer, data.byteOffset, data.byteLength / 8);
      default:
        throw Exception('Unrecognized data type $dataType');
    }
  }
}
