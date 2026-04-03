"""Fullstack Starter - Entry Point.

Imports server-side symbols and mounts the client app.
"""

import from service.appService {
    list_projects,
    analyze_project,
    get_project_graph,
    trace_project_paths,
    set_project_manifest,
    get_project_summary
}

cl import from .index { ClientApp }

cl {
    def:pub app() -> JsxElement {
        return <ClientApp />;
    }
}
