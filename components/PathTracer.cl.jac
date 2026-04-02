def:pub PathTracer(props: dict) -> JsxElement {
    modules = props["modules"] or [];
    on_trace = props["on_trace"];
    result = props["result"];

    has start: str = "";
    has goal: str = "";
    has max_depth: str = "6";

    def on_start(e: any) -> None { start = e.target.value; }
    def on_goal(e: any) -> None { goal = e.target.value; }
    def on_depth(e: any) -> None { max_depth = e.target.value; }

    async def submit(e: any) -> None {
        e.preventDefault();
        depth = int(max_depth) if max_depth else 6;
        await on_trace(start, goal, depth);
    }

    def option(m: dict) -> JsxElement {
        mid = str((m and ("id" in m) and m["id"]) or "");
        return <option value={mid}>{mid}</option>;
    }

    paths = result["paths"] if (result and ("paths" in result) and result["paths"]) else [];

    def path_row(p: list[str], idx: int) -> JsxElement {
        return (
            <div key={"p" + str(idx)} className="rounded-[0.75rem] border border-border bg-surface px-3 py-2 text-sm">
                {" → ".join([str(x) for x in p])}
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
                        {[option(m) for m in modules if m]}
                    </select>
                </div>
                <div>
                    <label className="label">Goal</label>
                    <select className="input" value={goal} onChange={on_goal}>
                        <option value="">Select…</option>
                        {[option(m) for m in modules if m]}
                    </select>
                </div>
                <div>
                    <label className="label">Max depth</label>
                    <input className="input" value={max_depth} onChange={on_depth} placeholder="6" />
                </div>

                <div className="md:col-span-3 flex items-center justify-between gap-3 mt-1">
                    <button className="btn btn-primary" type="submit">
                        Trace
                    </button>
                    {result
                    and (
                        <div className="text-xs text-muted-foreground">
                            {(
                                ("Start not found" if ("start_exists" in result and (not result["start_exists"])) else "")
                                + (
                                    (" · " if (("start_exists" in result) and (not result["start_exists"]) and ("goal_exists" in result) and (not result["goal_exists"])) else "")
                                )
                                + ("Goal not found" if (("goal_exists" in result) and (not result["goal_exists"])) else "")
                            )}
                        </div>
                    )}
                </div>
            </form>

            <div className="mt-4 flex flex-col gap-2">
                {(result and (len(paths) == 0))
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
