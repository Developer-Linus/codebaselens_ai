def:pub ModuleList(props: dict) -> JsxElement {
    modules = props["modules"] or [];
    selected_id = props["selected_id"] or "";
    on_select = props["on_select"];
    query = props["query"] or "";
    on_query = props["on_query"];

    q = str(query).lower();

    filtered = [
        m for m in modules
        if m
        if (
            (not q)
            or (q in str(m["id"]).lower())
            or (q in str(m["summary"]).lower() if ("summary" in m and m["summary"]) else "")
            or (q in str(m["kind"]).lower() if ("kind" in m and m["kind"]) else "")
        )
    ];

    def row(m: dict) -> JsxElement {
        mid = m["id"];
        is_sel = (selected_id == mid);
        cls = (
            "text-left w-full rounded-[0.75rem] border px-3 py-2.5 transition-colors "
            + ("border-primary bg-muted" if is_sel else "border-border hover:bg-muted")
        );

        return (
            <button className={cls} onClick={lambda: on_select(mid)}>
                <div className="flex items-center justify-between gap-3">
                    <div className="min-w-0">
                        <div className="text-sm font-medium truncate">{str(mid)}</div>
                        <div className="text-xs text-muted-foreground truncate">
                            {str(m["summary"]) if ("summary" in m and m["summary"]) else ""}
                        </div>
                    </div>
                    <span className="text-[0.7rem] uppercase tracking-wider text-muted-foreground">
                        {str(m["kind"]) if ("kind" in m and m["kind"]) else ""}
                    </span>
                </div>
            </button>
        );
    }

    return (
        <div className="card p-5">
            <div className="flex items-center justify-between gap-3 mb-4">
                <div>
                    <h2 className="text-sm font-semibold">Modules</h2>
                    <p className="text-xs text-muted-foreground">Search and select a file to see how it connects.</p>
                </div>
            </div>

            <input
                className="input mb-4"
                placeholder="Search (e.g. service, router, auth)"
                value={query}
                onChange={on_query}
            />

            <div className="flex flex-col gap-2 max-h-[22rem] overflow-auto pr-1">
                {[row(m) for m in filtered]}

                {(len(filtered) == 0)
                and (
                    <div className="text-xs text-muted-foreground py-6 text-center">
                        No matches.
                    </div>
                )}
            </div>
        </div>
    );
}
