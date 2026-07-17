// stockLevel.js — StockLevel model with invariant: available = onHand - reserved, available >= 0
// Node.js built-ins only, no npm packages

function createStockLevel(skuId, onHand, reserved) {
  if (!skuId) {
    throw new Error("StockLevel requires skuId");
  }
  const _onHand = Number(onHand) || 0;
  let _reserved = Number(reserved) || 0;

  if (_onHand < 0) {
    throw new Error("onHand must be >= 0");
  }
  if (_reserved < 0) {
    throw new Error("reserved must be >= 0");
  }

  let available = _onHand - _reserved;
  if (available < 0) {
    throw new Error("Invariant violation: available = onHand - reserved must be >= 0");
  }

  function recomputeAvailable() {
    available = _onHand - _reserved;
    if (available < 0) {
      throw new Error("Invariant violation: available = onHand - reserved must be >= 0");
    }
    return available;
  }

  return Object.freeze({
    get skuId() { return skuId; },
    get onHand() { return _onHand; },
    get reserved() { return _reserved; },
    get available() { return available; },
  });
}

module.exports = {
  createStockLevel,
};
