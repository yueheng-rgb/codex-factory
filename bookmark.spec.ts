import { test, expect } from "@playwright/test";

test.describe("Bookmark Manager", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await page.evaluate(() => localStorage.clear());
  });

  // AC-ADD
  test("adds a new bookmark", async ({ page }) => {
    await page.fill("#title-input", "My Site");
    await page.fill("#url-input", "https://example.com");
    await page.click("button:has-text('Add')");
    await expect(page.locator(".bookmark-item")).toHaveCount(1);
    await expect(page.locator(".title a")).toHaveText("My Site");
    await expect(page.locator(".url-text")).toHaveText("https://example.com");
  });

  test("rejects empty title", async ({ page }) => {
    await page.fill("#url-input", "https://example.com");
    await page.click("button:has-text('Add')");
    await expect(page.locator("#add-error")).toHaveText("Title cannot be empty.");
    await expect(page.locator(".bookmark-item")).toHaveCount(0);
  });

  test("rejects whitespace-only title", async ({ page }) => {
    await page.fill("#title-input", "   ");
    await page.fill("#url-input", "https://example.com");
    await page.click("button:has-text('Add')");
    await expect(page.locator("#add-error")).toHaveText("Title cannot be empty.");
  });

  test("rejects empty URL", async ({ page }) => {
    await page.fill("#title-input", "Test");
    await page.click("button:has-text('Add')");
    await expect(page.locator("#add-error")).toHaveText("URL cannot be empty.");
  });

  test("rejects invalid URL", async ({ page }) => {
    await page.fill("#title-input", "Test");
    await page.fill("#url-input", "not-a-url");
    await page.click("button:has-text('Add')");
    await expect(page.locator("#add-error")).toContainText("http:// or https://");
  });

  test("submits on Enter key", async ({ page }) => {
    await page.fill("#title-input", "Enter Site");
    await page.fill("#url-input", "https://enter.com");
    await page.press("#url-input", "Enter");
    await expect(page.locator(".bookmark-item")).toHaveCount(1);
  });

  // AC-DISPLAY
  test("displays added bookmarks", async ({ page }) => {
    await page.fill("#title-input", "A"); await page.fill("#url-input", "https://a.com");
    await page.click("button:has-text('Add')");
    await page.fill("#title-input", "B"); await page.fill("#url-input", "https://b.com");
    await page.click("button:has-text('Add')");
    await expect(page.locator(".bookmark-item")).toHaveCount(2);
  });

  test("shows bookmark count", async ({ page }) => {
    await page.fill("#title-input", "A"); await page.fill("#url-input", "https://a.com");
    await page.click("button:has-text('Add')");
    await expect(page.locator(".count")).toContainText("1 / 1");
    await page.fill("#title-input", "B"); await page.fill("#url-input", "https://b.com");
    await page.click("button:has-text('Add')");
    await expect(page.locator(".count")).toContainText("2 / 2");
  });

  // AC-DELETE
  test("deletes a bookmark", async ({ page }) => {
    await page.fill("#title-input", "Del"); await page.fill("#url-input", "https://del.com");
    await page.click("button:has-text('Add')");
    await page.click(".del-btn");
    await expect(page.locator(".bookmark-item")).toHaveCount(0);
    await expect(page.locator(".empty-state")).toBeVisible();
  });

  // AC-FAVORITE
  test("toggles favorite on bookmark", async ({ page }) => {
    await page.fill("#title-input", "Fav"); await page.fill("#url-input", "https://fav.com");
    await page.click("button:has-text('Add')");
    await page.click(".fav-btn");
    await expect(page.locator(".fav-btn.favorited")).toHaveCount(1);
    await page.click(".fav-btn");
    await expect(page.locator(".fav-btn.favorited")).toHaveCount(0);
  });

  test("favorite state persists after refresh", async ({ page }) => {
    await page.fill("#title-input", "Persist"); await page.fill("#url-input", "https://persist.com");
    await page.click("button:has-text('Add')");
    await page.click(".fav-btn");
    await page.reload();
    await expect(page.locator(".fav-btn.favorited")).toHaveCount(1);
  });

  // AC-SEARCH
  test("filters bookmarks by title", async ({ page }) => {
    await page.fill("#title-input", "Alpha"); await page.fill("#url-input", "https://a.com");
    await page.click("button:has-text('Add')");
    await page.fill("#title-input", "Beta"); await page.fill("#url-input", "https://b.com");
    await page.click("button:has-text('Add')");
    await page.fill("#search-input", "Alp");
    await expect(page.locator(".bookmark-item")).toHaveCount(1);
    await expect(page.locator(".title a")).toHaveText("Alpha");
  });

  test("filters bookmarks by URL", async ({ page }) => {
    await page.fill("#title-input", "A"); await page.fill("#url-input", "https://unique.com");
    await page.click("button:has-text('Add')");
    await page.fill("#title-input", "B"); await page.fill("#url-input", "https://other.com");
    await page.click("button:has-text('Add')");
    await page.fill("#search-input", "unique");
    await expect(page.locator(".bookmark-item")).toHaveCount(1);
  });

  test("shows no results message", async ({ page }) => {
    await page.fill("#title-input", "A"); await page.fill("#url-input", "https://a.com");
    await page.click("button:has-text('Add')");
    await page.fill("#search-input", "zzz_nonexistent");
    await expect(page.locator(".no-results")).toBeVisible();
  });

  // AC-FILTER
  test("shows all bookmarks by default", async ({ page }) => {
    await page.fill("#title-input", "A"); await page.fill("#url-input", "https://a.com");
    await page.click("button:has-text('Add')");
    await page.fill("#title-input", "B"); await page.fill("#url-input", "https://b.com");
    await page.click("button:has-text('Add')");
    await expect(page.locator(".bookmark-item")).toHaveCount(2);
  });

  test("filters to favorites only", async ({ page }) => {
    await page.fill("#title-input", "Fav"); await page.fill("#url-input", "https://fav.com");
    await page.click("button:has-text('Add')");
    await page.click(".fav-btn");
    await page.fill("#title-input", "Reg"); await page.fill("#url-input", "https://reg.com");
    await page.click("button:has-text('Add')");
    await page.click("button:has-text('Favorites')");
    await expect(page.locator(".bookmark-item")).toHaveCount(1);
    await expect(page.locator(".title a")).toHaveText("Fav");
  });

  // AC-PERSIST
  test("persists bookmarks across reload", async ({ page }) => {
    await page.fill("#title-input", "Keep"); await page.fill("#url-input", "https://keep.com");
    await page.click("button:has-text('Add')");
    await page.reload();
    await expect(page.locator(".bookmark-item")).toHaveCount(1);
  });

  test("restores favorite state after reload", async ({ page }) => {
    await page.fill("#title-input", "F"); await page.fill("#url-input", "https://f.com");
    await page.click("button:has-text('Add')");
    await page.click(".fav-btn");
    await page.reload();
    await expect(page.locator(".fav-btn.favorited")).toHaveCount(1);
  });

  // AC-EMPTY
  test("shows empty state when no bookmarks", async ({ page }) => {
    await expect(page.locator(".empty-state")).toBeVisible();
  });

  // AC-KEYBOARD
  test("Enter key adds bookmark", async ({ page }) => {
    await page.fill("#title-input", "Key"); await page.fill("#url-input", "https://key.com");
    await page.press("#url-input", "Enter");
    await expect(page.locator(".bookmark-item")).toHaveCount(1);
  });

  test("Tab navigates controls", async ({ page }) => {
    await page.focus("#title-input");
    await page.keyboard.press("Tab");
    const focused = await page.evaluate(() => document.activeElement?.id);
    expect(focused).toBe("url-input");
  });

  // AC-RESPONSIVE
  test("layout works at narrow width", async ({ page }) => {
    await page.setViewportSize({ width: 360, height: 600 });
    await page.fill("#title-input", "Narrow"); await page.fill("#url-input", "https://narrow.com");
    await page.click("button:has-text('Add')");
    await expect(page.locator(".bookmark-item")).toBeVisible();
  });
});
