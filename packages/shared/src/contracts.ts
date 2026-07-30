export interface Clock {
  now(): Date;
}

export interface CorrelationContext {
  readonly correlationId: string;
  readonly requestId?: string;
}

export interface Identifiable<Identifier = string> {
  readonly id: Identifier;
}

export interface Timestamped {
  readonly createdAt: Date;
  readonly updatedAt: Date;
}
