library materials;

import 'package:three_dart/three3d/renderers/webgl/index.dart';
import 'package:three_dart/three_dart.dart' as THREE;

class Library {
  final THREE.Material opaque;
  final THREE.Material transparent;
  final THREE.Material wireframe;

  static Library? _materials;
  static Map<String, dynamic> shader = _Material.cutomPhong();

  Library({
    required THREE.Material? opaque,
    required THREE.Material? transparent,
    required THREE.Material? wireframe,
  })  : opaque = opaque ?? opaqueMaterial,
        transparent = transparent ?? transparentMaterial,
        wireframe = wireframe ?? wreframeMaterial;

  factory Library.defaultLibrary() =>
      _materials ??
      (_materials = Library(opaque: null, transparent: null, wireframe: null));

  void dispose() {
    opaque.dispose();
    transparent.dispose();
    wireframe.dispose();
    _materials = null;
  }

  // Creates a new instance of the default opaque material used by the vim-loader
  static THREE.Material opaqueMaterial = THREE.MeshPhongMaterial({
    'color': THREE.Color.fromHex(0x999999),
    'vertexColors': true,
    'flatShading': true,
    'side': THREE.DoubleSide,
    'shininess': 70,
    // 'fragmentShader': shader['fragmentShader'],
    // 'vertexShader': shader['vertexShader'],
  })
    ..patch(shader);

  // Creates a new instance of the default loader transparent material
  static THREE.MeshPhongMaterial transparentMaterial = THREE.MeshPhongMaterial({
    'color': THREE.Color.fromHex(0x999999),
    'vertexColors': true,
    'flatShading': true,
    'side': THREE.DoubleSide,
    'shininess': 70,
    'transparent': true,
    // 'fragmentShader': shader['fragmentShader'],
    // 'vertexShader': shader['vertexShader'],
  })
    ..patch(shader);

  // Creates a new instance of the default wireframe material
  static THREE.LineBasicMaterial get wreframeMaterial =>
      THREE.LineBasicMaterial({
        'depthTest': false,
        'opacity': 0.5,
        'color': THREE.Color.fromHex(0x0000ff),
        'transparent': true
      });
}

extension _Material on THREE.Material {
  void patch(Map<String, dynamic> shader) {
    onBeforeCompile = (WebGLParameters params, renderer) {
      params.fragmentShader = shader['fragmentShader'];
      params.vertexShader = shader['vertexShader'];
      userData['shader'] = params;
    };
  }

  static Map<String, dynamic> cutomPhong() {
    final Map<String, dynamic> phong = THREE.ShaderLib['phong'];
    return {
      "uniforms": phong["uniforms"],
      "vertexShader": _phongVertexShader(phong['vertexShader']),
      "fragmentShader": _phongFragmentShader(phong['fragmentShader'])
    };
  }

  // Adds feature to default three material to support color change.
  // Developed and tested for Phong material, but might work for other materials.
  static String _phongFragmentShader(String fragmentShader) {
    // final Map<String, dynamic> phong = THREE.ShaderLib['phong'];
    // final String fragmentShader = phong['fragmentShader'];
    final shader = fragmentShader
        .replaceAll('#include <clipping_planes_pars_fragment>', '''
#include <clipping_planes_pars_fragment>
varying float vIgnore;
varying float vIgnorePhong;
''').replaceAll(
      '#include <output_fragment>',
      '''
// VISIBILITY
if (vIgnore > 0.0f)
  discard;

// COLORING
// vIgnorePhong == 1 -> Vertex Color * light 
// vIgnorePhong == 0 -> Phong Color 
float d = length(outgoingLight);
gl_FragColor = vec4(vIgnorePhong * vColor.xyz * d + (1.0f - vIgnorePhong) * outgoingLight.xyz, diffuseColor.a);
''',
    );
    return shader;
  }

  // Patches phong shader to be able to control when lighting should be applied to resulting color.
  // Instanced meshes ignore light when InstanceColor is defined
  // Instanced meshes ignore vertex color when instance attribute useVertexColor is 0
  // Regular meshes ignore light in favor of vertex color when uv.y = 0
  static String _phongVertexShader(String vertexShader) {
    // final Map<String, dynamic> phong = THREE.ShaderLib['phong'];
    // final String vertexShader = phong['vertexShader'];
    final shader = vertexShader.replaceAll('#include <color_pars_vertex>', '''
#include <color_pars_vertex>
        
// COLORING
// Vertex attribute for color override
#ifdef USE_INSTANCING
  attribute float ignoreVertexColor;
#endif
// There seems to be an issue where setting mehs.instanceColor
// doesn't properly set USE_INSTANCING_COLOR
// so we always use it as a fix
#ifndef USE_INSTANCING_COLOR
attribute vec3 instanceColor;
#endif
// Passed to fragment to ignore phong model
varying float vIgnorePhong;

// VISIBILITY

// Passed to fragment to discard them
varying float vIgnore;
// Instance or vertex attribute to hide objects 
#ifdef USE_INSTANCING
  attribute float ignoreInstance;
#else
  attribute float ignoreVertex;
#endif
''').replaceAll('#include <color_vertex>', '''
vColor = color;
vIgnorePhong = 0.0f;
// COLORING
// ignoreVertexColor == 1 -> instance color
// ignoreVertexColor == 0 -> vertex color
#ifdef USE_INSTANCING
  vIgnorePhong = ignoreVertexColor;
  vColor.xyz = ignoreVertexColor * instanceColor.xyz + (1.0f - ignoreVertexColor) * color.xyz;
#endif
// VISIBILITY
// Set frag ignore from instance or vertex attribute
#ifdef USE_INSTANCING
  vIgnore = ignoreInstance;
#else
  vIgnore = ignoreVertex;
#endif
''');
    return shader;
  }
}
