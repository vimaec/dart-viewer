part of three_materials;

class MeshBasicMaterial extends Material {
  MeshBasicMaterial([Map<String, dynamic>? parameters]) : super() {
    type = 'MeshBasicMaterial';
    color = Color(1, 1, 1); // emissive

    map = null;

    lightMap = null;
    lightMapIntensity = 1.0;

    aoMap = null;
    aoMapIntensity = 1.0;

    specularMap = null;

    alphaMap = null;

    // this.envMap = null;
    combine = MultiplyOperation;
    reflectivity = 1;
    refractionRatio = 0.98;

    wireframe = false;
    wireframeLinewidth = 1;
    wireframeLinecap = 'round';
    wireframeLinejoin = 'round';

    setValues(parameters);
  }

  @override
  MeshBasicMaterial copy(Material source) {
    super.copy(source);

    color.copy(source.color);

    map = source.map;

    lightMap = source.lightMap;
    lightMapIntensity = source.lightMapIntensity;

    aoMap = source.aoMap;
    aoMapIntensity = source.aoMapIntensity;

    specularMap = source.specularMap;

    alphaMap = source.alphaMap;

    envMap = source.envMap;
    combine = source.combine;
    reflectivity = source.reflectivity;
    refractionRatio = source.refractionRatio;

    wireframe = source.wireframe;
    wireframeLinewidth = source.wireframeLinewidth;
    wireframeLinecap = source.wireframeLinecap;
    wireframeLinejoin = source.wireframeLinejoin;

    return this;
  }

  @override
  MeshBasicMaterial clone() {
    return MeshBasicMaterial().copy(this);
  }
}
