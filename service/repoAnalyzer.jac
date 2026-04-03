import from pathlib { Path }
import from os { walk }


def _is_hidden_path(p: str) -> bool {
    parts = p.split("/");
    for seg in parts {
        if seg and seg[0] == "." {
            return True;
        }
    }
    return False;
}


def _should_skip_dir(rel_dir: str) -> bool {
    if not rel_dir {
        return False;
    }

    # Normalize to forward slashes
    d = rel_dir.replace("\\", "/");

    # Skip hidden folders anywhere
    if _is_hidden_path(d) {
        return True;
    }

    # Skip common vendor/build/cache folders
    skip_prefixes = [
        "node_modules",
        "dist",
        "build",
        "out",
        "target",
        "coverage",
        "__pycache__",
        ".venv",
        "venv",
        ".git",
        ".jac",
        ".next",
        ".nuxt",
        ".svelte-kit",
        ".cache",
        ".pytest_cache",
        ".mypy_cache",
        ".idea",
        ".vscode"
    ];

    for pref in skip_prefixes {
        if d == pref or d.startswith(pref + "/") {
            return True;
        }
    }

    return False;
}


def _kind_for_file(rel_path: str) -> str {
    if rel_path.endswith(".cl.jac") {
        return "client";
    }
    if rel_path.endswith(".sv.jac") {
        return "service";
    }
    if rel_path.endswith(".jac") {
        return "module";
    }
    if rel_path.endswith(".md") or rel_path.endswith(".rst") {
        return "doc";
    }
    if rel_path.endswith(".toml") or rel_path.endswith(".yaml") or rel_path.endswith(".yml") {
        return "config";
    }
    return "file";
}


def _extract_import_targets(line: str) -> list[str] {
    ln = line.strip();
    if not ln {
        return [];
    }

    # Only handle Jac import forms we care about.
    if (not ln.startswith("import from ")) and (not ln.startswith("sv import from ")) and (not ln.startswith("cl import from ")) {
        return [];
    }

    parts = ln.split();
    from_idx = -1;
    for i in range(len(parts)) {
        if parts[i] == "from" {
            from_idx = i;
            break;
        }
    }
    if from_idx < 0 {
        return [];
    }
    if from_idx + 1 >= len(parts) {
        return [];
    }

    target: str = str(parts[from_idx + 1]);

    # Strip trailing "{" if split didn't separate it
    if target and target[len(target) - 1] == "{" {
        target = target[: len(target) - 1];
    }

    # Remove quotes
    if len(target) >= 2 {
        if (target[0] == '"' and target[len(target) - 1] == '"') or (target[0] == "'" and target[len(target) - 1] == "'") {
            target = target[1 : len(target) - 1];
        }
    }

    # Ignore npm/runtime imports
    if target.startswith("@") {
        return [];
    }

    # Ignore obvious URLs
    if target.startswith("http://") or target.startswith("https://") {
        return [];
    }

    # Normalize dotted module path to a likely file path.
    # Leave relative imports (starting with ".") intact so _resolve_import can handle them.
    if "." in target and not target.startswith(".") {
        return [target.replace(".", "/")];
    }

    return [target];
}


def _candidate_paths_for_target(target: str) -> list[str] {
    # Given an import target token (already de-quoted), generate likely repo-relative paths.
    t = target.strip();
    if not t {
        return [];
    }

    # If it already looks like a path, keep it.
    if "/" in t {
        base = t;
    } else {
        base = t;
    }

    # If it already has an extension, keep as-is.
    if base.endswith(".jac") or base.endswith(".cl.jac") or base.endswith(".sv.jac") {
        return [base];
    }

    # Try Jac module variants.
    return [
        base + ".jac",
        base + ".cl.jac",
        base + ".sv.jac",
        base + "/__init__.jac",
        base + "/__init__.cl.jac",
        base + "/__init__.sv.jac"
    ];
}


def _resolve_import(current_rel: str, target: str, known: dict) -> str {
    # Returns a module id (repo-relative path) if resolvable, else "".
    t = target.strip();
    if not t {
        return "";
    }

    # Ignore npm/runtime imports
    if t.startswith("@") {
        return "";
    }

    # If already a known module id
    if t in known {
        return t;
    }

    cur_dir = str(Path(current_rel).parent).replace("\\", "/");
    if cur_dir == "." {
        cur_dir = "";
    }

    # Relative dot imports: .foo, ..foo, ...foo
    if t.startswith(".") {
        dot_count = 0;
        for ch in t {
            if ch == "." {
                dot_count += 1;
            } else {
                break;
            }
        }
        rest = t[dot_count:];
        if rest.startswith("/") {
            rest = rest[1:];
        }
        rest = rest.replace(".", "/");
        base_dir = cur_dir;
        up = dot_count - 1;
        for _ in range(up) {
            base_dir = str(Path(base_dir).parent).replace("\\", "/");
            if base_dir == "." {
                base_dir = "";
            }
        }
        rel_base = (base_dir + "/" + rest) if base_dir and rest else (rest if rest else base_dir);
        for cand in _candidate_paths_for_target(rel_base) {
            if cand in known {
                return cand;
            }
        }
        return "";
    }

    # Dotted module path: a.b.c
    if "." in t {
        t = t.replace(".", "/");
    }

    # Try as repo-relative
    for cand in _candidate_paths_for_target(t) {
        if cand in known {
            return cand;
        }
    }

    # Try relative to current directory
    if cur_dir {
        for cand in _candidate_paths_for_target(cur_dir + "/" + t) {
            if cand in known {
                return cand;
            }
        }
    }

    # Fallback: suffix match (best-effort)
    for mid in known {
        if mid.endswith("/" + t) or mid.endswith(t) {
            return str(mid);
        }
    }

    return "";
}


def _read_summary_and_imports(full_path: str) -> dict {
    summary = "";
    imports: list[str] = [];

    try {
        with open(full_path, "r") as f {
            lines = f.read().split("\n");
        }

        for ln in lines {
            t = str(ln).strip();
            if t {
                summary = t[:140];
                break;
            }
        }

        for ln in lines {
            for imp in _extract_import_targets(str(ln)) {
                if imp and (imp not in imports) {
                    imports.append(str(imp));
                }
            }
        }
    } except Exception {
        summary = "(unreadable)";
    }

    return {"summary": summary, "imports": imports};
}


def:pub analyze_workspace(workspace_path: str, repo_url: str = "") -> dict {
    if not workspace_path {
        return {"ok": False, "error": "Missing workspace_path"};
    }

    root_path = Path(workspace_path);
    if not root_path.exists() {
        return {"ok": False, "error": "Workspace not found"};
    }

    # 1) Index files (module ids)
    modules: list[dict] = [];
    known: dict = {};

    for entry in walk(str(root_path)) {
        dirpath = str(entry[0]);
        filenames = entry[2];

        rel_dir = str(Path(dirpath).relative_to(root_path)).replace("\\", "/");
        if rel_dir == "." {
            rel_dir = "";
        }
        if _should_skip_dir(rel_dir) {
            continue;
        }

        for fn in filenames {
            fn_s = str(fn);
            rel_path = (rel_dir + "/" + fn_s) if rel_dir else fn_s;
            rel_path = rel_path.replace("\\", "/");

            if _is_hidden_path(rel_path) {
                continue;
            }

            # Include Jac sources + a few useful metadata files.
            is_jac = rel_path.endswith(".jac") or rel_path.endswith(".cl.jac") or rel_path.endswith(".sv.jac");
            is_meta = rel_path.endswith("jac.toml") or rel_path.endswith("README.md") or rel_path.endswith("readme.md");
            if not (is_jac or is_meta) {
                continue;
            }

            full_path = str(Path(dirpath) / fn_s);
            info = _read_summary_and_imports(full_path) if is_jac else {"summary": "", "imports": []};

            mid = rel_path;
            known[mid] = True;
            modules.append({
                "id": mid,
                "kind": _kind_for_file(mid),
                "summary": info["summary"],
                "imports": info["imports"],
                "exports": [],
                "calls": [],
                "tags": []
            });
        }
    }

    # 2) Resolve imports to known module ids
    for m in modules {
        mid = str(m["id"]);
        raw = m["imports"] if (m and ("imports" in m) and m["imports"]) else [];
        resolved: list[str] = [];

        for imp_any in raw {
            imp = str(imp_any);
            hit = _resolve_import(current_rel=mid, target=imp, known=known);
            if hit and (hit not in resolved) {
                resolved.append(hit);
            }
        }

        m["imports"] = resolved;
    }

    # 3) Repo name: last path segment of URL, else workspace folder name
    name = "codebase";
    if repo_url {
        parts = repo_url.replace(".git", "").split("/");
        if len(parts) > 0 {
            name = parts[len(parts) - 1] if parts[len(parts) - 1] else name;
        }
    } else {
        name = str(root_path.name);
    }

    return {"ok": True, "manifest": {"name": name, "repo_url": repo_url, "modules": modules}};
}
