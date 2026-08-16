// P5Alert — p5.js flow field with one-time alert overlay
// The alert shows on first run, is dismissed on click, and never shows again
// (until the saver is reinstalled or settings are reset).
"use strict";

// ─── Alert overlay ───────────────────────────────────────────────
const ALERT_SHOWN_KEY = "p5alert_shown";
const alertOverlay = document.getElementById("alert-overlay");
const dismissBtn = document.getElementById("alert-dismiss");

function showAlert() {
  alertOverlay.classList.remove("hidden");
}

function hideAlert() {
  alertOverlay.classList.add("hidden");
  try { localStorage.setItem(ALERT_SHOWN_KEY, "1"); } catch (e) {}
}

// Show alert only if it hasn't been shown before
if (!localStorage.getItem(ALERT_SHOWN_KEY)) {
  showAlert();
} else {
  hideAlert();
}

dismissBtn.addEventListener("click", hideAlert);

// ─── p5.js flow field sketch ─────────────────────────────────────
const sketch = (p) => {
  const NUM_PARTICLES = 350;
  const SCALE = 18;
  let cols, rows;
  let particles = [];
  let flowField = [];
  let zOff = 0;

  p.setup = () => {
    p.createCanvas(p.windowWidth, p.windowHeight);
    p.pixelDensity(1);
    p.background(5, 5, 10);

    cols = Math.floor(p.width / SCALE);
    rows = Math.floor(p.height / SCALE);

    for (let i = 0; i < NUM_PARTICLES; i++) {
      particles.push(new Particle(p));
    }
  };

  p.windowResized = () => {
    p.resizeCanvas(p.windowWidth, p.windowHeight);
    cols = Math.floor(p.width / SCALE);
    rows = Math.floor(p.height / SCALE);
  };

  p.draw = () => {
    // Semi-transparent background for trail effect
    p.noStroke();
    p.fill(5, 5, 10, 18);
    p.rect(0, 0, p.width, p.height);

    // Compute flow field from Perlin noise
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

    // Update and draw particles
    particles.forEach((particle) => {
      particle.follow(flowField);
      particle.update();
      particle.edges();
      particle.show(p);
    });
  };

  class Particle {
    constructor(p) {
      this.pos = p.createVector(p.random(p.width), p.random(p.height));
      this.vel = p.createVector(0, 0);
      this.acc = p.createVector(0, 0);
      this.maxSpeed = p.random(1.5, 3.5);
      this.prevPos = this.pos.copy();

      // Color each particle with a teal/blue tint
      const hue = p.random(170, 210);
      this.col = p.color(
        p.random(60, 120),
        p.random(140, 200),
        p.random(180, 255),
        p.random(100, 200)
      );
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
