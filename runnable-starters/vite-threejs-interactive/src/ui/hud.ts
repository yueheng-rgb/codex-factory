/**
 * HUD — Heads-Up Display
 * Shows project name, scene name, interaction mode, and hints.
 */

import { getState, subscribe } from "../state/appState.js";
import type { InteractionMode } from "../types/index.js";

const MODE_LABELS: Record<InteractionMode, string> = {
  explore: "探索",
  inspect: "检查",
  interact: "交互",
};

export function setupHUD(projectName: string): () => void {
  const hud = document.getElementById("hud");
  if (!hud) return () => {};

  hud.innerHTML = `
    <div class="hud-top">
      <span class="hud-project">${projectName}</span>
      <span class="hud-mode" id="hud-mode">${MODE_LABELS.explore}</span>
    </div>
    <div class="hud-hint" id="hud-hint">点击场景中的对象查看详情</div>
  `;

  const modeEl = document.getElementById("hud-mode");
  const hintEl = document.getElementById("hud-hint");

  const unsub = subscribe((state) => {
    if (modeEl) modeEl.textContent = MODE_LABELS[state.interactionMode];
    if (hintEl) {
      hintEl.textContent = state.selectedObjectId
        ? `已选中: ${state.selectedObjectId}`
        : "点击场景中的对象查看详情";
    }
  });

  return unsub;
}
