import from ..hooks.useCodebase { useCodebase }
import from ..components.ModuleList { ModuleList }
import from ..components.ModuleDetails { ModuleDetails }
import from ..components.PathTracer { PathTracer }
import from ..components.ManifestEditor { ManifestEditor }
import from "@jac/runtime" { jacLogout, useNavigate }

def:pub page() -> JsxElement {
    api = useCodebase();
    navigate = api["navigate"];

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

    async can with entry {
        try {
            manifest = await api["get_manifest"]();
            if manifest and ("repo_url" in manifest) {
                repo_url = str(manifest["repo_url"]);
            }

            graph = await api["get_graph"]();
            if graph and ("name" in graph) {
                repo_name = str(graph["name"]);
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
            }
        } except Exception as ex {
            error = str(ex);
        }
        loading = False;
    }

    def handle_logout() -> None {
        api["logout"]();
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
        if not repo_url.strip() {
            return;
        }

        loading = True;
        error = "";
        try {
            res = await api["clone_and_analyze"](repo_url.strip(), "");
            if not res or ("ok" not in res) or (not res["ok"]) {
                if res and ("error" in res) {
                    error = str(res["error"]);
                } else {
                    error = "Failed to clone/analyze repo";
                }
            } else {
                graph = await api["get_graph"]();
                if graph and ("name" in graph) {
                    repo_name = str(graph["name"]);
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
        ok = await api["set_manifest"](manifest);
        if ok {
            loading = True;
            error = "";
            graph = await api["get_graph"]();
            if graph and ("name" in graph) {
                repo_name = str(graph["name"]);
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
                modules = [];
                edges = [];
            }

            trace_result = {};
            active_tab = "module";
            loading = False;
        }
        return True if ok else False;
    }

    async def do_trace(start: str, goal: str, depth: int) -> None {
        trace_result = await api["trace"](start, goal, depth);
    }

    def set_tab(t: str) -> None {
        active_tab = t;
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
                                </>
                            )}
                        </div>

                    </div>
                )}
            </div>
        </div>
    );
}
