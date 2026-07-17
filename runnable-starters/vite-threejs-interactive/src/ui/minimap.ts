/**
 * MiniMap — placehoder top-down view
 * Real project: implement a secondary orthographic camera or canvas-based map.
 */

import { getAllSceneObjects } from "../state/sceneObjects.js";

export function setupMiniMap(): void {
  const minimap = document.getElementById("minimap");
  if (!minimap) return;

  const objects = getAllSceneObjects();

  minimap.innerHTML = `
    <div class="minimap-header">小地图</div>
    <div class="minimap-grid">
      ${objects
        .map(
          (o) =>
            `<div class="minimap-dot" style="left:${((o.position.x + 5) / 10) * 100}%;top:${((o.position.z + 5) / 10) * 100}%" title="${o.name}"></div>`
        )
        .join("")}
    </div>
    <div class="minimap-legend">⬤ 场景对象</div>
  `;
}
