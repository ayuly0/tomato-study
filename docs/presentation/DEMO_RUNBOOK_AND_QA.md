# Tomato Study — Live Demo Runbook & Supervisor Q&A Defense Bank

This document serves as the tactical preparation guide for **Slide 8 (Live Demo)** and the **Q&A Defense Session** with supervisor [GVHD] and course evaluators.

---

## Part 1: Slide 8 Live Demo Runbook

### 1. Pre-Flight Checklist (15 Minutes Before Presentation)
- [ ] **Laptop Audio:** Set master volume to ~40%. Ensure audio output is directed to room speakers or HDMI.
- [ ] **Network Check:** Connect to room Wi-Fi (test `https://late.sh` ping).
  - *Offline Note:* If Wi-Fi is unstable, the timer works 100% offline. Audio stream can simply be skipped without breaking the demo.
- [ ] **Display Setup:** Resolution set to standard 1080p (1920x1080) at 100% or 125% scaling for optimal projector visibility.
- [ ] **App Staging:** Run `./run.sh` or `run.bat` in advance, position window centered on screen, then close it or keep it minimized.
- [ ] **Emergency Fallback Open:** Have `assets/main_preview.png` and `assets/settings_preview.png` open in an image viewer on a background virtual desktop just in case.

---

### 2. Live Demo Choreography (Duration: 90–120 Seconds)
Speaker: **Member 3** (or designated live operator)

```
[0:00] Initial Screen Walkthrough
  Action: Bring Tomato Study window to front (350x400 size).
  Speaking: "Here is Tomato Study on first launch. Notice our clean split-card flip clock and the session counter at the top: Focus Work, Session 1 of 4, set for 25 minutes."

[0:15] Play/Pause & Card Flip
  Action: Press [Space] on keyboard.
  Visual Cue: Cards flip with smooth 2.5D animation; countdown ticks down.
  Speaking: "Pressing Space starts our focus session immediately. Notice the satisfying mechanical flip animation."

[0:30] Settings Drawer
  Action: Press [S] on keyboard.
  Visual Cue: Sleek Settings panel slides in from the right.
  Speaking: "Pressing S opens our settings panel. Here, students can customize everything without stopping the timer."

[0:45] Clock Style & Presets
  Action: Click "Digital Clock" toggle, then switch Timer Preset to "Flowtime". Click outside to close settings.
  Visual Cue: UI switches to clean digital digits; timer displays 00:00 counting upwards.
  Speaking: "We can switch between our mechanical flip clock and a minimalist digital display. We just switched to Flowtime mode — now the clock counts upwards, keeping deep work uninterrupted."

[1:05] Zen Mode & Particle Background
  Action: Press [Z] on keyboard (or double-click background).
  Visual Cue: Window borders, buttons, and system cursor instantly vanish.
  Action: Gently move mouse in circular motion across the window.
  Visual Cue: GPU fragment shader generates glowing star dust trails behind the cursor.
  Speaking: "When students need zero distractions, pressing Z enters Zen Mode. All buttons and cursors disappear. Behind the clock, our custom OpenGL fragment shader renders drifting stars and shooting meteors that dynamically track mouse movement."

[1:25] Study Stream & Audio Control
  Action: Press [Z] to exit Zen Mode. Press [P] to start study stream, adjust volume slider, press [M] to mute.
  Visual Cue: Stream connects to late.sh; lo-fi music plays softly, then mutes instantly with M.
  Speaking: "Pressing P engages our built-in late.sh lo-fi study stream with zero advertisements, and M provides instant mute."

[1:40] Reset & Handover
  Action: Press [R] to reset.
  Speaking: "Pressing R resets the session, and we are ready for our next block. Let’s look at how we tested this."
```

---

### 3. Emergency Fallback Protocol (If Anything Goes Wrong)

| Failure Scenario | Immediate Action | What to Say |
|---|---|---|
| **No Internet / Wi-Fi drops** | Do not click stream [P]. Keep focus on timer and Zen mode. | *"Tomato Study’s core timer and OpenGL shaders operate completely offline. Only the background lo-fi stream requires internet, which is optional."* |
| **Projector cannot render OpenGL** | Set environment variable: `export QSG_RHI_BACKEND=software` or show preview images. | *"Because school projectors sometimes restrict GPU hardware acceleration, we prepared high-resolution captures of both the active workspace and our settings engine."* |
| **Accidental hotkey misfire** | Double click background or hit `[R]` to reset cleanly. | Keep composure: *"Notice how easily the hotkeys reset or toggle states with a single keypress."* |

---

## Part 2: Supervisor & Evaluator Q&A Defense Bank

### Category A: Technical Choices & Architecture

#### Q1: "Why did you build this with PySide6 and QML instead of web frameworks like Electron or Tauri?"
- **Defense Answer:**
  > "We evaluated Electron, Tauri, and native Qt. While Electron is popular for desktop apps, it bundles an entire Chromium browser and NodeJS runtime, consuming 150 to 300 megabytes of RAM just to display a clock. For students studying on laptops with limited battery and memory, that overhead is counterproductive.
  > 
  > PySide6 with Qt Quick (QML) gives us native C++ rendering performance, 60 FPS animations, and direct access to GPU fragment shaders via OpenGL RHI, all while staying under 50 MB of memory. Furthermore, QML allowed us to implement our 2.5D flip card math declaratively and cleanly."

#### Q2: "How does the OpenGL fragment shader work, and will it drain laptop battery during a 4-hour study session?"
- **Defense Answer:**
  > "Our background is powered by `shader.frag`, which is compiled to Qt’s binary shader package format (`shader.frag.qsb`). It computes procedural stars, shooting meteors, and mouse trails entirely on the GPU in a single render pass.
  > 
  > To ensure battery efficiency, the shader does not use expensive multi-pass raymarching or heavy texture sampling. It runs at standard display refresh rate and scales dynamically. During user testing on battery-powered student laptops, CPU utilization remained under 2%."

#### Q3: "How does your cross-platform shader compilation handle different operating systems?"
- **Defense Answer:**
  > "Qt 6 utilizes RHI (Rendering Hardware Interface). We pre-compile our fragment shader into `ui/shader.frag.qsb` so that end-users do not need a Qt SDK compiler installed on their machines.
  > 
  > In `src/main.py`, our `compile_shader()` function uses `shutil.which` to search dynamically for `qsb` or `pyside6-qsb` on both Linux and Windows. If the source file hasn't changed or if the compiler is absent, it seamlessly loads the pre-compiled binary package without throwing errors."

---

### Category B: Study Methodologies & User Experience

#### Q4: "Why combine both Pomodoro and Flowtime in one app? Isn't Pomodoro enough?"
- **Defense Answer:**
  > "Pomodoro is exceptionally effective when fighting initial procrastination and building daily study discipline. However, cognitive research shows that when students enter a 'flow state' — particularly in complex tasks like coding, essay writing, or mathematics — an abrupt alarm after 25 minutes forcibly breaks that concentration, taking up to 15 minutes to recover.
  > 
  > Flowtime solves this by counting up. By offering both in Tomato Study, a student can start their morning with Pomodoro to build momentum, and switch to Flowtime when tackling deep creative problem-solving."

#### Q5: "How does Flowtime calculate earned break times?"
- **Defense Answer:**
  > "In `src/timer.py`, we implement standard ergonomic study intervals:
  > - Focus under 25 minutes: 5-minute break
  > - Focus 25 to 50 minutes: 8-minute break
  > - Focus 50 to 90 minutes: 12-minute break
  > - Focus exceeding 90 minutes: 15-to-20-minute restorative break.
  > When the student finishes a Flowtime block, Tomato Study calculates the earned break time automatically and configures the break countdown."

---

### Category C: AI Usage & Engineering Integrity

#### Q6: "How did you use AI tools (Gemini and Claude), and how did you verify the code was correct and not hallucinated?"
- **Defense Answer:**
  > "We treated AI as a pair programmer, not an unverified code dumper. Our methodology was structured into three tiers:
  > 1. **Architecture & Scaffolding:** We designed the system boundaries ourselves (separating `TimerBackend` from QML view contexts).
  > 2. **Vibe Coding with Claude:** Used to rapidly draft boilerplate QML syntax, animation transitions, and UI layout grids.
  > 3. **Error Analysis & Diagnostics with Gemini:** When debugging complex issues — such as QAudioOutput stream restarts when `late.sh` experienced network jitter or OpenGL context initialization on Linux — we used Gemini to diagnose stack traces.
  > 4. **Rigorous Automated Testing:** Every single core logic module is validated by our test suite in `tests/test_timer.py` and `tests/test_audio.py` using `pytest`. We wrote 10 comprehensive unit tests verifying timer transitions, Flowtime formulas, and audio error recovery."

#### Q7: "What is the single biggest lesson your team learned during this project?"
- **Defense Answer:**
  > "The biggest lesson was the value of user-centered iteration and cross-platform realities. What worked flawlessly on one team member's Arch Linux machine required careful attention to paths and execution policies on Windows. Building automated installers (`install.sh`, `install.bat`, `install.ps1`) taught us that production software isn't just about code running in our terminal — it is about delivering a frictionless experience for the everyday student."
