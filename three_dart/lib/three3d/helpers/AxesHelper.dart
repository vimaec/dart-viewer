part of three_helpers;

class AxesHelper extends LineSegments {
  @override
  String type = "AxesHelper";

  AxesHelper.create({num size = 1, geometry, material})
      : super(geometry, material);

  factory AxesHelper([num size = 1]) {
    List<double> vertices = [
      0,
      0,
      0,
      size.toDouble(),
      0,
      0,
      0,
      0,
      0,
      0,
      size.toDouble(),
      0,
      0,
      0,
      0,
      0,
      0,
      size.toDouble()
    ];

    List<double> colors = [
      1,
      0,
      0,
      1,
      0.6,
      0,
      0,
      1,
      0,
      0.6,
      1,
      0,
      0,
      0,
      1,
      0,
      0.6,
      1
    ];

    var geometry = BufferGeometry();
    geometry.setAttribute(
        'position',
        Float32BufferAttribute(Float32Array.from(vertices), 3, false));
    geometry.setAttribute(
        'color',
        Float32BufferAttribute(Float32Array.from(colors), 3, false));

    var material =
        LineBasicMaterial({"vertexColors": true, "toneMapped": false});

    return AxesHelper.create(
        size: size, geometry: geometry, material: material);
  }

  setColors(Color xAxisColor, Color yAxisColor, Color zAxisColor) {
    var color = Color(1, 1, 1);
    var array = geometry!.attributes["color"].array;

    color.copy(xAxisColor);
    color.toArray(array, 0);
    color.toArray(array, 3);

    color.copy(yAxisColor);
    color.toArray(array, 6);
    color.toArray(array, 9);

    color.copy(zAxisColor);
    color.toArray(array, 12);
    color.toArray(array, 15);

    geometry!.attributes["color"].needsUpdate = true;

    return this;
  }

  @override
  void dispose() {
    geometry!.dispose();
    material.dispose();
  }
}
