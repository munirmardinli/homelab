import { MarkdownDocument } from "./markdownDocument.js";

class PageView {
  constructor(private page: MarkdownDocument) { }

  mount(parent: HTMLElement): void {
    let main = document.createElement("main");
    main.id = "content";
    main.tabIndex = -1;
    main.innerHTML = this.page.html;
    parent.append(main);
  }
}

export { PageView };
