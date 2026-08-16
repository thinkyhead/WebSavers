// HermesBoard — screensaver dashboard logic
"use strict";

// ─── Settings (defaults mirror ObjC ScreenSaverDefaults) ───
let showClock = true, clockTop = true, showSeconds = true, showImage = false;

// ─── THREE.js background atoms ───
const canvas = document.getElementById('bg-canvas');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
renderer.setPixelRatio(window.devicePixelRatio);
renderer.setSize(window.innerWidth, window.innerHeight);
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.z = 30;
scene.add(new THREE.AmbientLight(0x00ff66, 0.25));
const pl = new THREE.PointLight(0x00ff66, 1.2, 80); pl.position.set(10, 10, 20); scene.add(pl);
const pl2 = new THREE.PointLight(0x0088ff, 0.6, 60); pl2.position.set(-15, -10, 15); scene.add(pl2);

class Atom {
  constructor(i) {
    this.index = i;
    this.baseRotSpeed = 0.003 + Math.random() * 0.006;
    this.rotS = new THREE.Vector3((Math.random()-0.5)*this.baseRotSpeed, (Math.random()-0.5)*this.baseRotSpeed, (Math.random()-0.5)*this.baseRotSpeed);
    this.baseOrbitSpeed = 0.3 + Math.random() * 0.8;
    this.spd = this.baseOrbitSpeed;
    this.pos = new THREE.Vector3((Math.random()-0.5)*40, (Math.random()-0.5)*25, (Math.random()-0.5)*20);
    this.rad = 0.7 + Math.random() * 1.0;
    this.phase = Math.random() * Math.PI * 2;
    this.intensity = 0;
    const ng = new THREE.IcosahedronGeometry(0.35, 0);
    const nm = new THREE.MeshBasicMaterial({ color: Math.random()>0.5 ? 0x00ff66 : 0x0088ff, wireframe: true, transparent: true, opacity: 0.7 });
    this.nuc = new THREE.Mesh(ng, nm);
    this.nuc.position.copy(this.pos);
    scene.add(this.nuc);
    const eg = new THREE.SphereGeometry(0.1, 6, 6);
    this.elec = new THREE.Mesh(eg, new THREE.MeshBasicMaterial({ color: 0xffffff }));
    scene.add(this.elec);
  }
  setIntensity(val) { this.intensity = Math.min(1, val); }
  update(t) {
    const boost = 1 + this.intensity * 4;
    this.nuc.rotation.x += this.rotS.x * boost;
    this.nuc.rotation.y += this.rotS.y * boost;
    this.nuc.material.opacity = 0.5 + this.intensity * 0.5;
    this.nuc.scale.setScalar(1 + this.intensity * 0.3);
    const a = t * this.spd * boost + this.phase;
    this.elec.position.set(this.pos.x + Math.cos(a)*this.rad, this.pos.y + Math.sin(a)*this.rad, this.pos.z + Math.sin(a*0.7)*0.3);
    this.elec.material.color.setHex(this.intensity > 0.5 ? 0xff4444 : 0xffffff);
  }
}
const atoms = [];
for (let i = 0; i < 20; i++) atoms.push(new Atom(i));
const pg = new THREE.BufferGeometry();
const pp = new Float32Array(100 * 3);
for (let i = 0; i < 100; i++) { pp[i*3]=(Math.random()-0.5)*60; pp[i*3+1]=(Math.random()-0.5)*40; pp[i*3+2]=(Math.random()-0.5)*30-10; }
pg.setAttribute('position', new THREE.BufferAttribute(pp, 3));
scene.add(new THREE.Points(pg, new THREE.PointsMaterial({ color: 0x00ff44, size: 0.05, transparent: true, opacity: 0.25 })));
function animate(time) { requestAnimationFrame(animate); atoms.forEach(a => a.update(time*0.001)); renderer.render(scene, camera); }
animate(0);
window.addEventListener('resize', () => { camera.aspect = window.innerWidth/window.innerHeight; camera.updateProjectionMatrix(); renderer.setSize(window.innerWidth, window.innerHeight); });

// ─── Clock ───
function pad(n) { return n < 10 ? '0' + n : '' + n; }
function updateClock() {
  const d = new Date();
  const secs = showSeconds ? ':' + pad(d.getSeconds()) : '';
  document.getElementById('clock-time').textContent = pad(d.getHours()) + ':' + pad(d.getMinutes()) + secs;
  document.getElementById('clock-date').textContent = d.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
}
function layoutClock() {
  document.getElementById('clock-panel').classList.toggle('hidden', !showClock);
  document.getElementById('dashboard').classList.toggle('clock-bottom', !clockTop);
}

// ─── Gauges ───
const gauges = {};
function buildGauge(id, title, opts) {
  const card = document.createElement('div');
  card.className = 'gauge-card';
  card.id = 'gcard-' + id;
  const cv = document.createElement('canvas');
  cv.id = 'g-' + id;
  card.appendChild(cv);
  const t = document.createElement('div');
  t.className = 'gauge-title';
  t.textContent = title;
  card.appendChild(t);
  document.getElementById('gauges-col').appendChild(card);

  const cfg = Object.assign({
    renderTo: cv,
    width: 180, height: 180,
    units: '',
    minValue: 0, maxValue: 100,
    majorTicks: ['0','25','50','75','100'],
    minorTicks: 4,
    strokeTicks: false,
    highlights: [{ from: 80, to: 100, color: 'rgba(239,68,68,0.25)' }],
    colorPlate: 'rgba(10,15,12,0)',
    colorMajorTicks: '#0a0f0c',
    colorMinorTicks: '#0f0',
    colorNumbers: 'rgba(0,255,100,0.6)',
    colorNeedle: '#0f0',
    colorNeedleEnd: '#0f0',
    colorNeedleCircleOuter: '#0f0',
    colorNeedleCircleInner: '#fff',
    colorNeedleShadowUp: 'rgba(0,0,0,0)',
    colorNeedleShadowDown: 'rgba(0,0,0,0)',
    colorValueBox: 'rgba(0,0,0,0)',
    colorValueText: '#0f0',
    valueBox: true,
    fontValue: 'Menlo',
    fontNumbers: 'Menlo',
    animation: true,
    animationDuration: 500
  }, opts || {});
  gauges[id] = new RadialGauge(cfg);
  gauges[id].draw();
  return gauges[id];
}

function setGauge(id, value) {
  if (gauges[id]) gauges[id].value = value;
}

function clearGauges() {
  document.getElementById('gauges-col').innerHTML = '';
  for (const k in gauges) delete gauges[k];
}

// Build a set of system gauges
function renderSystemGauges() {
  clearGauges();
  buildGauge('cpu', 'CPU', { maxValue: 100, majorTicks: ['0','25','50','75','100'] });
  buildGauge('memory', 'MEMORY', { maxValue: 32, majorTicks: ['0','8','16','24','32'], units: 'GB' });
  buildGauge('temp', 'TEMP', { maxValue: 100, majorTicks: ['0','25','50','75','100'], units: '°C' });
}

// ─── Feed rendering ───
function renderFeedStats(stats) {
  const extra = {};
  for (const [k, v] of Object.entries(stats)) {
    const kl = k.toLowerCase();
    if (kl.includes('cpu')) setGauge('cpu', parseFloat(String(v))||0);
    else if (kl.includes('memory') || kl.includes('mem')) setGauge('memory', parseFloat(String(v))||0);
    else if (kl.includes('temp')) setGauge('temp', parseFloat(String(v))||0);
    else extra[k] = v;
  }
  // Show any extra non-system stats as small text rows below the gauges
  const col = document.getElementById('gauges-col');
  const existing = document.getElementById('extra-stats');
  if (existing) existing.remove();
  const keys = Object.keys(extra);
  if (keys.length) {
    const box = document.createElement('div');
    box.id = 'extra-stats';
    box.style.cssText = 'display:flex;flex-direction:column;gap:2px;';
    for (const k of keys) {
      const r = document.createElement('div');
      r.style.cssText = 'display:flex;justify-content:space-between;font-size:10px;padding:2px 6px;background:rgba(10,15,12,0.5);border-radius:3px;';
      r.innerHTML = `<span style="color:rgba(255,255,255,0.4)">${escapeHtml(k)}</span><span style="color:#0f0">${escapeHtml(String(extra[k]))}</span>`;
      box.appendChild(r);
    }
    col.appendChild(box);
  }
}

function renderMessages(messages) {
  const el = document.getElementById('messages-body');
  if (!messages || messages.length === 0) { el.innerHTML = '<div class="empty-state">No messages</div>'; return; }
  el.innerHTML = messages.slice(-6).reverse().map(m => {
    const t = m.time || '';
    const f = escapeHtml(m.from || 'System');
    const txt = escapeHtml(m.text || m.message || '');
    return `<div class="message"><span class="from">${f}</span>${txt}<span class="time">${t}</span></div>`;
  }).join('');
}

function renderAlerts(alerts) {
  const el = document.getElementById('alerts-body');
  if (!alerts || alerts.length === 0) { el.innerHTML = '<div class="empty-state">No alerts</div>'; return; }
  el.innerHTML = alerts.slice(0, 6).map(a => {
    const level = a.level || 'info';
    return `<div class="alert ${level}">${escapeHtml((a.text || a.message || '').substring(0, 50))}</div>`;
  }).join('');
}

function renderImage() {
  const panel = document.getElementById('image-panel');
  const img = document.getElementById('board-image');
  if (!showImage) { panel.style.display = 'none'; return; }
  panel.style.display = 'flex';
  img.src = IMAGE_URL + '?t=' + Date.now();
  img.onerror = () => { panel.innerHTML = '<div class="image-placeholder">No image</div>'; };
}

function escapeHtml(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }

// ─── Data sources ───
const FEED_URL = "file://" + (window.HOME || "/Users/thinkyhead") + "/Library/Application%20Support/WebSavers/HermesBoard/feed.json";
const IMAGE_URL = "file://" + (window.HOME || "/Users/thinkyhead") + "/Library/Application%20Support/WebSavers/HermesBoard/image.png";

let feedStats = {};
let liveStats = {};

async function checkFeed() {
  try {
    const resp = await fetch(FEED_URL + '?t=' + Date.now(), { cache: 'no-store' });
    if (!resp.ok) return;
    const data = await resp.json();
    feedStats = data.stats || {};
    renderFeedStats(Object.assign({}, liveStats, feedStats));
    if (data.messages) renderMessages(data.messages);
    if (data.alerts) renderAlerts(data.alerts);
    document.getElementById('status-dot').classList.remove('status-offline');
    document.getElementById('status-text').textContent = 'Connected';
    document.getElementById('last-update').textContent = 'Updated ' + new Date().toLocaleTimeString();
  } catch (e) {
    document.getElementById('status-dot').classList.add('status-offline');
    document.getElementById('status-text').textContent = 'Offline';
  }
}

window.applySystemStats = function(stats) {
  liveStats = {
    'CPU': stats.cpu.toFixed(1) + '%',
    'Memory': (stats.memory / (1024*1024*1024)).toFixed(1) + ' GB',
    'Temperature': stats.temperature.toFixed(0) + '°C'
  };
  renderFeedStats(Object.assign({}, liveStats, feedStats));
};

window.applySettings = function(s) {
  if (s.clock !== undefined) showClock = s.clock;
  if (s.clockPosition !== undefined) clockTop = !s.clockPosition;
  if (s.seconds !== undefined) showSeconds = s.seconds;
  if (s.image !== undefined) showImage = s.image;
  layoutClock();
  updateClock();
  renderImage();
};

// ─── Init ───
renderSystemGauges();
layoutClock();
updateClock();
setInterval(updateClock, 1000);
setInterval(checkFeed, 3000);
checkFeed();
renderImage();
