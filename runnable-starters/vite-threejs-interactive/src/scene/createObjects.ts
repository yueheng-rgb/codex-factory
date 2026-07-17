/**
 * Create low-poly placeholder objects from the scene object registry.
 * Each mesh stores its object id in userData for raycaster lookup.
 */

import * as THREE from "three";
import { getAllSceneObjects } from "../state/sceneObjects.js";

export function createObjects(scene: THREE.Scene, objectMap: Map<string, THREE.Object3D>): void {
  const objects = getAllSceneObjects();

  for (const obj of objects) {
    let mesh: THREE.Mesh;
    const { x, y, z } = obj.position;

    switch (obj.type) {
      case "furniture":
        mesh = createFurniture(obj.color);
        break;
      case "clue":
        mesh = createClueBox(obj.color);
        break;
      case "door":
        mesh = createDoor(obj.color);
        break;
      default:
        mesh = createDefaultProp(obj.color);
    }

    mesh.position.set(x, y, z);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    mesh.userData = { objectId: obj.id };

    scene.add(mesh);
    objectMap.set(obj.id, mesh);
  }
}

/** Ground plane */
export function createGround(scene: THREE.Scene): THREE.Mesh {
  const geo = new THREE.PlaneGeometry(20, 20);
  const mat = new THREE.MeshStandardMaterial({ color: 0x333344, roughness: 0.9 });
  const ground = new THREE.Mesh(geo, mat);
  ground.rotation.x = -Math.PI / 2;
  ground.position.y = -0.5;
  ground.receiveShadow = true;
  ground.userData = { objectId: "ground" };
  scene.add(ground);
  return ground;
}

function createFurniture(color: number): THREE.Mesh {
  // Table-like shape
  const topGeo = new THREE.CylinderGeometry(1, 1, 0.15, 16);
  const legGeo = new THREE.CylinderGeometry(0.1, 0.1, 1.2, 8);
  const mat = new THREE.MeshStandardMaterial({ color, roughness: 0.6 });

  const group = new THREE.Group();
  const top = new THREE.Mesh(topGeo, mat);
  top.position.y = 0.6;
  group.add(top);

  for (const angle of [0, Math.PI / 2, Math.PI, Math.PI * 1.5]) {
    const leg = new THREE.Mesh(legGeo, mat);
    leg.position.set(Math.cos(angle) * 0.8, 0, Math.sin(angle) * 0.8);
    group.add(leg);
  }

  const parent = new THREE.Mesh(new THREE.SphereGeometry(0.01), mat);
  parent.add(group);
  parent.userData = { isGroup: true };
  return parent;
}

function createClueBox(color: number): THREE.Mesh {
  const geo = new THREE.BoxGeometry(0.6, 0.4, 0.4);
  const mat = new THREE.MeshStandardMaterial({ color, roughness: 0.4, metalness: 0.3 });
  const mesh = new THREE.Mesh(geo, mat);
  // Slight tilt for visual interest
  mesh.rotation.y = Math.PI / 6;
  return mesh;
}

function createDoor(color: number): THREE.Mesh {
  const geo = new THREE.BoxGeometry(0.2, 2.5, 1.2);
  const mat = new THREE.MeshStandardMaterial({ color, roughness: 0.5, metalness: 0.4 });
  const mesh = new THREE.Mesh(geo, mat);
  mesh.position.y = 0.75;
  return mesh;
}

function createDefaultProp(color: number): THREE.Mesh {
  const geo = new THREE.SphereGeometry(0.4, 16, 16);
  const mat = new THREE.MeshStandardMaterial({ color, roughness: 0.5 });
  return new THREE.Mesh(geo, mat);
}
