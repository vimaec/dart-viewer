import 'dart:io';
import 'dart:typed_data';
import '../vim-loader/settings.dart';
import './vim.dart';
import './document.dart';
import './scene.dart';
import 'package:http/http.dart' as http;

class Loader {
  Future<Vim> fromUrl(
    String uri, {
    VimSettings settings = const VimSettings(),
    List<int>? instances,
  }) async {
    final bytes = await http.readBytes(Uri.parse(uri));
    final vim = Document.fromArray(bytes);
    final scene = fromDocument(vim, settings: settings, instances: instances);
    return scene;
  }

  Future<Vim> fromFileAsync(
    String path, {
    VimSettings settings = const VimSettings(),
    List<int>? instances,
  }) async {
    final file = File(path);
    final data = await file.readAsBytes();
    final vim = Document.fromArrayBuffer(data.buffer);
    final scene = fromDocument(vim, settings: settings, instances: instances);
    return scene;
  }

  Vim fromArrayBuffer(
    ByteBuffer data, {
    VimSettings settings = const VimSettings(),
    List<int>? instances,
  }) {
    final vim = Document.fromArrayBuffer(data);
    return fromDocument(vim, settings: settings, instances: instances);
  }

  Vim fromDocument(
    Document doc, {
    VimSettings settings = const VimSettings(),
    List<int>? instances,
  }) {
    final scene = Scene.fromG3d(doc.g3d, settings.transparency, instances);
    return Vim(doc, scene, settings);
  }
}
