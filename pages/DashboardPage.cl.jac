import from ..hooks.useCodebase { useCodebase }
import from ..components.ModuleList { ModuleList }
import from ..components.ModuleDetails { ModuleDetails }
import from ..components.PathTracer { PathTracer }
import from ..components.ManifestEditor { ManifestEditor }
import from "@jac/runtime" { jacLogout, useNavigate }

def:pub page() -> JsxElement {
    api = useCodebase();
    navigate = useNavigate();

    has loading: bool = True;
    has error: str = "";

    has repo_url: str = "";
    has repo_name: str = "codebase";
    has modules: list[dict] = [];
    has edges: list[dict] = [];

    has selected_id: str = "";
    has query: str = "";

    has trace_result: dict = {};
    has active_tab: str = "module";
    has project_summary: str = "";
    has summary_loading: bool = False;
    has summary_error: str = "";

    has projects: list[dict] = [];
    has selected_repo_url: str = "";

    async can with entry {
        loading = True;
        error = "";
        try {
            await refresh_projects();
        } except Exception as ex {
            error = str(ex);
        }
        loading = False;
    }

    async def refresh_projects(prefer_repo_url: str = "") -> None {
        res = await api["list_projects"]();
        projects = res["projects"] if (res and ("projects" in res)) else [];

        avail_urls = [
            str(p["repo_url"])
            for p in projects
            if p and ("repo_url" in p) and p["repo_url"]
        ];

        target_url: str = "";
        if prefer_repo_url and (prefer_repo_url in avail_urls) {
            target_url = prefer_repo_url;
        } elif selected_repo_url and (selected_repo_url in avail_urls) {
            target_url = selected_repo_url;
        } elif avail_urls {
            target_url = avail_urls[0];
        } else {
            target_url = "";
        }

        selected_repo_url = target_url;
        if selected_repo_url {
            await load_graph_for(selected_repo_url);
        } else {
            repo_name = "codebase";
            modules = [];
            edges = [];
            selected_id = "";
            trace_result = {};
        }
    }

    async def load_graph_for(target_url: str) -> None {
        if not target_url {
            repo_name = "codebase";
            modules = [];
            edges = [];
            selected_id = "";
            trace_result = {};
            return;
        }

        repo_url = target_url;
        graph = await api["get_graph"](target_url);
        if graph and ("name" in graph) {
            repo_name = str(graph["name"]);
        } else {
            repo_name = "codebase";
        }
        if graph and ("nodes" in graph) and graph["nodes"] {
            modules = [m for m in graph["nodes"] if m];
        } else {
            modules = [];
        }
        if graph and ("edges" in graph) and graph["edges"] {
            edges = [e for e in graph["edges"] if e];
        } else {
            edges = [];
        }

        if len(modules) > 0 and modules[0] and ("id" in modules[0]) {
            selected_id = str(modules[0]["id"]);
        } else {
            selected_id = "";
        }

        trace_result = {};
        project_summary = "";
        summary_error = "";
    }

    async def handle_project_select(target_url: str) -> None {
        if not target_url {
            return;
        }
        selected_repo_url = target_url;
        loading = True;
        try {
            await load_graph_for(target_url);
            trace_result = {};
            active_tab = "module";
        } finally {
            loading = False;
        }
    }

    def handle_logout() -> None {
        jacLogout();
        navigate("/login");
    }

    def on_repo_url(e: any) -> None {
        if e and ("target" in e) and ("value" in e["target"]) {
            repo_url = str(e["target"]["value"]);
        }
    }

    async def save_repo(e: any) -> None {
        if e and ("preventDefault" in e) {
            e["preventDefault"]();
        }
        trimmed = repo_url.strip();
        if not trimmed {
            return;
        }

        loading = True;
        error = "";
        try {
            res = await api["analyze_project"](trimmed, "", False);
            if not res or ("ok" not in res) or (not res["ok"]) {
                if res and ("error" in res) {
                    error = str(res["error"]);
                } else {
                    error = "Failed to analyze repo";
                }
            } else {
                repo_url = trimmed;
                try {
                    await refresh_projects(prefer_repo_url=trimmed);
                } except Exception as ex {
                    error = str(ex);
                }
                trace_result = {};
                active_tab = "module";
            }
        } except Exception as ex {
            error = str(ex);
        }
        loading = False;
    }

    def on_select(mid: str) -> None {
        selected_id = mid;
        active_tab = "module";
    }

    def on_query(e: any) -> None {
        if e and ("target" in e) and ("value" in e["target"]) {
            query = str(e["target"]["value"]);
        }
    }

    def selected_module() -> dict {
        for m in modules {
            if not m {
                continue;
            }
            if ("id" in m) and (str(m["id"]) == selected_id) {
                return m if m else {};
            }
        }
        return {};
    }

    def incoming_for(mid: str) -> list[str] {
        return [str(e["from"]) for e in edges if e and (e["type"] == "imports") and (e["to"] == mid)];
    }

    def outgoing_for(mid: str) -> list[str] {
        return [str(e["to"]) for e in edges if e and (e["type"] == "imports") and (e["from"] == mid)];
    }

    async def apply_manifest(manifest: dict) -> bool {
        if not selected_repo_url {
            return False;
        }
        ok = await api["set_manifest"](selected_repo_url, manifest);
        if ok {
            loading = True;
            error = "";
            try {
                await load_graph_for(selected_repo_url);
                trace_result = {};
                active_tab = "module";
            } except Exception as ex {
                error = str(ex);
            }
            loading = False;
        }
        return True if ok else False;
    }

    async def do_trace(start: str, goal: str, depth: int) -> None {
        if not selected_repo_url {
            trace_result = {"start": start, "goal": goal, "start_exists": False, "goal_exists": False, "paths": []};
            return;
        }
        trace_result = await api["trace"](selected_repo_url, start, goal, depth);
    }

    async def fetch_summary() -> None {
        if not selected_repo_url {
            return;
        }
        summary_loading = True;
        summary_error = "";
        try {
            res = await api["get_summary"](selected_repo_url);
            if res and res["ok"] {
                project_summary = str(res["summary"]);
            } else {
                summary_error = str(res["error"]) if (res and "error" in res) else "Failed to generate summary";
            }
        } except Exception as ex {
            summary_error = str(ex);
        }
        summary_loading = False;
    }

    def set_tab(t: str) -> None {
        active_tab = t;
        if t == "summary" and not project_summary and not summary_loading {
            fetch_summary();
        }
    }

    sel = selected_module();
    incoming = incoming_for(selected_id) if selected_id else [];
    outgoing = outgoing_for(selected_id) if selected_id else [];

    has_modules = len(modules) > 0;

    return (
        <div className="page">
            <div className="page-container max-w-[72rem]">

                <div className="page-header">
                    <div>
                        <h1>CodebaseLens</h1>
                        <p className="text-sm text-muted-foreground">
                            {"Explore import graphs for Jac codebases."}
                        </p>
                    </div>
                    <button className="btn btn-ghost" onClick={handle_logout}>{"Sign out"}</button>
                </div>

                {error and (<div className="error-box mb-5">{error}</div>)}

                {loading and (
                    <div className="card p-6">
                        <div className="text-sm text-muted-foreground">{"Analyzing repository…"}</div>
                    </div>
                )}

                {(not loading) and (
                    <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">

                        <div className="lg:col-span-4 flex flex-col gap-4">
                            <div className="card p-5">
                                <label className="label">{"GitHub repository"}</label>
                                <form onSubmit={save_repo} className="flex gap-2 mt-1">
                                    <input
                                        className="input flex-1"
                                        value={repo_url}
                                        onChange={on_repo_url}
                                        placeholder="https://github.com/org/repo"
                                    />
                                    <button className="btn btn-primary" type="submit" disabled={not repo_url.strip()}>
                                        {"Analyze"}
                                    </button>
                                </form>

                                <div className="mt-6 space-y-3">
                                    <div className="flex items-center justify-between">
                                        <span className="text-xs font-semibold">{"Tracked projects"}</span>
                                        <span className="text-xs text-muted-foreground">{str(len(projects)) + " saved"}</span>
                                    </div>
                                    {(not projects) and (
                                        <div className="text-xs text-muted-foreground">
                                            {"Analyze a repo to cache it here for quick access."}
                                        </div>
                                    )}
                                    {projects and (
                                        <div className="space-y-2">
                                            {[
                                                (
                                                    <button
                                                        key={str(proj["repo_url"])}
                                                        type="button"
                                                        className={
                                                            "w-full rounded-[1rem] border px-4 py-3 text-left transition-colors" +
                                                            (
                                                                " border-primary bg-primary/5"
                                                                if (proj and ("repo_url" in proj) and (str(proj["repo_url"]) == selected_repo_url))
                                                                else " border-border bg-surface"
                                                            )
                                                        }
                                                        onClick={lambda: handle_project_select(str(proj["repo_url"]))}
                                                    >
                                                        <div className="text-sm font-semibold text-foreground">
                                                            {proj["name"] if (proj and ("name" in proj)) else str(proj["repo_url"])}
                                                        </div>
                                                        <div className="text-xs text-muted-foreground">
                                                            {str(proj["module_count"] if (proj and ("module_count" in proj)) else 0) + " modules"}
                                                        </div>
                                                        <div className="text-xs text-muted-foreground">
                                                            {str(proj["repo_url"])}
                                                        </div>
                                                    </button>
                                                )
                                                for proj in projects
                                                if (proj and ("repo_url" in proj) and proj["repo_url"])
                                            ]}
                                        </div>
                                    )}
                                </div>
                            </div>

                            {has_modules and (
                                <ModuleList
                                    modules={modules}
                                    selected_id={selected_id}
                                    on_select={on_select}
                                    query={query}
                                    on_query={on_query}
                                />
                            )}
                        </div>

                        <div className="lg:col-span-8 flex flex-col gap-3">
                            {(not has_modules) and (
                                <div className="card p-10 text-center">
                                    <div className="db-empty-icon">{"⬡"}</div>
                                    <div className="text-base font-semibold mt-3 mb-2">{"Paste a repo URL to get started"}</div>
                                    <div className="text-sm text-muted-foreground max-w-xs mx-auto">
                                        {"Enter a public GitHub URL on the left and click Analyze. CodebaseLens will map the full import graph."}
                                    </div>
                                </div>
                            )}

                            {has_modules and (
                                <>
                                    <div className="db-tab-bar">
                                        <button
                                            className={"db-tab" + (" db-tab-active" if active_tab == "module" else "")}
                                            onClick={lambda: set_tab("module")}
                                        >
                                            {"Module"}
                                        </button>
                                        <button
                                            className={"db-tab" + (" db-tab-active" if active_tab == "trace" else "")}
                                            onClick={lambda: set_tab("trace")}
                                        >
                                            {"Trace paths"}
                                        </button>
                                        <button
                                            className={"db-tab" + (" db-tab-active" if active_tab == "manifest" else "")}
                                            onClick={lambda: set_tab("manifest")}
                                        >
                                            {"Manifest"}
                                        </button>
                                        <button
                                            className={"db-tab" + (" db-tab-active" if active_tab == "summary" else "")}
                                            onClick={lambda: set_tab("summary")}
                                        >
                                            {"Summary"}
                                        </button>
                                    </div>

                                    {(active_tab == "module") and (
                                        <ModuleDetails
                                            module={sel if sel and ("id" in sel) else None}
                                            incoming={incoming}
                                            outgoing={outgoing}
                                        />
                                    )}
                                    {(active_tab == "trace") and (
                                        <PathTracer
                                            modules={modules}
                                            on_trace={do_trace}
                                            result={trace_result if trace_result and ("paths" in trace_result) else None}
                                        />
                                    )}
                                    {(active_tab == "manifest") and (
                                        <ManifestEditor
                                            repo_name={repo_name}
                                            on_apply={apply_manifest}
                                        />
                                    )}
                                    {(active_tab == "summary") and (
                                        <div className="card p-6">
                                            <div className="flex items-start justify-between gap-4 mb-4">
                                                <div>
                                                    <h2 className="text-sm font-semibold">{"Project summary"}</h2>
                                                    <p className="text-xs text-muted-foreground">{"AI-generated overview of modules and dependencies."}</p>
                                                </div>
                                                <button
                                                    className="btn btn-primary text-xs"
                                                    onClick={fetch_summary}
                                                    disabled={summary_loading}
                                                >
                                                    {summary_loading and "Generating…" or (project_summary and "Regenerate" or "Generate")}
                                                </button>
                                            </div>
                                            {summary_error and (
                                                <div className="text-sm text-red-500 mb-3">{summary_error}</div>
                                            )}
                                            {(not summary_loading) and (not project_summary) and (not summary_error) and (
                                                <div className="text-sm text-muted-foreground">
                                                    {"Click Generate to create an AI summary of this project's structure and dependencies."}
                                                </div>
                                            )}
                                            {summary_loading and (
                                                <div className="text-sm text-muted-foreground">{"Analyzing modules and generating summary…"}</div>
                                            )}
                                            {project_summary and (
                                                <div className="text-sm leading-relaxed whitespace-pre-wrap text-foreground">{project_summary}</div>
                                            )}
                                        </div>
                                    )}
                                </>
                            )}
                        </div>

                    </div>
                )}
            </div>
        </div>
    );
}
