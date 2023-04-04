/**
 * Matrix Screensaver
 *
 * This version of the classic screensaver uses a large number of divs
 * with css animation to achieve a cleaner result than canvas fill.
 */
"use strict";

function rndint(n) { return Math.floor(Math.random() * n); }

const fixed_col = 0,  // Use a fixed number of columns or 0 for the default font size
      theme = 0,      // 0: Green, 1: Amber, 2: Light, 3: Atari 800
      overlay = 1,    // 0: none, 1: scanlines, 2: shadowmask
      oalpha = overlay == 1 ? 0.8 : 0.6,
      flipping = true,
      fps = 30,
      fadetime = 3;   // (seconds)

function get_colors(t) {
  switch (t) {
    default: return { drop:"#FFF", tail:"#0F0", fill:"#000" };    // Green
    case 1:  return { drop:"#FFF", tail:"#FA0", fill:"#000" };    // Amber
    case 2:  return { drop:"#F00", tail:"#0F0", fill:"#FFF" };    // Light
    case 3:  return { drop:"#FF0", tail:"#EEF", fill:"#6A6AEE" }; // Atari
  }
}
const colors = get_colors(theme), dotail = colors.drop != colors.tail;

const chinese = { chr:"田由甲申甴电甶男甸甹町画甼甽甾甿畀畁畂畃畄畅畆畇畈畉畊畋界畍畎畏畐畑", size:24, xgap:0, ygap:0, drat:12 },
      alphanum = { chr:"ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", size:22, xgap:2, ygap:2, drat:11 },
      katakana = { chr:"ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", size:24, xgap:2, ygap:2, drat:12 },
      katakana2 = { chr:"アァカサタナハマヤャラワガザダバパイィキシチニヒミリヰギジヂビピウゥクスツヌフムユュルグズブヅプエェケセテネヘメレヱゲゼデベペオォコソトノホモヨョロヲゴゾドボポヴッンABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", size:22, xgap:6, ygap:4, drat:1000 },
      thinkycs = { chr:"TtHhIiNnKkYyEeAaDd1347", size:18, xgap:2, ygap:2, drat:9 },
      set = theme == 3 ? alphanum : (rndint(200) ? katakana2 : thinkycs),
      chars = set.chr,
      font = theme == 3 ? 'Atari Classic' : 'arial';

// Globals for window size
const w = window.innerWidth, h = window.innerHeight;

// Get fontsize from the set or based on columns
const fontsize = fixed_col ? w / fixed_col : set.size;

// Column size and number of columns
const colsize = fontsize + set.xgap, cols = Math.floor(w / colsize),
      rowsize = fontsize + set.ygap, rows = Math.floor(h / rowsize),
      coffs = Math.floor((w - cols * colsize) / 2),
      roffs = -set.ygap / 2;

function celstart(cel) {
  if (cel.timer) clearTimeout(cel.timer);
  cel.innerHTML = chars.charAt(rndint(chars.length));
  cel.style.color = colors.drop;
  if (flipping) cel.style.transform = Math.random() < 0.5 ? "rotate(180deg)" : undefined;
  cel.style.display = 'block';
  cel.timer = setTimeout(() => { cel.timer = undefined; cel.style.display = 'none'; }, fadetime * 1000);
}

function new_cel(d, x, y, w, h, f, s) {
  const cel = document.createElement('div');
  cel.setAttribute('class', 'cel');
  cel.style.left = `${x}px`;
  cel.style.top = `${y}px`;
  cel.style.width = `${w}px`;
  cel.style.height = `${h}px`;
  cel.style.fontFamily = f;
  cel.style.fontSize = `${s}px`;
  cel.style.color = 'white';
  cel.style.animationDuration = `${fadetime}s`;

  //cel.style = `display:none; left:${x}px; top:${y}px; width:${w}px; height:${h}px; font-family:${f}; font-size:${s}px; color:white; opacity; animation-duration:${fadetime}s`;

  // Use a timeout so the js loop gets called beforehand
  // and has a chance to see that the style display became 'none'
  cel.start = ()=>{
    cel.style.display = 'none';
    setTimeout(() => { celstart(cel); }, 2);
  };
  d.appendChild(cel);
  return cel;
}

const bkgd = document.getElementById('container');
bkgd.style.background = colors.fill;

// Make many cels
var cels = [];
var x = coffs;
for (let c = 0; c < cols; c++) {
  cels[c] = [];
  var y = roffs;
  for (let r = 0; r < rows; r++) {
    cels[c][r] = new_cel(bkgd, x, y, fontsize, fontsize, font, fontsize);
    cels[c][r].info = { c:c, r:r };
    y += rowsize;
  }
  x += colsize;
}

// Draw or hide the overlay
function init_overlay(ov, w, h, fill) {
  const o = document.getElementById("overlay");
  if (!ov) return o.setAttribute('style', 'display:none');

  const ctx = o.getContext("2d");

  o.width = w; o.height = h;
  ctx.clearRect(0, 0, w, h);

  ctx.globalAlpha = oalpha;
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

init_overlay(overlay, w, h, colors.fill);

// Init a new or existing drop
function initdrop(drop) {
  drop.y = -rndint(rows * 4) - 5;
  drop.int = (fps + rndint(fps)) / 2;
  drop.cnt = fps / 2;
  return drop;
}

// Create an array of drops, one per column
var drops = [];
for (var x = 0; x < cols; x++) drops.push(initdrop({}));

// Update the drops array and init cels whenever drops advance
function update() {
  for (var i = 0; i < cols; i++) {
    var drop = drops[i];
    if ((drop.cnt -= drop.int) > 0) continue;
    drop.cnt += fps;
    const y = ++drop.y;
    if (y < 0) continue;
    if (dotail && y > 0) cels[i][y-1].style.color = colors.tail;
    if (y >= rows)
      initdrop(drops[i]);
    else
      cels[i][y].start();
  }
}

setInterval(update, 1000 / fps);
