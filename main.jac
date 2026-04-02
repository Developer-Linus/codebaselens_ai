"""Fullstack Starter - Entry Point.

Imports server-side symbols and mounts the client app.
"""

import from service.appService {
    greet,
    set_codebase_manifest,
    get_codebase_manifest,
    get_codebase_graph,
    trace_paths,
    clone_repo_to_workspace,
    cleanup_repo_workspace
}

cl import from .index { ClientApp }

cl {
    def:pub app() -> JsxElement {
        return <ClientApp />;
    }
}
