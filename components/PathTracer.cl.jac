def:pub PathTracer(props: dict) -> JsxElement {
    modules = props["modules"] or [];
    on_trace = props["on_trace"];
    result = props["result"] or {};

    has start: str = "";
    has goal: str = "";
    has max_depth: str = "6";

    def on_start(e: any) -> None {
        if e and ("target" in e) and ("value" in e["target"]) {
            start = str(e["target"]["value"]);
        }
    }

    def on_goal(e: any) -> None {
        if e and ("target" in e) and ("value" in e["target"]) {
            goal = str(e["target"]["value"]);
        }
    }

    def on_depth(e: any) -> None {
        if e and ("target" in e) and ("value" in e["target"]) {
            max_depth = str(e["target"]["value"]);
        }
    }

    async def submit(e: any) -> None {
        if e and ("preventDefault" in e) {
            e["preventDefault"]();
        }
        depth = int(max_depth) if max_depth else 6;
        await on_trace(start, goal, depth);
    }

    def option(m: any) -> JsxElement {
        if not m { return <option value="" />; }
        mid = str(m["id"]) if ("id" in m) else "";
        return <option value={mid}>{mid}</option>;
    }

    paths = result["paths"] or [];

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
                        {[option(m) for m in modules]}
                    </select>
                </div>
                <div>
                    <label className="label">Goal</label>
                    <select className="input" value={goal} onChange={on_goal}>
                        <option value="">Select…</option>
                        {[option(m) for m in modules]}
                    </select>
                </div>
                <div>
                    <label className="label">Max depth</label>
                    <input className="input" value={max_depth} onChange={on_depth} placeholder="6" />
                </div>

                <div className="md:col-span-3 flex items-center justify-between gap-3 mt-1">
                    <button className="btn btn-primary" type="submit">Trace</button>
                </div>
            </form>

            <div className="mt-4 flex flex-col gap-2">
                {(len(paths) == 0)
                and (
                    <div className="text-sm text-muted-foreground">No paths found (try increasing max depth).</div>
                )}
                {(len(paths) > 0)
                and (
                    <div className="flex flex-col gap-2">
                        {[path_row(paths[i], i) for i in range(len(paths))]}
                    </div>
                )}
            </div>
        </div>
    );
}
