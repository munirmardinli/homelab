class Styles {
  mount(): void {
    let node = document.createElement("style");
    node.textContent = this.rules() + this.mobile();
    document.head.appendChild(node);
  }

  rule(selector: string, style: Record<string, string>): string {
    let body = Object.entries(style)
      .map(([key, value]) => `${key.replace(/[A-Z]/g, (letter) => `-${letter.toLowerCase()}`)}:${value}`)
      .join(";");
    return `${selector}{${body}}`;
  }

  rules(): string {
    return [
      this.rule(":root", { colorScheme: "light", "--bg": "#fff", "--fg": "#000", "--muted": "#222" }),
      this.rule("[data-theme=dark]", { colorScheme: "dark", "--bg": "#000", "--fg": "#fff", "--muted": "#ddd" }),
      this.rule("body", { margin: "0", font: "16px/1.6 system-ui, sans-serif", background: "var(--bg)", color: "var(--fg)" }),
      this.rule("a", { color: "inherit" }),
      this.rule(".skip", { position: "absolute", left: "-999px", top: "0", background: "var(--fg)", color: "var(--bg)", padding: "0.4rem 0.7rem" }),
      this.rule(".skip:focus", { left: "0.5rem", top: "0.5rem", zIndex: "2" }),
      this.rule("nav", { position: "fixed", top: "0", left: "0", bottom: "0", width: "240px", boxSizing: "border-box", overflow: "auto", borderRight: "1px solid var(--fg)", padding: "1.25rem 1rem 4.5rem", background: "var(--bg)" }),
      this.rule("nav a", { display: "block", padding: "0.35rem 0", textDecoration: "none" }),
      this.rule("nav a.active", { fontWeight: "700", textDecoration: "underline" }),
      this.rule("a:focus-visible, button:focus-visible", { outline: "2px solid var(--fg)", outlineOffset: "2px" }),
      this.rule(".brand", { fontWeight: "700", margin: "0 0 0.25rem" }),
      this.rule(".hint", { color: "var(--muted)", fontSize: "0.85rem", margin: "0 0 1rem" }),
      this.rule(".tools", { display: "flex", gap: "0.4rem", position: "fixed", left: "0", bottom: "0", width: "240px", boxSizing: "border-box", padding: "0.75rem 1rem", background: "var(--bg)", borderTop: "1px solid var(--fg)", borderRight: "1px solid var(--fg)", zIndex: "2" }),
      this.rule(".i18n", { position: "relative" }),
      this.rule("button.icon", { background: "transparent", color: "var(--fg)", border: "0", width: "2.25rem", height: "2.25rem", padding: "0.25rem", cursor: "pointer" }),
      this.rule("button.icon svg", { display: "block", width: "100%", height: "100%" }),
      this.rule(".menu", { position: "absolute", left: "0", bottom: "2.6rem", minWidth: "9.5rem", background: "var(--bg)", color: "var(--fg)", border: "1px solid var(--fg)", borderRadius: "10px", padding: "0.35rem", zIndex: "3" }),
      this.rule("button.choice", { display: "flex", alignItems: "center", gap: "0.55rem", width: "100%", background: "transparent", color: "inherit", border: "0", borderRadius: "8px", padding: "0.4rem 0.5rem", cursor: "pointer", textAlign: "left" }),
      this.rule("button.choice[aria-checked=true]", { background: "var(--fg)", color: "var(--bg)" }),
      this.rule("button.choice svg", { width: "1.35rem", height: "0.9rem", flex: "0 0 auto" }),
      this.rule("main", { marginLeft: "240px", padding: "2rem 2.4rem 4rem", maxWidth: "860px" }),
      this.rule("h1", { lineHeight: "1.2" }),
      this.rule("h2", { marginTop: "2rem" }),
      this.rule("table", { width: "100%", borderCollapse: "collapse", margin: "1rem 0" }),
      this.rule("th, td", { border: "1px solid var(--fg)", padding: "0.45rem 0.6rem", textAlign: "left", verticalAlign: "top" }),
      this.rule("th", { background: "var(--fg)", color: "var(--bg)" }),
      this.rule("code, pre", { fontFamily: "ui-monospace, SFMono-Regular, Menlo, monospace" }),
      this.rule("code", { border: "1px solid var(--fg)", padding: "0.05rem 0.3rem" }),
    ].join("");
  }

  mobile(): string {
    return `@media (max-width: 800px){${[
      this.rule("nav", { width: "100%", height: "auto", bottom: "auto", borderRight: "0", borderBottom: "1px solid var(--fg)", paddingBottom: "1rem" }),
      this.rule(".tools", { top: "0.75rem", right: "0.75rem", bottom: "auto", left: "auto", width: "auto", border: "0", padding: "0" }),
      this.rule(".menu", { top: "2.6rem", bottom: "auto" }),
      this.rule("main", { marginLeft: "0", padding: "1.25rem", paddingTop: "12rem" }),
    ].join("")}}`;
  }
}

export { Styles };
