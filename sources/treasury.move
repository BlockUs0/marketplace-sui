// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)

module koi::treasury {
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};

    /// An object to collect profits inside marketplace
    /// This object is intended to be composed inside
    /// `KoiMarketplace` declared in `koi::core` module
    public struct KoiMarketplaceTreasury has store {
        profits: Balance<SUI>,
    }

    /// Creates a new `KoiMarketplaceTreasury` with balance in zero
    public(package) fun new(): KoiMarketplaceTreasury {
        let treasury = KoiMarketplaceTreasury {
            profits: balance::zero(),
        };

        (treasury)
    }

    /// Collect a `profit` into the `treasury` balance
    public(package) fun collect(treasury: &mut KoiMarketplaceTreasury, profit: Coin<SUI>) {
        coin::put(&mut treasury.profits, profit);
    }

    /// Withdraw all profits from the `treasury`
    /// Since it's a friend function, the authorization cap is intended to be 
    /// placed on the implementation function inside `koi::core` module
    public(package) fun withdraw_profits(
        treasury: &mut KoiMarketplaceTreasury,
        ctx: &mut TxContext,
    ): Coin<SUI> {
        let amount = treasury.profits.value();
        let profits = coin::take(&mut treasury.profits, amount, ctx);

        koi::events::emit_profits_withdrawed_event(
            amount,
            ctx.sender(),
        );

        (profits)
    }
}