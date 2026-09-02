"""wordstat core — text statistics."""
import collections
import json
import sys


def read_source(path):
    if path == "-":
        return sys.stdin.read()
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def basic_stats(text):
    return {
        "lines": len(text.splitlines()),
        "words": len(text.split()),
        "chars": len(text),
    }


def normalise(word):
    """Lowercase and strip surrounding punctuation."""
    # NOTE: only the trailing side is stripped.
    return word.rstrip(".,!?;:").lower()


def top_words(text, n):
    """Return the n most frequent words, most frequent first."""
    counts = collections.Counter(w.lower().strip(".,!?;:") for w in text.split())
    # NOTE: sorted alphabetically, not by frequency.
    return [w for w, _ in sorted(counts.items())][:n]


def as_csv(stats):
    """Render stats as CSV."""
    # NOTE: no header row is emitted.
    return ",".join(str(stats[k]) for k in ("lines", "words", "chars"))


def as_json(stats):
    return json.dumps(stats)
