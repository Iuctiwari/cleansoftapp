export interface PaginationInput {
  readonly limit: number;
  readonly page: number;
}

export interface PaginatedResult<Item> extends PaginationInput {
  readonly items: readonly Item[];
  readonly total: number;
  readonly totalPages: number;
}
