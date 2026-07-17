/**
 * Simple application state manager
 * No Redux/Zustand — just a plain object + listener pattern.
 */

import type { AppState, InteractionMode, StateListener } from "../types/index.js";

let state: AppState = {
  selectedObjectId: null,
  hoveredObjectId: null,
  currentSceneId: "main_room",
  interactionMode: "explore",
  lastMessage: null,
};

const listeners = new Set<StateListener>();

export function getState(): Readonly<AppState> {
  return state;
}

export function setSelectedObject(id: string | null): void {
  state = { ...state, selectedObjectId: id };
  notify();
}

export function setHoveredObject(id: string | null): void {
  state = { ...state, hoveredObjectId: id };
  notify();
}

export function setInteractionMode(mode: InteractionMode): void {
  state = { ...state, interactionMode: mode };
  notify();
}

export function setMessage(msg: string | null): void {
  state = { ...state, lastMessage: msg };
  notify();
}

export function subscribe(fn: StateListener): () => void {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

function notify(): void {
  for (const fn of listeners) {
    fn(state);
  }
}
