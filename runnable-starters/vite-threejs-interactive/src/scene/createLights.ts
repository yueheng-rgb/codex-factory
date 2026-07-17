/** Add ambient + directional lights to the scene */

import * as THREE from "three";

export function createLights(scene: THREE.Scene): void {
  const ambient = new THREE.AmbientLight(0x404060, 0.8);
  scene.add(ambient);

  const directional = new THREE.DirectionalLight(0xffeedd, 1.2);
  directional.position.set(5, 10, 5);
  directional.castShadow = true;
  directional.shadow.mapSize.set(1024, 1024);
  directional.shadow.camera.near = 0.5;
  directional.shadow.camera.far = 50;
  directional.shadow.camera.left = -10;
  directional.shadow.camera.right = 10;
  directional.shadow.camera.top = 10;
  directional.shadow.camera.bottom = -10;
  scene.add(directional);
}
