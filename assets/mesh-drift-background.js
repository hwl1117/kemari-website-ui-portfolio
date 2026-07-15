(() => {
  'use strict';

  const host = document.querySelector('.case-main');
  const loader = document.currentScript;
  if (!host || !loader) return;

  const canvas = document.createElement('canvas');
  canvas.className = 'mesh-drift-canvas';
  canvas.setAttribute('aria-hidden', 'true');
  host.prepend(canvas);

  const gl = canvas.getContext('webgl', {
    alpha: false,
    antialias: false,
    depth: false,
    powerPreference: 'low-power',
    preserveDrawingBuffer: false,
    premultipliedAlpha: false,
    stencil: false
  });

  if (!gl) {
    canvas.remove();
    host.classList.add('mesh-drift-unavailable');
    return;
  }

  const vertexSource = `
    attribute vec2 a_position;
    void main() {
      gl_Position = vec4(a_position, 0.0, 1.0);
    }
  `;

  const compile = (type, source) => {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      const error = gl.getShaderInfoLog(shader);
      gl.deleteShader(shader);
      throw new Error(error || 'Shader compilation failed.');
    }
    return shader;
  };

  const createProgram = (fragmentSource) => {
    const program = gl.createProgram();
    const vertex = compile(gl.VERTEX_SHADER, vertexSource);
    const fragment = compile(gl.FRAGMENT_SHADER, fragmentSource);
    gl.attachShader(program, vertex);
    gl.attachShader(program, fragment);
    gl.linkProgram(program);
    gl.deleteShader(vertex);
    gl.deleteShader(fragment);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      const error = gl.getProgramInfoLog(program);
      gl.deleteProgram(program);
      throw new Error(error || 'Shader program link failed.');
    }
    return program;
  };

  const sourceUrl = new URL('mesh-drift.frag', loader.src);
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  let animationFrame = 0;
  let drawFrame = null;
  let observer = null;

  const stop = () => {
    if (animationFrame) cancelAnimationFrame(animationFrame);
    animationFrame = 0;
  };

  const fail = () => {
    stop();
    observer?.disconnect();
    canvas.remove();
    host.classList.add('mesh-drift-unavailable');
  };

  fetch(sourceUrl)
    .then((response) => {
      if (!response.ok) throw new Error('Mesh drift fragment shader was unavailable.');
      return response.text();
    })
    .then((fragmentSource) => {
      const program = createProgram(fragmentSource);
      const position = gl.getAttribLocation(program, 'a_position');
      const uniforms = {
        colors: gl.getUniformLocation(program, 'u_colors[0]'),
        scene: gl.getUniformLocation(program, 'u_scene'),
        shape: gl.getUniformLocation(program, 'u_shape'),
        surface: gl.getUniformLocation(program, 'u_surface'),
        finish: gl.getUniformLocation(program, 'u_finish'),
        transform: gl.getUniformLocation(program, 'u_transform'),
        space: gl.getUniformLocation(program, 'u_space'),
        cursor: gl.getUniformLocation(program, 'u_cursor')
      };
      const palette = new Float32Array([
        0.012, 0.071, 0.055,
        0.055, 0.486, 0.353,
        0.486, 0.898, 0.467,
        0.957, 1.000, 0.780,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0
      ]);
      const buffer = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
      gl.useProgram(program);
      gl.enableVertexAttribArray(position);
      gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);
      gl.uniform3fv(uniforms.colors, palette);
      gl.uniform4f(uniforms.shape, 1.16, 0.34, 0.50, 0.00);
      gl.uniform4f(uniforms.surface, 2.40, 1.16, 0.00, 1.00);
      gl.uniform4f(uniforms.finish, 0.00, 0.00, 0.000, 0.09);
      gl.uniform4f(uniforms.transform, 1453.0, 0.00, 0.00, 0.0);
      gl.uniform4f(uniforms.space, 0.00, 0.00, 0.00, 0.00);
      gl.uniform4f(uniforms.cursor, 0.00, 2.0, 0.65, 0.46);

      const resize = () => {
        const pixelRatio = Math.min(window.devicePixelRatio || 1, 2);
        const width = Math.max(1, Math.round(window.innerWidth * pixelRatio));
        const height = Math.max(1, Math.round(window.innerHeight * pixelRatio));
        if (canvas.width === width && canvas.height === height) return;
        canvas.width = width;
        canvas.height = height;
        gl.viewport(0, 0, width, height);
      };

      const draw = (timestamp) => {
        resize();
        gl.useProgram(program);
        gl.uniform4f(uniforms.scene, canvas.width, canvas.height, timestamp * 0.00073, 4.0);
        gl.drawArrays(gl.TRIANGLES, 0, 3);
      };

      drawFrame = (timestamp) => {
        if (document.hidden || reduceMotion.matches) {
          animationFrame = 0;
          return;
        }
        draw(timestamp);
        animationFrame = requestAnimationFrame(drawFrame);
      };

      const start = () => {
        if (!animationFrame && !document.hidden && !reduceMotion.matches) {
          animationFrame = requestAnimationFrame(drawFrame);
        }
      };

      observer = new ResizeObserver(resize);
      observer.observe(host);
      window.addEventListener('resize', resize, { passive: true });
      document.addEventListener('visibilitychange', () => {
        if (document.hidden) stop();
        else start();
      });
      reduceMotion.addEventListener('change', () => {
        if (reduceMotion.matches) {
          stop();
          draw(performance.now());
        } else {
          start();
        }
      });
      window.addEventListener('pagehide', () => {
        stop();
        observer?.disconnect();
      }, { once: true });

      draw(performance.now());
      start();
    })
    .catch(fail);
})();
