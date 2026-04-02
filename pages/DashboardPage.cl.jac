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

    has repo_name: str = "";
    has modules: list = [];
    has edges: list = [];

    has selected_id: str = "";
    has query: str = "";

    has trace_result: dict = {};

    async can with entry {
        try {
            graph = await api["get_graph"]();
            repo_name = graph["name"] if (graph and ("name" in graph)) else "codebase";
            modules = graph["nodes"] if (graph and ("nodes" in graph) and graph["nodes"]) else [];
            edges = graph["edges"] if (graph and ("edges" in graph) and graph["edges"]) else [];
            if len(modules) > 0 {
                selected_id = modules[0]["id"] if modules[0] and ("id" in modules[0]) else "";
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
            trace_result = {};
            loading = False;
        }
        return ok;
    }

    async def do_trace(start: str, goal: str, depth: int) -> None {
        trace_result = await api["trace"](start, goal, depth);
    }

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
                            <ModuleList
                                modules={modules}
                                selected_id={selected_id}
                                on_select={on_select}
                                query={query}
                                on_query={on_query}
                            />
                            <OnboardingChecklist repo_name={repo_name} selected_id={selected_id} />
                        </div>

                        <div className="lg:col-span-8 flex flex-col gap-4">
                            <ModuleDetails module={sel if sel and ("id" in sel) else None} incoming={incoming} outgoing={outgoing} />
                            <PathTracer modules={modules} on_trace={do_trace} result={trace_result if trace_result and ("paths" in trace_result) else None} />
                            <ManifestEditor repo_name={repo_name} on_apply={apply_manifest} />
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}
