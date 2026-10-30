declare module "node:fs" {
  export function cpSync(
    source: string,
    dest: string,
    options: { recursive: boolean; filter: (source: string) => boolean },
  ): void;
  export function mkdirSync(path: string, options: { recursive: boolean }): void;
  export function rmSync(path: string, options: { recursive: boolean; force: boolean }): void;
  export function writeFileSync(path: string, data: string): void;
  export function readdirSync(path: string): string[];
  export function readFileSync(path: string, encoding: string): string;
}
