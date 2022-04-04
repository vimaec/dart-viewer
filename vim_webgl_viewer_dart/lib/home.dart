import 'package:flutter/material.dart';
import 'vim-loader/settings.dart';
import 'vim-loader/transparency.dart';
import 'vim-loader/loader.dart';
import 'vim-webgl-viewer/settings.dart';
import 'vim-loader/vim.dart';
import 'vim_widget.dart';

// import 'webgl_loader_gltf_3.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Loader _loader = Loader();

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: FutureBuilder(
        future: _loader.fromUrl(
          //'https://vim.azureedge.net/samples/residence.vim',
          'https://raw.githubusercontent.com/dmk-rib/open-vim-sdk/dev/sample/Duplex_A.vim',
          //'https://raw.githubusercontent.com/dmk-rib/open-vim-sdk/dev/sample/DemoModel_High.vim',
          //'https://vim.azureedge.net/samples/stadium.vim',
          //'https://vim.azureedge.net/samples/skanska.vim',
          settings: const VimSettings(
            Vector3(x: 0, y: 0, z: 0),
            Vector3(x: 270, y: 0, z: 0),
            1,
            Mode.all,
          ),
        ),
        //"D:\\Duplex_A.vim"),
        //"D:\\model.vim"
        builder: (BuildContext context, AsyncSnapshot<Vim> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return VimWidget(
              viewerSettings: const ViewerSettings(
                camera: Camera(showGizmo: false),
                groundPlane: GroundPlane(
                  show: true,
                  opacity: 1,
                  size: 5,
                  texture:
                      'https://vimdevelopment01storage.blob.core.windows.net/textures/vim-floor-soft.png',
                ),
              ),
              vim: snapshot.data!,
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      //floatingActionButton: FloatingActionButton(onPressed: () {}),
    );
  }
}
