/** What the phone shows, plus data the app uses when the notification is tapped. */
export interface PushMessage {
  readonly title: string;
  readonly body: string;
  /** e.g. { type: 'online_request', requestId: '…' } — all values become strings. */
  readonly data?: Readonly<Record<string, string | number | boolean>>;
}

/** Who a push goes to. Exactly one of the three shapes. */
export type PushAudience =
  | { readonly kind: 'user'; readonly userId: string }
  | { readonly kind: 'consumer'; readonly consumerId: string }
  /** Shop users of one branch who can see orders, plus the shop's owners. */
  | {
      readonly kind: 'branch';
      readonly tenantId: string;
      readonly branchId: string;
      readonly excludeUserId?: string;
    };

export interface PushOutcome {
  /** false when no Firebase key is configured. */
  readonly enabled: boolean;
  readonly devices: number;
  readonly sent: number;
  /** Tokens Google reported as dead, now removed. */
  readonly removed: number;
}

export const NO_PUSH: PushOutcome = { enabled: false, devices: 0, sent: 0, removed: 0 };

export const MAX_DEVICES_PER_ACCOUNT = 10;
