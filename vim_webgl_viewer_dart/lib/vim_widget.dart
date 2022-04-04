import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'vim-loader/vim.dart';
import 'vim-webgl-viewer/settings.dart' as viewer;
import 'vim-loader/settings.dart' as vimsettings;
import 'vim-webgl-viewer/gl.dart';

class VimWidget extends StatefulWidget {
  final Vim vim;
  final viewer.ViewerSettings viewerSettings;
  final vimsettings.VimSettings vimSettings;

  const VimWidget({
    Key? key,
    required this.vim,
    this.viewerSettings = const viewer.ViewerSettings(),
    this.vimSettings = const vimsettings.VimSettings(),
  }) : super(key: key);

  @override
  _VimWidgetState createState() => _VimWidgetState();
}

class _VimWidgetState extends State<VimWidget> {
  late final PlatformPlugin _plugin;

  // private fitToCanvas = () => {
  //   const [width, height] = this.getContainerSize()

  //   this.renderer.setSize(width, height)
  //   this.camera.aspect = width / height
  //   this.camera.updateProjectionMatrix()
  // }

  @override
  Widget build(BuildContext context) {
    final mdq = MediaQuery.of(context);
    final width = mdq.size.width;
    final height = mdq.size.height;
    final dpr = mdq.devicePixelRatio;

    return FutureBuilder(
      future: _plugin.generateId(width, height, dpr),
      builder: (BuildContext cxt, AsyncSnapshot<int> snap) {
        if (snap.hasData) {
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerSignal: (PointerSignalEvent event) =>
                _plugin.viewer?.onPointerSignal(event, mdq.size),
            onPointerMove: (PointerMoveEvent event) =>
                _plugin.viewer?.onPointerMove(event, mdq.size),
            onPointerDown: (PointerDownEvent event) =>
                _plugin.viewer?.onPointerDown(event, mdq.size),
            onPointerUp: (PointerUpEvent event) =>
                _plugin.viewer?.onPointerUp(event, mdq.size),
            onPointerCancel: (PointerCancelEvent event) =>
                _plugin.viewer?.onPointerCancel(event, mdq.size),
            child: RawKeyboardListener(
              autofocus: true,
              focusNode: FocusNode(
                onKey: (FocusNode node, RawKeyEvent event) {
                  return _plugin.viewer != null
                      ? _plugin.viewer!.onFocusKey(node, event)
                      : KeyEventResult.ignored;
                },
              ),
              child: kIsWeb
                  ? HtmlElementView(
                      viewType: snap.data!.toString(),
                      onPlatformViewCreated: (id) {
                        _plugin.createAndLoad(width, height, dpr, widget.vim);
                      })
                  : Builder(builder: (BuildContext context) {
                      _plugin.createAndLoad(width, height, dpr, widget.vim);
                      return Texture(textureId: snap.data!);
                    }),
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  @override
  void initState() {
    _plugin = PlatformPlugin(widget.viewerSettings, widget.vimSettings);
    super.initState();
  }

  @override
  void dispose() {
    _plugin.dispose();
    super.dispose();
  }
}
