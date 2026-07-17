/**
 * Entry point — bootstrap Three.js scene + UI
 */

import { createScene } from "./scene/createScene.js";
import { createCamera } from "./scene/createCamera.js";
import { createRenderer } from "./scene/createRenderer.js";
import { createLights } from "./scene/createLights.js";
import { createObjects, createGround } from "./scene/createObjects.js";
import { setupInteraction, highlightObject, unhighlightObject } from "./scene/interaction.js";
import { startAnimationLoop } from "./scene/animationLoop.js";
import { setupResize } from "./scene/resize.js";
import { initRegistry } from "./state/sceneObjects.js";
import { subscribe } from "./state/appState.js";
import { setupHUD } from "./ui/hud.js";
import { setupPanel } from "./ui/panel.js";
import { setupMiniMap } from "./ui/minimap.js";
import { showToast } from "./ui/toast.js";
import * as THREE from "three";

const PROJECT_NAME = "vite-threejs-interactive";

function main(): void {
  const canvas = document.getElementById("three-canvas") as HTMLCanvasElement;
  if (!canvas) {
    console.error("Canvas #three-canvas not found");
    return;
  }

  // Initialize scene object registry
  initRegistry();

  // Create Three.js scene
  const scene = createScene();
  const camera = createCamera();
  const renderer = createRenderer(canvas);
  createLights(scene);
  createGround(scene);

  // Object mesh map for interaction
  const objectMeshMap = new Map<string, THREE.Object3D>();
  createObjects(scene, objectMeshMap);

  // Get all interactive objects (excluding ground)
  const interactiveObjects: THREE.Object3D[] = [];
  scene.traverse((child) => {
    if (child.userData.objectId && child.userData.objectId !== "ground") {
      interactiveObjects.push(child);
    }
  });

  // Setup interaction
  const cleanupInteraction = setupInteraction({
    camera,
    interactiveObjects,
    objectMeshMap,
    onObjectSelected: () => {},
    onObjectMarked: (id) => {
      showToast(`对象已标记为已查看: ${id}`);
    },
  });

  // Hover highlight sync
  subscribe((state) => {
    if (state.hoveredObjectId) {
      const prevHoveredEl = objectMeshMap.get(state.hoveredObjectId);
      highlightObject(prevHoveredEl, 0x444444);
    } else {
      // Unhighlight all
      for (const [, mesh] of objectMeshMap) {
        unhighlightObject(mesh);
      }
    }
  });

  // Setup UI
  const cleanupHUD = setupHUD(PROJECT_NAME);
  const cleanupPanel = setupPanel();
  setupMiniMap();

  // Animation loop
  const stopAnimation = startAnimationLoop(renderer, scene, camera);

  // Resize
  const cleanupResize = setupResize(camera, renderer);

  // Cleanup on hot-reload (dev)
  if (import.meta.hot) {
    import.meta.hot.dispose(() => {
      cleanupInteraction();
      cleanupHUD();
      cleanupPanel();
      stopAnimation();
      cleanupResize();
      renderer.dispose();
    });
  }
}

main();
