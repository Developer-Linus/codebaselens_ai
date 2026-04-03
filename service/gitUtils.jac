"""Git utilities for cloning GitHub repos into a temporary workspace.

These helpers are used by backend endpoints to fetch a repo for analysis.
"""

import from os { makedirs }
import from pathlib { Path }
import from shutil { rmtree }
import from subprocess { run }
import from uuid { uuid4 }


def:priv _safe_repo_slug(repo_url: str) -> str {
    slug = repo_url;
    slug = slug.replace("https://", "");
    slug = slug.replace("http://", "");
    slug = slug.replace("git@", "");
    slug = slug.replace(":", "/");
    slug = slug.replace(".git", "");
    slug = slug.replace("/", "_");
    slug = slug.replace(" ", "_");
    return slug;
}


def:priv _workspace_root() -> str {
    # Keep clones outside the project tree so the dev server won't watch them.
    return str(Path("/tmp/codebaselens/repos"));
}


def:pub make_repo_workspace(repo_url: str) -> dict {
    root_dir = _workspace_root();
    makedirs(root_dir, exist_ok=True);

    slug = _safe_repo_slug(repo_url);
    ws_id = str(uuid4());
    ws_path = str(Path(root_dir) / (slug + "__" + ws_id));
    makedirs(ws_path, exist_ok=True);

    return {"ok": True, "workspace_id": ws_id, "path": ws_path};
}


def:pub cleanup_workspace(path: str) -> dict {
    try {
        if path {
            rmtree(path, ignore_errors=True);
        }
        return {"ok": True};
    } except Exception as ex {
        return {"ok": False, "error": str(ex)};
    }
}


def:pub clone_github_repo(repo_url: str, token: str = "", depth: int = 1) -> dict {
    ws = make_repo_workspace(repo_url);
    if not ws or not ws["ok"] {
        return {"ok": False, "error": "Failed to create workspace"};
    }

    ws_path = ws["path"];

    # Build a non-interactive URL if a token is provided.
    clone_url = repo_url;
    if token and repo_url.startswith("https://") {
        clone_url = repo_url.replace("https://", "https://" + token + "@", 1);
    }

    cmd = ["git", "clone", "--depth", str(depth), clone_url, ws_path];

    try {
        res = run(cmd, capture_output=True, text=True);
        if res.returncode != 0 {
            cleanup_workspace(ws_path);
            err = res.stderr if res.stderr else res.stdout;
            return {"ok": False, "error": err, "cmd": " ".join(cmd)};
        }
        return {
            "ok": True,
            "repo_url": repo_url,
            "workspace_id": ws["workspace_id"],
            "path": ws_path
        };
    } except Exception as ex {
        cleanup_workspace(ws_path);
        return {"ok": False, "error": str(ex)};
    }
}
