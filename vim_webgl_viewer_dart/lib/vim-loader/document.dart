/*
 * Document is the parsed content of a vim, including geometry data, bim data and other meta data.
 * @module vim-loader
 */

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_gl/flutter_gl.dart';

import './bfast.dart';
import './g3d.dart';

typedef EntityTable = Map<String, NativeArray>;

class Document {
  static const TABLE_ELEMENT = 'Vim.Element';
  static const TABLE_ELEMENT_LEGACY = 'Rvt.Element';
  static const TABLE_NODE = 'Vim.Node';

  final String header;
  final BFast assets;
  final G3d g3d;
  final Map<String, EntityTable> entities;
  final List<String> strings;

  List<int>? _instanceToElement;

  Document({
    required this.header,
    required this.assets,
    required this.g3d,
    required this.entities,
    required this.strings,
  });

  // Returns BIM data for given element
  // @param element element index
  EntityTable getElement(int element) => getEntity(TABLE_ELEMENT, element);
  EntityTable getEntity(String type, int index) {
    final EntityTable result = {};
    if (index < 0) {
      return result;
    }
    final table = entities[type];
    if (table == null) {
      return result;
    }
    for (var key in table.keys) {
      final parts = key.split(':');
      final values = table[key] as List?;
      if (values != null) {
        final inx = values[index];
        final value = parts.first == 'string' ? strings[inx] : inx;
        final name = parts[parts.length - 1];
        result[name] = value;
      }
    }
    return result;
  }

  // Returns the element index associated with the g3d instance index.
  // @param instance g3d instance index
  // @returns element index or -1 if not found
  int? getElementFromInstance(int instance) => _instanceToElementMap[instance];
  int get instanceCount => _instanceToElementMap.length;

  List<String>? getStringColumn(
    EntityTable table,
    String colNameNoPrefix,
  ) =>
      table['string:$colNameNoPrefix'] as List<String>?;

  NativeArray? getIndexColumn(
    EntityTable table,
    String tableName,
    String fieldName,
  ) =>
      table['index:$tableName:$fieldName'];

  // Backwards compatible call with vim0.9
  NativeArray? getDataColumn(
    EntityTable table,
    String typePrefix,
    String colNameNoPrefix,
  ) =>
      table['$typePrefix$colNameNoPrefix'] ?? table['numeric:$colNameNoPrefix'];

  NativeArray? getIntColumn(
    EntityTable table,
    String colNameNoPrefix,
  ) =>
      getDataColumn(table, 'int:', colNameNoPrefix);

  NativeArray? getByteColumn(
    EntityTable table,
    String colNameNoPrefix,
  ) =>
      getDataColumn(table, 'byte:', colNameNoPrefix);

  Float32Array? getFloatColumn(
    EntityTable table,
    String colNameNoPrefix,
  ) =>
      getDataColumn(table, 'float:', colNameNoPrefix) as Float32Array?;

  Float64Array? getDoubleColumn(
    EntityTable table,
    String colNameNoPrefix,
  ) =>
      getDataColumn(table, 'double:', colNameNoPrefix) as Float64Array?;

  List<int> get _instanceToElementMap {
    if (_instanceToElement != null) return _instanceToElement!;
    final table = instanceTable;
    if (table != null) {
      final index = getIndexColumn(table, TABLE_ELEMENT, 'Element');
      _instanceToElement = (index ?? table[TABLE_ELEMENT_LEGACY])
          ?.toDartList()
          .cast<int>()
          .toList();
    }
    if (_instanceToElement == null) {
      throw Exception('Could not find element table.');
    }
    return _instanceToElement!;
  }

  EntityTable? get elementTable {
    return entities[TABLE_ELEMENT] ?? entities[TABLE_ELEMENT_LEGACY];
  }

  EntityTable? get instanceTable => entities[TABLE_NODE];

  factory Document.fromArray(Uint8List data) {
    final bfast = BFast.fromArray(data);
    return Document.fromBFast(bfast);
  }
  // Creates a new Document instance from an array buffer of a vim file
  // @param data array representation of a vim
  // @returns a Document instance
  factory Document.fromArrayBuffer(ByteBuffer data) {
    final bfast = BFast.fromArrayBuffer(data);
    return Document.fromBFast(bfast);
  }
  // Creates a new Document instance from a bfast following the vim format
  // @param data Bfast reprentation of a vim
  // @returns a Document instance
  factory Document.fromBFast(BFast bfast) {
    Uint8List _get(Map<String, Uint8List> lookup, String label) {
      final data = lookup[label];
      if (data == null) {
        throw Exception('Missing Attribute Buffer: $label');
      }
      return data;
    }

    if (bfast.buffers.length < 5) {
      throw Exception('VIM requires at least five BFast buffers');
    }
    final lookup = <String, Uint8List>{};
    for (int i = 0; i < bfast.buffers.length; ++i) {
      lookup[bfast.names[i]] = bfast.buffers[i];
    }

    final assetData = _get(lookup, 'assets');
    final g3dData = _get(lookup, 'geometry');
    final headerData = _get(lookup, 'header');
    final entityData = _get(lookup, 'entities');
    final stringData = _get(lookup, 'strings');

    const utf8 = Utf8Codec();
    final header = utf8.decode(headerData, allowMalformed: true);

    final g3d = G3d.fromBfast(BFast.fromArray(g3dData));
    final assets = BFast.fromArray(assetData);
    final entities = _parseEntityTables(BFast.fromArray(entityData));

    final zeroChar = String.fromCharCode(0);
    final strings = utf8
        .decode(stringData)
        .split(zeroChar)
        .where((e) => e.isNotEmpty)
        .toList();

    g3d.validate();

    return Document(
        header: header,
        assets: assets,
        g3d: g3d,
        entities: entities,
        strings: strings);
  }
  static Map<String, EntityTable> _parseEntityTables(BFast bfast) {
    final result = <String, EntityTable>{};
    for (int i = 0; i < bfast.buffers.length; ++i) {
      final current = bfast.names[i];
      final tableName = current.substring(current.indexOf(':') + 1);
      final buffer = bfast.buffers[i];
      final next = _parseEntityTable(BFast.fromArray(buffer));
      result[tableName] = next;
    }
    return result;
  }

  static EntityTable _parseEntityTable(BFast bfast) {
    final EntityTable result = {};
    for (int i = 0; i < bfast.buffers.length; ++i) {
      final columnName = bfast.names[i];
      final columns = columnName.split(':');
      final bytes = bfast.buffers[i];
      final columnType = columns.first;
      result[columnName] = bytes.castData(columnType);
    }
    return result;
  }
}
