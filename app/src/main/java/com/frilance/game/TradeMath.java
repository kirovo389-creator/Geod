package com.frilance.game;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;

/**
 * Exact virtual-trading arithmetic. Values are kept as decimals; display rounding
 * happens only in the UI and never affects the wallet.
 */
public final class TradeMath {
    private static final MathContext MC = MathContext.DECIMAL128;

    private TradeMath() {}

    public static BigDecimal quantityForCash(BigDecimal cashAmount, BigDecimal unitPrice) {
        requireNonNegative(cashAmount, "cashAmount");
        requirePositive(unitPrice, "unitPrice");
        return cashAmount.divide(unitPrice, 36, RoundingMode.DOWN).stripTrailingZeros();
    }

    public static BigDecimal marketValue(BigDecimal quantity, BigDecimal unitPrice) {
        requireNonNegative(quantity, "quantity");
        requireNonNegative(unitPrice, "unitPrice");
        return quantity.multiply(unitPrice, MC);
    }

    public static BigDecimal cashAfterSale(BigDecimal cash, BigDecimal quantity, BigDecimal unitPrice) {
        requireNonNegative(cash, "cash");
        return cash.add(marketValue(quantity, unitPrice), MC);
    }

    public static BigDecimal soldCostBasis(BigDecimal totalCostBasis,
                                           BigDecimal quantitySold,
                                           BigDecimal totalQuantity) {
        requireNonNegative(totalCostBasis, "totalCostBasis");
        requireNonNegative(quantitySold, "quantitySold");
        requirePositive(totalQuantity, "totalQuantity");
        return totalCostBasis.multiply(quantitySold, MC)
                .divide(totalQuantity, 36, RoundingMode.HALF_UP);
    }

    public static BigDecimal unrealizedProfit(BigDecimal quantity,
                                              BigDecimal currentPrice,
                                              BigDecimal costBasis) {
        requireNonNegative(costBasis, "costBasis");
        return marketValue(quantity, currentPrice).subtract(costBasis, MC);
    }

    private static void requirePositive(BigDecimal value, String name) {
        if (value == null || value.signum() <= 0) {
            throw new IllegalArgumentException(name + " must be greater than zero");
        }
    }

    private static void requireNonNegative(BigDecimal value, String name) {
        if (value == null || value.signum() < 0) {
            throw new IllegalArgumentException(name + " must not be negative");
        }
    }
}
