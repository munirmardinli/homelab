import { App } from "./app.js";
import { Styles } from "./css.js";
import { SiteCatalog } from "./siteCatalog.js";

class Main {
  async run(): Promise<void> {
    if (typeof document === "undefined") {
      let { SiteBuild } = await import("./build.js");
      new SiteBuild().run();
      return;
    }
    new Styles().mount();
    let response = await fetch("./pages.json");
    let catalog = (await response.json()) as SiteCatalog;
    new App(catalog).start();
  }
}

export { Main };

new Main().run();
