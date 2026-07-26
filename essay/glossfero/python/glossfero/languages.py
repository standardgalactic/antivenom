"""Language fraction computation, per spec/protocol/protocol.md §1d."""

EXTENSION_TO_LANGUAGE = {
    ".py": "Python",
    ".rs": "Rust",
    ".hs": "Haskell",
    ".clj": "Clojure", ".cljc": "Clojure", ".cljs": "Clojure", ".edn": "Clojure",
    ".elm": "Elm",
    ".js": "JavaScript", ".mjs": "JavaScript",
    ".ts": "TypeScript",
    ".md": "Markdown", ".markdown": "Markdown",
    ".toml": "TOML",
    ".json": "JSON",
    ".yaml": "YAML", ".yml": "YAML",
    ".sh": "Shell", ".bash": "Shell",
}


def _extension_of(path: str) -> str:
    name = path.rsplit("/", 1)[-1]
    if "." not in name:
        return ""
    return "." + name.rsplit(".", 1)[-1]


def language_fractions(ls_tree_entries: list[dict]) -> dict[str, float]:
    bytes_by_lang: dict[str, int] = {}
    total = 0
    for entry in ls_tree_entries:
        ext = _extension_of(entry["path"])
        lang = EXTENSION_TO_LANGUAGE.get(ext, "Other")
        bytes_by_lang[lang] = bytes_by_lang.get(lang, 0) + entry["size"]
        total += entry["size"]

    if total == 0:
        return {}

    return {lang: b / total for lang, b in bytes_by_lang.items() if b > 0}
