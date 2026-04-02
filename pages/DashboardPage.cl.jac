import from "@jac/runtime" { jacLogout, useNavigate }

import from ..hooks.useCodebase { useCodebase }
import from ..components.ModuleList { ModuleList }
import from ..components.ModuleDetails { ModuleDetails }
import from ..components.PathTracer { PathTracer }
import from ..components.ManifestEditor { ManifestEditor }
import from ..components.OnboardingChecklist { OnboardingChecklist }


def:pub page() -> JsxElement {
    api = useCodebase();
    navigate = useNavigate();

    has loading: bool = True;
    has error: str = "";

    has repo_url: str = "";
    has repo_name: str = "";
    has modules: list = [];
    has edges: list = [];

    has selected_id: str = "";
    has query: str = "";

    has trace_result: dict = {};

    async can with entry {
        try {
            manifest = await api["get_manifest"]();
            repo_url = manifest["repo_url"] if (manifest and ("repo_url" in manifest)) else "";

            graph = await api["get_graph"]();
            repo_name = graph["name"] if (graph and ("name" in graph)) else "codebase";
            modules = graph["nodes"] if (graph and ("nodes" in graph) and graph["nodes"]) else [];
            edges = graph["edges"] if (graph and ("edges" in graph) and graph["edges"]) else [];
            if len(modules) > 0 {
                selected_id = (modules[0]["id"] if (len(modules) > 0 and modules[0] and ("id" in modules[0])) else "");
            }
        } except Exception as ex {
            error = str(ex);
        }
        loading = False;
    }

    def handle_logout() -> None {
        jacLogout();
        navigate("/login");
    }

    def on_repo_url(e: any) -> None {
        repo_url = e.target.value;
    }

    async def save_repo(e: any) -> None {
        e.preventDefault();
        if not repo_url.strip() { return; }
        ok = await api["set_manifest"]({"repo_url": repo_url.strip()});
        if ok {
            error = "";
        }
    }

    def on_select(mid: str) -> None {
        selected_id = mid;
    }

    def on_query(e: any) -> None {
        query = e.target.value;
    }

    def selected_module() -> dict {
        for m in modules {
            if not m { continue; }
            if ("id" in m) and (m["id"] == selected_id) {
                return m;
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
            repo_name = graph["name"] if (graph and ("name" in graph)) else "codebase";
            modules = graph["nodes"] if (graph and ("nodes" in graph) and graph["nodes"]) else [];
            edges = graph["edges"] if (graph and ("edges" in graph) and graph["edges"]) else [];
            selected_id = (modules[0]["id"] if (len(modules) > 0 and modules[0] and ("id" in modules[0])) else "");
            if not selected_id { modules = []; edges = []; }
            trace_result = {};
            loading = False;
        }
        return ok;
    }

    async def do_trace(start: str, goal: str, depth: int) -> None {
        trace_result = await api["trace"](start, goal, depth);
    }

    has_repo = bool(repo_url and repo_url.strip());

    sel = selected_module();
    incoming = incoming_for(selected_id) if selected_id else [];
    outgoing = outgoing_for(selected_id) if selected_id else [];

    return (
        <div className="page">
            <div className="page-container max-w-[72rem]">
                <div className="page-header">
                    <div>
                        <h1>CodebaseLens</h1>
                        <p className="text-sm text-muted-foreground">
                            Explore how files connect, then follow a guided onboarding path.
                        </p>
                    </div>
                    <div className="flex items-center gap-2">
                        <div className="text-xs text-muted-foreground hidden md:block">
                            Repo: <span className="text-foreground font-medium">{str(repo_name)}</span>
                        </div>
                        <button className="btn btn-ghost" onClick={handle_logout}>Sign out</button>
                    </div>
                </div>

                {error and (<div className="error-box mb-5">{error}</div>)}

                {loading
                and (
                    <div className="card p-6">
                        <div className="text-sm text-muted-foreground">Loading graph…</div>
                    </div>
                )}

                {(not loading)
                and (
                    <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
                        <div className="lg:col-span-4 flex flex-col gap-4">
                            <div className="card p-5">
                                <div className="flex items-start justify-between gap-3">
                                    <div>
                                        <div className="text-sm font-semibold">1) Paste a public GitHub repo link</div>
                                        <div className="text-xs text-muted-foreground mt-1">
                                            This unlocks the rest of the onboarding explorer.
                                        </div>
                                    </div>
                                    {has_repo and (
                                        <span className="text-xs px-2 py-1 rounded-full bg-emerald-500/10 text-emerald-300 border border-emerald-500/20">
                                            Linked
                                        </span>
                                    )}
                                </div>
                                <form onSubmit={save_repo} className="mt-4 flex gap-2">
                                    <input
                                        className="input flex-1"
                                        value={repo_url}
                                        onChange={on_repo_url}
                                        placeholder="https://github.com/org/repo"
                                    />
                                    <button className="btn" type="submit" disabled={not repo_url.strip()}>
                                        Analyze
                                    </button>
                                </form>
                                <div className="text-xs text-muted-foreground mt-3">
                                    Tip: you can still use the Manifest panel later to paste a full module manifest.
                                </div>
                            </div>

                            {has_repo and (
                                <ModuleList
                                    modules={modules}
                                    selected_id={selected_id}
                                    on_select={on_select}
                                    query={query}
                                    on_query={on_query}
                                />
                            )}

                            <OnboardingChecklist repo_name={repo_name} selected_id={selected_id} />
                        </div>

                        <div className="lg:col-span-8 flex flex-col gap-4">
                            {(not has_repo)
                            and (
                                <div className="card p-8">
                                    <div className="text-lg font-semibold">Connect a repo to begin</div>
                                    <div className="text-sm text-muted-foreground mt-2 max-w-[52ch]">
                                        Paste a public GitHub repo link on the left. Then you’ll be able to explore modules,
                                        see imports/imported-by, and trace paths across the codebase.
                                    </div>
                                </div>
                            )}

                            {has_repo and (
                                <>
                                    <ModuleDetails module={sel if sel and ("id" in sel) else None} incoming={incoming} outgoing={outgoing} />
                                    <PathTracer modules={modules} on_trace={do_trace} result={trace_result if trace_result and ("paths" in trace_result) else None} />
                                    <ManifestEditor repo_name={repo_name} on_apply={apply_manifest} />
                                </>
                            )}
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}
