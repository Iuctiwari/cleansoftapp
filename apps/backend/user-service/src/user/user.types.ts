export type UserRole = 'Owner' | 'Branch Manager' | 'Staff' | 'Cashier';
export type UserStatus = 'Active' | 'Suspended';

export interface UserRecord {
  userId: string;
  tenantId: string;
  name: string;
  /** Unique login username set by the owner at registration time. Cannot be changed. */
  loginId: string;
  email?: string;
  mobileNumber?: string;
  department?: string;
  role: UserRole;
  branchIds: string[];
  status: UserStatus;
  createdAt: Date;
  updatedAt: Date;
}

