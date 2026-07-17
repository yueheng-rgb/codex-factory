/** Shared type definitions for Three.js interactive scene */

export interface SceneObject {
  id: string;
  name: string;
  type: "furniture" | "clue" | "door" | "npc" | "prop" | "trigger";
  description: string;
  status: "default" | "viewed" | "interacted" | "locked" | "unlocked";
  position: { x: number; y: number; z: number };
  color: number;
  selectable: boolean;
  metadata: Record<string, unknown>;
}

export type InteractionMode = "explore" | "inspect" | "interact";

export interface AppState {
  selectedObjectId: string | null;
  hoveredObjectId: string | null;
  currentSceneId: string;
  interactionMode: InteractionMode;
  lastMessage: string | null;
}

export type StateListener = (state: AppState) => void;
