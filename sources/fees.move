// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)

module koi::fees {

    /// An object to store the fee structure to be apply on every
    /// sale inside the marketplace.
    /// This object is intended to be used inside `KoiMarketplace`
    /// declared in `koi::core`
    public struct KoiMarketplaceFeeStructure has store, drop {
        base_fee: u64,
    }

    /// Creates a new FeeStructure with the provided `base_fee`
    public(package) fun new(base_fee: u64): KoiMarketplaceFeeStructure {
        let fee_structure = KoiMarketplaceFeeStructure {
            base_fee
        };

        (fee_structure)
    }

    /// Given a price, the `fee` to apply is returned
    public(package) fun calculate_fee(
        price: u64,
        fee_structure: &KoiMarketplaceFeeStructure,
    ): (u64) {
        let base_fee = fee_structure.base_fee;
        let fee = (base_fee * price) / 100_000_000_000;

        (fee)
    }
}