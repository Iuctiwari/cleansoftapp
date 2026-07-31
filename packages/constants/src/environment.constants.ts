export const RUNTIME_ENVIRONMENTS = ['development', 'test', 'production'] as const;

export type RuntimeEnvironment = (typeof RUNTIME_ENVIRONMENTS)[number];
