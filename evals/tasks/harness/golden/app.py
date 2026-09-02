#!/usr/bin/env python3
"""wordstat — reference implementation. Satisfies every feature in the list.

Deliberately prints `word: count` for --top: the steps specify an ordering and
say nothing about format, so a grader that only accepts a bare word is testing
its own assumption. This file exists to catch that class of grader bug before
any capacity is spent.
"""
import sys

sys.path.insert(0, "src")
from wordstat import as_csv, as_json, basic_stats, read_text, top_words  # noqa: E402

KNOWN = {"--json", "--csv", "--top"}
BOLD, RESET = "\033[1m", "\033[0m"


def main(argv):
    if not argv or argv[0] != "stats" or len(argv) < 2:
        print("usage: app.py stats <file|-> [--json|--csv] [--top N]", file=sys.stderr)
        return 2
    path, flags = argv[1], argv[2:]

    i = 0
    top_n = None
    while i < len(flags):
        f = flags[i]
        if f not in KNOWN:
            print(f"error: unknown flag {f}", file=sys.stderr)
            print("usage: app.py stats <file|-> [--json|--csv] [--top N]", file=sys.stderr)
            return 2
        if f == "--top":
            i += 1
            if i >= len(flags):
                print("error: --top needs a count", file=sys.stderr)
                return 2
            top_n = int(flags[i])
        i += 1

    try:
        if top_n is not None:
            pairs = top_words(read_text(path), top_n)
            if "--csv" in flags:
                print("word,count")
                for w, c in pairs:
                    print(f"{w},{c}")
            else:
                for w, c in pairs:
                    print(f"{w}: {c}")
            return 0
        stats = basic_stats(path)
    except FileNotFoundError:
        print(f"error: no such file: {path}", file=sys.stderr)
        return 1
    except OSError as exc:
        print(f"error: {exc.strerror}: {path}", file=sys.stderr)
        return 1

    if "--csv" in flags:
        print(as_csv(stats))
        return 0
    if "--json" in flags:
        print(as_json(stats))
        return 0

    colour = sys.stdout.isatty()
    for key in ("lines", "words", "chars"):
        label = f"{BOLD}{key}{RESET}" if colour else key
        print(f"{label}: {stats[key]}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
