'use strict';

const assert = require('node:assert/strict');
const trade = require('../../main/assets/trade-math.js');

function close(actual, expected, message) {
  assert.ok(Math.abs(actual - expected) < 1e-10, message + ': expected ' + expected + ', got ' + actual);
}

const purchase = trade.buy(5, 100);
close(purchase.qty, 0.05, 'Buying $5 when asset price is $100 gives 0.05 units');
close(purchase.fee, 0, 'Buying has no fee');
close(purchase.cost, 5, 'Purchase spends exactly the chosen amount');

close(trade.sell(purchase.qty, 100).proceeds, 5, 'Selling at the entry price returns the full $5');
close(trade.sell(purchase.qty, 20).proceeds, 1, 'A drop from $100 to $20 returns $1, not the original balance');
close(trade.sell(purchase.qty, 392).proceeds, 19.6, 'A rise from $100 to $392 returns $19.60');
close(trade.sell(purchase.qty, 20).fee, 0, 'Selling has no fee');

assert.deepEqual(trade.buy(5, 0), { qty: 0, fee: 0, cost: 0 }, 'Zero price must not create a position');
assert.deepEqual(trade.sell(0.05, 0), { gross: 0, fee: 0, proceeds: 0 }, 'Zero price must return zero');

console.log('Trade math tests passed (9 checks).');
