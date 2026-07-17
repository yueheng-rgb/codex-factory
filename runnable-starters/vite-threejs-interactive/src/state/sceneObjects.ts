/**
 * Scene Object Registry
 * Defines all scene objects and provides lookup/update helpers.
 */

import type { SceneObject } from "../types/index.js";

export const INITIAL_OBJECTS: SceneObject[] = [
  {
    id: "room_table",
    name: "圆桌",
    type: "furniture",
    description: "一张旧木圆桌，表面有划痕。替换为实际场景描述。",
    status: "default",
    position: { x: 0, y: 0, z: -2 },
    color: 0x8b5e3c,
    selectable: true,
    metadata: {},
  },
  {
    id: "clue_box",
    name: "线索盒",
    type: "clue",
    description: "一个金属盒子，可能藏有关键信息。替换为实际线索。",
    status: "default",
    position: { x: -2, y: 0.5, z: 0 },
    color: 0x4a90d9,
    selectable: true,
    metadata: {},
  },
  {
    id: "locked_door",
    name: "上锁的门",
    type: "door",
    description: "一扇紧锁的铁门，需要找到钥匙。替换为实际门描述。",
    status: "locked",
    position: { x: 2, y: 0, z: 2 },
    color: 0x666666,
    selectable: true,
    metadata: { requiresKey: true },
  },
];

const objectMap = new Map<string, SceneObject>();

export function initRegistry(objects?: SceneObject[]): void {
  objectMap.clear();
  const list = objects ?? INITIAL_OBJECTS;
  for (const obj of list) {
    objectMap.set(obj.id, { ...obj });
  }
}

export function getSceneObjectById(id: string): SceneObject | undefined {
  return objectMap.get(id);
}

export function getAllSceneObjects(): SceneObject[] {
  return Array.from(objectMap.values());
}

export function updateSceneObjectStatus(
  id: string,
  status: SceneObject["status"]
): SceneObject | undefined {
  const obj = objectMap.get(id);
  if (!obj) return undefined;
  obj.status = status;
  objectMap.set(id, obj);
  return obj;
}
