# Tomato Study — Final Presentation Deck
**"Focus. Study. Be Productive."**

> **Course:** Introduction to the Major and Soft Skills (Semester 1, 2026–2027)  
> **Format:** 5 Speakers · ~10 Minutes Total · 14 Slides  
> **Supervisor:** [GVHD]  
> **Team Members:** [Member 1], [Member 2], [Member 3], [Member 4], [Member 5]

---

## Deck Overview & Timing Schedule

| Part | Topic | Speaker | Time | Slides |
|:---:|---|:---:|:---:|:---:|
| **Part 1** | Introduction & Purpose | **Member 1** | ~2.0 min | Slides 1 – 3 |
| **Part 2** | From Idea to Design | **Member 2** | ~2.0 min | Slides 4 – 5 |
| **Part 3** | Building Tomato Study | **Member 3** | ~2.5 min | Slides 6 – 9 |
| **Part 4** | Testing & Evaluation | **Member 4** | ~2.5 min | Slides 10 – 12 |
| **Part 5** | Summary & Conclusion | **Member 5** | ~1.0 min | Slides 13 – 14 |
| **Total** | **Full Project Defense** | **5 Speakers** | **~10.0 min** | **14 Slides** |

---

# Part 1 — Introduction & Purpose
*Speaker: Member 1 · Target Time: ~2 min · Slides 1–3*

---

### Slide 1: Title & Team Introduction
- **Slide Title:** Tomato Study
- **Subtitle:** “Focus. Study. Be Productive.”
- **Visual Blueprint:** 
  - Central dark card layout with glowing tomato red accent (`#e03131`).
  - App Logo / Icon prominently displayed alongside subtitle.
  - Left footer: Course details — *Introduction to the Major and Soft Skills (Semester 1, 2026–2027)* & Supervisor: *[GVHD]*.
  - Right footer: Full team roster with assigned presentation roles.
- **On-Slide Content:**
  - **Tomato Study** — Modern Focus & Study Timer
  - *Team Members:*
    - Member 1: Project Overview & Problem Framing
    - Member 2: Methodology & UI/UX Architecture
    - Member 3: Implementation & Feature Demonstration
    - Member 4: Quality Assurance, Feedback & Analysis
    - Member 5: Synthesis & Future Roadmap
  - *Supervisor:* [GVHD]
- **Speaker Notes (Member 1):**
  > "Good morning, respected teacher [GVHD] and fellow classmates. Welcome to our presentation. Today, our team is proud to introduce **Tomato Study**, an interactive desktop application created to help students like us focus, study, and be truly productive. Over the next ten minutes, our five team members will take you on the journey from the core study struggles we face every day, through our software design and vibe-coding development process, to our testing results and future vision. Let’s begin by looking at the exact challenge that inspired this project."

---

### Slide 2: The Problem — The Battle for Focus
- **Slide Title:** The Problem: Losing Focus While Studying
- **Visual Blueprint:**
  - Two-column contrast layout:
    - Left column: "The Modern Student Reality" (infographic of phone notifications, tab overload, study fatigue).
    - Right column: "The Psychological Cost" (broken flow state, procrastination loop, burnout).
- **On-Slide Content:**
  - **The Reality:**
    - Constant digital distractions: social media alerts, endless browser tabs, and notification fatigue.
    - Loss of attention within the first 10–15 minutes of independent study.
  - **The Friction:**
    - Rigid traditional timers cause anxiety rather than calm focus.
    - Existing desktop timers are either bloated with subscriptions or plain, clunky, and visually uninspiring.
  - **The Question:**
    - *How can we create a desktop workspace that actively invites calm, disciplined study?*
- **Speaker Notes (Member 1):**
  > "Have you ever sat down with all your books open, determined to study for hours, only to find your mind wandering after just ten minutes? We have experienced this countless times. Research shows that college students encounter digital distractions every few minutes, whether it is a phone ping, message notifications, or opening dozens of unrelated browser tabs. 
  > 
  > When we lose focus, getting back into deep work takes upwards of twenty minutes. Traditional kitchen timers or rigid phone apps often make this worse — they beep abruptly, clutter our screens, or tempt us with more phone notifications. We needed an environment right on our desktop that protects our attention instead of breaking it."

---

### Slide 3: Purpose & Learning Objectives
- **Slide Title:** Project Purpose & Applied Course Skills
- **Visual Blueprint:**
  - Three visual pillars / cards representing our triple goals:
    1. Product Purpose (The App)
    2. Engineering Skills (AI & Vibe Coding)
    3. Soft Skills (Teamwork, Agile, English Delivery)
- **On-Slide Content:**
  - **1. Product Purpose:**
    - Build a modern desktop timer implementing evidence-based study protocols (Pomodoro & Flowtime).
    - Provide an immersive, aesthetic, distraction-free environment with ambient lo-fi soundscapes.
  - **2. Technical & AI Practice:**
    - Leverage modern AI tools from concept to code generation, error diagnostics, and presentation prep.
    - Adopt production-ready packaging (`uv`, cross-platform installers).
  - **3. Soft Skills Mastery:**
    - Practice agile sprint planning, role division, code reviews on GitHub, and professional English delivery.
- **Speaker Notes (Member 1):**
  > "Our primary purpose was to solve this problem by building Tomato Study — an app that accurately tracks study time using modern, proven study methods, coupled with calming visuals and ambient lo-fi audio. 
  > 
  > But beyond just writing code, this project was our opportunity to put into practice every key skill from our 'Introduction to the Major and Soft Skills' course. We practiced using AI tools at every stage of the lifecycle — from ideation and rapid vibe coding to debugging and presentation synthesis. We practiced structured teamwork and task management across five team members, and we are delivering our entire project defense in professional English.
  > 
  > **Next, [Member 2] will show how we turned this problem into an idea.**"

---

# Part 2 — From Idea to Design
*Speaker: Member 2 · Target Time: ~2 min · Slides 4–5*

---

### Slide 4: Idea & Study Methodologies
- **Slide Title:** Scientific Study Methods: Pomodoro vs. Flowtime
- **Visual Blueprint:**
  - Split comparison graphic:
    - Left side: Circular cycle diagram for Pomodoro (Work 25m → Short Break 5m → Work 25m → Long Break 15m).
    - Right side: Upward progression curve for Flowtime (Count-up focus → Dynamic formula break).
- **On-Slide Content:**
  - **The Classic Pomodoro Technique:**
    - Structured rhythm: **25-minute work**, **5-minute short break**.
    - Rest cycle: **15-minute long break** automatically triggered every **4 work cycles**.
    - Best for: Overcoming procrastination, structured memorization, exam prep.
  - **The Flowtime Technique:**
    - Flexible count-up mode: Timer counts *upwards* without arbitrary cutoffs.
    - Protects the 'deep work' state when a student is in peak creative concentration.
    - Break calculation is dynamic: breaks scale proportionally with how long you focused.
  - **Preset Engine:**
    - Seamless switching between Classic Pomodoro, Flowtime, and user-defined custom intervals.
- **Speaker Notes (Member 2):**
  > "Thank you, [Member 1]. When designing Tomato Study, our first realization was that one size does not fit all. Different study sessions require different rhythms. That is why Tomato Study directly integrates two leading study methods.
  > 
  > First, the classic **Pomodoro Technique**: twenty-five minutes of locked-in focus followed by a five-minute rest. After four consecutive cycles, the app automatically awards a fifteen-minute restorative long break. This works wonders when you are fighting procrastination or tackling heavy homework.
  > 
  > But what happens when you are deep into coding or essay writing and twenty-five minutes feels too short? For that, we implemented **Flowtime Mode**. Flowtime counts upwards from zero. You remain focused as long as your momentum lasts, and when you finally decide to pause, the application automatically calculates your earned break time based on your actual focus duration. You get the structure of a timer without breaking your deep work."

---

### Slide 5: Design Philosophy & Technology Stack
- **Slide Title:** Design Philosophy & Production Tech Stack
- **Visual Blueprint:**
  - UI mockup showing dark theme aesthetics, split flip-digit clock, and interactive background shader.
  - Bottom row: Technology badges (Python 3.10+, PySide6, Qt Quick / QML, GLSL Shaders, uv, late.sh).
- **On-Slide Content:**
  - **UI/UX Design Philosophy:**
    - Crafted specifically for students: dark, distraction-free aesthetic with warm tomato accents.
    - Minimalist typography and satisfying split-card 2.5D flip clock animation.
    - Instant Zen Mode: hides all borders, buttons, and system cursors.
  - **Under the Hood (Technology Stack):**
    - **PySide6 & Qt Quick (QML):** High-performance reactive UI rendering at 60 FPS.
    - **GLSL Fragment Shaders:** Hardware-accelerated OpenGL background rendering drifting stars, shooting meteors, and mouse trails.
    - **Astral `uv`:** Blazing-fast virtual environment management and deterministic dependency lockfiles.
    - **`late.sh` Study Radio:** Seamless HTTP live audio streaming of curated lo-fi study beats.
- **Speaker Notes (Member 2):**
  > "To make students actually look forward to opening the app every day, we designed Tomato Study in our favorite colors: a sleek, midnight-dark backdrop accented by calming ruby tones that protect your eyes during late-night study sessions. 
  > 
  > For the technology stack, we chose **PySide6** and **Qt Quick with QML**. QML gives us declarative, butter-smooth animations, allowing our 2.5D flip-clock cards to render cleanly without consuming heavy CPU resources like Electron apps often do. In the background, an interactive **GLSL fragment shader** brings the night sky to life with drifting stars and shooting meteors that dynamically trail your mouse. 
  > 
  > We paired this with Astral's `uv` for ultra-fast dependency resolution and integrated the curated lo-fi stream from `late.sh` so students have high-quality background music at the click of a button.
  > 
  > **Now [Member 3] will walk you through how we built Tomato Study.**"

---

# Part 3 — Building Tomato Study
*Speaker: Member 3 · Target Time: ~2.5 min · Slides 6–9*

---

### Slide 6: Engineering Workflow & AI Collaboration
- **Slide Title:** Development Workflow: Idea to Vibe Coding to GitHub
- **Visual Blueprint:**
  - Linear chevron flow diagram:
    `Ideation & UI Wireframing` ➔ `Vibe Coding (Claude)` ➔ `Error Checking & Diagnostics (Gemini)` ➔ `Git & GitHub Collaboration` ➔ `Automated Installers`
- **On-Slide Content:**
  - **1. Conceptualization & Architecture:**
    - Defining the state machine: Work ➔ Short Break ➔ Long Break ➔ Flowtime.
    - Separating backend logic (`TimerBackend`, QObject) from QML visual layers.
  - **2. AI-Assisted Vibe Coding:**
    - Rapid prototyping of QML flip animations and OpenGL shader pipelines with Claude.
  - **3. Systematic Error Checking:**
    - Real-time diagnostic validation, shader compilation flags (`QSG_RHI_BACKEND=opengl`), and audio thread handling using Gemini.
  - **4. Version Control & CI-Ready Repo:**
    - GitHub repository with pull requests, branch protection, automated tests with PyTest, and self-contained installer scripts.
- **Speaker Notes (Member 3):**
  > "Thank you, [Member 2]. Building Tomato Study was an exciting demonstration of modern software development. Rather than traditional slow manual boilerplate coding, we adopted a disciplined **AI vibe-coding workflow**.
  > 
  > We started by architecting our application into two clean layers: a pure Python backend handling the state machine, timers, and streaming proxies, and a reactive QML frontend handling user interactions. During the coding phase, we utilized Claude to rapidly generate UI components like our FlipDigit cards and keybind bindings. 
  > 
  > Whenever we hit tricky runtime challenges — such as cross-platform OpenGL shader compilation across Qt6 RHI or audio streamer recovery when network drops occur — we consulted Gemini for precise error analysis and thread debugging. Every milestone was committed and reviewed on GitHub, and validated with PyTest. This hybrid human-AI engineering methodology allowed us to build a production-grade application in days instead of weeks."

---

### Slide 7: Ten Key Features
- **Slide Title:** 10 Core Features of Tomato Study
- **Visual Blueprint:**
  - 2x5 Poster Grid Layout with clear icons and concise descriptions (matching the project poster layout).
- **On-Slide Content:**
  | # | Feature | Capability |
  |---|---|---|
  | **1** | **Flip & Digital Clock** | Toggle between classic mechanical 2.5D split-cards and crisp digital readout |
  | **2** | **Timer Presets** | Instant presets: Classic Pomodoro, Flowtime, 50/10 Focus, and custom intervals |
  | **3** | **Flowtime Mode** | Open-ended count-up timer with automatic break calculation |
  | **4** | **Compact Mode** | Minimal screen footprint so you can pin it alongside notes or code editors |
  | **5** | **Study Stream** | Direct integration with `late.sh` lo-fi radio, dedicated volume slider & mute |
  | **6** | **Zen Mode** | Press `Z` or double-click to hide all controls and cursors for zero distraction |
  | **7** | **Live Background** | OpenGL GPU fragment shaders with drifting stars and reactive mouse trails |
  | **8** | **Custom Intervals** | Full control over focus minutes, break durations, and auto-start triggers |
  | **9** | **Custom Hotkeys** | Fully rebindable global keybindings (Space, R, S, Z, P, M) |
  | **10**| **Always on Top** | Keep the countdown visible over full-screen editors, PDFs, and slide decks |
- **Speaker Notes (Member 3):**
  > "On our project poster, we highlighted the ten core features that make Tomato Study uniquely suited for everyday study. 
  > 
  > First, visual flexibility: choose between our signature split-card flip clock or a sleek digital readout. Second, instant presets for traditional Pomodoro, extended study blocks, or Flowtime. Third, our dedicated Flowtime mode for long, uninterrupted work sessions. Fourth, Compact Mode, which shrinks the window down to fit snugly alongside your PDF reader or VS Code. Fifth, our embedded `late.sh` study stream with smooth volume attenuation. 
  > 
  > Sixth, our beloved Zen Mode — double click anywhere or tap 'Z' to hide every border and button. Seventh, the live GPU shader background reacting to your cursor. Eighth, fully custom time intervals. Ninth, custom hotkeys for every action. And tenth, Always on Top mode to keep your focus timer comfortably pinned above all your active windows."

---

### Slide 8: Live Demonstration & UI Walkthrough
- **Slide Title:** Live Demonstration & Application Walkthrough
- **Visual Blueprint:**
  - High-resolution dual showcase:
    - Left: Main Application View (*Focus Work · Session 1/4 · 25:00* with Flip Clock and starry background).
    - Right: Settings Panel View (*Intervals, Audio volume sliders, and Hotkey rebinding*).
- **On-Slide Content:**
  - **Live Demonstration Sequence:**
    1. **Primary Interface:** Flip clock animation, session counter (Session 1/4), control bar.
    2. **Settings Panel:** Opening with `S`, switching presets, toggling Digital/Flip view.
    3. **Flowtime Demonstration:** Switching to Flowtime, observing count-up and break reward.
    4. **Zen Mode & Background:** Double-clicking to trigger Zen Mode and demonstrating mouse-reactive shader particle trails.
    5. **Audio Stream:** Engaging late.sh lo-fi stream, volume adjustment, and mute toggle.
- **Speaker Notes (Member 3):**
  > "*(If conducting live app demo)*: Let me now demonstrate the live application running on our system. Notice the smooth card flip when I hit Space to start. As time counts down, the top header indicates our session progress — here, Session 1 of 4. Pressing 'S' opens the sleek slide-out Settings panel. From here, we can switch to Digital Clock, adjust our work and break intervals, or select Flowtime. Watch what happens when I switch to Flowtime — the clock begins counting up smoothly. Now, double-clicking the background or tapping 'Z' instantly drops us into Zen Mode: no chrome, no buttons, just the clock and the interactive starlight tracking my cursor. 
  > 
  > *(If using screenshots fallback)*: As shown in our screenshot on the left, the main window delivers immediate clarity without visual clutter. On the right screenshot, our Settings panel provides full control over intervals, keybindings, and audio streaming."

---

### Slide 9: Run It Yourself — Production Setup
- **Slide Title:** Production Setup: 3-Step Installation & Hotkeys
- **Visual Blueprint:**
  - Top section: Terminal mockups showing Linux/macOS and Windows one-click commands.
  - Bottom section: Keyboard hotkey reference cheat-sheet.
- **On-Slide Content:**
  - **Quick Start (Linux & macOS):**
    ```bash
    git clone https://github.com/[team-repo]/tomato-study.git
    cd tomato-study
    ./install.sh     # Auto-configures Python, uv, dependencies & desktop shortcut
    ./run.sh         # One-click launcher
    ```
  - **Quick Start (Windows):**
    ```cmd
    git clone https://github.com/[team-repo]/tomato-study.git
    cd tomato-study
    install.bat      # Double-click or run: creates desktop shortcut & venv
    run.bat          # Double-click to launch
    ```
  - **Astral `uv` Direct Execution:**
    ```bash
    uv run python src/main.py
    ```
  - **Essential Hotkey Reference:**
    - `[Space]` Play / Pause &nbsp;|&nbsp; `[R]` Reset &nbsp;|&nbsp; `[S]` Settings
    - `[Z]` Zen Mode &nbsp;|&nbsp; `[P]` Toggle Stream &nbsp;|&nbsp; `[M]` Mute Audio
- **Speaker Notes (Member 3):**
  > "We wanted our classmates and evaluators to be able to test Tomato Study with zero setup friction. That is why we built automated production installers for both Linux and Windows. 
  > 
  > On Linux or macOS, you simply run `./install.sh`. It automatically detects your Python version, bootstraps `uv`, resolves dependencies, and installs a desktop launcher icon. On Windows, classmates can simply double-click `install.bat`, and our PowerShell script handles the virtual environment and places a shortcut right on their desktop. Once running, you don't even need to touch the mouse — Space to start or pause, R to reset, S for settings, and Z for Zen Mode.
  > 
  > **[Member 4] will now tell you how we tested it and what we learned from the feedback.**"

---

# Part 4 — Testing & Evaluation
*Speaker: Member 4 · Target Time: ~2.5 min · Slides 10–12*

---

### Slide 10: Testing & Classmate Feedback
- **Slide Title:** Real-World Testing & Student Feedback
- **Visual Blueprint:**
  - Two-column dashboard:
    - Left: Test environment matrix (Ubuntu 24.04, Arch Linux, Windows 11, Windows 10).
    - Right: Classmate user testing quotes and satisfaction metrics bar chart.
- **On-Slide Content:**
  - **Multi-Platform Test Matrix:**
    - Tested on **Linux** (Ubuntu, Arch, Fedora) and **Windows** (10 & 11).
    - Verified Qt Quick OpenGL RHI shader performance on both integrated and dedicated GPUs.
    - Automated unit test suite (`pytest`) validating timer transitions, long break intervals, and Flowtime math.
  - **User Feedback Highlights (N=15 Classmates):**
    - **93%** praised the aesthetic visual design and flip-clock animation.
    - **87%** found Flowtime Mode more natural for programming and math than fixed Pomodoros.
    - **100%** confirmed successful installation using our one-click install scripts.
  - **User Voices:**
    - *"The Zen Mode with the live background keeps me in the zone without feeling pressured."*
    - *"Flowtime mode is a game changer for long coding assignments."*
- **Speaker Notes (Member 4):**
  > "Thank you, [Member 3]. To verify that Tomato Study was not just working on our personal laptops, we conducted comprehensive testing across multiple operating systems. We verified the application across Linux distributions like Ubuntu and Arch, as well as Windows 10 and 11, ensuring our OpenGL shaders maintain high frame rates even on modest student laptops.
  > 
  > We invited fifteen classmates to install the app and use it for their actual study sessions. The feedback was overwhelmingly positive: ninety-three percent highlighted the aesthetic quality of the interface, eighty-seven percent reported that Flowtime mode helped them avoid the frustration of arbitrary cutoffs during deep work, and every single classmate was able to install and launch the software without any technical issues using our one-click installation scripts."

---

### Slide 11: Project Evaluation: Feasibility, Strengths & Limitations
- **Slide Title:** Project Evaluation: Strengths & Limitations
- **Visual Blueprint:**
  - Balanced 3-column evaluation scorecard:
    - Column 1: Feasibility (Green)
    - Column 2: Strengths (Blue)
    - Column 3: Current Limitations (Amber)
- **On-Slide Content:**
  - **Feasibility (Proven):**
    - Seamlessly operates across Windows and Linux.
    - Simple 3-step setup via `uv` or automated scripts.
    - Lightweight CPU and memory footprint compared to web/Electron competitors.
  - **Core Strengths:**
    - **Dual Methodology:** Combines structured Pomodoro with open-ended Flowtime.
    - **Polished UX:** High-end visual appeal, 2.5D flip animations, and interactive shader trails.
    - **Distraction-Free:** Dedicated Zen Mode and Always-on-Top functionality.
    - **Ergonomic Hotkeys:** Keyboard-first workflow for uninterrupted momentum.
  - **Identified Limitations:**
    - **Streaming Only:** The lo-fi study music is an internet stream (`late.sh`); users cannot currently select individual tracks or load local MP3s.
    - **Platform Breadth:** Thoroughly tested on Windows and Linux; macOS testing is currently community-verified only.
- **Speaker Notes (Member 4):**
  > "Evaluating our project objectively, Tomato Study achieves strong feasibility. It delivers native desktop responsiveness with minimal memory footprint, avoiding the heavy memory consumption typical of Electron-based apps.
  > 
  > Its biggest strength is the harmony between aesthetics and productivity: having two proven study methods, rich customization, and a distraction-free Zen mode makes studying feel rewarding rather than stressful.
  > 
  > However, being honest engineers, we also identified clear limitations. Currently, the music player is connected to the `late.sh` internet radio stream. This means you need an active internet connection to listen, and you cannot choose specific tracks or play local MP3 files. Additionally, while our architecture is cross-platform, our primary user testing was concentrated on Windows and Linux."

---

### Slide 12: Improvement Directions & Roadmap
- **Slide Title:** Future Improvement Directions (Project Proposals)
- **Visual Blueprint:**
  - Roadmap timeline with three milestone releases:
    - Phase 1: Audio Freedom
    - Phase 2: Expanded OS & Mobile Support
    - Phase 3: Analytics & Cloud Sync
- **On-Slide Content:**
  - **Proposal 1: Local & Custom Audio Engine:**
    - Support local audio playback (`.mp3`, `.flac`, `.wav`) and custom internet radio URLs.
    - Add ambient sound generators (white noise, rainfall, café sounds) alongside lo-fi beats.
  - **Proposal 2: Extended OS Ecosystem:**
    - Native macOS `.dmg` and Homebrew distribution.
    - Wayland fractional scaling optimizations and native notification integration.
  - **Proposal 3: Study Analytics & Habit Tracking:**
    - Daily/weekly focus time charts and study streak tracking.
    - Optional export to CSV or integration with calendar applications.
- **Speaker Notes (Member 4):**
  > "Based on our testing data and classmate feedback, we formulated concrete improvement proposals for our future development roadmap.
  > 
  > First and foremost is audio flexibility: we plan to expand our audio engine so students can load their own local study playlists, choose individual music tracks, or select calming ambient sounds such as gentle rain or café white noise. 
  > 
  > Second, we aim to broaden our packaging ecosystem by providing signed macOS DMG installers and native Linux Flatpaks. Finally, we plan to implement a lightweight, local study analytics dashboard so students can visually track their daily focus hours and celebrate their consistency.
  > 
  > **Finally, [Member 5] will summarize our project.**"

---

# Part 5 — Summary & Conclusion
*Speaker: Member 5 · Target Time: ~1 min · Slides 13–14*

---

### Slide 13: Project Summary & Key Takeaways
- **Slide Title:** Project Summary: From Problem to Production
- **Visual Blueprint:**
  - Big picture summary infographic tracing the full arc:
    `Problem Identified` ➔ `Methodology Designed` ➔ `AI-Assisted Build` ➔ `Rigorous Testing` ➔ `Production App`
  - Bottom banner: The Three Core Course Competencies practiced.
- **On-Slide Content:**
  - **The Journey at a Glance:**
    - **Problem:** Frequent loss of focus and study fatigue in students.
    - **Idea:** Combine Pomodoro, Flowtime, ambient shaders, and lo-fi audio.
    - **Build:** Modern PySide6 and QML architecture accelerated by AI vibe coding.
    - **Test:** Multi-OS validation with positive classmate feedback.
    - **Result:** A production-ready, beautiful, free desktop tool for student productivity.
  - **Skills We Mastered in This Course:**
    - **AI Acceleration:** Using Claude and Gemini responsibly from ideation to debugging.
    - **Teamwork & Engineering Discipline:** Version control, automated installers, and sprint execution.
    - **Professional Communication:** Technical documentation, video demonstration, and English presentation.
- **Speaker Notes (Member 5):**
  > "Thank you, [Member 4]. To summarize our project: we started with a very real problem that affects every one of us — losing focus while studying. We transformed that problem into an idea, combining two proven study methods with modern graphics and calming audio. 
  > 
  > Through modern AI-assisted vibe coding, rigorous debugging, and automated packaging, we turned that idea into a production-ready application that runs smoothly on both Linux and Windows. 
  > 
  > Throughout this project, our team did not just build software — we practiced the foundational soft skills of our course: collaborating effectively as a team, leveraging AI responsibly to accelerate our workflow, and delivering a complete technical presentation in English."

---

### Slide 14: Thank You & Q&A
- **Slide Title:** Thank You & Q&A
- **Visual Blueprint:**
  - Left side: Prominent QR code linking to GitHub repository, website, and live release downloads.
  - Right side: Final links, contact information, and open invitation for Q&A.
- **On-Slide Content:**
  - **Tomato Study — Focus. Study. Be Productive.**
  - **GitHub Repository:** `https://github.com/[team-repo]/tomato-study`
  - **Project Documentation & Release:** Check `README.md` & `install.sh` / `install.bat`
  - **Poster & Live Demo QR Code:** *(Scannable QR box)*
  - **Special Thanks:**
    - Course Instructor & Supervisor: **[GVHD]**
    - Stream Audio Provider: **late.sh**
  - *We welcome your questions, feedback, and suggestions!*
- **Speaker Notes (Member 5):**
  > "We would like to express our sincere gratitude to our supervisor [GVHD] for your guidance and support throughout this semester, and to all our classmates for your valuable feedback during user testing.
  > 
  > You can find our complete open-source codebase, installation guides, and documentation on GitHub via the link and QR code on the screen. 
  > 
  > Thank you very much for your time and attention. We are now excited to answer any questions you may have!"
