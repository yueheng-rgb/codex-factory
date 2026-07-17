// C++ Memory Safety Runtime Validation — Type Definitions
// These mirror C/C++ concepts in TypeScript for invariant validation.

export const BOUNDS_DEFAULTS = {
  MAX_BUFFER_SIZE: 4096,
  MAX_INPUT_SIZE: 1048576, // 1MB
  MAX_FILE_PARSE_DEPTH: 100,
  MAX_ALLOCATION_SIZE: 1073741824, // 1GB guard
} as const;

export const VALID_MEMORY_STATES = ["ALLOCATED", "FREED", "NULLIFIED", "UNINITIALIZED"] as const;
export type MemoryState = typeof VALID_MEMORY_STATES[number];

export const ALLOWED_TRANSITIONS: Record<MemoryState, MemoryState[]> = {
  ALLOCATED: ["FREED", "NULLIFIED"],
  FREED: ["ALLOCATED", "NULLIFIED"],
  NULLIFIED: ["ALLOCATED"],
  UNINITIALIZED: ["ALLOCATED"],
};

export const DISALLOWED_OPERATIONS: Record<MemoryState, string[]> = {
  ALLOCATED: ["double_free"],
  FREED: ["dereference", "write", "free", "read"],
  NULLIFIED: ["dereference", "write", "read", "free"],
  UNINITIALIZED: ["read"],
};

export const FORMAT_STRING_FUNCTIONS = [
  "printf", "sprintf", "snprintf", "fprintf", "vprintf", "vsprintf"
] as const;

export const UNSAFE_STRING_FUNCTIONS = [
  "strcpy", "strcat", "gets", "scanf", "sscanf",
  "memcpy", "memmove", "memset"
] as const;

export const SANITIZER_FLAGS: Record<string, string> = {
  ASAN: "-fsanitize=address -fno-omit-frame-pointer -g",
  UBSAN: "-fsanitize=undefined -fno-omit-frame-pointer -g",
  TSAN: "-fsanitize=thread -fno-omit-frame-pointer -g",
  MSAN: "-fsanitize=memory -fno-omit-frame-pointer -g",
};

export interface BufferOperation {
  buffer: string;
  offset: number;
  size: number;
  operation: "read" | "write" | "copy";
}

export interface PointerState {
  id: string;
  state: MemoryState;
  allocatedSize: number;
  freedAt: number | null;
}

export interface FormatStringCall {
  function: string;
  formatArg: string;
  isLiteral: boolean;
}

export interface AllocationRequest {
  elementSize: number;
  count: number;
  totalSize: number;
}

export interface FileParseConfig {
  maxInputSize: number;
  maxDepth: number;
  allowedMimeTypes: string[];
  inputFile: string;
}

export interface CompilationResult {
  compiler: string;
  compilerVersion: string | null;
  available: boolean;
  sanitizerFlagsSupported: Record<string, boolean>;
  exitCode: number | null;
  stdout: string;
  stderr: string;
}

export interface ToolAvailability {
  tool: string;
  available: boolean;
  version: string | null;
  path: string | null;
  limitation: string | null;
}

