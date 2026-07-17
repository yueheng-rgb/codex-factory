// transfer.js — Transfer model with PENDING/COMPLETED status
// Node.js built-ins only, no npm packages

const TransferStatus = Object.freeze({
  PENDING: "PENDING",
  COMPLETED: "COMPLETED",
});

const TransferStatus_values = Object.values(TransferStatus);

function createTransfer(transferId, fromSkuId, toSkuId, quantity, status) {
  if (!transferId || !fromSkuId || !toSkuId) {
    throw new Error("Transfer requires transferId, fromSkuId, and toSkuId");
  }
  if (typeof quantity !== "number" || quantity <= 0) {
    throw new Error("quantity must be a positive number");
  }
  const _status = status || TransferStatus.PENDING;
  if (!TransferStatus_values.includes(_status)) {
    throw new Error(`Invalid TransferStatus: ${_status}`);
  }
  return Object.freeze({ transferId, fromSkuId, toSkuId, quantity, status: _status });
}

module.exports = {
  TransferStatus,
  createTransfer,
};
