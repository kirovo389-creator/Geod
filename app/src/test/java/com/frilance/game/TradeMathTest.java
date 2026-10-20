package com.frilance.game;

import static org.junit.Assert.assertEquals;

import java.math.BigDecimal;

import org.junit.Test;

public class TradeMathTest {
    @Test
    public void fiveDollarsTracksPriceMoveAndProfit() {
        BigDecimal quantity = TradeMath.quantityForCash(new BigDecimal("5"), new BigDecimal("100"));
        assertEquals(0, new BigDecimal("0.05").compareTo(quantity));
        BigDecimal valueAt128 = TradeMath.marketValue(quantity, new BigDecimal("128"));
        assertEquals(0, new BigDecimal("6.4").compareTo(valueAt128));
        assertEquals(0, new BigDecimal("1.4").compareTo(valueAt128.subtract(new BigDecimal("5"))));
    }

    @Test
    public void sellingOneCoinAtTwentyCreditsTwentyDollars() {
        BigDecimal afterSale = TradeMath.cashAfterSale(BigDecimal.ZERO, BigDecimal.ONE,
                new BigDecimal("20"));
        assertEquals(0, new BigDecimal("20").compareTo(afterSale));
    }

    @Test
    public void fractionalPositionKeepsMoreThanCentPrecision() {
        BigDecimal quantity = new BigDecimal("0.0000000000000001");
        BigDecimal proceeds = TradeMath.marketValue(quantity, new BigDecimal("100000"));
        assertEquals(0, new BigDecimal("0.00000000001").compareTo(proceeds));
        BigDecimal afterSale = TradeMath.cashAfterSale(BigDecimal.ZERO, quantity,
                new BigDecimal("100000"));
        assertEquals(0, new BigDecimal("0.00000000001").compareTo(afterSale));
    }

    @Test
    public void soldCostBasisIsProportional() {
        BigDecimal basis = TradeMath.soldCostBasis(new BigDecimal("10"),
                new BigDecimal("0.25"), new BigDecimal("0.5"));
        assertEquals(0, new BigDecimal("5").compareTo(basis));
    }
}
