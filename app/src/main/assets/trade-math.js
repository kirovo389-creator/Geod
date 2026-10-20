(function (root) {
  'use strict';

  function nonNegative(value) {
    const number = Number(value);
    return Number.isFinite(number) && number > 0 ? number : 0;
  }

  function buy(spend, price) {
    const usd = nonNegative(spend);
    const unitPrice = nonNegative(price);
    if (usd === 0 || unitPrice === 0) return { qty: 0, fee: 0, cost: 0 };
    return { qty: usd / unitPrice, fee: 0, cost: usd };
  }

  function sell(quantity, price) {
    const qty = nonNegative(quantity);
    const unitPrice = nonNegative(price);
    const proceeds = qty * unitPrice;
    return { gross: proceeds, fee: 0, proceeds };
  }

  const api = Object.freeze({ feeRate: 0, buy, sell });
  root.FrilanceTradeMath = api;
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
})(typeof globalThis !== 'undefined' ? globalThis : this);
