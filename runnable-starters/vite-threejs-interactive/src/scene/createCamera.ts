/** Create a perspective camera */

import * as THREE from "three";

export function createCamera(): THREE.PerspectiveCamera {
  const camera = new THREE.PerspectiveCamera(
    60,
    window.innerWidth / window.innerHeight,
    0.1,
    100
  );
  camera.position.set(0, 3, 8);
  camera.lookAt(0, 0, 0);
  return camera;
}
