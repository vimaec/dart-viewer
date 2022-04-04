part of three_math;

var _matrix4v1 = Vector3.init();
var _matrix4m1 = Matrix4();
var _matrix4zero = Vector3(0, 0, 0);
var _matrix4one = Vector3(1, 1, 1);
var _matrix4x = Vector3.init();
var _matrix4y = Vector3.init();
var _matrix4z = Vector3.init();

class Matrix4 {
  String type = "Matrix4";
  late Float32Array elements;

  Matrix4() {
    elements = Float32Array.from([
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0
    ]);
  }

  Matrix4 set(
      num n11,
      num n12,
      num n13,
      num n14,
      num n21,
      num n22,
      num n23,
      num n24,
      num n31,
      num n32,
      num n33,
      num n34,
      num n41,
      num n42,
      num n43,
      num n44) {
    var te = elements;

    te[0] = n11.toDouble();
    te[4] = n12.toDouble();
    te[8] = n13.toDouble();
    te[12] = n14.toDouble();
    te[1] = n21.toDouble();
    te[5] = n22.toDouble();
    te[9] = n23.toDouble();
    te[13] = n24.toDouble();
    te[2] = n31.toDouble();
    te[6] = n32.toDouble();
    te[10] = n33.toDouble();
    te[14] = n34.toDouble();
    te[3] = n41.toDouble();
    te[7] = n42.toDouble();
    te[11] = n43.toDouble();
    te[15] = n44.toDouble();

    return this;
  }

  Matrix4 identity() {
    set(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 1.0);

    return this;
  }

  Matrix4 clone() {
    return Matrix4().fromArray(elements);
  }

  Matrix4 copy(Matrix4 m) {
    var te = elements;
    var me = m.elements;

    te[0] = me[0];
    te[1] = me[1];
    te[2] = me[2];
    te[3] = me[3];
    te[4] = me[4];
    te[5] = me[5];
    te[6] = me[6];
    te[7] = me[7];
    te[8] = me[8];
    te[9] = me[9];
    te[10] = me[10];
    te[11] = me[11];
    te[12] = me[12];
    te[13] = me[13];
    te[14] = me[14];
    te[15] = me[15];

    return this;
  }

  Matrix4 copyPosition(Matrix4 m) {
    var te = elements, me = m.elements;

    te[12] = me[12];
    te[13] = me[13];
    te[14] = me[14];

    return this;
  }

  Matrix4 setFromMatrix3(Matrix3 m) {
    var me = m.elements;

    set(me[0], me[3], me[6], 0, me[1], me[4], me[7], 0, me[2], me[5], me[8], 0,
        0, 0, 0, 1);

    return this;
  }

  Matrix4 extractBasis(Vector3 xAxis, Vector3 yAxis, Vector3 zAxis) {
    xAxis.setFromMatrixColumn(this, 0);
    yAxis.setFromMatrixColumn(this, 1);
    zAxis.setFromMatrixColumn(this, 2);

    return this;
  }

  Matrix4 makeBasis(Vector3 xAxis, Vector3 yAxis, Vector3 zAxis) {
    set(xAxis.x, yAxis.x, zAxis.x, 0, xAxis.y, yAxis.y, zAxis.y, 0, xAxis.z,
        yAxis.z, zAxis.z, 0, 0, 0, 0, 1);

    return this;
  }

  Matrix4 extractRotation(Matrix4 m) {
    // this method does not support reflection matrices

    var te = elements;
    var me = m.elements;

    var scaleX = 1 / _matrix4v1.setFromMatrixColumn(m, 0).length();
    var scaleY = 1 / _matrix4v1.setFromMatrixColumn(m, 1).length();
    var scaleZ = 1 / _matrix4v1.setFromMatrixColumn(m, 2).length();

    te[0] = me[0] * scaleX;
    te[1] = me[1] * scaleX;
    te[2] = me[2] * scaleX;
    te[3] = 0;

    te[4] = me[4] * scaleY;
    te[5] = me[5] * scaleY;
    te[6] = me[6] * scaleY;
    te[7] = 0;

    te[8] = me[8] * scaleZ;
    te[9] = me[9] * scaleZ;
    te[10] = me[10] * scaleZ;
    te[11] = 0;

    te[12] = 0;
    te[13] = 0;
    te[14] = 0;
    te[15] = 1;

    return this;
  }

  Matrix4 makeRotationFromEuler(Euler euler) {
    var te = elements;

    var x = euler.x, y = euler.y, z = euler.z;
    var a = Math.cos(x).toDouble(), b = Math.sin(x).toDouble();
    var c = Math.cos(y).toDouble(), d = Math.sin(y).toDouble();
    var e = Math.cos(z).toDouble(), f = Math.sin(z).toDouble();

    if (euler.order == 'XYZ') {
      var ae = a * e, af = a * f, be = b * e, bf = b * f;

      te[0] = c * e;
      te[4] = -c * f;
      te[8] = d;

      te[1] = af + be * d;
      te[5] = ae - bf * d;
      te[9] = -b * c;

      te[2] = bf - ae * d;
      te[6] = be + af * d;
      te[10] = a * c;
    } else if (euler.order == 'YXZ') {
      var ce = c * e, cf = c * f, de = d * e, df = d * f;

      te[0] = ce + df * b;
      te[4] = de * b - cf;
      te[8] = a * d;

      te[1] = a * f;
      te[5] = a * e;
      te[9] = -b;

      te[2] = cf * b - de;
      te[6] = df + ce * b;
      te[10] = a * c;
    } else if (euler.order == 'ZXY') {
      var ce = c * e, cf = c * f, de = d * e, df = d * f;

      te[0] = ce - df * b;
      te[4] = -a * f;
      te[8] = de + cf * b;

      te[1] = cf + de * b;
      te[5] = a * e;
      te[9] = df - ce * b;

      te[2] = -a * d;
      te[6] = b;
      te[10] = a * c;
    } else if (euler.order == 'ZYX') {
      var ae = a * e, af = a * f, be = b * e, bf = b * f;

      te[0] = c * e;
      te[4] = be * d - af;
      te[8] = ae * d + bf;

      te[1] = c * f;
      te[5] = bf * d + ae;
      te[9] = af * d - be;

      te[2] = -d;
      te[6] = b * c;
      te[10] = a * c;
    } else if (euler.order == 'YZX') {
      var ac = a * c, ad = a * d, bc = b * c, bd = b * d;

      te[0] = c * e;
      te[4] = bd - ac * f;
      te[8] = bc * f + ad;

      te[1] = f;
      te[5] = a * e;
      te[9] = -b * e;

      te[2] = -d * e;
      te[6] = ad * f + bc;
      te[10] = ac - bd * f;
    } else if (euler.order == 'XZY') {
      var ac = a * c, ad = a * d, bc = b * c, bd = b * d;

      te[0] = c * e;
      te[4] = -f;
      te[8] = d * e;

      te[1] = ac * f + bd;
      te[5] = a * e;
      te[9] = ad * f - bc;

      te[2] = bc * f - ad;
      te[6] = b * e;
      te[10] = bd * f + ac;
    }

    // bottom row
    te[3] = 0;
    te[7] = 0;
    te[11] = 0;

    // last column
    te[12] = 0;
    te[13] = 0;
    te[14] = 0;
    te[15] = 1;

    return this;
  }

  Matrix4 makeRotationFromQuaternion(Quaternion q) {
    return compose(_matrix4zero, q, _matrix4one);
  }

  Matrix4 lookAt(Vector3 eye, Vector3 target, Vector3 up) {
    var te = elements;

    _matrix4z.subVectors(eye, target);

    if (_matrix4z.lengthSq() == 0) {
      // eye and target are in the same position

      _matrix4z.z = 1;
    }

    _matrix4z.normalize();
    _matrix4x.crossVectors(up, _matrix4z);

    if (_matrix4x.lengthSq() == 0) {
      // up and z are parallel

      if (Math.abs(up.z) == 1) {
        _matrix4z.x += 0.0001;
      } else {
        _matrix4z.z += 0.0001;
      }

      _matrix4z.normalize();
      _matrix4x.crossVectors(up, _matrix4z);
    }

    _matrix4x.normalize();
    _matrix4y.crossVectors(_matrix4z, _matrix4x);

    te[0] = _matrix4x.x.toDouble();
    te[4] = _matrix4y.x.toDouble();
    te[8] = _matrix4z.x.toDouble();
    te[1] = _matrix4x.y.toDouble();
    te[5] = _matrix4y.y.toDouble();
    te[9] = _matrix4z.y.toDouble();
    te[2] = _matrix4x.z.toDouble();
    te[6] = _matrix4y.z.toDouble();
    te[10] = _matrix4z.z.toDouble();

    return this;
  }

  Matrix4 multiply(Matrix4 m, {Matrix4? n}) {
    if (n != null) {
      print(
          'THREE.Matrix4: .multiply() now only accepts one argument. Use .multiplyMatrices( a, b ) instead.');
      return multiplyMatrices(m, n);
    }

    return multiplyMatrices(this, m);
  }

  Matrix4 premultiply(Matrix4 m) {
    return multiplyMatrices(m, this);
  }

  Matrix4 multiplyMatrices(Matrix4 a, Matrix4 b) {
    var ae = a.elements;
    var be = b.elements;
    var te = elements;

    var a11 = ae[0], a12 = ae[4], a13 = ae[8], a14 = ae[12];
    var a21 = ae[1], a22 = ae[5], a23 = ae[9], a24 = ae[13];
    var a31 = ae[2], a32 = ae[6], a33 = ae[10], a34 = ae[14];
    var a41 = ae[3], a42 = ae[7], a43 = ae[11], a44 = ae[15];

    var b11 = be[0], b12 = be[4], b13 = be[8], b14 = be[12];
    var b21 = be[1], b22 = be[5], b23 = be[9], b24 = be[13];
    var b31 = be[2], b32 = be[6], b33 = be[10], b34 = be[14];
    var b41 = be[3], b42 = be[7], b43 = be[11], b44 = be[15];

    te[0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
    te[4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
    te[8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
    te[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

    te[1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
    te[5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
    te[9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
    te[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

    te[2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
    te[6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
    te[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
    te[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

    te[3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
    te[7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
    te[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
    te[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;

    return this;
  }

  Matrix4 multiplyScalar(num s) {
    var te = elements;

    te[0] *= s;
    te[4] *= s;
    te[8] *= s;
    te[12] *= s;
    te[1] *= s;
    te[5] *= s;
    te[9] *= s;
    te[13] *= s;
    te[2] *= s;
    te[6] *= s;
    te[10] *= s;
    te[14] *= s;
    te[3] *= s;
    te[7] *= s;
    te[11] *= s;
    te[15] *= s;

    return this;
  }

  double determinant() {
    var te = elements;

    double n11 = te[0], n12 = te[4], n13 = te[8], n14 = te[12];
    double n21 = te[1], n22 = te[5], n23 = te[9], n24 = te[13];
    double n31 = te[2], n32 = te[6], n33 = te[10], n34 = te[14];
    double n41 = te[3], n42 = te[7], n43 = te[11], n44 = te[15];

    //TODO: make this more efficient
    //( based on http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm )

    double v1 = n41 *
        (n14 * n23 * n32 -
            n13 * n24 * n32 -
            n14 * n22 * n33 +
            n12 * n24 * n33 +
            n13 * n22 * n34 -
            n12 * n23 * n34);

    double v2 = n42 *
        (n11 * n23 * n34 -
            n11 * n24 * n33 +
            n14 * n21 * n33 -
            n13 * n21 * n34 +
            n13 * n24 * n31 -
            n14 * n23 * n31);

    double v3 = n43 *
        (n11 * n24 * n32 -
            n11 * n22 * n34 -
            n14 * n21 * n32 +
            n12 * n21 * n34 +
            n14 * n22 * n31 -
            n12 * n24 * n31);

    double v4 = n44 *
        (-n13 * n22 * n31 -
            n11 * n23 * n32 +
            n11 * n22 * n33 +
            n13 * n21 * n32 -
            n12 * n21 * n33 +
            n12 * n23 * n31);

    final result = (v1 + v2 + v3 + v4);

    // print(" v1: ${v1} v2: ${v2} v3: ${v3} v4: ${v4}  result: ${result} ");

    return result;
  }

  Matrix4 transpose() {
    var te = elements;
    var tmp = te[1];
    te[1] = te[4];
    te[4] = tmp;
    tmp = te[2];
    te[2] = te[8];
    te[8] = tmp;
    tmp = te[6];
    te[6] = te[9];
    te[9] = tmp;

    tmp = te[3];
    te[3] = te[12];
    te[12] = tmp;
    tmp = te[7];
    te[7] = te[13];
    te[13] = tmp;
    tmp = te[11];
    te[11] = te[14];
    te[14] = tmp;

    return this;
  }

  // x is Vector3 | num
  Matrix4 setPosition(x, [y, z]) {
    var te = elements;

    if (x is Vector3) {
      print("warn use setPositionFromVector3 ........... ");
      return setPositionFromVector3(x);
    } else {
      te[12] = x.toDouble();
      te[13] = y.toDouble();
      te[14] = z.toDouble();
    }

    return this;
  }

  Matrix4 setPositionFromVector3(Vector3 x) {
    var te = elements;

    te[12] = x.x.toDouble();
    te[13] = x.y.toDouble();
    te[14] = x.z.toDouble();

    return this;
  }

  Matrix4 invert() {
    // based on http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm
    var te = elements;
    final double n11 = te[0],
        n21 = te[1],
        n31 = te[2],
        n41 = te[3],
        n12 = te[4],
        n22 = te[5],
        n32 = te[6],
        n42 = te[7],
        n13 = te[8],
        n23 = te[9],
        n33 = te[10],
        n43 = te[11],
        n14 = te[12],
        n24 = te[13],
        n34 = te[14],
        n44 = te[15],
        t11 = n23 * n34 * n42 -
            n24 * n33 * n42 +
            n24 * n32 * n43 -
            n22 * n34 * n43 -
            n23 * n32 * n44 +
            n22 * n33 * n44,
        t12 = n14 * n33 * n42 -
            n13 * n34 * n42 -
            n14 * n32 * n43 +
            n12 * n34 * n43 +
            n13 * n32 * n44 -
            n12 * n33 * n44,
        t13 = n13 * n24 * n42 -
            n14 * n23 * n42 +
            n14 * n22 * n43 -
            n12 * n24 * n43 -
            n13 * n22 * n44 +
            n12 * n23 * n44,
        t14 = n14 * n23 * n32 -
            n13 * n24 * n32 -
            n14 * n22 * n33 +
            n12 * n24 * n33 +
            n13 * n22 * n34 -
            n12 * n23 * n34;

    final det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14;

    if (det == 0) return set(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    var detInv = 1 / det;

    te[0] = t11 * detInv;
    te[1] = (n24 * n33 * n41 -
            n23 * n34 * n41 -
            n24 * n31 * n43 +
            n21 * n34 * n43 +
            n23 * n31 * n44 -
            n21 * n33 * n44) *
        detInv;
    te[2] = (n22 * n34 * n41 -
            n24 * n32 * n41 +
            n24 * n31 * n42 -
            n21 * n34 * n42 -
            n22 * n31 * n44 +
            n21 * n32 * n44) *
        detInv;
    te[3] = (n23 * n32 * n41 -
            n22 * n33 * n41 -
            n23 * n31 * n42 +
            n21 * n33 * n42 +
            n22 * n31 * n43 -
            n21 * n32 * n43) *
        detInv;

    te[4] = t12 * detInv;
    te[5] = (n13 * n34 * n41 -
            n14 * n33 * n41 +
            n14 * n31 * n43 -
            n11 * n34 * n43 -
            n13 * n31 * n44 +
            n11 * n33 * n44) *
        detInv;
    te[6] = (n14 * n32 * n41 -
            n12 * n34 * n41 -
            n14 * n31 * n42 +
            n11 * n34 * n42 +
            n12 * n31 * n44 -
            n11 * n32 * n44) *
        detInv;
    te[7] = (n12 * n33 * n41 -
            n13 * n32 * n41 +
            n13 * n31 * n42 -
            n11 * n33 * n42 -
            n12 * n31 * n43 +
            n11 * n32 * n43) *
        detInv;

    te[8] = t13 * detInv;
    te[9] = (n14 * n23 * n41 -
            n13 * n24 * n41 -
            n14 * n21 * n43 +
            n11 * n24 * n43 +
            n13 * n21 * n44 -
            n11 * n23 * n44) *
        detInv;
    te[10] = (n12 * n24 * n41 -
            n14 * n22 * n41 +
            n14 * n21 * n42 -
            n11 * n24 * n42 -
            n12 * n21 * n44 +
            n11 * n22 * n44) *
        detInv;
    te[11] = (n13 * n22 * n41 -
            n12 * n23 * n41 -
            n13 * n21 * n42 +
            n11 * n23 * n42 +
            n12 * n21 * n43 -
            n11 * n22 * n43) *
        detInv;

    te[12] = t14 * detInv;
    te[13] = (n13 * n24 * n31 -
            n14 * n23 * n31 +
            n14 * n21 * n33 -
            n11 * n24 * n33 -
            n13 * n21 * n34 +
            n11 * n23 * n34) *
        detInv;
    te[14] = (n14 * n22 * n31 -
            n12 * n24 * n31 -
            n14 * n21 * n32 +
            n11 * n24 * n32 +
            n12 * n21 * n34 -
            n11 * n22 * n34) *
        detInv;
    te[15] = (n12 * n23 * n31 -
            n13 * n22 * n31 +
            n13 * n21 * n32 -
            n11 * n23 * n32 -
            n12 * n21 * n33 +
            n11 * n22 * n33) *
        detInv;

    return this;
  }

  Matrix4 scale(Vector3 v) {
    var te = elements;
    var x = v.x, y = v.y, z = v.z;

    te[0] *= x;
    te[4] *= y;
    te[8] *= z;
    te[1] *= x;
    te[5] *= y;
    te[9] *= z;
    te[2] *= x;
    te[6] *= y;
    te[10] *= z;
    te[3] *= x;
    te[7] *= y;
    te[11] *= z;

    return this;
  }

  double getMaxScaleOnAxis() {
    var te = elements;

    double scaleXSq = te[0] * te[0] + te[1] * te[1] + te[2] * te[2];
    double scaleYSq = te[4] * te[4] + te[5] * te[5] + te[6] * te[6];
    double scaleZSq = te[8] * te[8] + te[9] * te[9] + te[10] * te[10];

    return Math.sqrt(Math.max(Math.max(scaleXSq, scaleYSq), scaleZSq));
  }

  Matrix4 makeTranslation(num x, num y, num z) {
    set(1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, z, 0, 0, 0, 1);

    return this;
  }

  Matrix4 makeRotationX(num theta) {
    var c = Math.cos(theta).toDouble(), s = Math.sin(theta).toDouble();

    set(1, 0, 0, 0, 0, c, -s, 0, 0, s, c, 0, 0, 0, 0, 1);

    return this;
  }

  Matrix4 makeRotationY(num theta) {
    var c = Math.cos(theta).toDouble(), s = Math.sin(theta).toDouble();

    set(c, 0, s, 0, 0, 1, 0, 0, -s, 0, c, 0, 0, 0, 0, 1);

    return this;
  }

  Matrix4 makeRotationZ(num theta) {
    var c = Math.cos(theta).toDouble(), s = Math.sin(theta).toDouble();

    set(c, -s, 0, 0, s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);

    return this;
  }

  Matrix4 makeRotationAxis(Vector3 axis, num angle) {
    // Based on http://www.gamedev.net/reference/articles/article1199.asp

    var c = Math.cos(angle).toDouble();
    var s = Math.sin(angle).toDouble();
    var t = 1 - c;
    var x = axis.x, y = axis.y, z = axis.z;
    var tx = t * x, ty = t * y;

    set(
        tx * x + c,
        tx * y - s * z,
        tx * z + s * y,
        0,
        tx * y + s * z,
        ty * y + c,
        ty * z - s * x,
        0,
        tx * z - s * y,
        ty * z + s * x,
        t * z * z + c,
        0,
        0,
        0,
        0,
        1);

    return this;
  }

  Matrix4 makeScale(num x, num y, num z) {
    set(x, 0, 0, 0, 0, y, 0, 0, 0, 0, z, 0, 0, 0, 0, 1);

    return this;
  }

  Matrix4 makeShear(num xy, num xz, num yx, num yz, num zx, num zy) {
    set(1, yx, zx, 0, xy, 1, zy, 0, xz, yz, 1, 0, 0, 0, 0, 1);

    return this;
  }

  Matrix4 compose(Vector3 position, Quaternion quaternion, Vector3 scale) {
    var te = elements;

    var x = quaternion.x.toDouble();
    var y = quaternion.y.toDouble();
    var z = quaternion.z.toDouble();
    var w = quaternion.w.toDouble();
    var x2 = x + x, y2 = y + y, z2 = z + z;
    var xx = x * x2, xy = x * y2, xz = x * z2;
    var yy = y * y2, yz = y * z2, zz = z * z2;
    var wx = w * x2, wy = w * y2, wz = w * z2;

    var sx = scale.x, sy = scale.y, sz = scale.z;

    te[0] = (1 - (yy + zz)) * sx.toDouble();
    te[1] = (xy + wz) * sx;
    te[2] = (xz - wy) * sx;
    te[3] = 0;

    te[4] = (xy - wz) * sy;
    te[5] = (1.0 - (xx + zz)) * sy;
    te[6] = (yz + wx) * sy;
    te[7] = 0;

    te[8] = (xz + wy) * sz;
    te[9] = (yz - wx) * sz;
    te[10] = (1 - (xx + yy)) * sz.toDouble();
    te[11] = 0;

    te[12] = position.x.toDouble();
    te[13] = position.y.toDouble();
    te[14] = position.z.toDouble();
    te[15] = 1;

    return this;
  }

  Matrix4 decompose(Vector3 position, Quaternion quaternion, Vector3 scale) {
    var te = elements;

    var sx = _matrix4v1.set(te[0], te[1], te[2]).length();
    var sy = _matrix4v1.set(te[4], te[5], te[6]).length();
    var sz = _matrix4v1.set(te[8], te[9], te[10]).length();

    // if determine is negative, we need to invert one scale
    var det = determinant();
    if (det < 0) sx = -sx;

    position.x = te[12];
    position.y = te[13];
    position.z = te[14];

    // scale the rotation part
    _matrix4m1.copy(this);

    var invSX = 1 / sx;
    var invSY = 1 / sy;
    var invSZ = 1 / sz;

    _matrix4m1.elements[0] *= invSX;
    _matrix4m1.elements[1] *= invSX;
    _matrix4m1.elements[2] *= invSX;

    _matrix4m1.elements[4] *= invSY;
    _matrix4m1.elements[5] *= invSY;
    _matrix4m1.elements[6] *= invSY;

    _matrix4m1.elements[8] *= invSZ;
    _matrix4m1.elements[9] *= invSZ;
    _matrix4m1.elements[10] *= invSZ;

    quaternion.setFromRotationMatrix(_matrix4m1);

    scale.x = sx;
    scale.y = sy;
    scale.z = sz;

    return this;
  }

  Matrix4 makePerspective(
      num left, num right, num top, num bottom, num near, num far) {
    
    var te = elements;
    var x = 2 * near / (right - left);
    var y = 2 * near / (top - bottom);

    var a = (right + left) / (right - left);
    var b = (top + bottom) / (top - bottom);
    var c = -(far + near) / (far - near);
    var d = -2 * far * near / (far - near);

    te[0] = x;
    te[4] = 0;
    te[8] = a;
    te[12] = 0;
    te[1] = 0;
    te[5] = y;
    te[9] = b;
    te[13] = 0;
    te[2] = 0;
    te[6] = 0;
    te[10] = c;
    te[14] = d;
    te[3] = 0;
    te[7] = 0;
    te[11] = -1;
    te[15] = 0;

    return this;
  }

  Matrix4 makeOrthographic(
      num left, num right, num top, num bottom, num near, num far) {
    var te = elements;
    var w = 1.0 / (right - left);
    var h = 1.0 / (top - bottom);
    var p = 1.0 / (far - near);

    var x = (right + left) * w;
    var y = (top + bottom) * h;
    var z = (far + near) * p;

    te[0] = 2 * w;
    te[4] = 0;
    te[8] = 0;
    te[12] = -x;
    te[1] = 0;
    te[5] = 2 * h;
    te[9] = 0;
    te[13] = -y;
    te[2] = 0;
    te[6] = 0;
    te[10] = -2 * p;
    te[14] = -z;
    te[3] = 0;
    te[7] = 0;
    te[11] = 0;
    te[15] = 1;

    return this;
  }

  bool equals(Matrix4 matrix) {
    var te = elements;
    var me = matrix.elements;

    for (var i = 0; i < 16; i++) {
      if (te[i] != me[i]) return false;
    }

    return true;
  }

  Matrix4 fromArray(array, [int offset = 0]) {
    for (var i = 0; i < 16; i++) {
      elements[i] = array[i + offset].toDouble();
    }

    return this;
  }

  toArray(array, [int offset = 0]) {
    var te = elements;

    array[offset] = te[0];
    array[offset + 1] = te[1];
    array[offset + 2] = te[2];
    array[offset + 3] = te[3];

    array[offset + 4] = te[4];
    array[offset + 5] = te[5];
    array[offset + 6] = te[6];
    array[offset + 7] = te[7];

    array[offset + 8] = te[8];
    array[offset + 9] = te[9];
    array[offset + 10] = te[10];
    array[offset + 11] = te[11];

    array[offset + 12] = te[12];
    array[offset + 13] = te[13];
    array[offset + 14] = te[14];
    array[offset + 15] = te[15];

    return array;
  }

  toJSON() {
    return elements.sublist(0);
  }

  Matrix4 getInverse(Matrix4 matrix) {
    print(
        'THREE.Matrix4: .getInverse() has been removed. Use matrixInv.copy( matrix ).invert(); instead.');
    return copy(matrix).invert();
  }
}
