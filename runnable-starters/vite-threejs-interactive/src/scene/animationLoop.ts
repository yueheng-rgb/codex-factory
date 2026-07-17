/** Render loop — continuous animation */

import * as THREE from "three";

export function startAnimationLoop(
  renderer: THREE.WebGLRenderer,
  scene: THREE.Scene,
  camera: THREE.PerspectiveCamera
): () => void {
  const clock = new THREE.Clock();
  let animId = 0;

  function animate(): void {
    animId = requestAnimationFrame(animate);

    const delta = clock.getDelta();
    // Subtle rotation on interactive objects for visual feedback
    scene.traverse((child) => {
      if (child.userData.objectId && child.userData.objectId !== "ground" && !child.userData.isGroup) {
        child.rotation.y += delta * 0.3;
      }
    });

    renderer.render(scene, camera);
  }

  animate();

  return () => cancelAnimationFrame(animId);
}
