def:pub PathTracer(props: dict) -> JsxElement {
    modules = props["modules"] or [];
    on_trace = props["on_trace"];
    result = props["result"] or {};

    has start: str = "";
    has goal: str = "";
    has max_depth: str = "6";
    has tracing: bool = False;
    has traced: bool = False;
    has trace_error: str = "";

    def _val(e: any) -> str {
        if not e { return ""; }
        if ("target" in e) and e["target"] and ("value" in e["target"]) {
            return str(e["target"]["value"]);
        }
        if "value" in e {
            return str(e["value"]);
        }
        return "";
    }

    def on_start(e: any) -> None { start = _val(e); }
    def on_goal(e: any) -> None { goal = _val(e); }
    def on_depth(e: any) -> None { max_depth = _val(e); }

    async def submit(e: any) -> None {
        if e and ("preventDefault" in e) {
            e["preventDefault"]();
        }
        if not start or not goal {
            return;
        }
        depth = int(max_depth) if max_depth else 6;
        tracing = True;
        traced = False;
        trace_error = "";
        try {
            await on_trace(start, goal, depth);
        } except Exception as ex {
            trace_error = str(ex);
        }
        tracing = False;
        traced = True;
    }

    paths = result["paths"] if ("paths" in result) else [];
    start_exists = result["start_exists"] if ("start_exists" in result) else True;
    goal_exists = result["goal_exists"] if ("goal_exists" in result) else True;

    def path_row(p: any, idx: int) -> JsxElement {
        return (
            <div key={"p" + str(idx)} className="rounded-[0.75rem] border border-border bg-surface px-3 py-2 text-sm">
                {" → ".join([str(x) for x in (p or [])])}
            </div>
        );
    }

    return (
        <div className="card p-6">
            <div className="flex items-start justify-between gap-4 mb-4">
                <div>
                    <h2 className="text-sm font-semibold">Trace a connection</h2>
                    <p className="text-xs text-muted-foreground">Find import paths between two modules (BFS, up to 5 paths).</p>
                </div>
            </div>

            <form onSubmit={submit} className="grid grid-cols-1 md:grid-cols-3 gap-3">
                <div>
                    <label className="label">Start</label>
                    <select className="input" value={start} onChange={on_start}>
                        <option value="">Select…</option>
                        {[<option key={str(m["id"])} value={str(m["id"])}>{str(m["id"])}</option> for m in modules if m and ("id" in m)]}
                    </select>
                </div>
                <div>
                    <label className="label">Goal</label>
                    <select className="input" value={goal} onChange={on_goal}>
                        <option value="">Select…</option>
                        {[<option key={str(m["id"])} value={str(m["id"])}>{str(m["id"])}</option> for m in modules if m and ("id" in m)]}
                    </select>
                </div>
                <div>
                    <label className="label">Max depth</label>
                    <input className="input" value={max_depth} onChange={on_depth} placeholder="6" />
                </div>

                <div className="md:col-span-3 flex items-center justify-between gap-3 mt-1">
                    <button className="btn btn-primary" type="submit" disabled={tracing or not start or not goal}>
                        {tracing and "Tracing…" or "Trace"}
                    </button>
                </div>
            </form>

            <div className="mt-4 flex flex-col gap-2">
                {trace_error and (
                    <div className="text-sm text-red-500">{trace_error}</div>
                )}
                {(not tracing) and traced and (not start_exists) and (
                    <div className="text-sm text-muted-foreground">Start module not found in graph.</div>
                )}
                {(not tracing) and traced and (not goal_exists) and (
                    <div className="text-sm text-muted-foreground">Goal module not found in graph.</div>
                )}
                {(not tracing) and traced and start_exists and goal_exists and (len(paths) == 0) and (
                    <div className="text-sm text-muted-foreground">No paths found (try increasing max depth).</div>
                )}
                {(len(paths) > 0) and (
                    <div className="flex flex-col gap-2">
                        {[path_row(paths[i], i) for i in range(len(paths))]}
                    </div>
                )}
            </div>
        </div>
    );
}
