# Nexus — Your Life, in One Place

Nexus is a personal life management app that helps you **capture, organize, and follow through** on the things you care about—without turning your day into a project.

It's built to feel **fast, reliable, and calm**: you can keep using it even when your device is offline, and it quietly syncs when it can.

This README is intentionally **user-facing and non-technical**. It explains what
Nexus does and how it helps users in daily life.

For technical documentation:
- `docs/nexus_knowledge_base.md` provides a high-level technical map.
- `developer_README.md` is the deep technical walkthrough and reference for contributors.

## Table of contents

- [What Nexus is for](#what-nexus-is-for)
- [Why Nexus is different](#why-nexus-is-different)
- [Core features](#core-features)
  - [Tasks](#tasks)
  - [Reminders](#reminders)
  - [Notes](#notes)
  - [Habits](#habits)
  - [Calendar](#calendar)
  - [Analytics](#analytics)
  - [Settings & customization](#settings--customization)
- [Who Nexus is great for](#who-nexus-is-great-for)
- [A quick day with Nexus](#a-quick-day-with-nexus)
- [What Nexus is not trying to be](#what-nexus-is-not-trying-to-be)
- [Want technical details?](#want-technical-details)

---

## What Nexus is for

- **One place for your life**: tasks, reminders, notes, habits, a simple calendar view, and light analytics.
- **Less mental load**: capture quickly, organize just enough, and trust that nothing falls through the cracks.
- **Works where you are**: designed for **Android** and **Windows**.

---

## Why Nexus is different

- **Offline-first by design**: everything is saved locally first, so the app stays usable and responsive even with poor or no connection.
- **Simple, opinionated flow**: Nexus focuses on a small set of powerful building blocks instead of trying to be a heavy project-management suite.
- **All-in-one, not all-at-once**: tasks, reminders, notes, habits, calendar, and analytics are tightly integrated, but you can start with just one and grow as you need.
- **Thoughtful visuals**: multiple navigation bar styles, theme customization, and a clean dashboard help the app feel "yours" without endless tweaking.

---

## Core features

### Tasks

Capture and organize everything you need to do with powerful task management:

- **Rich task details**: titles, descriptions, due dates, priority levels, difficulty ratings, and recurrence patterns.
- **Attachments**: attach images or voice notes directly to tasks—perfect for capturing context like photos of receipts, screenshots of requirements, or quick voice memos.
- **Smart organization**: filter by status, priority, category, or search across all your tasks to find what matters quickly.
- **Categories and subcategories**: organize tasks hierarchically for better structure.

### Reminders

Never miss an important moment with reliable notification reminders:

- **Smart notifications**: get notified at exactly the right time with reliable background scheduling that works even when the app is closed.
- **Flexible scheduling**: set one-time or recurring reminders, snooze when needed, and reschedule as plans change.
- **Background reliability**: uses multiple strategies (AlarmManager, in-app timers, and Workmanager) to help notifications fire reliably across different Android devices. On first launch, Nexus asks to be excluded from battery optimization so reminders survive Doze mode, and all scheduled alarms are automatically restored after a device reboot.

### Notes

Capture ideas and reference material with a full-featured note workflow:

- **Full-screen editor**: open a note above the bottom navigation for focused editing; when you’re done, you return to the notes list.
- **Flexible writing modes**: write with rich formatting or in Markdown, depending on your preference.
- **Useful note actions**: quickly search inside a note, organize with categories, and manage note-specific options from one place.
- **Voice and media support**: attach voice clips and images when text alone is not enough.
- **Comfortable editing**: tuned for focused writing sessions with a clean layout and responsive controls.
- **Multilingual content**: mixed-language notes (including Arabic) render naturally where supported.

### Habits

Build consistency with habit tracking that keeps you motivated:

- **Streak tracking**: see your current streak for each habit and watch it grow day by day.
- **Visual progress**: view completion trends over time with charts and heatmaps.
- **Link to tasks**: connect habits to recurring tasks for seamless workflow integration.
- **Simple daily check-in**: mark habits as done with a single tap.

### Calendar

See your life at a glance with integrated calendar views:

- **Unified view**: see tasks and reminders laid out over days to spot overload early and plan ahead.
- **Native calendar integration**: export events to your device's native calendar app (Google Calendar, Samsung Calendar, etc.) so they appear alongside your other appointments.
- **Filter by type**: view all items, or filter to see only tasks, reminders, or habits.

### Analytics

Understand your productivity patterns with light, actionable insights:

- **Task insights**: see completion rates, overdue load, task velocity trends, and priority distribution at a glance.
- **Habit analytics**: track consistency with heatmaps and progress circles showing your habit completion over time.
- **Visual charts**: pie charts for task status breakdown, line charts for completion trends, and habit heatmaps—all designed to be human-scale, not overwhelming.
- **Quick stats**: overview cards showing active tasks, completed items, overdue tasks, and upcoming reminders.

### Settings & customization

- Choose between multiple navigation bar styles (standard, Google-like, curved, animated notch).
- Toggle light/dark themes or follow the system.
- Tune retention for completed items and manage app permissions in one place.

---

## Who Nexus is great for

- Students managing classes, assignments, exams, and personal errands.
- Busy professionals balancing projects, meetings, and home life.
- Anyone who wants a simple daily system: **tasks + reminders + notes + habits** in one place.

---

## A quick day with Nexus

1. Capture tasks as they appear ("Pay rent", "Call dentist", "Finish report").
2. Add reminders for time- or date-sensitive items.
3. Use priorities and due dates to focus your next actions.
4. Attach photos, screenshots, or voice notes when extra context matters.
5. Glance at the calendar and dashboard to plan the next few days.
6. Check off habits and watch your streaks grow.

---

## What Nexus is not trying to be

- Not a complex project-management tool.
- Not a social or collaboration app.
- Not a "setup-heavy" productivity system that needs hours of configuration.

The goal is **clarity and follow-through**, with as little friction as possible.

---

## Want technical details?

If you're interested in how Nexus is built (architecture, data flow, routes, and contribution guidelines), see:

- [`developer_README.md`](developer_README.md) — developer onboarding and deep architecture guide.
- [`docs/nexus_knowledge_base.md`](docs/nexus_knowledge_base.md) — project structure, routing, sync, Hive, and entry-point flow.
- [`docs/CLEAN_ARCHITECTURE_MIGRATION.md`](docs/CLEAN_ARCHITECTURE_MIGRATION.md) — walkthrough of the Domain / Data / Presentation layout.
