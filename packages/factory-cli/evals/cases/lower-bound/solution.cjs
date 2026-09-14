exports.lowerBound = function lowerBound(array, target) {
  let low = 0, high = array.length;
  while (low < high) {
    const mid = Math.floor((low + high) / 2);
    if (array[mid] <= target) low = mid + 1;
    else high = mid;
  }
  return low;
};
