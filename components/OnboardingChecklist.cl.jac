def:pub OnboardingChecklist(props: dict) -> JsxElement {
    repo_name = props["repo_name"] or "codebase";
    selected_id = props["selected_id"] or "";

    steps = [
        {
            "id": "repo",
            "title": "Provide a public GitHub repo link",
            "desc": "Paste a public GitHub URL (or repo name) into the Manifest panel so everyone is aligned on the same source of truth.",
            "hint": "No link yet? Load the Sample manifest and replace it with your repo details."
        },
        {
            "id": "entry",
            "title": "Understand how the app starts",
            "desc": "Locate main.jac (or equivalent) and see what it imports, registers, and mounts.",
            "hint": "Select main.jac in the module list, then review its direct imports."
        },
        {
            "id": "routes",
            "title": "Map pages and navigation",
            "desc": "Identify the client router and the key pages/screens.",
            "hint": "Look for index.cl.jac and pages/*.cl.jac, then trace imports into components/."
        },
        {
            "id": "services",
            "title": "Map backend endpoints",
            "desc": "List server functions and where the client calls them.",
            "hint": "Search for service/ modules and hooks/ that import them."
        },
        {
            "id": "dataflow",
            "title": "Trace a feature path (before changing code)",
            "desc": "Pick a UI action and trace the import path end-to-end. Only start making changes once the path is clear.",
            "hint": "Use the Trace panel to find paths between modules, then open each module in order."
        }
    ];

    def step_row(s: dict) -> JsxElement {
        return (
            <div key={(s and ("id" in s) and s["id"]) or "step"} className="rounded-[0.75rem] border border-border bg-surface px-4 py-3">
                <div className="flex items-start justify-between gap-3">
                    <div>
                        <div className="text-sm font-semibold">{s["title"]}</div>
                        <div className="text-sm text-muted-foreground mt-1">{s["desc"]}</div>
                        <div className="text-xs text-muted-foreground mt-2">{s["hint"]}</div>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="card p-6">
            <div className="flex items-start justify-between gap-4 mb-4">
                <div>
                    <h2 className="text-sm font-semibold">Onboarding checklist</h2>
                    <p className="text-xs text-muted-foreground">A guided path to understand <span className="text-foreground font-medium">{str(repo_name)}</span>.</p>
                </div>
                <div className="text-[0.7rem] uppercase tracking-wider text-muted-foreground">
                    {selected_id and ("Selected: " + str(selected_id)) or ""}
                </div>
            </div>

            <div className="flex flex-col gap-2">
                {[step_row(s) for s in steps]}
            </div>
        </div>
    );
}
