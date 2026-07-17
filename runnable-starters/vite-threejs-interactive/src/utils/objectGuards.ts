/**
 * Object guards — prevent crashes from missing registry entries.
 */

import { getSceneObjectById } from "../state/sceneObjects.js";
import type { SceneObject } from "../types/index.js";

/**
 * Safely get an object's display name.
 */
export function safeObjectName(id: string, fallback = "未知对象"): string {
  const obj = getSceneObjectById(id);
  return obj?.name ?? fallback;
}

/**
 * Safely get an object's type label.
 */
export function safeObjectType(id: string, fallback = "unknown"): string {
  const obj = getSceneObjectById(id);
  return obj?.type ?? fallback;
}

/**
 * Safely get an object's description.
 */
export function safeDescription(id: string, fallback = "暂无描述"): string {
  const obj = getSceneObjectById(id);
  return obj?.description ?? fallback;
}

/**
 * Check if an object is selectable.
 */
export function isSelectable(id: string): boolean {
  const obj = getSceneObjectById(id);
  return obj?.selectable ?? false;
}
