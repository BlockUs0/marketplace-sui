// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)

#[test_only]
module koi::treasury_tests {
    #[test]
    fun test_treasury_creation() {
        let test = koi::test_utils::new();
        let treasury = koi::treasury::new();

        assert!(treasury.profits() == 0, 0);

        test.destroy((treasury));
    }

    #[test]
    fun test_treasury_collect() {
        let amount = 10000;
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let mut treasury = koi::treasury::new();

        let coins = test.mint_sui(amount,ctx);

        treasury.collect(coins);

        assert!(treasury.profits() == amount, 1);

        test.destroy(treasury);
    }

    #[test]
    fun test_treasury_withdraw() {
        let amount = 10000;
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let mut treasury = koi::treasury::new();

        let coins = test.mint_sui(amount,ctx);

        treasury.collect(coins);

        let taken = treasury.withdraw_profits(ctx);

        assert!(taken.balance().value() == amount, 2);

        test.destroy(treasury);
        test.destroy(taken);
    }
}