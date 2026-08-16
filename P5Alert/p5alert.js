// P5Alert — p5.js flow field dashboard with floating gauges and alerts
// No DOM buttons (any interaction closes the saver). All visuals are
// drawn in p5. Alerts float in space and auto-fade, only once.
"use strict";

// ─── Alert state ─────────────────────────────────────────────────
const ALERT_SHOWN_KEY = "p5alert_shown_v1";
let alertShown = false;
let alertAlpha = 0;
let alertTargetAlpha = 0;
let alertText = "";
let alertTitle = "";

// ─── Live stats (updated from ObjC via window.applySystemStats) ──
let stats = { cpu: 0, memory: 0, memTotal: 64, memActive: 0, memWired: 0, memCompressed: 0, temperature: 0 };

window.applySystemStats = function(s) {
  stats = s;
};

// ─── p5.js sketch ─────────────────────────────────────────────────
const sketch = (p) => {
  const NUM_PARTICLES = 300;
  const SCALE = 20;
  let cols, rows;
  let particles = [];
  let flowField = [];
  let zOff = 0;
  let gaugeAngle = 0;

  p.setup = () => {
    p.createCanvas(p.windowWidth, p.windowHeight);
    p.pixelDensity(1);
    p.colorMode(p.HSB, 360, 100, 100, 100);
    p.background(220, 50, 5);

    cols = Math.floor(p.width / SCALE);
    rows = Math.floor(p.height / SCALE);

    for (let i = 0; i < NUM_PARTICLES; i++) {
      particles.push(new Particle(p));
    }

    // Show alert if never shown
    try {
      if (!localStorage.getItem(ALERT_SHOWN_KEY)) {
        alertTitle = "P5Alert";
        alertText = "Flow-field dashboard\nCPU  Memory  Temperature\n\nClick anywhere to dismiss";
        alertTargetAlpha = 100;
        alertShown = false;
      } else {
        alertShown = true;
      }
    } catch (e) {}
  };

  p.windowResized = () => {
    p.resizeCanvas(p.windowWidth, p.windowHeight);
    cols = Math.floor(p.width / SCALE);
    rows = Math.floor(p.height / SCALE);
  };

  p.mousePressed = () => {
    // Click dismisses the alert permanently
    if (!alertShown && alertAlpha > 5) {
      alertTargetAlpha = 0;
      alertShown = true;
      try { localStorage.setItem(ALERT_SHOWN_KEY, "1"); } catch (e) {}
    }
  };

  p.draw = () => {
    // Semi-transparent background for trail effect
    p.noStroke();
    p.fill(220, 50, 5, 8);
    p.rect(0, 0, p.width, p.height);

    // Compute flow field
    let yOff = 0;
    for (let y = 0; y < rows; y++) {
      let xOff = 0;
      for (let x = 0; x < cols; x++) {
        const index = x + y * cols;
        const angle = p.noise(xOff, yOff, zOff) * p.TWO_PI * 2;
        const v = p5.Vector.fromAngle(angle);
        v.setMag(1);
        flowField[index] = v;
        xOff += 0.1;
      }
      yOff += 0.1;
    }
    zOff += 0.005;

    // Draw particles
    particles.forEach((particle) => {
      particle.follow(flowField);
      particle.update();
      particle.edges();
      particle.show(p);
    });

    // Draw gauges as overlay
    drawGauges(p);

    // Draw floating alert
    drawAlert(p);

    gaugeAngle += 0.005;
  };

  function drawGauges(pt) {
    const cx = pt.width * 0.25;
    const cy = pt.height * 0.25;
    const spacing = 120;
    const gaugeRadius = 40;

    // CPU gauge (top-left)
    drawCircularGauge(pt, cx, cy, gaugeRadius, stats.cpu / 100, "CPU", stats.cpu.toFixed(0) + "%");

    // Memory gauge (top-center)
    const memPct = stats.memTotal > 0 ? stats.memory / stats.memTotal : 0;
    drawCircularGauge(pt, cx + spacing, cy, gaugeRadius, memPct, "MEM", stats.memory.toFixed(1) + "G");

    // Temperature gauge (top-right)
    drawCircularGauge(pt, cx + spacing * 2, cy, gaugeRadius, Math.min(stats.temperature / 100, 1), "TEMP", stats.temperature.toFixed(0) + "°");
  }

  function drawCircularGauge(pt, x, y, r, pct, label, valueStr) {
    pt.push();
    pt.translate(x, y);

    // Outer ring
    pt.noFill();
    pt.stroke(220, 30, 40, 60);
    pt.strokeWeight(2);
    pt.ellipse(0, 0, r * 2, r * 2);

    // Arc for value
    const startAngle = -p.HALF_PI;
    const endAngle = startAngle + p.TWO_PI * Math.min(Math.max(pct, 0), 1);

    pt.noFill();
    // Color shifts from cyan to red as pct increases
    const hue = p.lerp(190, 0, pct);
    pt.stroke(hue, 80, 90, 90);
    pt.strokeWeight(4);
    pt.strokeCap(p.PROJECT);
    pt.arc(0, 0, r * 2, r * 2, startAngle, endAngle);

    // Needle
    const needleAngle = startAngle + p.TWO_PI * Math.min(Math.max(pct, 0), 1);
    pt.stroke(0, 0, 100, 90);
    pt.strokeWeight(2);
    pt.line(0, 0, Math.cos(needleAngle) * r * 0.8, Math.sin(needleAngle) * r * 0.8);

    // Center dot
    pt.noStroke();
    pt.fill(0, 0, 100, 90);
    pt.ellipse(0, 0, 5, 5);

    // Label
    pt.noStroke();
    pt.fill(220, 20, 70, 80);
    pt.textAlign(p.CENTER, p.CENTER);
    pt.textSize(10);
    pt.text(label, 0, r + 12);

    // Value
    pt.fill(0, 0, 100, 90);
    pt.textSize(11);
    pt.text(valueStr, 0, 0);

    pt.pop();
  }

  function drawAlert(pt) {
    if (alertAlpha <= 0.5) return;

    // Smooth fade
    alertAlpha = p.lerp(alertAlpha, alertTargetAlpha, 0.05);
    if (alertAlpha < 0.5) return;

    pt.push();
    pt.translate(pt.width / 2, pt.height / 2);

    // Card background
    const cardW = 320;
    const cardH = 160;
    pt.noStroke();
    pt.fill(220, 30, 15, alertAlpha * 0.85);
    pt.rectMode(p.CENTER);
    pt.rect(0, 0, cardW, cardH, 12);

    // Card border
    pt.noFill();
    pt.stroke(200, 60, 70, alertAlpha * 0.3);
    pt.strokeWeight(1);
    pt.rect(0, 0, cardW, cardH, 12);

    // Title
    pt.noStroke();
    pt.fill(200, 60, 80, alertAlpha);
    pt.textAlign(p.CENTER, p.CENTER);
    pt.textSize(16);
    pt.textStyle(p.BOLD);
    pt.text(alertTitle, 0, -45);

    // Message
    pt.textStyle(p.NORMAL);
    pt.textSize(11);
    pt.fill(0, 0, 90, alertAlpha * 0.7);
    pt.text(alertText, 0, 10);

    pt.pop();
  }

  class Particle {
    constructor(p) {
      this.pos = p.createVector(p.random(p.width), p.random(p.height));
      this.vel = p.createVector(0, 0);
      this.acc = p.createVector(0, 0);
      this.maxSpeed = p.random(1.5, 3.5);
      this.prevPos = this.pos.copy();

      // Teal/blue hue with some variation
      const hue = p.random(170, 210);
      this.col = p.color(hue, p.random(50, 80), p.random(70, 100), p.random(60, 160));
    }

    follow(field) {
      const x = Math.floor(this.pos.x / SCALE);
      const y = Math.floor(this.pos.y / SCALE);
      const index = x + y * cols;
      if (field[index]) {
        const force = field[index].copy();
        force.setMag(0.5);
        this.applyForce(force);
      }
    }

    applyForce(force) {
      this.acc.add(force);
    }

    update() {
      this.vel.add(this.acc);
      this.vel.limit(this.maxSpeed);
      this.pos.add(this.vel);
      this.acc.mult(0);
    }

    show(pt) {
      pt.stroke(this.col);
      pt.strokeWeight(1);
      pt.line(this.pos.x, this.pos.y, this.prevPos.x, this.prevPos.y);
      this.updatePrev();
    }

    updatePrev() {
      this.prevPos.x = this.pos.x;
      this.prevPos.y = this.pos.y;
    }

    edges() {
      if (this.pos.x > p.width) {
        this.pos.x = 0;
        this.updatePrev();
      }
      if (this.pos.x < 0) {
        this.pos.x = p.width;
        this.updatePrev();
      }
      if (this.pos.y > p.height) {
        this.pos.y = 0;
        this.updatePrev();
      }
      if (this.pos.y < 0) {
        this.pos.y = p.height;
        this.updatePrev();
      }
    }
  }
};

new p5(sketch);

// Settings (for config sheet, if any)
window.applySettings = function(settings) {
  // Currently no settings
};
