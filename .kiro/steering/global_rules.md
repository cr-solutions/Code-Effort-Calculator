---
inclusion: always
---

# Global AI Coding & Workflow Rules

These rules are strictly binding for all code generation, refactorings, and Git operations.

## 1. Programming Paradigm & Style
* **Bouncer Pattern (Guard Clauses):** Consistently use the "Bouncer Pattern". Validate inputs and preconditions at the very beginning of a function and exit early (Return/Throw). Avoid deep `if-else` nesting.
* **EAFP Approach:** Use "Easier to ask for forgiveness than permission" - attempt operations and handle exceptions rather than checking conditions first.
* **Single Responsibility:** One function should do one thing. Avoid magic numbers and unclear logic.
* **Flat Structure:** Functions should not be deeply nested. Use clear, independent units with flat structure.
* **Error Handling:** Use precise HTTP status codes:
    * `400` (Bad Request), `401` (Unauthorized), `403` (Forbidden), `404` (Not Found), `410` (Gone), `412` (Precondition Failed)
    * `419` (Authentication Timeout), `421` (Too Many Connections), `423` (Locked), `429` (Too Many Requests)
    * `500` (Internal Server Error) only for genuine system failures, `501` (Not Implemented), `503` (Service Unavailable)
* **Custom Error Classes:** Create CustomError classes with error codes:
    * System Error Codes: 0-99
    * HTTP Error Codes: 100-599
    * Custom Business Logic: ≥5000
    * Database Errors: ≥50000
* **Database Schema (MySQL/Relational):**
    * Every table requires an `id` (INT) as the Primary Key.
    * Use a `code` field (Unique, Not Null) for human-readable identifiers.
    * **Foreign Keys:** Name them following the schema `fk_tablesrc_tabledst`. They must reference the destination table's `id` or `code`.
    * **N:M Tables:** Name them `nm_table1_table2`.
    * **1:1 Tables:** Name them `table1_table2` with UNIQUE constraint on both IDs.
    * **Polymorphic Relations:** Use `ref_table` (VARCHAR) and `ref_id` (INT) fields.

## 2. Code Style & Formatting
* **Naming Conventions:**
    * Variables, functions, methods, fields: `snake_case` (Python standard)
    * Single words: all lowercase
    * Constants: `UPPER_CASE` (e.g., `TYPE_CUSTOMER = 'b2c'`)
    * Classes, Interfaces, Enums: `PascalCase` (e.g., `MyClass`, `MyEnum`)
* **Formatting:**
    * Python: 4 spaces (no tabs)
    * Use LF instead of CRLF, UTF-8 encoding
    * Prefer single quotes where possible

## 3. Documentation & Comments
* **The "Why", not the "What":** Comments must not explain what the code does, but **why** it does it (justification for logic decisions).
* **Mandatory Inline Comments:** Meaningful inline comments are mandatory, even for hotfixes.
* **Refactoring History:** When replacing old methods, briefly mention in a comment which method was replaced and why (e.g., performance, security).

## 4. Logging & Monitoring
* **Log Levels:** Use appropriate levels with precise control:
    * `TRACE`: Internal library details
    * `DEBUG`: Detailed outputs for debugging
    * `INFO`: Main application steps
    * `WARN`: Non-critical problems causing non-breaking issues
    * `ERROR`: Issues that may not have been considered
    * `CRITICAL`: Unexpected behavior
* **Exception Handling:** Always include logging in main procedures with proper exception handling and exit codes.

## 5. Git Workflow & Branching
* **Branch Naming:** Use only lowercase letters and hyphens.
    * Format: `[prefix]/[ticket-nr]/[short-description]`
    * Prefixes: `feature/`, `bugfix/`, `hotfix/`, `release/`, `docs/`.
* **Commits:**
    * Use descriptive industry-standard messages (e.g., "Add support for...", "Refactor tax calculation...").
    * Avoid vague messages like "update" or "fix".
* **Squashing:** Feature, bugfix, and hotfix branches **must** be squashed before merging into `main` or `master`. Do not create unnecessary merge commits on the feature branch.

## 6. Workflow Routine
* **Pull before Work:** Always pull the latest state before starting development.
* **Frequent Commits:** Commit small, logical units frequently.
* **Conflict Resolution:** Use VS Code tools for conflict resolution. Do not hold local changes for too long.

## 7. Environment
* **Python:** 4 spaces, no tabs. Use `snake_case` throughout.
* **Framework:** Flask — follow existing project structure (`api/`, `website/`, `libs/`, `wsgi/`).
* **WSGI:** Gunicorn for production, Flask dev server for local development.
* **Config:** All environment-specific values via `.env` / `config.py` — never hardcode secrets.
* **.venv:** Located per repository root.

## 8. Context History
* **File:** Create and update a context history file per task under `.kiro/context/` using the format:
  `CONTEXT_HISTORY_<year>-<month>-<day>_<task_name>.md`
  Example: `.kiro/context/CONTEXT_HISTORY_2026-05-28_password-reset.md`
* **Purpose:** Tracks decisions, blockers, and progress so any AI tool can resume work without losing context across sessions.
* **Note:** This folder is separate from `.kiro/steering/` (which holds always-on rules). Context history files are session logs, not steering rules.
