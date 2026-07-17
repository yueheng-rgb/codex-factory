/**
 * Right-side info panel
 * Shows selected object details or empty state.
 */

import { getState, subscribe } from "../state/appState.js";
import { getSceneObjectById } from "../state/sceneObjects.js";
import { safeObjectName, safeDescription, safeObjectType } from "../utils/objectGuards.js";

export function setupPanel(): () => void {
  const panel = document.getElementById("panel");
  if (!panel) return () => {};

  function renderPanel(): void {
    const state = getState();
    if (!state.selectedObjectId) {
      panel!.innerHTML = `
        <div class="panel-empty">
          <div class="panel-empty-icon">👆</div>
          <p>点击场景中的对象查看详情</p>
          <p class="panel-empty-sub">选中对象后将在此显示详细信息</p>
        </div>
      `;
      return;
    }

    const obj = getSceneObjectById(state.selectedObjectId);
    const name = safeObjectName(state.selectedObjectId);
    const type = safeObjectType(state.selectedObjectId);
    const desc = safeDescription(state.selectedObjectId);

    panel!.innerHTML = `
      <div class="panel-header">对象详情</div>
      <div class="panel-body">
        <div class="panel-field"><span class="panel-label">名称</span> ${name}</div>
        <div class="panel-field"><span class="panel-label">类型</span> ${type}</div>
        <div class="panel-field"><span class="panel-label">状态</span> ${obj?.status ?? "unknown"}</div>
        <div class="panel-field"><span class="panel-label">描述</span> ${desc}</div>
      </div>
      <div class="panel-actions">
        <button class="panel-btn" id="btn-mark-viewed" ${!obj ? "disabled" : ""}>标记已查看</button>
      </div>
    `;

    const btn = document.getElementById("btn-mark-viewed");
    if (btn) {
      btn.addEventListener("click", () => {
        window.postMessage(
          { type: "mark-viewed", objectId: state.selectedObjectId },
          window.location.origin
        );
      });
    }
  }

  const unsub = subscribe(renderPanel);
  // Initial render
  renderPanel();

  return unsub;
}
