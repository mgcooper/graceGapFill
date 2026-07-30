# Code Style

Project-agnostic engineering conventions. Project-specific conventions
live in `STYLE.local.md`. Match surrounding code first; these are defaults.

## Reuse and structure

- No duplicate logic across functions: define one helper and call it.
- Before adding a helper, check the codebase for an existing equivalent.
- Organize reusable code into the relevant module/package.
- When moving or renaming, update every call site, test, and doc/comment
  that refers to it in the same change.
- No thin wrappers: update all call sites with new function names or syntax.

## Linter discipline

- Do not silence linter or static-analysis warnings with inline suppression
  comments. Refactor the code to remove the underlying warning instead.

## Version control hygiene

- Use your VCS's rename (e.g. `git mv`) when moving or renaming tracked files, so
  history is preserved and reviewers see a rename rather than a delete plus add.

## Comments and documentation

Comment discipline is **strict and non-negotiable** — a hard requirement, not a
preference.

- **Never write uncommented code.** Every new function gets a docstring/header, and
  every block of code gets an explanatory comment that says *why*, not just *what*.
  Do not skip a comment because the code looks trivial, simple, obvious, or
  self-explanatory — that is not an exception. Uncommented code is incomplete and
  must not be submitted.
- **Never remove existing comments.** A comment may be removed *only* when the code it
  documents is itself removed. It is never acceptable to delete, trim, shorten,
  summarize away, or "clean up" comments — not for brevity, not for tidiness, and not
  because a comment seems obvious or redundant.
- **Edit existing comments only for accuracy.** When you change code, update the
  affected comments and docstrings so they stay correct, preserving the information
  they carry. Never leave a comment describing behavior that no longer exists, and
  never silently drop the detail a comment held.
- Group operations logically.

## User-facing prose

Write for people who must understand and act on the result.
Prefer clear, direct, active, and globally understandable language.
Complete factual and structural editing before applying `$humanize-prose`.

Apply this policy to comments, docstrings, documentation, Quarto narrative,
draft handoffs, DesignSpecs, final reports, release notes, UI copy, and
substantive final responses.
Do not apply it to AGENTS or STYLE files, skill instructions, prompts,
ExecPlans, Beads, configuration, logs, or machine-readable content.

Every prose edit must preserve facts, requirements, normative strength,
technical terminology, specificity, examples, causal explanations,
limitations, citations, identifiers, commands, code, and protected structure.
Comments and docstrings must retain the rationale and technical detail they
carry.

For Quarto, edit only source narrative.
Do not alter YAML, executable cells, chunk options, equations, citations,
cross-references, data, or generated HTML, PDF, and other rendered output.

# MATLAB conventions

Canonical conventions shared across MATLAB projects. These extend the language-agnostic
rules above. Opinionated, project-varying choices belong in `STYLE.local.md`.

## Function naming

- Prefer MATLAB-style short, punchy, all-lowercase single-word names when the name is
  short and readable (roughly four syllables or fewer) — e.g. `loadcases`, `plotcase`,
  `getforcings`, `concatoutput`.
- Use `camelCase` when a single lowercase word becomes hard to read — e.g.
  `snowDataRoot`.
- Avoid `snake_case` for function names **unless** a project deliberately adopts it for
  a large or complex subsystem where long camelCase becomes unreadable; document any
  such exception in that project's `STYLE.local.md`.

## Files and functions

- Extend existing functions over adding new thin wrappers unless the abstraction
  boundary is real.
- No thin wrappers when function names change: update all call sites.
- Close every function with an explicit `end`.

## Shared tunables and mappings

- Define every pipeline threshold, channel list, source mapping, alias, and other
  policy-controlled tunable in one authoritative options, `+namelists`, or
  dedicated function.
- Derive name-value defaults, validators, aliases, and identity mappings from
  that source. Do not repeat the governed literals or member lists in consumers.

## Formatting

- Wrap code and comments at roughly 80 columns; continue long lines with `...`.
  (Indentation width is project-specific — see `STYLE.local.md`.)

## Testing

- Name the variable holding the actual result `returned`, and compare it against a
  variable named `expected` — e.g. `testCase.verifyEqual(returned, expected)`. This
  keeps test bodies uniform and the intent of each assertion obvious.
- Put reusable test fixtures in `<+toolbox>/+test/+fixtures` so shared setup stays
  in one place.
- Use `matlab.unittest.fixtures.Fixture` for reusable setup/teardown.
- Prefer parameterized `matlab.unittest.TestCase` classes when multiple cases or
  shared setup/teardown benefit from them; use simpler function-based tests when
  they are clearer.
- Keep test-data generation in a helper function named `+<toolbox>/+test/generateTestData.m` so
  demos and scripts can access the same data.
- Fixture classes must wrap that helper instead of owning the data definition.
- Do not hide data generation capability useful for demos and scripts in test setup.

## Linting

- No `%#ok<...>` suppressions (AGROW, DATST, ASGLU, NASGU, etc.) in new code —
  refactor to remove the underlying warning rather than silencing it.
- `%#ok<AGROW>` specifically: preallocate the output, or compute its size before the
  loop. If a growing pattern seems unavoidable, restructure so the size is known up
  front (count matches first, then allocate, then fill).
- Where available, lint with `codeIssues` and treat a clean result as the bar.

## Running MATLAB

- Never launch the MATLAB desktop GUI to run code. Run headless from a shell with
  `matlab -nodisplay -nosplash -batch "<expr>"` — `-batch` or MATLAB MCP.
- Prefer the shell launcher for batch runs, tests, and anything you may need to
  debug from full stdout/stderr. Prefer the MATLAB MCP only for short
  interactive checks when an already-open session is available and its returned
  result shape is sufficient.
- If `matlab` is not on `$PATH`, locate the installed binary and invoke its
  absolute path. Record a durable machine- or project-specific launcher path in
  `STYLE.local.md`, not this shared style file.
