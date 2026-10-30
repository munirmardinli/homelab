import { FrontMatter } from "./front-matter.js";
import { MarkdownDocument } from "./markdownDocument.js";

class Markdown {
  compile(id: string, source: string): MarkdownDocument {
    let body = source.replace(/^\uFEFF/, "");
    let meta = new FrontMatter();
    if (body.startsWith("---\n")) {
      let end = body.indexOf("\n---", 4);
      meta = this.readFrontMatter(body.slice(4, end));
      body = body.slice(end + 4).trim();
    }
    let doc = new MarkdownDocument();
    doc.id = id;
    doc.nav = meta.nav;
    doc.order = meta.order;
    doc.html = this.blocks(body, doc);
    return doc;
  }

  readFrontMatter(raw: string): FrontMatter {
    let meta = new FrontMatter();
    for (let line of raw.split("\n")) {
      let cut = line.indexOf(":");
      if (cut < 0) continue;
      let key = line.slice(0, cut).trim();
      let value = line.slice(cut + 1).trim();
      if (key === "nav") meta.nav = value;
      if (key === "order") meta.order = Number(value);
    }
    return meta;
  }

  escapeHtml(value: string): string {
    return value.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
  }

  inline(value: string): string {
    return this.escapeHtml(value).replaceAll(/`([^`]+)`/g, "<code>$1</code>");
  }

  blocks(body: string, doc: MarkdownDocument): string {
    let html: string[] = [];
    let lines = body.split("\n");
    let index = 0;
    while (index < lines.length) {
      let line = lines[index];
      if (!line.trim()) {
        index += 1;
        continue;
      }
      if (line.startsWith("# ")) {
        doc.title = line.slice(2).trim();
        html.push(`<h1>${this.inline(doc.title)}</h1>`);
        index += 1;
        continue;
      }
      if (line.startsWith("## ")) {
        html.push(`<h2>${this.inline(line.slice(3).trim())}</h2>`);
        index += 1;
        continue;
      }
      if (line.startsWith("| ")) {
        let table: string[] = [];
        while (index < lines.length && lines[index].startsWith("|")) {
          table.push(lines[index]);
          index += 1;
        }
        html.push(this.table(table));
        continue;
      }
      if (line.startsWith("- ")) {
        let items: string[] = [];
        while (index < lines.length && lines[index].startsWith("- ")) {
          items.push(lines[index].slice(2));
          index += 1;
        }
        html.push(`<ul>${items.map((item) => `<li>${this.inline(item)}</li>`).join("")}</ul>`);
        continue;
      }
      if (/^\d+\. /.test(line)) {
        let items: string[] = [];
        while (index < lines.length && /^\d+\. /.test(lines[index])) {
          items.push(lines[index].replace(/^\d+\. /, ""));
          index += 1;
        }
        html.push(`<ol>${items.map((item) => `<li>${this.inline(item)}</li>`).join("")}</ol>`);
        continue;
      }
      let paragraph: string[] = [];
      while (index < lines.length && lines[index].trim() && !this.startsBlock(lines[index])) {
        paragraph.push(lines[index].trim());
        index += 1;
      }
      html.push(`<p>${this.inline(paragraph.join(" "))}</p>`);
    }
    return html.join("");
  }

  startsBlock(line: string): boolean {
    return line.startsWith("#") || line.startsWith("| ") || line.startsWith("- ") || /^\d+\. /.test(line);
  }

  table(rows: string[]): string {
    let cells = (row: string) => row.split("|").slice(1, -1).map((cell) => cell.trim());
    let head = cells(rows[0]);
    let body = rows.slice(2).map((row) => `<tr>${cells(row).map((cell) => `<td>${this.inline(cell)}</td>`).join("")}</tr>`);
    return `<table><tr>${head.map((cell) => `<th>${this.inline(cell)}</th>`).join("")}</tr>${body.join("")}</table>`;
  }
}

export { Markdown };
