"""wordstat core — reference implementation used only to validate the grader."""
import collections
import io
import json
import os
import sys

CHUNK = 1 << 20


def _counts_streaming(fh):
    """Line/word/char counts without holding the file in memory (F-010)."""
    lines = words = chars = 0
    tail_is_space = True
    while True:
        chunk = fh.read(CHUNK)
        if not chunk:
            break
        chars += len(chunk)
        lines += chunk.count("\n")
        for ch in chunk:
            if ch.isspace():
                tail_is_space = True
            else:
                if tail_is_space:
                    words += 1
                tail_is_space = False
    return {"lines": lines, "words": words, "chars": chars}


def basic_stats(path):
    if path == "-":
        return _counts_streaming(sys.stdin)
    with open(path, encoding="utf-8") as fh:
        return _counts_streaming(fh)


def read_text(path):
    if path == "-":
        return sys.stdin.read()
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def normalise(word):
    """Lowercase and strip surrounding punctuation."""
    return word.strip(".,!?;:").lower()


def top_words(text, n):
    counts = collections.Counter(w.lower().strip(".,!?;:") for w in text.split() if w.strip(".,!?;:"))
    return counts.most_common(n)


def as_csv(stats):
    return "lines,words,chars\n{lines},{words},{chars}".format(**stats)


def as_json(stats):
    return json.dumps(stats)
