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


def _kind_for_file(rel_path: str) -> str {
    if rel_path.endswith(".cl.jac") {
        return "client";
    }
    if rel_path.endswith(".sv.jac") {
        return "service";
    }
    return "module";
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

    # Normalize dotted module path to a likely file path
    if "." in target {
        return [target.replace(".", "/") + ".jac"];
    }

    return [target];
}


def:pub analyze_workspace(workspace_path: str, repo_url: str = "") -> dict {
    if not workspace_path {
        return {"ok": False, "error": "Missing workspace_path"};
    }

    root_path = Path(workspace_path);
    if not root_path.exists() {
        return {"ok": False, "error": "Workspace not found"};
    }

    modules: list[dict] = [];
    module_ids: list[str] = [];

    for entry in walk(str(root_path)) {
        dirpath = str(entry[0]);
        filenames = entry[2];

        rel_dir = str(Path(dirpath).relative_to(root_path));
        if rel_dir == "." {
            rel_dir = "";
        }
        if rel_dir and _is_hidden_path(rel_dir) {
            continue;
        }

        # Skip common non-Jac frontend/build folders inside cloned repos.
        # This prevents the preview from attempting to compile unrelated .jac files.
        if rel_dir.startswith("frontend") or rel_dir.startswith("src") or rel_dir.startswith("node_modules") or rel_dir.startswith("dist") or rel_dir.startswith("build") {
            continue;
        }

        for fn in filenames {
            fn_s = str(fn);
            if fn_s.endswith(".jac") or fn_s.endswith(".cl.jac") or fn_s.endswith(".sv.jac") {
                rel_path = str(Path(rel_dir) / fn_s) if rel_dir else fn_s;
                if _is_hidden_path(rel_path) {
                    continue;
                }

                full_path = str(Path(dirpath) / fn_s);
                imports: list[str] = [];
                summary = "";

                try {
                    with open(full_path, "r") as f {
                        lines = f.read().split("\n");
                    }

                    for ln in lines {
                        t = ln.strip();
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
            }
        }
    }

    # Normalize imports to known module ids when possible.
    for m in modules {
        norm: list[str] = [];
        imps = m["imports"] if (m and ("imports" in m)) else [];
        for imp_any in imps {
            imp = str(imp_any);
            if imp in module_ids {
                norm.append(imp);
                continue;
            }

            hit = "";
            for mid_any in module_ids {
                mid = str(mid_any);
                if mid.endswith("/" + imp) or mid.endswith(imp) {
                    hit = mid;
                    break;
                }
            }
            if hit {
                norm.append(hit);
            }
        }
        m["imports"] = norm;
    }

    # Repo name: last path segment of URL, else workspace folder name
    name = "codebase";
    if repo_url {
        parts = repo_url.replace(".git", "").split("/");
        if len(parts) > 0 {
            name = parts[len(parts) - 1] if parts[len(parts) - 1] else name;
        }
    } else {
        name = root.name;
    }

    return {"ok": True, "manifest": {"name": name, "repo_url": repo_url, "modules": modules}};
}
