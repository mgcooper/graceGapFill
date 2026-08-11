# Project-specific code style — graceGapFill

Conventions specific to this project, extending the canonical `STYLE.md` (and any
language conventions merged into it). This file is project-owned — `--update` never
overwrites it.

## Naming

TODO: function/file name casing (e.g. camelCase vs snake_case vs lowercase), package
or namespace layout, variable casing, and any semantic variable prefixes.

## Formatting

TODO: indentation width, line length, how functions are closed, continuation style.

## Idioms and patterns

TODO: preferred patterns (vectorization, input parsing, optional outputs), key
libraries/toolboxes, and how new or risky code is staged.

## Other project conventions

TODO: anything else specific to this project — kernel conventions, argument-ordering
schemas, domain prefixes, etc. Delete this section if unused.

## Prose examples

Rewrite this:

> Note that it's not necessary for the function to return the onCleanup object
> because it works automatically once it's created. However, you might want to
> return it if you need to manually trigger the cleanup (by deleting the object)
> or prevent the cleanup (by keeping a reference to the object so it doesn't get
> deleted).

as this:

> The onCleanup object runs when it is destroyed, so the function does not have
> to return it. Return it to control the cleanup time. Delete the object to run
> the cleanup early. Hold a reference to delay it.
