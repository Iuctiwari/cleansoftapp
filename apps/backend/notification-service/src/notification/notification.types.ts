export enum NotificationType {
  WORKER_ASSIGNED = 'WorkerAssigned',
  ASSIGNMENT_ACCEPTED = 'AssignmentAccepted',
  ORDER_CREATED = 'OrderCreated',
  ORDER_IN_PROGRESS = 'OrderInProgress',
  ORDER_IN_DELIVERY = 'OrderInDelivery',
  DELIVERY_COMPLETED = 'DeliveryCompleted',
  PAYMENT_PENDING = 'PaymentPending',
  PAYMENT_RECEIVED = 'PaymentReceived',
  SYSTEM = 'System',
}

export interface NotificationRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly branchId: string;
  readonly recipientId: string;
  readonly title: string;
  readonly message: string;
  readonly type: NotificationType;
  readonly entityType?: string;
  readonly entityId?: string;
  readonly orderId?: string;
  readonly isRead: boolean;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface CreateNotificationRecord {
  readonly tenantId: string;
  readonly branchId: string;
  readonly recipientId: string;
  readonly title: string;
  readonly message: string;
  readonly type: NotificationType;
  readonly entityType?: string;
  readonly entityId?: string;
  readonly orderId?: string;
}

/** Raw request body for POST /notifications, unvalidated until the service parses it. */
export interface CreateNotificationInput {
  readonly recipientId?: unknown;
  readonly title?: unknown;
  readonly message?: unknown;
  readonly type?: unknown;
  readonly entityType?: unknown;
  readonly entityId?: unknown;
  readonly orderId?: unknown;
}

export interface NotificationListQuery {
  readonly page: number;
  readonly limit: number;
  readonly isRead?: boolean;
  readonly type?: NotificationType;
  readonly sortDirection: 1 | -1;
}

export interface NotificationPage {
  readonly items: readonly NotificationRecord[];
  readonly total: number;
  readonly page: number;
  readonly limit: number;
  readonly totalPages: number;
}

export interface NotificationUnreadCount {
  readonly count: number;
}

export interface NotificationScope {
  readonly actorId: string;
  readonly authorization: string;
  readonly branchId: string;
  readonly permissions: readonly string[];
  readonly roleCode: string;
  readonly tenantId: string;
}

export interface NotificationRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  notificationScope?: NotificationScope;
}
