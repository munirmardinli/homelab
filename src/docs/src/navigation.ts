import { LanguageBook } from "./language-book.js";

class Navigation {
  constructor(
    private book: LanguageBook,
    private pageId: string,
    private lang: "de" | "en",
    private theme: "light" | "dark",
    private onLang: (lang: "de" | "en") => void,
    private onTheme: (theme: "light" | "dark") => void,
  ) { }

  mount(parent: HTMLElement): void {
    let nav = document.createElement("nav");
    nav.setAttribute("aria-label", this.lang === "de" ? "Inhalt" : "Contents");
    let brand = document.createElement("p");
    brand.className = "brand";
    brand.textContent = this.book.brand;
    let hint = document.createElement("p");
    hint.className = "hint";
    hint.textContent = this.book.hint;
    nav.append(brand, hint);
    for (let page of this.book.pages) {
      let link = document.createElement("a");
      link.href = `#${page.id}`;
      link.textContent = page.nav;
      if (page.id === this.pageId) {
        link.className = "active";
        link.setAttribute("aria-current", "page");
      }
      nav.append(link);
    }
    let tools = document.createElement("div");
    tools.className = "tools";
    tools.append(this.languageMenu(), this.themeButton());
    nav.append(tools);
    parent.append(nav);
  }

  languageMenu(): HTMLDivElement {
    let wrap = document.createElement("div");
    wrap.className = "i18n";
    let button = document.createElement("button");
    button.type = "button";
    button.className = "icon";
    button.innerHTML = this.globe();
    button.setAttribute("aria-label", this.lang === "de" ? "Sprache" : "Language");
    button.setAttribute("aria-expanded", "false");
    button.setAttribute("aria-haspopup", "menu");
    let menu = document.createElement("div");
    menu.className = "menu";
    menu.hidden = true;
    menu.setAttribute("role", "menu");
    menu.append(this.langItem("de", "Deutsch", this.flagDe()), this.langItem("en", "English", this.flagEn()));
    button.addEventListener("click", () => {
      menu.hidden = !menu.hidden;
      button.setAttribute("aria-expanded", String(!menu.hidden));
    });
    wrap.append(button, menu);
    return wrap;
  }

  langItem(code: "de" | "en", label: string, icon: string): HTMLButtonElement {
    let button = document.createElement("button");
    button.type = "button";
    button.className = "choice";
    button.setAttribute("role", "menuitemradio");
    button.setAttribute("aria-checked", String(code === this.lang));
    button.innerHTML = `${icon}<span>${label}</span>`;
    button.addEventListener("click", () => this.onLang(code));
    return button;
  }

  themeButton(): HTMLButtonElement {
    let button = document.createElement("button");
    button.type = "button";
    button.className = "icon";
    button.innerHTML = this.theme === "dark" ? this.sun() : this.moon();
    button.setAttribute("aria-label", this.lang === "de" ? (this.theme === "dark" ? "Hellmodus" : "Dunkelmodus") : (this.theme === "dark" ? "Light mode" : "Dark mode"));
    button.setAttribute("aria-pressed", String(this.theme === "dark"));
    button.addEventListener("click", () => this.onTheme(this.theme === "dark" ? "light" : "dark"));
    return button;
  }

  globe(): string {
    return `<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9" fill="none" stroke="currentColor"/><path d="M3 12 H21 M12 3 A14 14 0 0 1 12 21 A14 14 0 0 1 12 3" fill="none" stroke="currentColor"/></svg>`;
  }

  flagDe(): string {
    return `<svg viewBox="0 0 24 16" aria-hidden="true"><rect width="24" height="5.34" fill="#000"/><rect y="5.33" width="24" height="5.34" fill="#dd0000"/><rect y="10.66" width="24" height="5.34" fill="#ffce00"/></svg>`;
  }

  flagEn(): string {
    return `<svg viewBox="0 0 24 16" aria-hidden="true"><rect width="24" height="16" fill="#012169"/><path d="M0 0 L24 16 M24 0 L0 16" stroke="#fff" stroke-width="3"/><path d="M0 0 L24 16 M24 0 L0 16" stroke="#c8102e" stroke-width="1.4"/><path d="M12 0 V16 M0 8 H24" stroke="#fff" stroke-width="5"/><path d="M12 0 V16 M0 8 H24" stroke="#c8102e" stroke-width="2.4"/></svg>`;
  }

  sun(): string {
    return `<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4" fill="none" stroke="currentColor"/><path d="M12 2 V5 M12 19 V22 M2 12 H5 M19 12 H22 M4.5 4.5 L6.7 6.7 M17.3 17.3 L19.5 19.5 M19.5 4.5 L17.3 6.7 M6.7 17.3 L4.5 19.5" stroke="currentColor"/></svg>`;
  }

  moon(): string {
    return `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15 3 A9 9 0 1 0 21 14 A7 7 0 0 1 15 3" fill="currentColor"/></svg>`;
  }
}

export { Navigation };
