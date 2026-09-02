#!/usr/bin/env python3
"""wordstat — text statistics CLI."""
import sys

sys.path.insert(0, "src")
from wordstat import as_csv, as_json, basic_stats, read_source, top_words  # noqa: E402


def main(argv):
    if not argv or argv[0] != "stats":
        print("usage: app.py stats <file|-> [--json|--csv] [--top N] [--url U]",
              file=sys.stderr)
        return 2
    args = argv[1:]
    if not args:
        print("usage: app.py stats <file|-> [--json|--csv] [--top N] [--url U]",
              file=sys.stderr)
        return 2

    path, flags = args[0], args[1:]
    text = read_source(path)
    stats = basic_stats(text)

    if "--top" in flags:
        n = int(flags[flags.index("--top") + 1])
        for word in top_words(text, n):
            print(word)
        return 0
    if "--csv" in flags:
        print(as_csv(stats))
        return 0
    if "--json" in flags:
        print(as_json(stats))
        return 0

    for key in ("lines", "words", "chars"):
        print(f"{key}: {stats[key]}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
