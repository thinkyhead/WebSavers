/**
 * Starfield Screensaver
 *
 * Javascript based on CodePen sketch:
 *   - https://codepen.io/nodws/pen/pejBNb
 */

"use strict";

var numStars = 6000;

function rndint(n) { return Math.floor(Math.random() * n); }

// Based on an Example by @curran
window.requestAnimFrame = (function() { return window.requestAnimationFrame; })();

const c = document.getElementById("starfield"), ctx = c.getContext("2d"),
      w = window.innerWidth, h = window.innerHeight,
      centerX = w / 2, centerY = h / 2,
      focalLength = w * 2;

c.width = w; c.height = h;

var stars = [];
function initializeStars() {
  for (var i = 0; i < numStars; i++) {
    const o = '0.' + rndint(99) + 0;
    stars[i] = { x:w*Math.random(), y:h*Math.random(), z:w*Math.random(), o:o, s:`rgba(255,255,255,${o})` };
  }
  c.setAttribute('class', 'ready');
}

const starSpeed = rndint(5) + 5;
function moveStars() {
  for (var i = 0; i < numStars; i++) {
    var star = stars[i];
    if ((star.z -= starSpeed) <= 0) star.z = w;
  }
}

function drawStars() {
  ctx.clearRect(0, 0, w, h);
  for (var i = 0; i < numStars; i++) {
    const star = stars[i],
          pixelR = focalLength / star.z,
          pixelX = centerX + (star.x - centerX) * pixelR,
          pixelY = centerY + (star.y - centerY) * pixelR;
    ctx.fillStyle = star.s;
    ctx.fillRect(pixelX, pixelY, pixelR, pixelR);
  }
}

function executeFrame() {
  requestAnimFrame(executeFrame);
  moveStars();
  drawStars();
}

initializeStars();
executeFrame();
