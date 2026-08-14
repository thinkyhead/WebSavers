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
  overlay     : 0       , // 0: none, 1: scanlines, 2: shadowmask
  oalpha      : 0       , // (0 < n <= 1) Overlay Alpha or 0 for default
  flip        : true    , // Draw flipped characters?
  change      : 4       , // Character randomization per frame (0 = none)
  fps         : 30      , // (Hz) Maximum drop advance frequency
  minspeed    : 0.2     , // (0 < n <= 1) Minimum drop speed
  maxspeed    : 1.0     , // (0 < n <= 1) Maximum drop speed
  respawn     : 2       , // (screens) Random respawn range (minus 5 rows)
  fadetime    : 3       , // (s) Duration of the fade animation
};

// Merge URL query parameters into opts so the view can be configured
(function applyURLParams() {
  const params = new URLSearchParams(window.location.search);
  for (const key of Object.keys(opts)) {
    if (!params.has(key)) continue;
    const val = params.get(key);
    switch (typeof opts[key]) {
      case 'boolean':
        opts[key] = /^(1|true|yes|on)$/i.test(val);
        break;
      case 'number':
        const num = parseFloat(val);
        if (!isNaN(num)) opts[key] = num;
        break;
    }
  }
})();

function get_colors(t) {
  switch (t) {
    default: return { drop:"#FFF", tail:"#0F0", fill:"#000" };    // Green
    case 1:  return { drop:"#FFF", tail:"#FA0", fill:"#000" };    // Amber
    case 2:  return { drop:"#000", tail:"#0A0", fill:"#FFF" };    // Light
    case 3:  return { drop:"#FF0", tail:"#CCD", fill:"#4A4ABE" }; // Atari
  }
}

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
      atascii = "";

// Globals for window size
const w = window.innerWidth, h = window.innerHeight;

// Dynamic values that update with opts
let colors, chars, set, colsize, cols, rowsize, rows, coffs, roffs,
    minfps, maxfps, cels, drops, updateTimer;

function getChars() {
  const atasciis = opts.theme == 3 ? atascii : '';
  const puncts = opts.punctuation ? '!@#$%^&*-+{}[]|\\/<>?:;\'"|' : '';
  const alphas = opts.alpha ? alphabet : '';
  const alphanum = { chr:alphabet + puncts + atasciis, size:22, xgap:2, ygap:2, flop:2 };
  const katakana = { chr:alphas + puncts + "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ", size:24, xgap:2, ygap:2, flop:2 };
  const katakana2 = { chr:alphas + puncts + "アァカサタナハマヤャラワガザダバパイィキシチニヒミリヰギジヂビピウゥクスツヌフムユュルグズブヅプエェケセテネヘメレヱゲゼデベペオォコソトノホモヨョロヲゴゾドボポヴッン", size:22, xgap:6, ygap:4, flop:2 };
  set = opts.theme == 3 ? alphanum : katakana2;
  chars = set.chr;
  colsize = set.size + set.xgap;
  cols = Math.floor(w / colsize);
  rowsize = set.size + set.ygap;
  rows = Math.ceil(h / rowsize);
  coffs = Math.floor((w - cols * colsize) / 2);
  roffs = -set.ygap / 2;
  minfps = Math.floor(opts.fps * opts.minspeed);
  maxfps = Math.max(minfps, Math.floor(opts.fps * opts.maxspeed));
}

function init_matrix() {
  const frag = document.createDocumentFragment();
  const bkgd = document.getElementById('cels');
  if (opts.theme == 3) bkgd.setAttribute('class', 'atari'); else bkgd.removeAttribute('class');
  const docstyle = document.documentElement.style;
  docstyle.setProperty('--cel-fade-time', `${opts.fadetime}s`);
  docstyle.setProperty('--cel-font-size', `${set.size}px`);
  docstyle.setProperty('--cel-width', `${colsize}px`);
  docstyle.setProperty('--cel-height', `${rowsize}px`);
  bkgd.style.background = colors.fill;

  function new_cel(d, x, y) {
    const cel = document.createElement('div');
    cel.style.left = `${x}px`;
    cel.style.top = `${y}px`;

    cel.rand = () => {
      cel.textContent = chars.charAt(rndint(chars.length));
      if (opts.flip) cel.classList = Math.random() < 0.5 ? ['flop'] : [];
    };

    cel.start = () => {
      cel.style.display = 'none';
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

  let celsArray = Array(cols);
  let x = coffs;
  for (let c = 0; c < cols; c++) {
    celsArray[c] = Array(rows);
    var y = roffs;
    for (let r = 0; r < rows; r++) {
      celsArray[c][r] = new_cel(frag, x, y);
      y += rowsize;
    }
    x += colsize;
  }

  bkgd.appendChild(frag);
  return celsArray;
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

// Init a new or existing drop
function initdrop(drop) {
  drop.y = -rndint(rows * opts.respawn) - 5;
  drop.int = minfps + rndint(maxfps - minfps);
  drop.cnt = 0;
  return drop;
}

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
    if (y > 0) cels[i][y-1].style.color = colors.tail;
    if (y >= rows)
      initdrop(drops[i]);
    else
      cels[i][y].start();
  }
}

function init() {
  // Clear any existing timer
  if (updateTimer) clearInterval(updateTimer);
  updateTimer = null;
  // Clear existing cels
  const celsDiv = document.getElementById('cels');
  if (celsDiv) celsDiv.innerHTML = '';
  // Clear existing overlay
  const overlay = document.getElementById("overlay");
  if (overlay) overlay.setAttribute('style', 'display: none;');

  colors = get_colors(opts.theme);
  getChars();

  init_overlay(opts.overlay, w, h, colors.fill);
  cels = init_matrix();

  drops = [];
  for (var x = 0; x < cols; x++) drops.push(initdrop({}));

  updateTimer = setInterval(update, 1000 / opts.fps);
}

// Apply settings injected by the config sheet (called after page load)
window.applySettings = function(settings) {
  for (const key of Object.keys(settings)) {
    if (key in opts) opts[key] = settings[key];
  }
  init();
};

// Start the animation
init();
