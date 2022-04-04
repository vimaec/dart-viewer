part of three_materials;

class ShadowMaterial extends Material {
  ShadowMaterial([parameters]) : super() {
    type = 'ShadowMaterial';
    color = Color.fromHex(0x000000);
    transparent = true;

    setValues(parameters);
  }

  @override
  ShadowMaterial copy(Material source) {
    super.copy(source);

    color.copy(source.color);

    return this;
  }

  @override
  ShadowMaterial clone() {
    return ShadowMaterial().copy(this);
  }
}
