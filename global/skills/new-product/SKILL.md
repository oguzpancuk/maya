---
name: new-product
description: Instantiate the maya template as a new product repository — copies template/, fills the stack slots interactively, records the maya version, makes the first commit. Use only when deliberately starting a new product.
disable-model-invocation: true
argument-hint: [product-name] [target-directory, default ~/dev/<product-name>]
---

# /new-product — instantiate maya

## Preconditions (check, don't assume)
1. Locate the maya repo: try `~/dev/maya`, else ask me. Run
   `git -C <maya> pull` first so the template is current; report the commit.
2. Target directory must not exist or must be empty. Never overwrite.

## Process
1. Copy `template/` (including dotfiles: `.claude/`, `.github/`,
   `.gitignore`, `.mcp.json.example`) into the target directory.
2. Replace every `{{PRODUCT_NAME}}` placeholder with the product name
   (carriers: `CLAUDE.md`, `docs/PRD.md`, `docs/ROADMAP.md`) and every
   `{{DATE}}` with today's date (carrier: `docs/adr/0001-*.md`). Then grep
   the tree for `{{` to prove no placeholder survived.
3. Fill the `[STACK]` slots interactively — ask me in ONE batch:
   language/runtime, framework(s), package layout (single app / monorepo),
   database, deploy target, test runner. Then:
   - complete the Commands table and Standards slot in `CLAUDE.md`,
   - write the real battery into `.claude/hooks/verify.sh` (typecheck, lint,
     tests, build — whatever the stack offers; remove the placeholder warning),
   - adjust `.github/workflows/ci.yml` setup steps to match.
   Leave anything still unknown as an explicit `[STACK: TODO — <question>]`
   marker; never fill a slot with a guess.
4. Record provenance: write the maya repo's current commit hash to
   `.maya-version` in the new repo.
5. If the stack answers make it possible, offer to fill
   `contracts/init.sh` from `init.sh.example` now (boot + smoke check);
   otherwise leave it — the initializer session writes it before the first
   unattended run (see `contracts/README.md`).
6. `git init`, initial commit: `chore: instantiate from maya <short-hash>`.
7. Register the product in maya's `PRODUCTS.md` (name, repo URL if known,
   local path, the same maya commit as `.maya-version`), commit that in the
   maya repo. An unregistered product is invisible to /update-stack's
   harvest — registration is part of instantiation, not optional.
8. Report: created path, filled slots, remaining TODO slots, and the next
   steps — run /spec, then /mvp-scope, then configure remotes/CI.

## Rules
- Every slot is either correctly filled or a visible TODO. A silently empty
  verify.sh is a false green and is not acceptable.
- Do not install plugins or MCP servers here; the global layer already has
  the plugins, and MCP servers are added per measured need later.
