# Code Style

Project-agnostic engineering conventions. This file is **canonical and shared**
across projects; language-specific conventions are appended below it (e.g. from
`STYLE.matlab.md`), and project-specific conventions live in `STYLE.local.md`.
Match the surrounding code first; these are the defaults.

## Reuse and structure

- Do not repeat logic. If logic is shared, define one helper and call it — do not
  copy-paste or leave shared contract logic as inline blocks.
- Before adding a helper, check the codebase for an existing equivalent.
- Organize reusable code into the relevant module/package, not at an arbitrary top
  level. Keep only small, file-local glue (parsing, formatting, or one-off
  table/display helpers) local.
- When moving or renaming something, update every call site, test, and doc/comment
  that refers to it in the same change.

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

# MATLAB conventions

Canonical MATLAB-specific conventions, shared across MATLAB projects. These extend
the language-agnostic rules above. Opinionated, project-varying choices —
function-name casing, indentation width, variable casing, package layout, and any
kernel/architecture rules — belong in `STYLE.local.md`, since they legitimately
differ between projects.

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

- One primary function per file, with the file named for it. Local/sub-functions
  live in the same file.
- MATLAB requires the function declaration to match the filename, so a rename needs
  a follow-up edit to the function line, the docstring, and any error identifiers —
  in addition to the `git mv`.
- Close every function with an explicit `end`.

## Formatting

- Wrap code and comments at roughly 80 columns; continue long lines with `...`.
  (Indentation width is project-specific — see `STYLE.local.md`.)

## Testing

- Name the variable holding the actual result `returned`, and compare it against a
  variable named `expected` — e.g. `testCase.verifyEqual(returned, expected)`. This
  keeps test bodies uniform and the intent of each assertion obvious.

## Linting

- No `%#ok<...>` suppressions (AGROW, DATST, ASGLU, NASGU, etc.) in new code —
  refactor to remove the underlying warning rather than silencing it.
- `%#ok<AGROW>` specifically: preallocate the output, or compute its size before the
  loop. If a growing pattern seems unavoidable, restructure so the size is known up
  front (count matches first, then allocate, then fill).
- Prefer `isfolder(p)` / `isfile(p)` over `exist(p,'dir')==7` / `exist(p,'file')==2`;
  the boolean predicates read more clearly and avoid the magic numbers.
- Where available, lint with `codeIssues` and treat a clean result as the bar.

## Running MATLAB

- Never launch the MATLAB desktop GUI to run code. Prefer an already-open MATLAB
  session when one is available; otherwise run headless from a shell with
  `matlab -nodisplay -nosplash -batch "<expr>"` — `-batch` runs the expression
  non-interactively and exits.
- `matlab` is often not on `$PATH`; invoke the binary inside the install
  (e.g. `/Applications/MATLAB_R<release>.app/bin/matlab`). The exact path is
  machine-specific — record it in `STYLE.local.md` if useful.
