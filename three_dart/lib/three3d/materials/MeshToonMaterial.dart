part of three_materials;

class MeshToonMaterial extends Material {
  MeshToonMaterial([Map<String, dynamic>? parameters]) : super() {
    defines = {'TOON': ''};

    type = 'MeshToonMaterial';

    color = Color.fromHex(0xffffff);

    map = null;
    gradientMap = null;

    lightMap = null;
    lightMapIntensity = 1.0;

    aoMap = null;
    aoMapIntensity = 1.0;

    emissive = Color.fromHex(0x000000);
    emissiveIntensity = 1.0;
    emissiveMap = null;

    bumpMap = null;
    bumpScale = 1;

    normalMap = null;
    normalMapType = TangentSpaceNormalMap;
    normalScale = Vector2(1, 1);

    displacementMap = null;
    displacementScale = 1;
    displacementBias = 0;

    alphaMap = null;

    wireframe = false;
    wireframeLinewidth = 1;
    wireframeLinecap = 'round';
    wireframeLinejoin = 'round';

    setValues(parameters);
  }

  @override
  MeshToonMaterial copy(Material source) {
    super.copy(source);

    color.copy(source.color);

    map = source.map;
    gradientMap = source.gradientMap;

    lightMap = source.lightMap;
    lightMapIntensity = source.lightMapIntensity;

    aoMap = source.aoMap;
    aoMapIntensity = source.aoMapIntensity;

    emissive?.copy(source.emissive!);
    emissiveMap = source.emissiveMap;
    emissiveIntensity = source.emissiveIntensity;

    bumpMap = source.bumpMap;
    bumpScale = source.bumpScale;

    normalMap = source.normalMap;
    normalMapType = source.normalMapType;
    normalScale?.copy(source.normalScale!);

    displacementMap = source.displacementMap;
    displacementScale = source.displacementScale;
    displacementBias = source.displacementBias;

    alphaMap = source.alphaMap;

    wireframe = source.wireframe;
    wireframeLinewidth = source.wireframeLinewidth;
    wireframeLinecap = source.wireframeLinecap;
    wireframeLinejoin = source.wireframeLinejoin;

    return this;
  }
}
