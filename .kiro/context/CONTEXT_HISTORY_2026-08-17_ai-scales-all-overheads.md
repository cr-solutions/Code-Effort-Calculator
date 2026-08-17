# Context History: AI Scales All Overheads & Output Improvements

**Date:** 2026-08-17
**Task:** Make AI reduce all effort components and improve output readability

---

## Summary

Extended AI impact beyond just coding effort — AI now also reduces unit testing overhead, documentation effort, and migration research. Improved output formatting for consistency and transparency.

---

## Decisions Made

### 1. AI Reduces Unit Testing Factor

**Problem:** Unit testing factor was fixed ×1.30 regardless of AI — but AI excels at generating test boilerplate.

**Solution:** Testing factor scales with AI level:
- None: ×1.30 (full manual)
- Light: ×1.25
- Moderate: ×1.15
- Heavy: ×1.10

Applied *after* the AI section (so `coding_effort_no_ai` still uses the original ×1.30 for correct overhead computation).

### 2. AI Reduces Documentation Effort

**Problem:** Documentation was a flat additive cost regardless of AI — but AI can draft docs from code context.

**Solution:** Doc effort scales with AI level:
- None: ×1.0
- Light: ×0.80
- Moderate: ×0.50
- Heavy: ×0.30

### 3. AI Reduces Migration Research

**Problem:** Migration R&D was flat regardless of AI — but AI can read changelogs and identify affected code.

**Solution:** Already implemented in prior session, confirmed working:
- None: ×1.0, Light: ×0.85, Moderate: ×0.60, Heavy: ×0.40

### 4. Output Improvements

- **Familiarity label**: Shows `(Team code)`, `(Inherited)`, `(Unknown)` in breakdown when > 1.00
- **Unit testing time**: Shows absolute time added `(+Xh Ym)` in breakdown
- **Coding effort hint**: Shows `(= steering, review & integration)` when AI is active
- **AI savings display**: All reduction lines now show consistent format: `-X% (saves Yh Zm)`
- **Version bumped**: v3.0 → v3.1 in usage header and startup banner

---

## Files Changed

| File | Change |
|------|--------|
| `code_effort_calculator.bash` | AI-scaled unittest/doc/migration, output hints, version bump |
| `README.md` | Updated unittest and doc sections with AI reduction tables |
| `CHANGELOG.md` | Added all new features |
| `.kiro/steering/project_rules.md` | Created project-specific rules |
| `.kiro/context/CONTEXT_HISTORY_2026-08-17_*.md` | This file |

---

## Verification

- All AI levels (0-3) produce smooth decreasing progression for every component
- Tested full combination: version/2, familiarity=2, unittest=y, functest=2, doc=2 across all AI levels
- Output only shows relevant reduction lines (no doc line when doc=0, no migration when type≠version)
- Confirmed `coding_effort_no_ai` is unaffected by the post-AI unittest adjustment

---

## Open / Future Considerations

- Functest could get direct AI reduction in future (currently only indirect via reduced coding_effort)
- Per-language AI effectiveness factors (AI is better at Python than at Rust)
- Confidence interval output (optimistic/pessimistic range)
