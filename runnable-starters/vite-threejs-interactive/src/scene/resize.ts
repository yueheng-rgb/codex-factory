/** Handle window resize — update camera aspect + renderer size */

import * as THREE from "three";

export function setupResize(
  camera: THREE.PerspectiveCamera,
  renderer: THREE.WebGLRenderer
): () => void {
  function onResize(): void {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  }

  window.addEventListener("resize", onResize);
  return () => window.removeEventListener("resize", onResize);
}
