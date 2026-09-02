import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class BranchDto {
  @ApiProperty({ example: 'a1b2c3d4e5f60718293a4b5c' })
  branchId!: string;

  @ApiProperty({ example: 'a1b2c3d4e5f60718293a4b5c' })
  tenantId!: string;

  @ApiProperty({ example: 'Kothrud Branch' })
  branchName!: string;

  @ApiPropertyOptional({ example: 'KTD' })
  code?: string;

  @ApiProperty({ example: 'Paud Road, Kothrud' })
  streetAddress!: string;

  @ApiProperty({ example: 'Pune' })
  city!: string;

  @ApiProperty({ example: 'Maharashtra' })
  state!: string;

  @ApiProperty({ example: 'India' })
  country!: string;

  @ApiProperty({ example: '411038' })
  postalCode!: string;

  @ApiProperty({ example: '9876543212' })
  phone!: string;

  @ApiProperty({ example: 'kothrud-branch@business.com' })
  email!: string;

  @ApiPropertyOptional({ example: '09:00' })
  openingTime?: string;

  @ApiPropertyOptional({ example: '21:00' })
  closingTime?: string;

  @ApiPropertyOptional({ example: '64f1c2a9b1d4e2a1c8f9a123', nullable: true })
  managerId?: string;

  @ApiPropertyOptional({ example: 'Aisha Noor' })
  managerName?: string;

  @ApiProperty({ example: 8, minimum: 0 })
  totalStaff!: number;

  @ApiProperty({ example: 142, minimum: 0 })
  totalOrders!: number;

  @ApiProperty({ example: 7, minimum: 0 })
  ordersToday!: number;

  @ApiProperty({ example: false })
  isHeadOffice!: boolean;

  @ApiProperty({ enum: ['active', 'inactive', 'closed'], example: 'active' })
  status!: 'active' | 'inactive' | 'closed';

  @ApiProperty({ example: '2026-08-11T10:15:30.000Z' })
  createdAt!: string;

  @ApiProperty({ example: '2026-08-11T10:15:30.000Z' })
  updatedAt!: string;
}

export class BranchStatisticsDto {
  @ApiProperty({ example: 3, minimum: 0 })
  totalBranches!: number;

  @ApiProperty({ example: 18, minimum: 0 })
  totalStaff!: number;

  @ApiProperty({ example: 392, minimum: 0 })
  totalOrders!: number;

  @ApiProperty({ example: 14, minimum: 0 })
  ordersToday!: number;
}
