import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three3d/math/index.dart';
import 'package:three_dart/three_dart.dart' as THREE;
import 'package:vim_webgl_viewer_dart/vim-loader/vim.dart';
import 'package:vim_webgl_viewer_dart/vim-webgl-viewer/viewer.dart';
import '../vim-loader/settings.dart';
import 'renderer.dart';
import 'settings.dart';

class PlatformPlugin {
  final FlutterGlPlugin _gl = FlutterGlPlugin();
  final ViewerSettings _viewerSettings;
  final VimSettings _vimSettings;

  Viewer? viewer;

  void _disposeViewer() {
    viewer?.dispose();
    viewer = null;
  }

  PlatformPlugin([
    this._viewerSettings = const ViewerSettings(),
    this._vimSettings = const VimSettings(),
  ]);

  Future<int> generateId(int width, int height, double dpr) async {
    final initData = await _gl.init(width, height, dpr);
    await _gl.hasContext();
    return initData['textureId'];
  }

  Viewer createViewer(int width, int height, double dpr) {
    _disposeViewer();
    final renderer = _gl.makeRenderer(width, height, dpr);
    final view = Viewer(_gl, renderer, _viewerSettings);
    viewer = view;
    return view;
  }

  bool createAndLoad(int width, int height, double dpr, Vim vim) {
    final viewer = createViewer(width, height, dpr);
    return viewer.loadVim(vim, _vimSettings);
  }

  void dispose() {
    _disposeViewer();
    _gl.dispose();
  }
}

extension Gl on FlutterGlPlugin {
  Future<Map<String, dynamic>> init(int width, int height, double dpr) async {
    final plug = await initialize(options: {
      'antialias': true,
      'alpha': false,
      'width': width,
      'height': height,
      'dpr': dpr
    });
    return plug;
  }

  Future<bool> hasContext() async {
    // await Future.delayed(
    //   const Duration(milliseconds: 100),
    //   _glPlugin.prepareContext,
    // );
    await prepareContext();
    return isInitialized;
  }

  Renderer makeRenderer(int width, int height, double dpr) {
    final webGl = THREE.WebGLRenderer({
      'width': width,
      'height': height,
      'gl': gl,
      'canvas': element,
      'antialias': true,
      'precision': 'highp', // 'lowp', 'mediump', 'highp'
      // 'alpha': true,
      'stencil': false,
      'powerPreference': 'high-performance',
      'logarithmicDepthBuffer': true
    });
    webGl.setClearColor(Color.fromHex(0xF5F5F5));
    webGl.setPixelRatio(dpr);
    // webGl.setSize(width, height, false);
    webGl.shadowMap.enabled = false;

    if (!kIsWeb) {
      final renderTarget = THREE.WebGLMultisampleRenderTarget(
        (width * dpr).toInt(),
        (height * dpr).toInt(),
        THREE.WebGLRenderTargetOptions({
          // 'minFilter': THREE.LinearFilter,
          // 'magFilter': THREE.LinearFilter,
          'format': THREE.RGBAFormat
        }),
      );
      webGl.setRenderTarget(renderTarget);
      final sourceTexture = webGl.getRenderTargetGLTexture(renderTarget);
      return Renderer(webGl, sourceTexture);
    } else {
      return Renderer(webGl);
    }
  }

  Future<void> render(Renderer renderer) async {
    // bool verbose = true;
    // int _t = DateTime.now().millisecondsSinceEpoch;
//OpenGLContextES
    final _gl = gl;

    // print(_gl.getString(_gl.VENDOR));
    // print(_gl.getString(_gl.RENDERER));
    //_gl.flush();
    // _gl.clear(gl.COLOR_BUFFER_BIT);
    renderer.render();

    // int _t1 = DateTime.now().millisecondsSinceEpoch;

    // if (verbose) {
    //   print("render cost: ${_t1 - _t} ");
    //   print(renderer.renderer.info.memory);
    //   print(renderer.renderer.info.render);
    // }

    // 重要 更新纹理之前一定要调用 确保gl程序执行完毕
    _gl.flush();
    //_gl.clear(gl.COLOR_BUFFER_BIT);
    //if (verbose) print(" render: sourceTexture: ${renderer.sourceTexture} ");

    // _gl.flush();
    if (!kIsWeb && renderer.sourceTexture != null) {
      //_gl.flush();
      await updateTexture(renderer.sourceTexture!);
    }
  }
}
