/**
 * ????
 */

import type { PaginatedResult, PaginationParams } from "../types/index.js";

export const DEFAULT_PAGE = 1;
export const DEFAULT_PAGE_SIZE = 20;
export const MAX_PAGE_SIZE = 100;

export interface PaginationResult {
  valid: true;
  params: PaginationParams;
}

export interface PaginationError {
  valid: false;
  code: "INVALID_PAGINATION";
  message: string;
  details: Array<{ field: string; message: string }>;
}

export type PaginationParseResult = PaginationResult | PaginationError;

/**
 * ????????????????????????
 */
export function parsePaginationStrict(query: {
  page?: string;
  limit?: string;
  pageSize?: string;
}): PaginationParseResult {
  const errors: Array<{ field: string; message: string }> = [];
  const rawPage = query.page;
  const rawLimit = query.limit || query.pageSize;

  let page = NaN;
  let pageSize = NaN;

  // ---- page ?? ----
  if (rawPage === undefined || rawPage === null || rawPage === "") {
    page = DEFAULT_PAGE;
  } else {
    const parsed = Number(rawPage);
    if (!Number.isInteger(parsed) || String(parsed) !== String(rawPage).trim()) {
      errors.push({ field: "page", message: "page ?????" });
    } else if (parsed < 1) {
      errors.push({ field: "page", message: "page ?? >= 1" });
    } else {
      page = parsed;
    }
  }

  // ---- pageSize ?? ----
  if (rawLimit === undefined || rawLimit === null || rawLimit === "") {
    pageSize = DEFAULT_PAGE_SIZE;
  } else {
    const parsed = Number(rawLimit);
    if (!Number.isInteger(parsed) || String(parsed) !== String(rawLimit).trim()) {
      errors.push({ field: "pageSize", message: "pageSize ?????" });
    } else if (parsed < 1) {
      errors.push({ field: "pageSize", message: "pageSize ?? >= 1" });
    } else if (parsed > MAX_PAGE_SIZE) {
      errors.push({ field: "pageSize", message: `pageSize ???? ${MAX_PAGE_SIZE}` });
    } else {
      pageSize = parsed;
    }
  }

  if (errors.length > 0) {
    return {
      valid: false,
      code: "INVALID_PAGINATION",
      message: "??????",
      details: errors,
    };
  }

  return { valid: true, params: { page, pageSize } };
}

/**
 * @deprecated ?? parsePaginationStrict ????????
 * ????????????????????
 */
export function parsePagination(query: {
  page?: string;
  limit?: string;
  pageSize?: string;
}): PaginationParams {
  let page = parseInt(query.page || String(DEFAULT_PAGE), 10);
  let pageSize = parseInt(query.limit || query.pageSize || String(DEFAULT_PAGE_SIZE), 10);

  if (isNaN(page) || page < 1) page = DEFAULT_PAGE;
  if (isNaN(pageSize) || pageSize < 1) pageSize = DEFAULT_PAGE_SIZE;
  if (pageSize > MAX_PAGE_SIZE) pageSize = MAX_PAGE_SIZE;

  return { page, pageSize };
}

export function paginate<T>(
  items: T[],
  total: number,
  page: number,
  pageSize: number
): PaginatedResult<T> {
  return {
    items,
    page,
    pageSize,
    total,
    totalPages: Math.ceil(total / pageSize),
  };
}
