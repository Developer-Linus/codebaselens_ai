"""Repo analyzer: build a lightweight module/import manifest from a cloned workspace."""

import from pathlib { Path };
import from os { walk };


def:priv _is_hidden_path(p: str) -> bool {
    parts = p.split("/");
    for part in parts {
        if part.startswith(".") and part not in [".", ".."] {
            return True;
        }
    }
    return False;
}


def:priv _kind_for_file(rel_path: str) -> str {
    if rel_path.endswith(".cl.jac") {
        return "client";
    }
    if rel_path.endswith(".sv.jac") {
        return "backend";
    }
    if rel_path.endswith(".jac") {
        return "backend";
    }
    if rel_path.endswith(".toml") {
        return "config";
    }
    return "unknown";
}


def:priv _extract_import_targets(line: str) -> list[str] {
    # Supports:
    #   import from service.appService { ... }
    #   sv import from ..services.items { ... }
    #   cl import from .index { ... }
    #   import from "@jac/runtime" { ... }
    s = line.strip();
    if not (s.startswith("import from ") or s.startswith("sv import from ") or s.startswith("cl import from ")) {
        return [];
    }

    # Find the token after 'from'
    parts = s.split();
    from_idx = -1;
    for i in range(len(parts)) {
        if parts[i] == "from" {
            from_idx = i;
            break;
        }
    }
    if from_idx < 0 or (from_idx + 1) >= len(parts) {
        return [];
    }

    target = parts[from_idx + 1];
    # Strip trailing '{' if split didn't separate it
    if target.endswith("{") {
        target = target[:-1];
    }

    # Remove quotes
    if (target.startswith('"') and target.endswith('"')) or (target.startswith("'") and target.endswith("'")) {
        target = target[1:-1];
    }

    # Ignore npm/runtime imports
    if target.startswith("@") {
        return [];
    }

    # Convert dotted module path to a likely file path.
    # We keep it simple: service.appService -> service/appService.jac
    # If it already looks like a path, keep it.
    if "/" in target {
        return [target];
    }

    if "." in target {
        return [target.replace(".", "/") + ".jac"];
    }

    return [target];
}


def:pub analyze_workspace(workspace_path: str, repo_url: str = "") -> dict {
    if not workspace_path {
        return {"ok": False, "error": "Missing workspace_path"};
    }

    root = Path(workspace_path);
    if not root.exists() {
        return {"ok": False, "error": "Workspace not found"};
    }

    modules: list[dict] = [];
    module_ids: list[str] = [];

    for dirpath, dirnames, filenames in walk(str(root)) {
        rel_dir = str(Path(dirpath).relative_to(root));
        if rel_dir == "." {
            rel_dir = "";
        }
        if rel_dir and _is_hidden_path(rel_dir) {
            continue;

        # Skip common heavy dirs
        if "node_modules" in dirnames {
            dirnames.remove("node_modules");
        }
        if ".git" in dirnames {
            dirnames.remove(".git");
        }

        for fn in filenames {
            if fn.endswith(".jac") or fn.endswith(".cl.jac") or fn.endswith(".sv.jac") {
                rel_path = str(Path(rel_dir) / fn) if rel_dir else fn;
                if _is_hidden_path(rel_path) {
                    continue;

                full_path = str(Path(dirpath) / fn);
                imports: list[str] = [];
                summary = "";

                try {
                    with open(full_path, "r") as f {
                        lines = f.read().split("\n");
                    # First non-empty line as a tiny summary
                    for ln in lines {
                        t = ln.strip();
                        if t {
                            summary = t[:140];
                            break;
                    for ln in lines {
                        for imp in _extract_import_targets(ln) {
                            if imp and (imp not in imports) {
                                imports.append(imp);
                } except Exception as ex {
                    summary = "(unreadable)";

                modules.append({
                    "id": rel_path,
                    "kind": _kind_for_file(rel_path),
                    "summary": summary,
                    "imports": imports,
                    "exports": [],
                    "calls": [],
                    "tags": []
                });
                module_ids.append(rel_path);

    # Normalize imports to known module ids when possible.
    # If an import points to a file that exists in the repo, keep it.
    # If it points to a dotted-path-derived .jac, try to match by suffix.
    for m in modules {
        norm: list[str] = [];
        for imp in (m["imports"] if (m and ("imports" in m)) else []) {
            if imp in module_ids {
                norm.append(imp);
                continue;

            # Try suffix match (e.g., service/appService.jac)
            hit = "";
            for mid in module_ids {
                if mid.endswith("/" + imp) or mid.endswith(imp) {
                    hit = mid;
                    break;
            if hit {
                norm.append(hit);
            else {
                # Keep unknowns out of the graph to avoid noisy nodes
                pass;
        m["imports"] = norm;

    # Repo name: last path segment of URL, else workspace folder name
    name = "codebase";
    if repo_url {
        parts = repo_url.replace(".git", "").split("/");
        if len(parts) > 0 {
            name = parts[-1] if parts[-1] else name;
    else {
        name = root.name;

    return {"ok": True, "manifest": {"name": name, "repo_url": repo_url, "modules": modules}};
