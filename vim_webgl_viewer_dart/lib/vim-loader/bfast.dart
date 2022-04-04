/*
 * BFAST is a data format for simple, efficient, and reliable serialization
 * and deserialization of collections of binary data with optional names as a single block of data.
 * See https://github.com/vimaec/bfast
 * @module vim-loader
 */
import 'dart:typed_data';
import 'dart:convert';

class BFastHeader {
  final int magic;
  final int dataStart;
  final int dataEnd;
  final int numArrays;

  const BFastHeader({
    required this.magic,
    required this.dataStart,
    required this.dataEnd,
    required this.numArrays,
    required int byteLength,
  })  : assert(magic == 0xbfa5, 'Not a BFAST file, or endianness is swapped'),
        assert(dataStart > 32 && dataStart <= byteLength,
            'Data start is out of valid range'),
        assert(dataEnd >= dataStart && dataEnd <= byteLength,
            'Data end is out of vaid range'),
        assert(numArrays >= 0 && numArrays <= dataEnd,
            'Number of arrays is invalid');

  factory BFastHeader.fromArray(Int32List array, int byteLength) {
    if (array[1] != 0) {
      throw Exception('Expected 0 in byte position 0');
    }
    if (array[3] != 0) {
      throw Exception('Expected 0 in byte position 8');
    }
    if (array[5] != 0) {
      throw Exception('Expected 0 in position 16');
    }
    if (array[7] != 0) {
      throw Exception('Expected 0 in position 24');
    }
    return BFastHeader(
        magic: array[0],
        dataStart: array[2],
        dataEnd: array[4],
        numArrays: array[6],
        byteLength: byteLength);
  }
}

/*
 * BFAST is a data format for simple, efficient, and reliable serialization
 * and deserialization of collections of binary data with optional names as a single block of data.
 * See https://github.com/vimaec/bfast
 */
class BFast {
  final BFastHeader header;
  final List<String> names;
  final List<Uint8List> buffers;

  const BFast({
    required this.header,
    required this.names,
    required this.buffers,
  });

  factory BFast.fromArray(Uint8List bytes) => BFast.fromArrayBuffer(
        bytes.buffer,
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );

  // Returns a newly constructed bfast instance from parsing the data of arrayBuffer
  // @param arrayBuffer an array of bytes from which to construct the bfast
  // @param byteOffset where to start parsing the array
  // @param byteLength how many bytes to parse from the array
  // @returns a bfast instance
  factory BFast.fromArrayBuffer(
    ByteBuffer arrayBuffer, [
    int offset = 0,
    int length = -1,
  ]) {
    length = length < 0 ? arrayBuffer.lengthInBytes - offset : length;
    // Cast the input data to 32-bit integers
    // Note that according to the spec they are 64 bit numbers. In JavaScript you can't have 64 bit integers,
    // and it would bust the amount of memory we can work with in most browsers and low-power devices
    final data = arrayBuffer.asInt32List(offset, length ~/ 4);
    // Parse the header
    final header = BFastHeader.fromArray(data, length);
    // Compute each buffer
    final List<Uint8List> buffers = <Uint8List>[];
    int pos = 8;
    for (int i = 0; i < header.numArrays; ++i) {
      final begin = data[pos + 0];
      final end = data[pos + 2];
      // Check validity of data
      if (data[pos + 1] != 0) {
        throw Exception('Expected 0 in position ${(pos + 1) * 4}');
      }
      if (data[pos + 3] != 0) {
        throw Exception('Expected 0 in position ${(pos + 3) * 4}');
      }
      if (begin < header.dataStart || begin > header.dataEnd) {
        throw Exception('Buffer start is out of range');
      }
      if (end < begin || end > header.dataEnd) {
        throw Exception('Buffer end is out of range');
      }
      pos += 4;
      final buffer = arrayBuffer.asUint8List(begin + offset, end - begin);
      buffers.add(buffer);
    }
    if (buffers.isEmpty) {
      throw Exception('Expected at least one buffer containing the names');
    }
    // break the first one up into names
    const utf8 = Utf8Codec();
    final joinedNames = utf8.decode(buffers[0], allowMalformed: true);
    final zeroChar = String.fromCharCode(0);
    // Removing the trailing '\0' before spliting the names
    var names = joinedNames.split(zeroChar).where((e) => e.isNotEmpty).toList();
    // Validate the number of names
    if (names.length != buffers.length - 1) {
      throw Exception(
          'Expected number of names to be equal to the number of buffers - 1');
    }
    return BFast(
      header: header,
      names: names,
      buffers: buffers.sublist(1),
    );
  }
}
