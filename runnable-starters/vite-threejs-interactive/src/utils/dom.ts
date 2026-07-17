/** DOM query helpers — plain vanilla */

export function qs<T extends HTMLElement>(selector: string): T | null {
  return document.querySelector<T>(selector);
}

export function qsId<T extends HTMLElement>(id: string): T | null {
  return document.getElementById(id) as T | null;
}

export function ensure<T extends HTMLElement>(selector: string): T {
  const el = qs<T>(selector);
  if (!el) throw new Error(`Element not found: ${selector}`);
  return el;
}
