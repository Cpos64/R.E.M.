# BUILD_LOG_TEMPLATE.md

This file instructs AI agents on how to create and update `BUILD_LOG.md`.

---

## Core Rules

- The build log is **single-day only**. It never accumulates multiple days.
- When creating a new day's log, **replace the entire file**. Never append.
- The log is touched **twice per day**: morning session and evening session.
- Never invent tasks or context. Only work from what is in the previous build log and what the user tells you explicitly.
- Keep all entries terse. This is a working log, not documentation.

---

## Morning (1st) Session

The user will share yesterday's `BUILD_LOG.md`. Use it to generate today's log:

1. **Date** — set to today's date.
2. **Focus Today** — pull directly from yesterday's `Tomorrow` section. Format each as an unchecked item: `[ ] Task name`
3. **Milestones Completed** — carry forward unchanged from yesterday. Only add a new entry if the user explicitly says a milestone was reached.
4. **What We Accomplished Today** — leave blank. Write the placeholder: `*(evening session)`*
5. **Tomorrow** — leave blank. Write the placeholder: `*(evening session)`*
6. **Backlog** — carry forward unchanged unless the user explicitly tells you to add, remove, or reprioritize items.

---

## Evening (2nd) Session

The user will share today's `BUILD_LOG.md` as it stands from the morning session. Update it in place:

1. **Focus Today** — mark completed tasks `[X]`. Leave incomplete tasks as `[ ]`.
2. **What We Accomplished Today** — review the git commits for today (`git log --oneline -5` + `git show --stat HEAD`) to determine what was worked in today's session. Write everything that was done today, and include where we left off. Be specific enough that the next session can pick up cleanly without additional context. Confirm with the user if anything is unclear.
3. **Tomorrow** — populate based on what the user tells you. Any `[ ]` incomplete tasks from Focus Today automatically carry over here unless the user says otherwise.
4. **Backlog** — update only if the user explicitly asks.

---

## File Format

Every `BUILD_LOG.md` must follow this exact structure:

```md
# BUILD LOG

**Date:** [Today's date]

---

## Focus Today
- [ ] Task one
- [ ] Task two

---

## Milestones Completed (high-level only; keep section short and sweet)
- Brief milestone entry
- Brief milestone entry

---

## What We Accomplished Today
*(evening session)*

---

## Tomorrow
*(evening session)*

---

## Backlog
- Backlog item one
- Backlog item two
```
