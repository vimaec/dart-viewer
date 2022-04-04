/*
 * Provides methods to create BufferGeometry from g3d geometry data.
 * @module vim-loader
 */
library transparency;

/*
 * Determines how to draw (or not) transparent and opaque objects
 */
enum Mode { all, opaqueOnly, transparentOnly, allAsOpaque }

extension ModeExtensions on Mode {
  //Returns true if the transparency mode requires to use RGBA colors
  bool useAlpha() => this == Mode.all || this == Mode.transparentOnly;

  //Returns true if the transparency mode requires using meshes of given opacity
  bool match(bool transparent) =>
      this == Mode.allAsOpaque ||
      this == Mode.all ||
      (!transparent && this == Mode.opaqueOnly) ||
      (transparent && this == Mode.transparentOnly);
}
