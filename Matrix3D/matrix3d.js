/**
 * Matrix 3D Screensaver
 *
 * Javascript from:
 *   - https://codepen.io/P3R0/pen/MwgoKv
 *   - https://r105.threejsfundamentals.org/threejs/threejs-canvas-textured-cube.html
 */
"use strict";

function rndint(n) { return Math.floor(Math.random() * n); }

//
// Matrix Drops
//

// Configure the Matrix animation appearance
const size_2d = 1024,
      drop_color = "#0F0",
      overlay = [ 0, 0, 0 ],
      font_size = 24,
      col_gap = 0;

const chinese = "田由甲申甴电甶男甸甹町画甼甽甾甿畀畁畂畃畄畅畆畇畈畉畊畋界畍畎畏畐畑",
      katakana = "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ1234567890",
      thinkycs = "TtHhIiNnKkYyEeAaDd1347",
      charset = (rndint(200) ? katakana : thinkycs).split("");

// A canvas for the Matrix animation
const c2 = document.createElement('canvas'), ctx2 = c2.getContext('2d');
c2.width = c2.height = size_2d;

ctx2.font = font_size + "px arial";

ctx2.fillStyle = drop_color;
ctx2.fillRect(0, 0, size_2d, size_2d);
ctx2.fillStyle = `rgba(0,0,0,0.95)`;
ctx2.fillRect(0, 0, size_2d, size_2d);

// Column size, columns, rows
const col_size = font_size + col_gap,
      columns = c2.width / col_size,
      rows = c2.height / font_size,
      alpha = 3 / rows;

// A new randomized drop above the top of the screen
function newdrop() {
  const intvl = rndint(4);
  return { y:-rndint(rows), int:intvl, cnt:intvl };
}

// Init all drops at the top of the screen
var drops = [];
for (var x = 0; x < columns; x++) drops.push(newdrop());

// Draw the next Matrix raindrop animation frame
function draw_drops() {
  // Draw translucent black over the entire animation
  ctx2.fillStyle = `rgba(0, 0, 0, ${alpha})`;
  ctx2.fillRect(0, 0, c2.width, c2.height);

  ctx2.fillStyle = drop_color;
  for (var i = 0; i < drops.length; i++) {
    if (drops[i].cnt--) continue;         // Drop is waiting (and fading)

    drops[i].cnt = drops[i].int;          // Reset counter
    drops[i].y++;                         // Move down

    var y = drops[i].y * font_size;       // Draw Y

    if (y > c2.height)                    // Past the bottom?
      drops[i] = newdrop();               // Recycle the drop
    else
      ctx2.fillText(charset[rndint(charset.length)], i * col_size, y); // Draw a random character
  }
  texture.needsUpdate = true;
}

//
// 3D Cube
//

// Get the canvas and its 3D context
const c3 = document.querySelector('#matrix3d'), ctx3 = c3.getContext("3d");
c3.height = window.innerHeight; c3.width = window.innerWidth;

const renderer = new THREE.WebGLRenderer({ canvas:c3 });

// Make a camera for our POV
const fov = 75, aspect = 2,  // the canvas default
      near = 0.1, far = 5,
      camera = new THREE.PerspectiveCamera(fov, aspect, near, far);
camera.position.z = 2;

const boxWidth = 1.5, boxHeight = 1.5, boxDepth = 1.5,
      geometry = new THREE.BoxGeometry(boxWidth, boxHeight, boxDepth);

// Make a cube for our scene
const texture = new THREE.CanvasTexture(ctx2.canvas),
      material = new THREE.MeshBasicMaterial({ map:texture }),
      cube = new THREE.Mesh(geometry, material);

// Make a scene with one cube
const scene = new THREE.Scene();
scene.add(cube);

const cubes = [ cube ]; // an array of cubes to rotate

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
    //cube.rotation.x = cube.rotation.y = rot;
  });

  renderer.render(scene, camera);

  requestAnimationFrame(render_3d);
}

// Redraw drops on one schedule
setInterval(draw_drops, 33);

// Redraw the cube on another schedule (60fps?)
requestAnimationFrame(render_3d);
