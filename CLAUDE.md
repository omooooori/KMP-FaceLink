# CLAUDE.md

Strictly follow the rules in [AGENTS.md](./AGENTS.md).

## Language

- **All generated content must be in English**: code, comments, commit messages, PR titles/descriptions, documentation, and TASKS.md entries.
- The only exception is conversation with the user (follow the user's language preference).

## Task Management

- **Read [TASKS.md](./TASKS.md) at the start of every session**
- Pick the next TODO task (highest priority among status = TODO) before starting work
- On task completion, do both:
  1. Update the task's status to `DONE` in `TASKS.md`
  2. Close the corresponding GitHub Issue (`gh issue close <number>`)
