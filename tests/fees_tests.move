// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)

#[test_only]
module koi::fees_tests {
    #[test]
    fun test_min_fee_value() {
        // base_fee_percentage = 2.5% = 0.025 * 10^9 = 25_000_000;
        let base_fee_percentage = 25_000_000;

        // min_fee_amount = 0.2 SUI * 10^9 = 200_000_000
        let min_fee_amount = 200_000_000;

        // price = 0.1 SUI
        let price = 100_000_000;

        let expected_fee = min_fee_amount;

        let config = koi::fees::new(base_fee_percentage, min_fee_amount);
        let fee = koi::fees::calculate_fee(price, &config);

        // Expect `fee` to be the `min_fee_amount` since 0.1 SUI * 2.5% < `min_fee_amount`
        assert!(fee == expected_fee, 0);
    }

    #[test]
    fun test_base_fee_percentage() {
        // base_fee_percentage = 2.5% = 0.025 * 10^9 = 25_000_000;
        let base_fee_percentage = 25_000_000;
        
        // min_fee_amount = 0.2 SUI * 10^9 = 200_000_000
        let min_fee_amount = 200_000_000;

        // price = 10 SUI
        let price = 10_000_000_000;

        // expected_fee = 10 SUI * 2.5% = 0.25 SUI * 10^9 = 250_000_000
        let expected_fee = 250_000_000;

        let config = koi::fees::new(base_fee_percentage, min_fee_amount);
        let fee = koi::fees::calculate_fee(price, &config);

        // Expect `fee` to be the `(price * base_fee_percentage) / 10^9` since 10 SUI * 2.5% > `min_fee_amount`
        assert!(fee == expected_fee, 0);
    }

    #[test]
    fun test_fee_percentage_for_difficult_price() {
        // base_fee_percentage = 2.5% = 0.025 * 10^9 = 25_000_000;
        let base_fee_percentage = 25_000_000;
        
        // min_fee_amount = 0.2 SUI * 10^9 = 200_000_000
        let min_fee_amount = 200_000_000;

        // price = 15.4 SUI = 15.4 * 10^9 = 15_400_000_000
        let price = 15_400_000_000;

        // expected_fee = 15.4 SUI * 2.5% = 0.385 SUI * 10^9 = 385_000_000
        let expected_fee = 385_000_000;

        let config = koi::fees::new(base_fee_percentage, min_fee_amount);
        let fee = koi::fees::calculate_fee(price, &config);

        // Expect `fee` to be the `(price * base_fee_percentage) / 10^9` since `fee` > `min_fee_amount`
        assert!(fee == expected_fee, 0);
    }

}