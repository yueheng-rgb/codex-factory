export interface SceneData { id: string; userId: string; objects: any[]; version: number; }
export interface AssetLoadRequest { url: string; type: string; }
export interface GameState { current: string; transitions: Record<string, string[]>; }
export interface ScoreSubmission { userId: string; score: number; gameId: string; }
export const ALLOWED_ASSET_DOMAINS = ["cdn.example.com","assets.mysite.com","localhost"];
export const VALID_GAME_STATES = ["menu","playing","paused","gameover","loading"];
export const VALID_TRANSITIONS: Record<string, string[]> = {
  "menu": ["playing","loading"], "playing": ["paused","gameover"], "paused": ["playing","menu"], "gameover": ["menu"], "loading": ["menu","playing"]
};
export const FRAME_BUDGET_MS = 16;
