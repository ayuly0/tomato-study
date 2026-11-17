# Tomato Study — Speaker Pocket Cue Cards
**Course:** Introduction to the Major and Soft Skills (Semester 1, 2026–2027)  
**Session Length:** 10 Minutes Total · 5 Speakers

---

## Member 1 — Introduction & Purpose
*Target Time: 2:00 (0:00 – 2:00) · Slides 1–3*

- [ ] **Core Message:** Frame the universal problem (losing focus) and introduce Tomato Study as our solution and our course skills showcase.
- [ ] **Slide 1 (0:00 - 0:40):** Welcome supervisor [GVHD] and class. State title: *"Tomato Study — Focus. Study. Be Productive."* Introduce teammates.
- [ ] **Slide 2 (0:40 - 1:20):** Relate to everyday struggles: constant phone notifications, 20-minute flow recovery penalty, ugly or bloated timers.
- [ ] **Slide 3 (1:20 - 2:00):** State project purpose: build modern timer with evidence-based study methods + lo-fi audio. State course practice: AI tools (ideation to slides), teamwork/planning, English delivery.
- [ ] **Verbatim Handover Cue:**
  > *"Next, [Member 2] will show how we turned this problem into an idea."*

---

## Member 2 — From Idea to Design
*Target Time: 2:00 (2:00 – 4:00) · Slides 4–5*

- [ ] **Core Message:** Explain the two scientific study methods (Pomodoro & Flowtime) and our design philosophy + tech stack.
- [ ] **Slide 4 (2:00 - 3:00):**
  - **Pomodoro:** 25m focus, 5m short break, 15m long break every 4 cycles. Great for beating procrastination.
  - **Flowtime:** Counts up without arbitrary stops. Automatically calculates break time based on how long you focused.
- [ ] **Slide 5 (3:00 - 4:00):**
  - Built for students in our favorite colors: dark, distraction-free aesthetic with calming ruby tones.
  - Tech: **PySide6 + Qt Quick (QML)** for 60 FPS 2.5D flip clock; **GLSL fragment shaders** for interactive star trails; **uv** for speed; **late.sh** for lo-fi stream.
- [ ] **Verbatim Handover Cue:**
  > *"Now [Member 3] will walk you through how we built Tomato Study."*

---

## Member 3 — Building Tomato Study
*Target Time: 2:30 (4:00 – 6:30) · Slides 6–9*

- [ ] **Core Message:** Explain our AI vibe-coding workflow, demonstrate the 10 core features, and highlight our one-click setup.
- [ ] **Slide 6 (4:00 - 4:40):** Engineering workflow: Idea ➔ Vibe coding with Claude ➔ Systematic error diagnostics with Gemini ➔ Git collaboration & PyTest on GitHub.
- [ ] **Slide 7 (4:40 - 5:20):** The 10 Features (Poster layout): Flip & Digital Clock, Presets, Flowtime, Compact Mode, Study Stream, Zen Mode, Live Background, Custom Intervals, Custom Hotkeys, Always on Top.
- [ ] **Slide 8 (5:20 - 6:00):** **Live Demo / Walkthrough:**
  - `Space` to start card flip.
  - `S` for settings.
  - Switch to Flowtime (counts up).
  - Double click or `Z` for Zen Mode + swirl mouse to show GPU star particles.
  - `P` for stream, `M` for mute, `R` to reset.
- [ ] **Slide 9 (6:00 - 6:30):** 3-step setup: install `uv`, `git clone`, `uv run python src/main.py` or use `./install.sh` / `install.bat`.
- [ ] **Verbatim Handover Cue:**
  > *"[Member 4] will tell you how we tested it and what we learned from the feedback."*

---

## Member 4 — Testing & Evaluation
*Target Time: 2:30 (6:30 – 9:00) · Slides 10–12*

- [ ] **Core Message:** Share real-world testing results across Windows and Linux, evaluate strengths and honest limitations, and propose roadmap items.
- [ ] **Slide 10 (6:30 - 7:20):** Multi-OS testing on Windows (10/11) and Linux (Ubuntu/Arch). 15 classmates tested the app. 93% loved the visuals/flip clock; 87% preferred Flowtime for coding/math; 100% installed successfully.
- [ ] **Slide 11 (7:20 - 8:15):** Evaluation Scorecard:
  - **Feasibility:** Proven cross-platform, light memory (<50MB vs >200MB Electron), 3-step setup.
  - **Strengths:** 2 study methods, 2.5D flip cards, distraction-free Zen mode, hotkey workflow.
  - **Limitations:** Music is an internet stream (`late.sh`), cannot choose individual songs yet; tested primarily on Windows and Linux so far.
- [ ] **Slide 12 (8:15 - 9:00):** Future Improvement Proposals:
  - Proposal 1: Local audio playback (.mp3) and ambient sound generators (rain, café).
  - Proposal 2: Native macOS packaging and Wayland optimizations.
  - Proposal 3: Daily study statistics and streak tracking.
- [ ] **Verbatim Handover Cue:**
  > *"Finally, [Member 5] will summarize our project."*

---

## Member 5 — Summary & Conclusion
*Target Time: 1:00 (9:00 – 10:00) · Slides 13–14*

- [ ] **Core Message:** Synthesize the project arc, summarize course skills practiced, and open the Q&A session.
- [ ] **Slide 13 (9:00 - 9:30):** The complete arc: Problem ➔ Idea ➔ Build ➔ Test ➔ Production Result. Reiterate what we practiced: AI tools from concept to slides, teamwork/planning, and English presentation.
- [ ] **Slide 14 (9:30 - 10:00):** Thank supervisor [GVHD] and classmates. Point to GitHub link, website, and poster QR code on screen.
- [ ] **Closing Line:**
  > *"Thank you very much for your time and attention. We are now excited to answer any questions you may have!"*

---

## Emergency Survival Tips for All Speakers
1. **If you lose your train of thought:** Glance at the on-screen slide title or bullet header, take a one-second breath, and state the headline.
2. **If time runs short:** Do not rush speaking rate; skip minor bullet details and head directly to the handover sentence.
3. **During Q&A:** Listen to the supervisor’s full question first. Member 1 or 5 can acknowledge and route to the specialist member (e.g., Member 2 for design/QML, Member 3 for code/shaders, Member 4 for testing/limitations).
