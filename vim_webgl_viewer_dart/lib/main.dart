import 'package:flutter/material.dart';

import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

// import * as VIM from './vim'
// import * as THREE from 'three'

// // Parse URL
// const params = new URLSearchParams(window.location.search)
// const url = params.has('vim')
//   ? params.get('vim')
//   : 'https://vim.azureedge.net/samples/residence.vim'

// let transparency: VIM.Transparency.Mode = 'all'
// if (params.has('transparency')) {
//   const t = params.get('transparency')
//   transparency = VIM.Transparency.isValid(t) ? t : 'all'
// }

// // Create Viewer
// const viewer = new VIM.Viewer({
//   camera: { showGizmo: true },
//   groundPlane: {
//     show: true,
//     texture:
//       'https://vimdevelopment01storage.blob.core.windows.net/textures/vim-floor-soft.png',
//     opacity: 1,
//     size: 5
//   }
// })

// /*
// viewer.loadVim(
//   'residence.vim',
//   {
//     // position: { x: 3, y: 0, z: 0 },
//     rotation: { x: 270, y: 0, z: 0 },
//     transparency: transparency
//   },
//   (result) => {
//     onLoaded()
//     // load2()
//   },
//   (progress) => {
//     if (progress === 'processing') console.log('Processing')
//     else console.log(`Downloading: ${(progress.loaded as number) / 1000000} MB`)
//   },
//   (error) => console.error(`Failed to load vim: ${error}`)
// ) */
// load2()

// function load2 () {
//   for (let i = 0; i < 2; i++) {
//     for (let j = 0; j < 2; j++) {
//       viewer.loadVim(
//         'residence.vim',
//         {
//           // position: { x: 1, y: 10.6, z: 0 },
//           position: { x: i, y: 0, z: j },
//           rotation: { x: 270, y: 0, z: 0 },
//           transparency: transparency
//         },
//         (result) => { console.log(result) },
//         (progress) => {
//           if (progress === 'processing') console.log('Processing')
//           else {
//             console.log(
//               `Downloading: ${(progress.loaded as number) / 1000000} MB`
//             )
//           }
//         },
//         (error) => console.error(`Failed to load vim: ${error}`)
//       )
//     }
//   }
// }

// globalThis.viewer = viewer
// globalThis.VIM = VIM
// globalThis.THREE = THREE