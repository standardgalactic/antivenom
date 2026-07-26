"""remote -> repo_id, per spec/protocol/protocol.md §1a."""
import hashlib


def normalize_remote(remote: str) -> str:
    r = remote.strip()

    if r.startswith("git@"):
        host_path = r[len("git@"):]
        host, _, path = host_path.partition(":")
        r = f"ssh://git@{host}/{path}"

    if "://" in r:
        scheme, rest = r.split("://", 1)
        if "/" in rest:
            host, path = rest.split("/", 1)
        else:
            host, path = rest, ""
        r = f"{scheme.lower()}://{host.lower()}/{path}" if path else f"{scheme.lower()}://{host.lower()}"

    if r.endswith(".git"):
        r = r[:-4]
    if r.endswith("/"):
        r = r[:-1]

    return r


def repo_id(remote: str) -> str:
    normalized = normalize_remote(remote)
    digest = hashlib.sha256(normalized.encode("utf-8")).hexdigest()
    return f"sha256:{digest}"
