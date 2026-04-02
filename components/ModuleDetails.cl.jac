def:pub ModuleDetails(props: dict) -> JsxElement {
    module = props["module"];
    incoming = props["incoming"] or [];
    outgoing = props["outgoing"] or [];

    if not module {
        return (
            <div className="card p-6">
                <h2 className="text-sm font-semibold mb-1">Module details</h2>
                <p className="text-sm text-muted-foreground">Select a module to see its summary, tags, and relationships.</p>
            </div>
        );
    }

    tags = module["tags"] if ("tags" in module and module["tags"]) else [];

    def pill(text: str) -> JsxElement {
        return (
            <span className="inline-flex items-center rounded-full border border-border bg-muted px-2.5 py-1 text-[0.7rem] uppercase tracking-wider text-muted-foreground">
                {text}
            </span>
        );
    }

    def rel_row(label: str, items: list[str]) -> JsxElement {
        return (
            <div className="mt-4">
                <div className="text-xs font-medium uppercase tracking-[0.08em] text-muted-foreground mb-2">{label}</div>
                {(len(items) == 0)
                and (<div className="text-sm text-muted-foreground">None</div>)}
                {(len(items) > 0)
                and (
                    <div className="flex flex-col gap-2">
                        {[
                            <div key={it} className="rounded-[0.75rem] border border-border bg-surface px-3 py-2 text-sm">
                                <span className="font-medium">{str(it)}</span>
                            </div>
                            for it in items
                        ]}
                    </div>
                )}
            </div>
        );
    }

    return (
        <div className="card p-6">
            <div className="flex items-start justify-between gap-4">
                <div className="min-w-0">
                    <h2 className="text-base font-semibold truncate">{str(module["id"])}</h2>
                    <p className="text-sm text-muted-foreground mt-1">{str(module["summary"]) if ("summary" in module and module["summary"]) else ""}</p>
                </div>
                <span className="text-[0.7rem] uppercase tracking-wider text-muted-foreground">
                    {str(module["kind"]) if ("kind" in module and module["kind"]) else ""}
                </span>
            </div>

            {(len(tags) > 0)
            and (
                <div className="flex flex-wrap gap-2 mt-4">
                    {[pill(str(t)) for t in tags if t]}
                </div>
            )}

            {rel_row("Imports", outgoing)}
            {rel_row("Imported by", incoming)}
        </div>
    );
}
