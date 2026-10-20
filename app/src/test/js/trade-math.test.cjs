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

close(trade.sell(purchase.qty, 100).proceeds, 5, 'Selling at the entry price returns the full $5.00');
close(trade.sell(purchase.qty, 20).proceeds, 1, 'A drop from $100 to $20 returns $1.00');
close(trade.sell(purchase.qty, 392).proceeds, 19.6, 'A rise from $100 to $392 returns $19.60');
close(trade.sell(purchase.qty, 20).fee, 0, 'Selling has no fee');
close(trade.sell(0.0123456789, 1).proceeds, 0.01, 'Sale proceeds are rounded to cents');
close(trade.sell(0.004, 1).proceeds, 0, 'A sub-cent sale rounds to $0.00');
close(trade.roundUsd(4.999999999999), 5, 'Floating-point noise does not lose a cent');
assert.deepEqual(trade.buy(5, 0), { qty: 0, fee: 0, cost: 0 }, 'Zero price must not create a position');
assert.deepEqual(trade.sell(0.05, 0), { gross: 0, fee: 0, proceeds: 0 }, 'Zero price must return zero');

const lossSale = trade.settleSale(0, 1, 20);
close(lossSale.proceeds, 20, 'Selling one coin at $20 returns $20, not the entry price');
close(lossSale.cashAfter, 20, 'A losing sale credits $20 to a zero-cash wallet');
const profitSale = trade.settleSale(0, 1, 150);
close(profitSale.proceeds, 150, 'Selling one coin at $150 returns $150');
close(profitSale.cashAfter, 150, 'A profitable sale credits $150 to the wallet');
const fractionalSale = trade.settleSale(0, 0.05, 128);
close(fractionalSale.proceeds, 6.4, 'Selling 0.05 coin at $128 returns $6.40');
close(fractionalSale.cashAfter, 6.4, 'A fractional position sale credits $6.40 to the wallet');
const existingCashSale = trade.settleSale(10.01, 0.5, 20);
close(existingCashSale.cashAfter, 20.01, 'Sale proceeds add to remaining cash without floating-point dust');
console.log('Trade math tests passed (19 checks).');
