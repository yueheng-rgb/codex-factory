interface Bookmark {
  id: string;
  title: string;
  url: string;
  favorited: boolean;
  createdAt: number;
}

type FilterMode = "all" | "favorites";

function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}

function isValidUrl(url: string): boolean {
  return /^https?:\/\/.+/.test(url);
}

function loadBookmarks(): Bookmark[] {
  try {
    const raw = localStorage.getItem("bookmarks");
    return raw ? JSON.parse(raw) : [];
  } catch { return []; }
}

function saveBookmarks(bookmarks: Bookmark[]): void {
  localStorage.setItem("bookmarks", JSON.stringify(bookmarks));
}

// State
let bookmarks: Bookmark[] = loadBookmarks();
let filterMode: FilterMode = "all";
let searchQuery = "";

// DOM refs
const app = document.getElementById("app")!;

function render(): void {
  const filtered = bookmarks.filter((b) => {
    if (filterMode === "favorites" && !b.favorited) return false;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      return b.title.toLowerCase().includes(q) || b.url.toLowerCase().includes(q);
    }
    return true;
  });

  app.innerHTML = "";

  // Header
  const h1 = document.createElement("h1");
  h1.textContent = "Bookmark Manager";
  app.appendChild(h1);

  // Add form
  const form = document.createElement("form");
  form.className = "add-form";
  form.onsubmit = (e) => { e.preventDefault(); addBookmark(); };

  const titleInput = document.createElement("input");
  titleInput.type = "text";
  titleInput.placeholder = "Title";
  titleInput.id = "title-input";

  const urlInput = document.createElement("input");
  urlInput.type = "text";
  urlInput.placeholder = "https://example.com";
  urlInput.id = "url-input";

  const addBtn = document.createElement("button");
  addBtn.type = "submit";
  addBtn.textContent = "Add";

  const errEl = document.createElement("div");
  errEl.className = "error";
  errEl.id = "add-error";

  form.append(titleInput, urlInput, addBtn, errEl);
  app.appendChild(form);

  // Toolbar
  const toolbar = document.createElement("div");
  toolbar.className = "toolbar";

  const searchInput = document.createElement("input");
  searchInput.type = "search";
  searchInput.placeholder = "Search bookmarks...";
  searchInput.value = searchQuery;
  searchInput.id = "search-input";
  searchInput.oninput = () => { searchQuery = searchInput.value; render(); };

  const allBtn = document.createElement("button");
  allBtn.className = "filter-btn" + (filterMode === "all" ? " active" : "");
  allBtn.textContent = "All";
  allBtn.onclick = () => { filterMode = "all"; render(); };

  const favBtn = document.createElement("button");
  favBtn.className = "filter-btn" + (filterMode === "favorites" ? " active" : "");
  favBtn.textContent = "Favorites";
  favBtn.onclick = () => { filterMode = "favorites"; render(); };

  const count = document.createElement("span");
  count.className = "count";
  count.textContent = `${filtered.length} / ${bookmarks.length}`;

  toolbar.append(searchInput, allBtn, favBtn, count);
  app.appendChild(toolbar);

  // Bookmark list or empty/no-results
  if (bookmarks.length === 0) {
    const empty = document.createElement("div");
    empty.className = "empty-state";
    empty.textContent = "No bookmarks yet. Add one above!";
    app.appendChild(empty);
    return;
  }

  if (filtered.length === 0 && bookmarks.length > 0) {
    const noRes = document.createElement("div");
    noRes.className = "no-results";
    noRes.textContent = "No bookmarks match your search.";
    app.appendChild(noRes);
    return;
  }

  const list = document.createElement("ul");
  list.className = "bookmark-list";

  for (const b of filtered) {
    const li = document.createElement("li");
    li.className = "bookmark-item";

    const fBtn = document.createElement("button");
    fBtn.className = "fav-btn" + (b.favorited ? " favorited" : "");
    fBtn.textContent = b.favorited ? "★" : "☆";
    fBtn.title = b.favorited ? "Unfavorite" : "Favorite";
    fBtn.onclick = () => toggleFavorite(b.id);

    const info = document.createElement("div");
    info.className = "info";

    const titleEl = document.createElement("div");
    titleEl.className = "title";
    const link = document.createElement("a");
    link.href = b.url;
    link.target = "_blank";
    link.rel = "noopener";
    link.textContent = b.title;
    titleEl.appendChild(link);

    const urlEl = document.createElement("div");
    urlEl.className = "url-text";
    urlEl.textContent = b.url;

    info.append(titleEl, urlEl);

    const dBtn = document.createElement("button");
    dBtn.className = "del-btn";
    dBtn.textContent = "×";
    dBtn.title = "Delete";
    dBtn.onclick = () => deleteBookmark(b.id);

    li.append(fBtn, info, dBtn);
    list.appendChild(li);
  }

  app.appendChild(list);
}

function addBookmark(): void {
  const titleInput = document.getElementById("title-input") as HTMLInputElement;
  const urlInput = document.getElementById("url-input") as HTMLInputElement;
  const errEl = document.getElementById("add-error")!;

  const title = titleInput.value.trim();
  const url = urlInput.value.trim();

  if (!title) { errEl.textContent = "Title cannot be empty."; return; }
  if (!url) { errEl.textContent = "URL cannot be empty."; return; }
  if (!isValidUrl(url)) { errEl.textContent = "URL must start with http:// or https://"; return; }

  errEl.textContent = "";
  bookmarks = [...bookmarks, { id: generateId(), title, url, favorited: false, createdAt: Date.now() }];
  saveBookmarks(bookmarks);
  titleInput.value = "";
  urlInput.value = "";
  render();
}

function deleteBookmark(id: string): void {
  bookmarks = bookmarks.filter((b) => b.id !== id);
  saveBookmarks(bookmarks);
  render();
}

function toggleFavorite(id: string): void {
  bookmarks = bookmarks.map((b) => b.id === id ? { ...b, favorited: !b.favorited } : b);
  saveBookmarks(bookmarks);
  render();
}

// Global for tests
(window as any).__bookmarkState = () => ({ bookmarks, filterMode, searchQuery });

render();
