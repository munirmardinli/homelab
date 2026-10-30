import { cpSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";

import { LanguageBook } from "./language-book.js";
import { Markdown } from "./markdown.js";
import { SiteCatalog } from "./siteCatalog.js";

class SiteBuild {
  root = "src/content";

  run(): void {
    rmSync("public", { recursive: true, force: true });
    mkdirSync("public", { recursive: true });
    cpSync("dist", "public", {
      recursive: true,
      filter: (source) => !source.endsWith("/build.js"),
    });
    writeFileSync("public/pages.json", JSON.stringify(this.catalog()));
    writeFileSync(
      "public/index.html",
      `<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Homelab Docker</title>
</head>
<body>
  <script type="module" src="./main.js"></script>
</body>
</html>
`,
    );
  }

  catalog(): SiteCatalog {
    let catalog = new SiteCatalog();
    catalog.de = this.book("de", "Homelab Docker", "Dokumentation");
    catalog.en = this.book("en", "Homelab Docker", "Documentation");
    return catalog;
  }

  book(lang: string, brand: string, hint: string): LanguageBook {
    let book = new LanguageBook();
    book.brand = brand;
    book.hint = hint;
    let compiler = new Markdown();
    for (let name of readdirSync(`${this.root}/${lang}`)) {
      if (!name.endsWith(".md")) continue;
      let source = readFileSync(`${this.root}/${lang}/${name}`, "utf8");
      book.pages.push(compiler.compile(name.slice(0, -3), source));
    }
    book.pages.sort((left, right) => left.order - right.order);
    return book;
  }
}

export { SiteBuild };
