// itemTypes.js — ItemType enum and SKU model
// Node.js built-ins only, no npm packages

const ItemType = Object.freeze({
  PHYSICAL: "PHYSICAL",
  DIGITAL: "DIGITAL",
});

const ItemType_values = Object.values(ItemType);

/**
 * @typedef {{ skuId: string, name: string, category: string }} SKU
 */

function createSKU(skuId, name, category) {
  if (!skuId || !name || !category) {
    throw new Error("SKU requires skuId, name, and category");
  }
  return Object.freeze({ skuId, name, category });
}

function isItemType(value) {
  return ItemType_values.includes(value);
}

module.exports = {
  ItemType,
  createSKU,
  isItemType,
};
