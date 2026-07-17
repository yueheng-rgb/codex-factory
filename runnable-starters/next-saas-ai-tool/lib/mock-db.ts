/**
 * Mock 数据库（用户 + 幂等 store + quota + history）
 * 所有数据在进程运行期间存在，重启后重置。
 */

import { resetMockQuota } from "./usage-quota";
import { resetMockHistory } from "./generation-history";

export function resetAllMockData(): void {
  resetMockQuota();
  resetMockHistory();
}

// 启动时自动初始化默认用户额度
import { getQuota } from "./usage-quota";
getQuota("u-001"); // admin
getQuota("u-002"); // user
