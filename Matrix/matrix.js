/**
 * Matrix 2D Screensaver
 *
 * Javascript based on the CodePen sketch:
 *   - https://codepen.io/P3R0/pen/MwgoKv
 *
 * This is a very simplified version of the "Matrix Rain" effect, based
 * on several similar examples to show the power of HTML Canvas.
 *
 * - Drops are first drawn in one color (e.g., white) and if the tail
 *   color differs the previous character is redrawn in the tail color.
 * - The canvas is continually filled with a transparent color to make
 *   all previously-drawn characters fade out.
 * - There are several config options to change the appearance. These
 *   can be updated to respond to ?setting=1&other=2 URL arguments.
 *
 * Meanwhile, in the original Matrix film:
 * - Drops are nearly white and fall over a background of vertical strips
 *   of regularly pulsing and changing green characters.
 * - Only around 10-15 active drops are ever seen on screen at once.
 * - Occasionally a drop will shift over horizontally or briefly disappear.
 * - Occasionally a strip is erased top-to bottom, with no fading effect,
 *   and sometimes it skips over a character.
 * - The head character doesn't always make it all the way to the bottom
 *   of the screen, but most do.
 * - The pulsing characters quickly fade from the old to the new.
 * - Perhaps only half of the background strips are actually changing.
 * - The overall screen is blurry and shimmering with only implied scanlines.
 *
 * Suggestions for Improvement:
 * - The transparent overlay used to fade out old characters doesn't completely
 *   erase them (unless the overlay color is pure white). This can be fixed by
 *   using a different method to "erase" old characters:
 *     1. Spawn a separate canvas for every grid cell.
 *     2. For a new drop erase the cell and draw the new drop character.
 *        The drop may or may not start fading at this point.
 *     3. When a drop moves down redraw it in the tail color.
 *     3. Just have each drop cell fade its own opacity until done.
 *
 */
"use strict";

function rndint(n) { return Math.floor(Math.random() * n); }

const fixed_col = 0,  // Use a fixed number of columns or 0 for the default font size
      theme = 0,      // 0: Green, 1: Amber, 2: Light, 3: Atari 800
      overlay = 1,    // 0: none, 1: scanlines, 2: shadowmask
      oalpha = overlay == 1 ? 0.8 : 0.5,
      flipping = false,
      fps = 30;

function get_colors(t) {
  switch (t) {
    default: return { drop:"#FFF", tail:"#0F0", fill:"0, 0, 0" };       // Green
    case 1:  return { drop:"#FFF", tail:"#F80", fill:"0, 0, 0" };       // Amber
    case 2:  return { drop:"#F00", tail:"#0F0", fill:"255, 255, 255" }; // Light
    case 3:  return { drop:"#FF0", tail:"#EEF", fill:"106, 106, 238" }; // Atari
  }
}
const colors = get_colors(theme), dotail = colors.drop != colors.fill;

const chinese = { chr:"田由甲申甴电甶男甸甹町画甼甽甾甿畀畁畂畃畄畅畆畇畈畉畊畋界畍畎畏畐畑", size:24, xgap:0, ygap:0, drat:12 },
      alphanum = { chr:"ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", size:22, xgap:2, ygap:2, drat:11 },
      katakana = { chr:"ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", size:24, xgap:2, ygap:2, drat:12 },
      katakana2 = { chr:"アァカサタナハマヤャラワガザダバパイィキシチニヒミリヰギジヂビピウゥクスツヌフムユュルグズブヅプエェケセテネヘメレヱゲゼデベペオォコソトノホモヨョロヲゴゾドボポヴッンABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", size:20, xgap:6, ygap:4, drat:1000 },
      thinkycs = { chr:"TtHhIiNnKkYyEeAaDd1347", size:18, xgap:2, ygap:2, drat:9 },
      set = theme == 3 ? alphanum : (rndint(200) ? katakana2 : thinkycs),
      chars = set.chr,
      font = theme == 3 ? 'Atari Classic' : 'arial';

// Init the main canvas and context
function init_canvas(w, h, a, f, s) {
  const c = document.getElementById("matrix"), ctx = c.getContext("2d");
  c.width = w; c.height = h;
  ctx.globalAlpha = a;
  ctx.font = `${s}px ${f}`;
  ctx.textAlign = 'center';
  ctx.textRendering = 'optimizeSpeed';

  //ctx.globalCompositeOperation = 'difference';
  //ctx.clearRect(0, 0, w, h);

  // Fill with the initial color
  //ctx.fillStyle = `rgba(0, 0, 0)`;
  //ctx.fillRect(0, 0, w, h);

  const alpha = 1/30, compl = 1.0 - alpha;
  ctx._eraseStyle = `rgba(${colors.fill}, ${alpha})`;

  ctx.fillStyle = colors.tail;
  ctx.fillRect(0, 0, w, h);
  ctx.fillStyle = `rgba(${colors.fill}, ${compl})`;
  ctx.fillRect(0, 0, w, h);

  return ctx;
}

// Draw or hide the overlay
function init_overlay(ov, fill) {
  const o = document.getElementById("overlay");
  if (!ov) return o.setAttribute('style', 'display:none');

  const ctx = o.getContext("2d");

  o.width = w; o.height = h;
  ctx.clearRect(0, 0, w, h);

  ctx.globalAlpha = oalpha;
  ctx.linewidth = 1;
  //ctx.strokeStyle = `rgb(${fill})`;
  ctx.strokeStyle = '#000';
  switch (ov) {
    case 3: // Diagonal lines
      for (var x = -w - h; x < w + h; x += 4) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x + h - 1, h - 1);
        ctx.stroke();
        ctx.moveTo(w - x, 0);
        ctx.lineTo(w - (x + h - 1), h - 1);
        ctx.stroke();
      }
      break;
    case 2: // Grid shadow mask
      for (var x = 1; x < w; x += 3) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, h - 1);
        ctx.stroke();
      }
    case 1: // Horizontal scanlines
      for (var y = 1; y < h; y += 3) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(w - 1, y);
        ctx.stroke();
      }
  }
}

// Get a 2D context for the canvas
const w = window.innerWidth, h = window.innerHeight;
if (fixed_col) set.size = w / fixed_col;

const ctx = init_canvas(w, h, 1, font, set.size);
init_overlay(overlay, colors.fill);

// Column size and number of columns
const colsize = set.size + set.xgap,
      rowsize = set.size + set.ygap,
      columns = Math.floor(w / colsize),
      coffs = (set.xgap + set.size) / 2 + Math.floor((w - columns * colsize) / 2),
      rows = h / rowsize;

function newdrop() {
  const intvl = 1 + rndint(4);
  return { y:-5 - rndint(rows), int:intvl, cnt:intvl, char: { chr:false, flip:false, y:0 } };
}

// Init all drops at the top of the screen
var drops = [];
for (var x = 0; x < columns; x++) drops.push(newdrop());

// Draw the characters
function draw() {
  ctx.setTransform(1, 0, 0, 1, 0, 0);

  // Black BG for the canvas
  // translucent BG to show trail
  ctx.fillStyle = ctx._eraseStyle;
  ctx.fillRect(0,0,w,h);

  ctx.fillStyle = colors.drop;

  var flip = false;
  for (var i = 0; i < drops.length; i++) {
    let drop = drops[i];
    if (drop.cnt--) continue;

    // Moving down
    drop.cnt = drop.int;
    drop.y++;

    // Send the drop back to the top randomly after it has crossed the screen
    // Add a randomness to the reset to make the drops scattered on the Y axis
    var y = drop.y * rowsize - set.ygap / 2;
    if (y > h + colsize) drop = drops[i] = newdrop();

    // Print a random character
    if (drop.y >= 0) {
      const x = coffs + i * colsize,
            c = chars.charAt(rndint(chars.length));

      if (flipping) {
        flip = Math.random() < 0.5;
        // Randomly flip the drawn character
        if (flip) {
          ctx.setTransform(1, 0, 0, -1, 0, 0);
          y = -y + set.size - 2;
        }
      }
      ctx.fillText(c, x, y);
      if (flip) ctx.setTransform(1, 0, 0, 1, 0, 0);

      // Draw the previous character in the tail color
      if (dotail) {
        const dc = drop.char;
        if (dc.chr) {
          if (dc.flip) ctx.setTransform(1, 0, 0, -1, 0, 0);
          ctx.fillStyle = colors.tail;
          ctx.fillText(dc.chr, x, dc.y);
          ctx.fillStyle = colors.drop;
          if (dc.flip) ctx.setTransform(1, 0, 0, 1, 0, 0);
        }
        // Remember the char just drawn and where
        dc.chr = c;
        dc.flip = flip;
        dc.y = y;
      }
    }
  }
}

const NATIVE_FPS = window.screen.refreshRate || 60;
let bcount = Math.floor(fps / 2);
function may_draw() {
  bcount += fps;
  if (bcount >= NATIVE_FPS) { draw(); bcount -= NATIVE_FPS; }
  requestAnimationFrame(may_draw);
}

requestAnimationFrame(may_draw);
