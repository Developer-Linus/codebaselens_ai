def:pub ManifestEditor(props: dict) -> JsxElement {
    repo_name = props["repo_name"] or "";
    on_apply = props["on_apply"];

    has text: str = "";
    has error: str = "";

    def on_text(e: any) -> None {
        text = e.target.value;
    }

    async def apply(e: any) -> None {
        e.preventDefault();
        error = "";

        if not text.strip() {
            error = "Paste a JSON manifest first (or use the sample).";
            return;
        }

        try {
            manifest = JSON.parse(text);
            ok = await on_apply(manifest);
            if not ok {
                error = "Could not apply manifest.";
            }
        } except Exception as ex {
            error = "Invalid JSON: " + str(ex);
        }
    }

    def load_sample() -> None {
        sample = {
            "name": "my-codebase",
            "modules": [
                {
                    "id": "main.jac",
                    "kind": "backend",
                    "summary": "Entry point: registers endpoints and mounts client.",
                    "imports": ["services/auth.sv.jac", "index.cl.jac"],
                    "exports": ["app"],
                    "tags": ["entry"]
                },
                {
                    "id": "index.cl.jac",
                    "kind": "client",
                    "summary": "Client router and top-level layout.",
                    "imports": ["pages/LoginPage.cl.jac", "pages/DashboardPage.cl.jac"],
                    "exports": ["ClientApp"],
                    "tags": ["routing"]
                },
                {
                    "id": "services/auth.sv.jac",
                    "kind": "backend",
                    "summary": "Auth endpoints and user model.",
                    "imports": [],
                    "exports": ["login", "signup"],
                    "tags": ["auth"]
                },
                {
                    "id": "pages/DashboardPage.cl.jac",
                    "kind": "client",
                    "summary": "Onboarding dashboard.",
                    "imports": ["hooks/useCodebase.cl.jac", "components/*"],
                    "exports": ["page"],
                    "tags": ["onboarding"]
                }
            ]
        };
        text = JSON.stringify(sample, None, 2);
    }

    return (
        <div className="card p-6">
            <div className="flex items-start justify-between gap-4 mb-4">
                <div>
                    <h2 className="text-sm font-semibold">Manifest</h2>
                    <p className="text-xs text-muted-foreground">Paste a lightweight JSON description of your repo to power onboarding.</p>
                </div>
                <button className="btn btn-ghost" type="button" onClick={load_sample}>Sample</button>
            </div>

            <form onSubmit={apply} className="flex flex-col gap-3">
                <textarea
                    className="w-full min-h-[12rem] rounded-[0.75rem] border border-border bg-surface text-foreground px-4 py-3 text-sm outline-none focus:border-primary"
                    value={text}
                    onChange={on_text}
                    placeholder="{\n  \"name\": \"repo\",\n  \"modules\": [...]\n}"
                />
                {error and (<div className="error-box">{error}</div>)}
                <div className="flex items-center justify-between gap-3">
                    <div className="text-xs text-muted-foreground">Current: <span className="text-foreground font-medium">{str(repo_name)}</span></div>
                    <button className="btn btn-primary" type="submit">Apply manifest</button>
                </div>
            </form>
        </div>
    );
}
