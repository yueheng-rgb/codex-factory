function rejectStaleVersion(skuId, currentVersion, expectedVersion) {
  if (currentVersion !== expectedVersion) {
    const err = new Error(
      `Optimistic concurrency conflict on SKU '${skuId}': expected version ${expectedVersion}, got ${currentVersion}`
    );
    err.code = 'STALE_VERSION';
    err.skuId = skuId;
    err.currentVersion = currentVersion;
    err.expectedVersion = expectedVersion;
    throw err;
  }
  return true;
}

module.exports = { rejectStaleVersion };
