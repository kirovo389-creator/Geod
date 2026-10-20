(function (root) {
  'use strict';

  function nonNegative(value) {
    const number = Number(value);
    return Number.isFinite(number) && number > 0 ? number : 0;
  }

  function roundUsd(value) {
    return Math.round((value + Number.EPSILON) * 100) / 100;
  }

  function buy(spend, price) {
    const usd = roundUsd(nonNegative(spend));
    const unitPrice = nonNegative(price);
    if (usd === 0 || unitPrice === 0) return { qty: 0, fee: 0, cost: 0 };
    return { qty: usd / unitPrice, fee: 0, cost: usd };
  }

  function sell(quantity, price) {
    const qty = nonNegative(quantity);
    const unitPrice = nonNegative(price);
    const gross = qty * unitPrice;
    return { gross, fee: 0, proceeds: roundUsd(gross) };
  }

  const api = Object.freeze({ feeRate: 0, buy, sell, roundUsd });
  root.FrilanceTradeMath = api;
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
})(typeof globalThis !== 'undefined' ? globalThis : this);
