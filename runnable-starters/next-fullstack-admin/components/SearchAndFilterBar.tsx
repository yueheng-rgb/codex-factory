"use client";

interface SearchAndFilterBarProps {
  searchValue: string;
  onSearchChange: (val: string) => void;
  statusValue: string;
  onStatusChange: (val: string) => void;
  onClear: () => void;
  statusOptions: Array<{ value: string; label: string }>;
  searchPlaceholder?: string;
  statusLabel?: string;
}

export default function SearchAndFilterBar({
  searchValue,
  onSearchChange,
  statusValue,
  onStatusChange,
  onClear,
  statusOptions,
  searchPlaceholder = "搜索...",
  statusLabel = "状态",
}: SearchAndFilterBarProps) {
  const hasFilters = searchValue || statusValue;

  return (
    <div className="search-filter-bar">
      <input
        type="text"
        className="search-input"
        placeholder={searchPlaceholder}
        value={searchValue}
        onChange={(e) => onSearchChange(e.target.value)}
      />
      <select
        className="filter-select"
        value={statusValue}
        onChange={(e) => onStatusChange(e.target.value)}
      >
        <option value="">全部{statusLabel}</option>
        {statusOptions.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
      {hasFilters && (
        <button className="btn-text" onClick={onClear}>
          清除
        </button>
      )}
    </div>
  );
}
