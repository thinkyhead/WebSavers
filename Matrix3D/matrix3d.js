/**
 * Matrix 3D Screensaver
 *
 * The Matrix raindrop animation (drawn into an offscreen texture that
 * wraps a rotating THREE.js cube) is adapted from the current Matrix
 * saver's matrix.js engine — richer than the older version: head + tail
 * colors, fading trails, multiple overlay modes, flip, FPS.
 *
 * Sources:
 *   - https://codepen.io/P3R0/pen/MwgoKv
 *   - https://r105.threejsfundamentals.org/threejs/threejs-canvas-textured-cube.html
 *   - Matrix/matrix.js (the 2D engine this texture is based on)
 */
"use strict";

function rndint(n) { return Math.floor(Math.random() * n); }

// Configurable appearance (set via applySettings, keys match ObjC sheet)
let theme = 0,       // 0: Green, 1: Amber, 2: Light, 3: Atari 800
    font_size = 24,
    overlay = 0,     // 0: none, 1: scanlines, 2: shadow mask
    flipping = false,
    fps = 30;

// Per-theme colors, matching Matrix/matrix.js get_colors()
function get_colors(t) {
  switch (t) {
    default: return { drop:"#FFF", tail:"#0F0", fill:"0, 0, 0" };       // Green
    case 1:  return { drop:"#FFF", tail:"#F80", fill:"0, 0, 0" };       // Amber
    case 2:  return { drop:"#F00", tail:"#0F0", fill:"255, 255, 255" }; // Light
    case 3:  return { drop:"#FF0", tail:"#EEF", fill:"106, 106, 238" }; // Atari
  }
}

// Charsets, matching Matrix/matrix.js
const katakana = "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
      alphanum = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
      thinkycs = "TtHhIiNnKkYyEeAaDd1347";

const size_2d = 1024;
const c2 = document.createElement('canvas'), ctx2 = c2.getContext('2d');
c2.width = c2.height = size_2d;

let colors, drops, charset, rows, columns;

function newdrop() {
  const intvl = 1 + rndint(4);
  return { y:-5 - rndint(rows), int:intvl, cnt:intvl, char: { chr:false, flip:false, y:0 } };
}

// (Re)initialize the offscreen Matrix texture using the current settings
function init_texture() {
  colors = get_colors(theme);
  charset = theme == 3 ? alphanum : (rndint(200) ? katakana : thinkycs);

  columns = c2.width / font_size;
  rows = c2.height / font_size;

  ctx2.font = font_size + "px arial";
  ctx2.textAlign = 'center';

  // Fill with the tail color, then cover almost entirely with the fill
  // color so the drop head is bright and the trail fades.
  ctx2.fillStyle = colors.tail;
  ctx2.fillRect(0, 0, size_2d, size_2d);
  ctx2.fillStyle = `rgba(${colors.fill}, 0.95)`;
  ctx2.fillRect(0, 0, size_2d, size_2d);

  // Init all drops at the top of the screen
  drops = [];
  for (var x = 0; x < columns; x++) drops.push(newdrop());

  draw_overlay();
  texture.needsUpdate = true;
}

// Draw a scanline / shadow-mask overlay onto the texture
function draw_overlay() {
  ctx2.save();
  ctx2.globalAlpha = 0.2;
  ctx2.strokeStyle = '#000';
  switch (overlay) {
    case 1: // Horizontal scanlines
      for (var y = 0; y < size_2d; y += 3) {
        ctx2.beginPath(); ctx2.moveTo(0, y); ctx2.lineTo(size_2d, y); ctx2.stroke();
      }
      break;
    case 2: // Grid shadow mask
      for (var x = 0; x < size_2d; x += 3) {
        ctx2.beginPath(); ctx2.moveTo(x, 0); ctx2.lineTo(x, size_2d); ctx2.stroke();
      }
      break;
  }
  ctx2.restore();
}

// Draw the next Matrix raindrop animation frame into the texture
function draw_drops() {
  const col_size = font_size;
  const alpha = 3 / rows;

  // Translucent fill over the whole canvas fades previous characters
  ctx2.fillStyle = `rgba(${colors.fill}, ${alpha})`;
  ctx2.fillRect(0, 0, c2.width, c2.height);

  var flip = false;
  for (var i = 0; i < drops.length; i++) {
    const drop = drops[i];
    if (drop.cnt--) continue;                    // Drop is waiting (and fading)

    drop.cnt = drop.int;                         // Reset counter
    drop.y++;                                    // Move down

    var y = drop.y * font_size;                  // Draw Y

    if (y > c2.height)                           // Past the bottom?
      drops[i] = newdrop();                      // Recycle the drop
    else {
      const x = i * col_size + font_size / 2,
            c = charset.charAt(rndint(charset.length));

      if (flipping) flip = Math.random() < 0.5;

      ctx2.fillStyle = colors.drop;              // Draw the head character
      if (flip) { ctx2.save(); ctx2.scale(1, -1); ctx2.fillText(c, x, -y); ctx2.restore(); }
      else ctx2.fillText(c, x, y);

      // Redraw the previous character in the tail color (the trail)
      if (drop.char.chr) {
        ctx2.fillStyle = colors.tail;
        if (drop.char.flip) { ctx2.save(); ctx2.scale(1, -1); ctx2.fillText(drop.char.chr, x, -drop.char.y); ctx2.restore(); }
        else ctx2.fillText(drop.char.chr, x, drop.char.y);
        ctx2.fillStyle = colors.drop;
      }
      drop.char.chr = c;
      drop.char.flip = flip;
      drop.char.y = y;
    }
  }
  texture.needsUpdate = true;
}

// 3D Cube
const c3 = document.querySelector('#matrix3d'), ctx3 = c3.getContext("3d");
c3.height = window.innerHeight; c3.width = window.innerWidth;

const renderer = new THREE.WebGLRenderer({ canvas:c3 });

const fov = 75, aspect = 2, near = 0.1, far = 5,
      camera = new THREE.PerspectiveCamera(fov, aspect, near, far);
camera.position.z = 2;

const boxWidth = 1.5, boxHeight = 1.5, boxDepth = 1.5,
      geometry = new THREE.BoxGeometry(boxWidth, boxHeight, boxDepth);

// Make a cube for our scene
const texture = new THREE.CanvasTexture(ctx2.canvas),
      material = new THREE.MeshBasicMaterial({ map:texture }),
      cube = new THREE.Mesh(geometry, material);

const scene = new THREE.Scene();
scene.add(cube);

const cubes = [ cube ];

var last_time = 0, axes = 2;
function render_3d(time) {
  time *= 0.001;
  const diff = time - last_time;
  last_time = time;

  if (!rndint(500)) axes = rndint(7) + 1;

  cubes.forEach((cube, ndx) => {
    const speed = .2 + ndx * .1, add = diff * speed;
    if (axes & 1) cube.rotation.x += add;
    if (axes & 2) cube.rotation.y += add;
    if (axes & 4) cube.rotation.z += add;
  });

  renderer.render(scene, camera);

  requestAnimationFrame(render_3d);
}

// Redraw the cube on a rAF schedule
requestAnimationFrame(render_3d);

init_texture();

// Redraw drops on an FPS-controlled schedule
const NATIVE_FPS = window.screen.refreshRate || 60;
let bcount = Math.floor(fps / 2);
function may_draw() {
  bcount += fps;
  if (bcount >= NATIVE_FPS) { draw_drops(); bcount -= NATIVE_FPS; }
  requestAnimationFrame(may_draw);
}
requestAnimationFrame(may_draw);

// Apply new settings and restart the display
window.applySettings = (settings) => {
  if (!settings) return;
  if ('theme' in settings)    theme = Math.max(0, Math.min(3, settings.theme|0));
  if ('fontSize' in settings) font_size = Math.max(12, Math.min(48, settings.fontSize|0));
  if ('overlay' in settings)  overlay = Math.max(0, Math.min(2, settings.overlay|0));
  if ('flip' in settings)     flipping = !!settings.flip;
  else if ('flipping' in settings) flipping = !!settings.flipping;
  if ('fps' in settings)      fps = Math.max(5, Math.min(60, settings.fps|0));
  bcount = 0; // Reset the frame counter for the new FPS
  init_texture();
};
