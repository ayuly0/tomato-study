/**
 * Tomato Study — Interactive App Simulator & Web Controller
 * Zero external dependencies. Adheres to antislop-ui guidelines (no emojis).
 */

(function () {
  'use strict';

  // =========================================================================
  // 1. Procedural Starfield Simulator (Canvas)
  // =========================================================================
  const canvas = document.getElementById('mockup-canvas');
  if (canvas) {
    const ctx = canvas.getContext('2d');
    let width = (canvas.width = canvas.offsetWidth);
    let height = (canvas.height = canvas.offsetHeight);

    const stars = [];
    const NUM_STARS = 45;
    let mouseX = width / 2;
    let mouseY = height / 2;
    let targetMouseX = mouseX;
    let targetMouseY = mouseY;

    for (let i = 0; i < NUM_STARS; i++) {
      stars.push({
        x: Math.random() * width,
        y: Math.random() * height,
        radius: Math.random() * 1.2 + 0.3,
        alpha: Math.random() * 0.7 + 0.2,
        speed: Math.random() * 0.3 + 0.05,
      });
    }

    const mockupBody = canvas.parentElement;
    if (mockupBody) {
      mockupBody.addEventListener('mousemove', (e) => {
        const rect = mockupBody.getBoundingClientRect();
        targetMouseX = e.clientX - rect.left;
        targetMouseY = e.clientY - rect.top;
      });
    }

    window.addEventListener('resize', () => {
      if (canvas.offsetWidth && canvas.offsetHeight) {
        width = canvas.width = canvas.offsetWidth;
        height = canvas.height = canvas.offsetHeight;
      }
    });

    function drawStars() {
      ctx.clearRect(0, 0, width, height);

      // Smooth mouse easing
      mouseX += (targetMouseX - mouseX) * 0.04;
      mouseY += (targetMouseY - mouseY) * 0.04;

      const offsetX = (mouseX - width / 2) * 0.03;
      const offsetY = (mouseY - height / 2) * 0.03;

      for (let i = 0; i < stars.length; i++) {
        const s = stars[i];
        s.y -= s.speed;
        if (s.y < 0) {
          s.y = height;
          s.x = Math.random() * width;
        }

        ctx.beginPath();
        ctx.arc(s.x + offsetX, s.y + offsetY, s.radius, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(255, 255, 255, ${s.alpha})`;
        ctx.fill();
      }

      requestAnimationFrame(drawStars);
    }
    requestAnimationFrame(drawStars);
  }

  // =========================================================================
  // 2. Interactive Focus Timer Engine
  // =========================================================================
  const state = {
    mode: 'pomodoro', // 'pomodoro' | 'flowtime'
    state: 'work',    // 'work' | 'short_break' | 'long_break'
    isRunning: false,
    pomodoroMinutes: 25,
    secondsRemaining: 25 * 60,
    elapsedSeconds: 0,
    strictFocusActive: true,
    volume: 50,
    isMuted: false,
    zenMode: false,
    intervalId: null,
  };

  const minEl = document.getElementById('clock-min');
  const secEl = document.getElementById('clock-sec');
  const stateEl = document.getElementById('mockup-state-label');
  const cycleEl = document.getElementById('mockup-cycle-label');
  const playBtn = document.getElementById('btn-play');
  const resetBtn = document.getElementById('btn-reset');
  const modeBtn = document.getElementById('btn-mode');
  const strictBadge = document.getElementById('mockup-strict-badge');
  const volSlider = document.getElementById('mockup-vol-slider');
  const volLabel = document.getElementById('mockup-vol-val');
  const volIcon = document.getElementById('mockup-vol-icon');
  const mockupInterior = document.getElementById('mockup-interior');

  function pad(n) {
    return String(Math.floor(n)).padStart(2, '0');
  }

  function updateDisplay() {
    if (state.mode === 'pomodoro') {
      const m = Math.floor(state.secondsRemaining / 60);
      const s = state.secondsRemaining % 60;
      if (minEl) minEl.textContent = pad(m);
      if (secEl) secEl.textContent = pad(s);
    } else {
      const m = Math.floor(state.elapsedSeconds / 60);
      const s = state.elapsedSeconds % 60;
      if (minEl) minEl.textContent = pad(m);
      if (secEl) secEl.textContent = pad(s);
    }

    if (playBtn) {
      playBtn.textContent = state.isRunning ? 'Pause' : 'Start';
      if (state.isRunning) {
        playBtn.classList.add('active-running');
      } else {
        playBtn.classList.remove('active-running');
      }
    }

    if (stateEl) {
      if (state.mode === 'flowtime') {
        stateEl.textContent = 'FLOWTIME DEEP FOCUS';
      } else {
        stateEl.textContent = state.state === 'work' ? 'FOCUS WORK' : 'RESTORATIVE BREAK';
      }
    }

    if (modeBtn) {
      modeBtn.textContent = state.mode === 'pomodoro' ? 'Mode: Pomodoro' : 'Mode: Flowtime';
    }

    if (strictBadge) {
      strictBadge.style.display = state.strictFocusActive ? 'inline-flex' : 'none';
    }
  }

  function tick() {
    if (state.mode === 'pomodoro') {
      if (state.secondsRemaining > 0) {
        state.secondsRemaining--;
      } else {
        // Complete cycle
        state.state = state.state === 'work' ? 'short_break' : 'work';
        state.secondsRemaining = (state.state === 'work' ? state.pomodoroMinutes : 5) * 60;
      }
    } else {
      state.elapsedSeconds++;
    }
    updateDisplay();
  }

  function start() {
    if (state.isRunning) return;
    state.isRunning = true;
    state.intervalId = setInterval(tick, 1000);
    updateDisplay();
  }

  function pause() {
    if (!state.isRunning) return;
    state.isRunning = false;
    clearInterval(state.intervalId);
    state.intervalId = null;
    updateDisplay();
  }

  function togglePlay() {
    if (state.isRunning) {
      pause();
    } else {
      start();
    }
  }

  function reset() {
    pause();
    state.secondsRemaining = state.pomodoroMinutes * 60;
    state.elapsedSeconds = 0;
    state.state = 'work';
    updateDisplay();
  }

  function toggleMode() {
    pause();
    state.mode = state.mode === 'pomodoro' ? 'flowtime' : 'pomodoro';
    reset();
  }

  function toggleStrict() {
    state.strictFocusActive = !state.strictFocusActive;
    updateDisplay();
  }

  function toggleZen() {
    state.zenMode = !state.zenMode;
    if (mockupInterior) {
      mockupInterior.classList.toggle('zen-active', state.zenMode);
    }
  }

  // Button Listeners
  if (playBtn) playBtn.addEventListener('click', togglePlay);
  if (resetBtn) resetBtn.addEventListener('click', reset);
  if (modeBtn) modeBtn.addEventListener('click', toggleMode);
  if (strictBadge) strictBadge.addEventListener('click', toggleStrict);

  if (volSlider) {
    volSlider.addEventListener('input', (e) => {
      state.volume = parseInt(e.target.value, 10);
      state.isMuted = state.volume === 0;
      if (volLabel) volLabel.textContent = `${state.volume}%`;
      updateVolumeIcon();
    });
  }

  if (volIcon) {
    volIcon.addEventListener('click', () => {
      state.isMuted = !state.isMuted;
      if (state.isMuted) {
        if (volLabel) volLabel.textContent = 'Muted';
        if (volSlider) volSlider.value = 0;
      } else {
        if (state.volume === 0) state.volume = 50;
        if (volLabel) volLabel.textContent = `${state.volume}%`;
        if (volSlider) volSlider.value = state.volume;
      }
      updateVolumeIcon();
    });
  }

  function updateVolumeIcon() {
    if (!volIcon) return;
    if (state.isMuted || state.volume === 0) {
      volIcon.innerHTML = '<polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"></polygon><line x1="23" y1="9" x2="17" y2="15"></line><line x1="17" y1="9" x2="23" y2="15"></line>';
    } else {
      volIcon.innerHTML = '<polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"></polygon><path d="M15.54 8.46a5 5 0 0 1 0 7.07"></path>';
    }
  }

  // Keyboard Shortcuts within window
  window.addEventListener('keydown', (e) => {
    // Only capture if not focused in an input/textarea
    if (['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) return;

    if (e.code === 'Space') {
      e.preventDefault();
      togglePlay();
    } else if (e.key === 'r' || e.key === 'R') {
      reset();
    } else if (e.key === 'z' || e.key === 'Z') {
      toggleZen();
    }
  });

  // Initial draw
  updateDisplay();

  // =========================================================================
  // 3. Setup Tabs Controller
  // =========================================================================
  document.querySelectorAll('.tab-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.tab-btn').forEach((b) => b.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach((c) => c.classList.remove('active'));
      btn.classList.add('active');
      const target = document.getElementById(btn.getAttribute('data-target'));
      if (target) target.classList.add('active');
    });
  });

  // Copy Snippet Global
  window.copySnippet = function (btn) {
    const code = btn.parentElement.querySelector('code').innerText;
    navigator.clipboard.writeText(code).then(() => {
      const orig = btn.innerText;
      btn.innerText = 'Copied';
      setTimeout(() => {
        btn.innerText = orig;
      }, 1500);
    });
  };

  // Export state API for testing verification
  window.tomatoSimulator = {
    getState: () => ({ ...state }),
    start,
    pause,
    reset,
    toggleMode,
    toggleStrict,
    toggleZen,
  };
})();
