import from "@jac/runtime" { useNavigate }

def:pub page() -> JsxElement {
    navigate = useNavigate();

    def go_login() -> None {
        navigate("/login");
    }

    return (
        <div className="home-page">

            <nav className="home-nav">
                <div className="home-nav-inner">
                    <div className="home-logo">
                        <span className="home-logo-mark">{"⬡"}</span>
                        <span className="home-logo-text">{"CodebaseLens"}</span>
                    </div>
                    <button className="btn" onClick={go_login}>{"Sign in"}</button>
                </div>
            </nav>

            <section className="home-hero">
                <div className="home-hero-inner">
                    <div className="home-hero-text">
                        <div className="home-badge">{"For Jac developers"}</div>
                        <h1 className="home-headline">{"Understand any Jac codebase, instantly"}</h1>
                        <p className="home-subtext">
                            {"Paste a GitHub URL. Get a full import graph, searchable module explorer, and path tracer — in seconds."}
                        </p>
                        <div className="home-ctas">
                            <button className="btn btn-primary home-cta-btn" onClick={go_login}>
                                {"Get started free →"}
                            </button>
                            <button className="btn" onClick={go_login}>{"Sign in"}</button>
                        </div>
                    </div>

                    <div className="home-preview">
                        <div className="home-preview-bar">
                            <span className="home-dot home-dot-red"></span>
                            <span className="home-dot home-dot-yellow"></span>
                            <span className="home-dot home-dot-green"></span>
                            <span className="home-preview-label">{"import graph · myapp"}</span>
                        </div>
                        <div className="home-preview-body">
                            <div className="home-preview-line">
                                <span className="hp-mod">{"pages/Dashboard"}</span>
                                <span className="hp-arrow">{"  ──→  "}</span>
                                <span className="hp-dep">{"hooks/useCodebase"}</span>
                            </div>
                            <div className="home-preview-line">
                                <span className="hp-mod">{"hooks/useCodebase"}</span>
                                <span className="hp-arrow">{"  ──→  "}</span>
                                <span className="hp-dep">{"service/appService"}</span>
                            </div>
                            <div className="home-preview-line">
                                <span className="hp-mod">{"service/appService"}</span>
                                <span className="hp-arrow">{"  ──→  "}</span>
                                <span className="hp-dep">{"service/gitUtils"}</span>
                            </div>
                            <div className="home-preview-line">
                                <span className="hp-mod">{"service/appService"}</span>
                                <span className="hp-arrow">{"  ──→  "}</span>
                                <span className="hp-dep">{"service/repoAnalyzer"}</span>
                            </div>
                            <div className="home-preview-sep"></div>
                            <div className="home-preview-trace-row">
                                <span className="hp-trace-label">{"trace  "}</span>
                                <span className="hp-trace-path">{"Dashboard → useCodebase → appService"}</span>
                            </div>
                            <div className="home-preview-trace-row">
                                <span className="hp-badge">{"3 hops · shortest path"}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <section className="home-features">
                <div className="home-section-inner">
                    <h2 className="home-section-title">{"Everything you need to navigate large Jac repos"}</h2>
                    <div className="home-feature-grid">
                        <div className="home-feature-card card">
                            <div className="info-icon">{"{ }"}</div>
                            <h3>{"Clone & Analyze"}</h3>
                            <p>{"Paste any public GitHub URL. CodebaseLens clones the repo and extracts every import relationship automatically — no config needed."}</p>
                        </div>
                        <div className="home-feature-card card">
                            <div className="info-icon">{"→"}</div>
                            <h3>{"Import Graph"}</h3>
                            <p>{"Browse every module, see what it imports and what imports it. Live search filters the list as you type."}</p>
                        </div>
                        <div className="home-feature-card card">
                            <div className="info-icon">{"~"}</div>
                            <h3>{"Path Tracer"}</h3>
                            <p>{"Find the shortest import chain between any two modules. Set a max depth and surface all reachable paths in one click."}</p>
                        </div>
                        <div className="home-feature-card card">
                            <div className="info-icon">{"[ ]"}</div>
                            <h3>{"Manifest Editor"}</h3>
                            <p>{"Not on GitHub? Load any codebase by editing the JSON manifest directly in the browser with live validation."}</p>
                        </div>
                    </div>
                </div>
            </section>

            <section className="home-steps-section">
                <div className="home-section-inner">
                    <h2 className="home-section-title">{"Up and running in three steps"}</h2>
                    <div className="home-steps">
                        <div className="home-step">
                            <div className="home-step-num">{"01"}</div>
                            <h3>{"Paste a GitHub URL"}</h3>
                            <p>{"Enter the URL of any public Jac repository on the dashboard."}</p>
                        </div>
                        <div className="home-step-rule"></div>
                        <div className="home-step">
                            <div className="home-step-num">{"02"}</div>
                            <h3>{"We do the analysis"}</h3>
                            <p>{"CodebaseLens clones, scans, and builds a complete import graph — no setup required."}</p>
                        </div>
                        <div className="home-step-rule"></div>
                        <div className="home-step">
                            <div className="home-step-num">{"03"}</div>
                            <h3>{"Explore & trace"}</h3>
                            <p>{"Browse modules, inspect dependencies, and trace import paths between any two files."}</p>
                        </div>
                    </div>
                </div>
            </section>

            <section className="home-bottom-cta">
                <div className="home-section-inner home-bottom-cta-inner">
                    <h2 className="home-bottom-cta-title">{"Ready to explore your codebase?"}</h2>
                    <p className="home-bottom-cta-sub">{"Create a free account and analyze your first Jac repo in under a minute."}</p>
                    <button className="btn btn-primary home-cta-btn" onClick={go_login}>
                        {"Get started free →"}
                    </button>
                </div>
            </section>

            <footer className="home-footer">
                <div className="home-section-inner home-footer-inner">
                    <span className="home-footer-brand">{"CodebaseLens AI"}</span>
                    <span className="home-footer-sep">{"·"}</span>
                    <span className="home-footer-note">{"Built with Jac"}</span>
                </div>
            </footer>

        </div>
    );
}
