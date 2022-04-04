import 'package:three_dart/three3d/math/index.dart';

/**
 * Convolution shader
 * ported from o3d sample to WebGL / GLSL
 * http://o3d.googlecode.com/svn/trunk/samples/convolution.html
 */

Map ConvolutionShader = {
  "defines": {'KERNEL_SIZE_FLOAT': '25.0', 'KERNEL_SIZE_INT': '25'},
  "uniforms": {
    'tDiffuse': {"value": null},
    'uImageIncrement': {"value": new Vector2(0.001953125, 0.0)},
    'cKernel': {"value": []}
  },
  "vertexShader": [
    'uniform vec2 uImageIncrement;',
    'varying vec2 vUv;',
    'void main() {',
    '	vUv = uv - ( ( KERNEL_SIZE_FLOAT - 1.0 ) / 2.0 ) * uImageIncrement;',
    '	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
    '}'
  ].join('\n'),
  "fragmentShader": [
    'uniform float cKernel[ KERNEL_SIZE_INT ];',
    'uniform sampler2D tDiffuse;',
    'uniform vec2 uImageIncrement;',
    'varying vec2 vUv;',
    'void main() {',
    '	vec2 imageCoord = vUv;',
    '	vec4 sum = vec4( 0.0, 0.0, 0.0, 0.0 );',
    '	for( int i = 0; i < KERNEL_SIZE_INT; i ++ ) {',
    '		sum += texture2D( tDiffuse, imageCoord ) * cKernel[ i ];',
    '		imageCoord += uImageIncrement;',
    '	}',
    '	gl_FragColor = sum;',
    '}'
  ].join('\n'),
};

Function ConvolutionShader_buildKernel = (sigma) {
  // We lop off the sqrt(2 * pi) * sigma term, since we're going to normalize anyway.

  Function gauss = (x, sigma) {
    return Math.exp(-(x * x) / (2.0 * sigma * sigma));
  };

  var i, values, sum, halfWidth, kMaxKernelSize = 25;
  int kernelSize = (2 * Math.ceil(sigma * 3.0) + 1).toInt();

  if (kernelSize > kMaxKernelSize) kernelSize = kMaxKernelSize;
  halfWidth = (kernelSize - 1) * 0.5;

  values = new List<num>.filled(kernelSize, 0.0);
  sum = 0.0;
  for (i = 0; i < kernelSize; ++i) {
    values[i] = gauss(i - halfWidth, sigma);
    sum += values[i];
  }

  // normalize the kernel

  for (i = 0; i < kernelSize; ++i) values[i] /= sum;

  return values;
};
