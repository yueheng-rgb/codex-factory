/**
 * Raycaster-based interaction: hover + click to select.
 * Separated from UI — scene layer only handles picking & state changes.
 */

import * as THREE from "three";
import { getState, setSelectedObject, setHoveredObject, setMessage } from "../state/appState.js";
import { getSceneObjectById, updateSceneObjectStatus } from "../state/sceneObjects.js";

export interface InteractionConfig {
  camera: THREE.PerspectiveCamera;
  interactiveObjects: THREE.Object3D[];
  objectMeshMap: Map<string, THREE.Object3D>;
  onObjectSelected?: (id: string) => void;
  onObjectMarked?: (id: string) => void;
}

export function setupInteraction(config: InteractionConfig): () => void {
  const raycaster = new THREE.Raycaster();
  const mouse = new THREE.Vector2();

  function onPointerMove(event: PointerEvent): void {
    mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

    raycaster.setFromCamera(mouse, config.camera);
    const intersects = raycaster.intersectObjects(config.interactiveObjects, true);
    if (intersects.length > 0) {
      const obj = findParentWithObjectId(intersects[0].object);
      if (obj && obj.userData.objectId && obj.userData.objectId !== "ground") {
        setHoveredObject(obj.userData.objectId);
        return;
      }
    }
    setHoveredObject(null);
  }

  function onClick(event: MouseEvent): void {
    mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

    raycaster.setFromCamera(mouse, config.camera);
    const intersects = raycaster.intersectObjects(config.interactiveObjects, true);
        if (intersects.length > 0) {
      const obj = findParentWithObjectId(intersects[0].object);
      if (obj && obj.userData.objectId && obj.userData.objectId !== "ground") {
        setSelectedObject(obj.userData.objectId);
        config.onObjectSelected?.(obj.userData.objectId);
        return;
      }
    }

    // Click on empty space → deselect
    setSelectedObject(null);
    config.onObjectSelected?.("");
  }

  // Expose mark-as-viewed action via message passing
  window.addEventListener("message", (event) => {
    if (event.data?.type === "mark-viewed") {
      const id = event.data.objectId;
      if (!id) return;
      updateSceneObjectStatus(id, "viewed");
      setMessage(`已标记为已查看: ${id}`);
      config.onObjectMarked?.(id);
    }
  });

  window.addEventListener("pointermove", onPointerMove);
  window.addEventListener("click", onClick);

  return () => {
    window.removeEventListener("pointermove", onPointerMove);
    window.removeEventListener("click", onClick);
  };
}

/**
 * Set hover highlight color on a mesh.
 */
export function highlightObject(
  mesh: THREE.Object3D | undefined,
  color: number
): void {
  if (!mesh) return;
  mesh.traverse((child) => {
    if (child instanceof THREE.Mesh && child.material instanceof THREE.MeshStandardMaterial) {
      child.userData._originalColor ??= child.material.color.getHex();
      child.material.emissive = new THREE.Color(color);
      child.material.emissiveIntensity = 0.4;
    }
  });
}

/**
 * Remove highlights from a mesh.
 */
export function unhighlightObject(mesh: THREE.Object3D | undefined): void {
  if (!mesh) return;
  mesh.traverse((child) => {
    if (child instanceof THREE.Mesh && child.material instanceof THREE.MeshStandardMaterial) {
      child.material.emissive = new THREE.Color(0x000000);
      child.material.emissiveIntensity = 0;
    }
  });
}

function findParentWithObjectId(obj: THREE.Object3D): THREE.Object3D | null {
  let current: THREE.Object3D | null = obj;
  while (current) {
    if (current.userData.objectId && !current.userData.isGroup) return current;
    current = current.parent;
  }
  return null;
}
