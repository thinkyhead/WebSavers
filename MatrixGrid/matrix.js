/**
 * Matrix Screensaver
 *
 * This version of the classic screensaver uses a large number of divs
 * with css animation to achieve a cleaner result than canvas fill.
 */
"use strict";

function rndint(n) { return Math.floor(Math.random() * n); }

const opts = {
  fixed_col   : 0       , // Use a fixed number of columns (0 = default size)
  theme       : 0       , // 0: Green, 1: Amber, 2: Light, 3: Atari 800
  alpha       : true    , // Mix in Roman alphabet?
  punctuation : false   , // Mix in Punctuation?
  overlay     : 1       , // 0: none, 1: scanlines, 2: shadowmask
  oalpha      : 0       , // (0 < n <= 1) Overlay Alpha or 0 for default
  flip        : true    , // Draw flipped characters?
  change      : 10      , // Character randomization per frame (0 = none)
  fps         : 30      , // (Hz) Maximum drop advance frequency
  minspeed    : 0.2     , // (0 < n <= 1) Minimum drop speed
  maxspeed    : 1.0     , // (0 < n <= 1) Maximum drop speed
  respawn     : 6       , // (screens) Random respawn range (minus 5 rows)
  fadetime    : 5       , // (s) Duration of the fade animation
};

function get_colors(t) {
  switch (t) {
    default: return { drop:"#FFF", tail:"#0F0", fill:"#000" };    // Green
    case 1:  return { drop:"#FFF", tail:"#FA0", fill:"#000" };    // Amber
    case 2:  return { drop:"#000", tail:"#0A0", fill:"#FFF" };    // Light
    case 3:  return { drop:"#FF0", tail:"#EEF", fill:"#6A6AEE" }; // Atari
  }
}
const colors = get_colors(opts.theme), dotail = colors.drop != colors.tail;

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
      puncts = opts.punctuation ? '!@#$%^&*-+{}[]|\\/<>?:;\'"|' : '',
      alphas = opts.alpha ? alphabet : '',
      alphanum = { chr:alphabet + puncts, size:22, xgap:2, ygap:2, flop:2 },
      chinese = { chr:"田由甲申甴电甶男甸甹町画甼甽甾甿畀畁畂畃畄畅畆畇畈畉畊畋界畍畎畏畐畑", size:24, xgap:4, ygap:4, flop:2 },
      katakana = { chr:alphas + puncts + "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ", size:24, xgap:2, ygap:2, flop:2 },
      katakana2 = { chr:alphas + puncts + "アァカサタナハマヤャラワガザダバパイィキシチニヒミリヰギジヂビピウゥクスツヌフムユュルグズブヅプエェケセテネヘメレヱゲゼデベペオォコソトノホモヨョロヲゴゾドボポヴッン", size:22, xgap:6, ygap:4, flop:2 },
      set = opts.theme == 3 ? alphanum : katakana2,
      font = opts.theme == 3 ? 'Atari Classic' : 'arial',
      chars = set.chr;

// Globals for window size
const w = window.innerWidth, h = window.innerHeight;

// Get fontsize from the set or based on columns
const fontsize = opts.fixed_col ? w / opts.fixed_col : set.size;

// Column size and number of columns
const colsize = fontsize + set.xgap, cols = Math.floor(w / colsize),
      rowsize = fontsize + set.ygap, rows = Math.ceil(h / rowsize),
      coffs = Math.floor((w - cols * colsize) / 2),
      roffs = -set.ygap / 2;

// Create character cels within the container
function init_matrix() {
  const frag = document.createDocumentFragment();
  const bkgd = document.getElementById('cels');
  bkgd.style.background = colors.fill;

  function new_cel(d, x, y, w, h, f, s) {
    const cel = document.createElement('div');
    cel.style = `left:${x}px; top:${y}px; width:${w}px; height:${h}px; font-family:${f}; font-size:${s}px; animation-duration:${opts.fadetime}s`;

    cel.rand = () => {
      cel.textContent = chars.charAt(rndint(chars.length));
      if (opts.flip) cel.classList = Math.random() < 0.5 ? ['flop'] : [];
    };

    cel.start = () => {
      cel.style.display = 'none';
      // Use a timeout so the js loop gets called beforehand
      // and has a chance to see that the style display became 'none'
      setTimeout(() => {
        if (cel.timer) clearTimeout(cel.timer);
        cel.rand();
        cel.style.color = colors.drop;
        cel.style.display = 'block';
        cel.timer = setTimeout(() => { cel.timer = undefined; cel.style.display = 'none'; }, opts.fadetime * 1000);
      }, 2);
    };

    d.appendChild(cel);
    return cel;
  }

  let cels = Array(cols);
  let x = coffs;
  for (let c = 0; c < cols; c++) {
    cels[c] = Array(rows);
    var y = roffs;
    for (let r = 0; r < rows; r++) {
      cels[c][r] = new_cel(frag, x, y, colsize, rowsize, font, fontsize);
      y += rowsize;
    }
    x += colsize;
  }

  bkgd.appendChild(frag);

  return cels;
}

// Draw or hide the overlay
function init_overlay(ov, w, h, fill) {
  if (!ov) return;

  const o = document.getElementById("overlay");
  o.setAttribute('style', 'display: block;');

  const ctx = o.getContext("2d");

  o.width = w; o.height = h;
  ctx.clearRect(0, 0, w, h);

  ctx.globalAlpha = opts.oalpha ? opts.oalpha : (ov == 1 ? 0.8 : 0.6);
  ctx.linewidth = 1;
  ctx.strokeStyle = `rgb(${fill})`;
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

init_overlay(opts.overlay, w, h, colors.fill);
const cels = init_matrix();

// Init a new or existing drop
const minfps = Math.floor(opts.fps * opts.minspeed), maxfps = Math.max(minfps, Math.floor(opts.fps * opts.maxspeed));
function initdrop(drop) {
  drop.y = -rndint(rows * opts.respawn) - 5;
  drop.int = minfps + rndint(maxfps - minfps);
  drop.cnt = 0;
  return drop;
}

// Create an array of drops, one per column
var drops = [];
for (var x = 0; x < cols; x++) drops.push(initdrop({}));

// Randomly change some characters
function random_change() {
  if (opts.change == 0) return;
  if (opts.change > 1) {
    for (let i = 0; i < opts.change; i++)
      cels[rndint(cols)][rndint(rows)].rand();
  }
  else {
    if (Math.random() < opts.change)
      cels[rndint(cols)][rndint(rows)].rand();
  }
}

// Update the drops array and init cels whenever drops advance
function update() {
  random_change();
  for (var i = 0; i < cols; i++) {
    var drop = drops[i];
    if ((drop.cnt -= drop.int) > 0) continue;
    drop.cnt += opts.fps;
    const y = ++drop.y;
    if (y < 0) continue;
    if (dotail && y > 0) cels[i][y-1].style.color = colors.tail;
    if (y >= rows)
      initdrop(drops[i]);
    else
      cels[i][y].start();
  }
}

setInterval(update, 1000 / opts.fps);
