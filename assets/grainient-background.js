(() => {
  const mount = document.querySelector('[data-grainient-background]');
  const main = mount && mount.closest('.case-main');
  if (!mount || !main) return;

  const enableFallback = () => {
    main.classList.remove('case-main--grainient-ready');
    main.classList.add('case-main--grainient-fallback');
  };

  if (!window.WebGL2RenderingContext) {
    enableFallback();
    return;
  }

  const canvas = document.createElement('canvas');
  const gl = canvas.getContext('webgl2', {
    alpha: false,
    antialias: false,
    powerPreference: 'low-power'
  });

  if (!gl) {
    enableFallback();
    return;
  }

  const vertex = `#version 300 es
in vec2 position;
void main() {
  gl_Position = vec4(position, 0.0, 1.0);
}`;

  const fragment = `#version 300 es
precision highp float;

uniform vec2 iResolution;
uniform float iTime;
uniform float uTimeSpeed;
uniform float uColorBalance;
uniform float uWarpStrength;
uniform float uWarpFrequency;
uniform float uWarpSpeed;
uniform float uWarpAmplitude;
uniform float uBlendAngle;
uniform float uBlendSoftness;
uniform float uRotationAmount;
uniform float uNoiseScale;
uniform float uGrainAmount;
uniform float uGrainScale;
uniform float uGrainAnimated;
uniform float uContrast;
uniform float uGamma;
uniform float uSaturation;
uniform vec2 uCenterOffset;
uniform float uZoom;
uniform vec3 uColor1;
uniform vec3 uColor2;
uniform vec3 uColor3;
uniform float uScrollOffset;

out vec4 fragColor;

#define S(a,b,t) smoothstep(a,b,t)

mat2 Rot(float a) {
  float s = sin(a);
  float c = cos(a);
  return mat2(c, -s, s, c);
}

vec2 hash(vec2 p) {
  p = vec2(dot(p, vec2(2127.1, 81.17)), dot(p, vec2(1269.5, 283.37)));
  return fract(sin(p) * 43758.5453);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float n00 = dot(-1.0 + 2.0 * hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0));
  float n10 = dot(-1.0 + 2.0 * hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
  float n01 = dot(-1.0 + 2.0 * hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
  float n11 = dot(-1.0 + 2.0 * hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));
  return 0.5 + 0.5 * mix(mix(n00, n10, u.x), mix(n01, n11, u.x), u.y);
}

void mainImage(out vec4 outputColor, vec2 coordinate) {
  float time = iTime * uTimeSpeed;
  vec2 uv = coordinate / iResolution.xy;
  float ratio = iResolution.x / iResolution.y;
  vec2 transformedUv = uv - 0.5 + uCenterOffset;
  transformedUv.y += uScrollOffset;
  transformedUv /= max(uZoom, 0.001);

  float degree = noise(vec2(time * 0.1, transformedUv.x * transformedUv.y) * uNoiseScale);
  transformedUv.y *= 1.0 / ratio;
  transformedUv *= Rot(radians((degree - 0.5) * uRotationAmount + 180.0));
  transformedUv.y *= ratio;

  float frequency = uWarpFrequency;
  float strength = max(uWarpStrength, 0.001);
  float amplitude = uWarpAmplitude / strength;
  float warpTime = time * uWarpSpeed;
  transformedUv.x += sin(transformedUv.y * frequency + warpTime) / amplitude;
  transformedUv.y += sin(transformedUv.x * (frequency * 1.5) + warpTime) / (amplitude * 0.5);

  float balance = uColorBalance;
  float softness = max(uBlendSoftness, 0.0);
  float blendX = (transformedUv * Rot(radians(uBlendAngle))).x;
  float edge0 = -0.3 - balance - softness;
  float edge1 = 0.2 - balance + softness;
  float vertical0 = 0.5 - balance + softness;
  float vertical1 = -0.3 - balance - softness;
  vec3 firstLayer = mix(uColor3, uColor2, S(edge0, edge1, blendX));
  vec3 secondLayer = mix(uColor2, uColor1, S(edge0, edge1, blendX));
  float verticalBlend = 1.0 - S(vertical1, vertical0, transformedUv.y);
  vec3 color = mix(firstLayer, secondLayer, verticalBlend);

  vec2 grainUv = uv * max(uGrainScale, 0.001);
  if (uGrainAnimated > 0.5) grainUv += vec2(iTime * 0.05);
  float grain = fract(sin(dot(grainUv, vec2(12.9898, 78.233))) * 43758.5453);
  color += (grain - 0.5) * uGrainAmount;

  color = (color - 0.5) * uContrast + 0.5;
  float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
  color = mix(vec3(luma), color, uSaturation);
  color = pow(max(color, 0.0), vec3(1.0 / max(uGamma, 0.001)));
  outputColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}

void main() {
  mainImage(fragColor, gl_FragCoord.xy);
}`;

  const compile = (type, source) => {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (gl.getShaderParameter(shader, gl.COMPILE_STATUS)) return shader;
    gl.deleteShader(shader);
    return null;
  };

  const vertexShader = compile(gl.VERTEX_SHADER, vertex);
  const fragmentShader = compile(gl.FRAGMENT_SHADER, fragment);
  if (!vertexShader || !fragmentShader) {
    enableFallback();
    return;
  }

  const program = gl.createProgram();
  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);
  gl.deleteShader(vertexShader);
  gl.deleteShader(fragmentShader);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    enableFallback();
    return;
  }

  const buffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
  const position = gl.getAttribLocation(program, 'position');
  gl.useProgram(program);
  gl.enableVertexAttribArray(position);
  gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);

  const uniforms = Object.fromEntries([
    'iResolution', 'iTime', 'uTimeSpeed', 'uColorBalance', 'uWarpStrength',
    'uWarpFrequency', 'uWarpSpeed', 'uWarpAmplitude', 'uBlendAngle',
    'uBlendSoftness', 'uRotationAmount', 'uNoiseScale', 'uGrainAmount',
    'uGrainScale', 'uGrainAnimated', 'uContrast', 'uGamma', 'uSaturation',
    'uCenterOffset', 'uZoom', 'uColor1', 'uColor2', 'uColor3', 'uScrollOffset'
  ].map(name => [name, gl.getUniformLocation(program, name)]));

  const paletteStops = [
    {
      color1: [0.14, 0.31, 0.23],
      color2: [0.09, 0.16, 0.10],
      color3: [0.008, 0.06, 0.04]
    },
    {
      color1: [0.28, 0.39, 0.23],
      color2: [0.11, 0.25, 0.16],
      color3: [0.018, 0.10, 0.06]
    },
    {
      color1: [0.34, 0.20, 0.09],
      color2: [0.18, 0.27, 0.17],
      color3: [0.05, 0.07, 0.04]
    }
  ];
  const activePalette = {
    color1: [...paletteStops[0].color1],
    color2: [...paletteStops[0].color2],
    color3: [...paletteStops[0].color3]
  };
  const settings = {
    timeSpeed: 0.18,
    colorBalance: 0.16,
    warpStrength: 0.62,
    warpFrequency: 3.8,
    warpSpeed: 0.55,
    warpAmplitude: 48.0,
    blendAngle: -18.0,
    blendSoftness: 0.14,
    rotationAmount: 180.0,
    noiseScale: 1.25,
    grainAmount: 0.075,
    grainScale: 2.2,
    contrast: 1.15,
    gamma: 1.0,
    saturation: 0.76,
    zoom: 0.96
  };

  canvas.className = 'grainient-canvas';
  mount.appendChild(canvas);
  main.classList.add('case-main--grainient-ready');

  let width = 1;
  let height = 1;
  let scrollOffset = 0;
  let scrollProgress = 0;
  let frameId = 0;
  let scrollFrameId = 0;
  let lastFrameAt = 0;
  let visible = true;
  let pageVisible = !document.hidden;
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const frameInterval = 1000 / 30;
  const startedAt = performance.now();

  const updatePaletteForScroll = progress => {
    const segment = progress < 0.5 ? 0 : 1;
    const localProgress = progress < 0.5 ? progress * 2 : (progress - 0.5) * 2;
    const from = paletteStops[segment];
    const to = paletteStops[segment + 1];
    ['color1', 'color2', 'color3'].forEach(name => {
      activePalette[name][0] = from[name][0] + (to[name][0] - from[name][0]) * localProgress;
      activePalette[name][1] = from[name][1] + (to[name][1] - from[name][1]) * localProgress;
      activePalette[name][2] = from[name][2] + (to[name][2] - from[name][2]) * localProgress;
    });
  };

  const positionCanvas = () => {
    const mainTop = main.getBoundingClientRect().top + window.scrollY;
    const maxOffset = Math.max(0, main.offsetHeight - window.innerHeight);
    const localOffset = Math.min(Math.max(0, window.scrollY - mainTop), maxOffset);
    canvas.style.transform = `translate3d(0, ${localOffset}px, 0)`;
    scrollProgress = maxOffset ? localOffset / maxOffset : 0;
    scrollOffset = 0.06 + scrollProgress * 0.46;
    updatePaletteForScroll(scrollProgress);
  };

  const resize = () => {
    positionCanvas();
    const rect = canvas.getBoundingClientRect();
    const dpr = Math.min(window.devicePixelRatio || 1, 1.25);
    width = Math.max(1, Math.floor(rect.width * dpr));
    height = Math.max(1, Math.floor(rect.height * dpr));
    if (canvas.width !== width || canvas.height !== height) {
      canvas.width = width;
      canvas.height = height;
    }
    draw(performance.now());
  };

  const draw = now => {
    gl.viewport(0, 0, width, height);
    gl.useProgram(program);
    gl.uniform2f(uniforms.iResolution, width, height);
    gl.uniform1f(uniforms.iTime, (now - startedAt) * 0.001);
    gl.uniform1f(uniforms.uTimeSpeed, settings.timeSpeed);
    gl.uniform1f(uniforms.uColorBalance, settings.colorBalance);
    gl.uniform1f(uniforms.uWarpStrength, settings.warpStrength);
    gl.uniform1f(uniforms.uWarpFrequency, settings.warpFrequency);
    gl.uniform1f(uniforms.uWarpSpeed, settings.warpSpeed);
    gl.uniform1f(uniforms.uWarpAmplitude, settings.warpAmplitude);
    gl.uniform1f(uniforms.uBlendAngle, settings.blendAngle);
    gl.uniform1f(uniforms.uBlendSoftness, settings.blendSoftness);
    gl.uniform1f(uniforms.uRotationAmount, settings.rotationAmount);
    gl.uniform1f(uniforms.uNoiseScale, settings.noiseScale);
    gl.uniform1f(uniforms.uGrainAmount, settings.grainAmount);
    gl.uniform1f(uniforms.uGrainScale, settings.grainScale);
    gl.uniform1f(uniforms.uGrainAnimated, 0.0);
    gl.uniform1f(uniforms.uContrast, settings.contrast);
    gl.uniform1f(uniforms.uGamma, settings.gamma);
    gl.uniform1f(uniforms.uSaturation, settings.saturation);
    gl.uniform2f(uniforms.uCenterOffset, 0.0, -0.03);
    gl.uniform1f(uniforms.uZoom, settings.zoom);
    gl.uniform3fv(uniforms.uColor1, activePalette.color1);
    gl.uniform3fv(uniforms.uColor2, activePalette.color2);
    gl.uniform3fv(uniforms.uColor3, activePalette.color3);
    gl.uniform1f(uniforms.uScrollOffset, scrollOffset);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
  };

  const stop = () => {
    if (frameId) cancelAnimationFrame(frameId);
    frameId = 0;
    if (scrollFrameId) cancelAnimationFrame(scrollFrameId);
    scrollFrameId = 0;
  };

  canvas.addEventListener('webglcontextlost', event => {
    event.preventDefault();
    stop();
    canvas.remove();
    enableFallback();
  }, { once: true });

  const loop = now => {
    if (now - lastFrameAt >= frameInterval) {
      draw(now);
      lastFrameAt = now;
    }
    frameId = requestAnimationFrame(loop);
  };

  const start = () => {
    if (!reduceMotion && visible && pageVisible && !frameId) frameId = requestAnimationFrame(loop);
  };

  const updateScroll = () => {
    if (scrollFrameId) return;
    scrollFrameId = requestAnimationFrame(() => {
      scrollFrameId = 0;
      positionCanvas();
      if (reduceMotion || !frameId) draw(performance.now());
    });
  };

  const onVisibilityChange = () => {
    pageVisible = !document.hidden;
    if (pageVisible) start();
    else stop();
  };

  const observer = new IntersectionObserver(([entry]) => {
    visible = entry.isIntersecting;
    if (visible) start();
    else stop();
  }, { threshold: 0 });

  observer.observe(main);
  window.addEventListener('resize', resize, { passive: true });
  window.addEventListener('scroll', updateScroll, { passive: true });
  document.addEventListener('visibilitychange', onVisibilityChange);
  resize();
  start();
})();
