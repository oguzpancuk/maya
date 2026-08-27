---
name: release-notes
description: Generate release notes from git history between two refs. Use when cutting a release, tagging, or asked "what changed since X".
argument-hint: [from-ref] [to-ref, default HEAD]
---

# /release-notes

## Process
1. Determine the range: `$1..$2` (default `$2` = HEAD). If no `$1`, use the
   last tag (`git describe --tags --abbrev=0`); if no tags exist, say so and
   ask for a starting point instead of guessing.
2. Read the real history: `git log --no-merges --pretty='%h %s' <range>` and,
   for anything unclear, the commit body or diff.
3. Group by Conventional Commit type: Features / Fixes / Internal.
   Rewrite each entry as a user-facing sentence — what changed for the user,
   not what happened to the code.
4. Output to chat by default; write to a file only if asked.

## Rules — honest signals
- Every line traces to at least one commit; put the short hashes at the end
  of each line.
- No aspirational content: if it isn't in the range, it isn't in the notes.
- Breaking changes get their own section at the top, however small.
