# CPSC_4150_ReadRight_App

# 📘 ReadRight Project Guidelines & Rubric Reference

This document summarizes the **CPSC 4150/6150 Team Project Competition** and grading rubric that I used as the foundation for developing my **ReadRight** mobile app.
The following details come directly from the official class competition and evaluation criteria.

---

## 🚀 Overview: Team Project Competition

**Course:** CPSC 4150/6150 — Software Engineering Practicum
**Competition Title:** *Build the Best ReadRight App*
**Due Date:** December 1 @ 11:59 PM
**Total Points:** 100 (Undergraduate Teams) | 120 (Graduate Teams)

The competition challenged teams to design and implement a **Flutter mobile application** called **ReadRight**, intended to help children practice *Dolch sight words* using speech recognition and text-to-speech.

The project combined aspects of software design, usability, and teamwork under a competitive framework — with **final exam exemptions** awarded to the top-performing team(s).

---

## 📱 Project Concept: ReadRight App

**Goal:**
Develop a working prototype of a mobile app that assists children in reading practice by recognizing spoken words and providing immediate feedback.

### Core Flow
1. The app plays a word aloud (using Text-to-Speech or an audio asset).
2. The student repeats the word into the microphone.
3. Speech-to-Text converts the response to text for string comparison.
4. The app gives immediate feedback:
   - ✅ **Correct:** Praise and show the word used in a sentence.
   - ❌ **Incorrect:** Encourage retry, replay the word slowly, and show usage in context.
5. Word lists are based on **Dolch Pre-Primer** and **Primer** vocabulary sets (provided in JSON).

Additional version levels (A, B, C) were announced for teams to implement progressively.

---

## 👥 Team Structure

- Teams consisted of **3–4 members**.
- Each team submitted a **unique version** of the ReadRight app.
- Collaboration and consistent commit activity in GitHub were key evaluation factors.

---

## 📅 Project Timeline

| Stage | Description |
|--------|--------------|
| Kickoff | Initial announcement and team formation |
| Development Period | Iterative feature design, testing, and collaboration |
| Demo Day | Final in-class presentation and app demonstration |
| Winner Announcement | Same day as demos; top teams received final exam exemption |

---

## 💡 Educational Purpose

The ReadRight competition emphasized **applied learning** in areas such as:
- Flutter app development (UI, state management, and TTS integration)
- Speech recognition and local data persistence
- Clean, readable, and modular coding practices
- Collaboration workflows using Git and Agile processes
- Presentation and communication skills

The broader intent was to simulate a *real-world product pitch* where technical skill, usability, and teamwork were equally important.

---

## 🧾 Official Rubric (Undergraduate Teams – 100 Points)

| **Criterion** | **Description** | **Points** |
|----------------|-----------------|-------------|
| **Core Functionality** | Meets project requirements; core features implemented; app runs without major crashes. | 30 |
| **UI/UX** | Clean, usable interface; appropriate widgets/layouts; accessibility considered where reasonable. | 15 |
| **Persistence & Data** | Local persistence (e.g., SQLite or `shared_preferences`) implemented correctly; data persists across sessions. | 20 |
| **Code Quality** | Organized, readable, modular code; clear comments; sensible project structure; follows style guides. | 15 |
| **Teamwork & Process** | Evidence of collaboration (Git history, PRs, issue tracking, task division); consistent commits. | 10 |
| **Presentation & Demo** | Clear explanation of features and implementation; successful live demo; answers questions effectively. | 10 |
| *Extra Credit (optional)* | Meaningful enhancements beyond baseline scope. | +5 |
| **Total** |  | **100** |

---

## 🏆 Judging Criteria Summary

- **Core Functionality (40 pts)**: End-to-end working demo.
- **User Experience (20 pts)**: Simple, accessible, child-friendly design.
- **Innovation (20 pts)**: Creative enhancements like progress tracking, animations, or adaptive difficulty.
- **Code Quality (10 pts)**: Organized, modular, and maintainable code.
- **Presentation (10 pts)**: Clear communication and demonstration of the project.

---

## 🎤 Demo & Presentation Guidelines

Each team was required to deliver a **live demo** during the final week of class.
Key expectations included:
- Explaining core design and implementation choices
- Demonstrating working features in real time
- Highlighting teamwork, innovation, and user-centered design decisions
- Answering technical questions effectively

---

## 📈 Reflection and Application

These guidelines served as the **baseline framework** for my ReadRight app design and development.
I used the rubric to prioritize:
- Robust functionality and persistence
- Clean and accessible UI
- Maintainable, well-documented code
- Evidence of collaboration through structured Git commits and issues

---

### 📚 Summary
This README captures the **competition rules and rubric** that informed the structure and evaluation of the ReadRight project.
It acts as both a **reference** for development standards and a **record** of the criteria the final submission was measured against.

