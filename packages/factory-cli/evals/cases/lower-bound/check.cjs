const assert = require('node:assert/strict');
const { lowerBound } = require('./solution.cjs');
for (const [array, target, expected] of [
  [[], 1, 0], [[1], 1, 0], [[1], 2, 1], [[1, 2, 2, 4], 2, 1],
  [[1, 2, 2, 4], 3, 3], [[-3, 0, 5], -10, 0], [[-3, 0, 5], 10, 3],
]) assert.equal(lowerBound(Object.freeze(array), target), expected);
for (let n = 0; n < 80; n++) {
  const array = Array.from({ length: n }, (_, i) => Math.floor(i / 3) - 10);
  for (let value = -12; value < 20; value++) {
    const index = array.findIndex((item) => item >= value);
    assert.equal(lowerBound(array, value), index < 0 ? array.length : index);
  }
}
console.log('lower-bound acceptance PASS');
