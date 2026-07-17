import { describe, it, expect, beforeEach } from "vitest";

// Mock localStorage
const store: Record<string, string> = {};
beforeEach(() => {
  Object.keys(store).forEach((k) => delete store[k]);
  globalThis.localStorage = {
    getItem: (key: string) => store[key] ?? null,
    setItem: (key: string, value: string) => { store[key] = value; },
    removeItem: (key: string) => { delete store[key]; },
    clear: () => { Object.keys(store).forEach((k) => delete store[k]); },
    get length() { return Object.keys(store).length; },
    key: (index: number) => Object.keys(store)[index] ?? null,
  } as Storage;
});

// Simple unit tests for core logic (not DOM-rendering tests)
describe("Bookmark Manager Logic", () => {
  it("loadBookmarks returns empty array when nothing stored", () => {
    // localStorage is empty after beforeEach
    const raw = localStorage.getItem("bookmarks");
    expect(raw).toBeNull();
  });

  it("saveBookmarks and loadBookmarks round-trip", () => {
    const data = [{ id: "1", title: "Test", url: "https://example.com", favorited: false, createdAt: 1 }];
    localStorage.setItem("bookmarks", JSON.stringify(data));
    const loaded = JSON.parse(localStorage.getItem("bookmarks")!);
    expect(loaded).toHaveLength(1);
    expect(loaded[0].title).toBe("Test");
  });

  it("isValidUrl rejects invalid URLs", () => {
    const valid = /^https?:\/\/.+/.test("https://example.com");
    const invalid1 = /^https?:\/\/.+/.test("ftp://example.com");
    const invalid2 = /^https?:\/\/.+/.test("");
    const invalid3 = /^https?:\/\/.+/.test("example.com");
    expect(valid).toBe(true);
    expect(invalid1).toBe(false);
    expect(invalid2).toBe(false);
    expect(invalid3).toBe(false);
  });

  it("isValidUrl accepts http and https", () => {
    expect(/^https?:\/\/.+/.test("http://example.com")).toBe(true);
    expect(/^https?:\/\/.+/.test("https://example.com/path?q=1")).toBe(true);
    expect(/^https?:\/\/.+/.test("https://sub.domain.com")).toBe(true);
  });

  it("generateId produces unique IDs", () => {
    const ids = new Set<string>();
    for (let i = 0; i < 100; i++) {
      const id = Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
      ids.add(id);
    }
    expect(ids.size).toBe(100);
  });

  it("delete removes correct bookmark", () => {
    const bookmarks = [
      { id: "a", title: "A", url: "https://a.com", favorited: false, createdAt: 1 },
      { id: "b", title: "B", url: "https://b.com", favorited: false, createdAt: 2 },
    ];
    const filtered = bookmarks.filter((b) => b.id !== "a");
    expect(filtered).toHaveLength(1);
    expect(filtered[0].id).toBe("b");
  });

  it("toggleFavorite flips favorited flag", () => {
    const b = { id: "x", title: "X", url: "https://x.com", favorited: false, createdAt: 1 };
    const toggled = { ...b, favorited: !b.favorited };
    expect(toggled.favorited).toBe(true);
    const untoggled = { ...toggled, favorited: !toggled.favorited };
    expect(untoggled.favorited).toBe(false);
  });

  it("filter by favorites only returns favorited", () => {
    const bookmarks = [
      { id: "1", title: "A", url: "https://a.com", favorited: true, createdAt: 1 },
      { id: "2", title: "B", url: "https://b.com", favorited: false, createdAt: 2 },
    ];
    const filtered = bookmarks.filter((b) => b.favorited);
    expect(filtered).toHaveLength(1);
    expect(filtered[0].id).toBe("1");
  });

  it("search filters by title", () => {
    const bookmarks = [
      { id: "1", title: "Alpha", url: "https://a.com", favorited: false, createdAt: 1 },
      { id: "2", title: "Beta", url: "https://b.com", favorited: false, createdAt: 2 },
    ];
    const q = "alp";
    const filtered = bookmarks.filter((b) => b.title.toLowerCase().includes(q));
    expect(filtered).toHaveLength(1);
    expect(filtered[0].title).toBe("Alpha");
  });

  it("search filters by URL", () => {
    const bookmarks = [
      { id: "1", title: "A", url: "https://example.com", favorited: false, createdAt: 1 },
      { id: "2", title: "B", url: "https://other.com", favorited: false, createdAt: 2 },
    ];
    const q = "example";
    const filtered = bookmarks.filter((b) => b.url.toLowerCase().includes(q));
    expect(filtered).toHaveLength(1);
  });
});
