import { LanguageBook } from "./language-book.js";
import { Navigation } from "./navigation.js";
import { PageView } from "./pageView.js";
import { SiteCatalog } from "./siteCatalog.js";

class App {
  constructor(private catalog: SiteCatalog) { }

  lang(): "de" | "en" {
    return localStorage.getItem("docs-lang") === "en" ? "en" : "de";
  }

  theme(): "light" | "dark" {
    let stored = localStorage.getItem("docs-theme");
    if (stored === "light" || stored === "dark") return stored;
    return matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  pageId(book: LanguageBook): string {
    let id = location.hash.replace("#", "") || "index";
    return book.pages.some((page) => page.id === id) ? id : "index";
  }

  render(): void {
    let lang = this.lang();
    let book = this.catalog[lang];
    let pageId = this.pageId(book);
    let page = book.pages.find((item) => item.id === pageId) ?? book.pages[0];
    let theme = this.theme();
    document.documentElement.lang = lang;
    document.documentElement.dataset.theme = theme;
    document.title = `${page.title} · Homelab`;
    document.body.replaceChildren();
    let skip = document.createElement("a");
    skip.className = "skip";
    skip.href = "#content";
    skip.textContent = lang === "de" ? "Zum Inhalt" : "Skip to content";
    document.body.append(skip);
    let layout = document.createElement("div");
    layout.className = "layout";
    new Navigation(book, page.id, lang, theme, (next) => {
      localStorage.setItem("docs-lang", next);
      this.render();
    }, (next) => {
      localStorage.setItem("docs-theme", next);
      this.render();
    }).mount(layout);
    new PageView(page).mount(layout);
    document.body.append(layout);
  }

  start(): void {
    addEventListener("hashchange", () => this.render());
    this.render();
  }
}

export { App };
