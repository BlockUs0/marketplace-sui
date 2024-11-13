// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)

module koi::fees {
    use std::debug;
    /// An object to store the fee structure to be apply on every
    /// sale inside the marketplace.
    /// This object is intended to be used inside `KoiMarketplace`
    /// declared in `koi::core`
    /// 
    /// The `base_fee_percentage` is the percentage
    /// of the transfer amount to be paid as a platform fee.
    /// 
    /// The `min_fee_amount` is the minimum amount to be paid if the percentage based fee is
    /// lower than the `min_fee_amount` setting. Useful to enforce a fixed fee even if
    /// the transfer amount is very small or 0.
    public struct KoiMarketplaceFeeStructure has store, drop {
        base_fee_percentage: u64,
        min_fee_amount: u64,
    }

    /// Creates a new FeeStructure with the provided `base_fee`
    public(package) fun new(
        base_fee_percentage: u64,
        min_fee_amount: u64,
    ): KoiMarketplaceFeeStructure {
        let fee_structure = KoiMarketplaceFeeStructure {
            base_fee_percentage,
            min_fee_amount
        };

        (fee_structure)
    }

    /// Given a price, the `fee` to apply is returned
    public(package) fun calculate_fee(
        price: u64,
        fee_structure: &KoiMarketplaceFeeStructure,
    ): (u64) {
        let base_fee_percentage = fee_structure.base_fee_percentage;
        let min_fee_amount = fee_structure.min_fee_amount;
        let mut amount = (price * base_fee_percentage) / 1_000_000_000;

        debug::print(&amount);

        // If the amount is less than the minimum, use the minimum
        if (amount < min_fee_amount) {
            amount = min_fee_amount;
        };

        (amount)
    }
}