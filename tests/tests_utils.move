// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)

#[test_only]
module koi::test_utils {
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::kiosk_test_utils::{Self as test, Asset};
    use sui::transfer_policy::{Self, TransferPolicy};

    public struct TestRunner has drop { seq: u64 }

    public fun new(): TestRunner {
        TestRunner { seq: 1 }
    }

    public fun next_tx(self: &mut TestRunner, sender: address): TxContext {
        self.seq = self.seq + 1;
        tx_context::new_from_hint(
            sender,
            self.seq,
            0,
            0,
            0
        )
    }

    public fun kiosk(_self: &TestRunner, ctx: &mut TxContext): (Kiosk, KioskOwnerCap, ID, Asset) {
        let (kiosk, cap) = kiosk::new(ctx);
        let (asset, asset_id) = test::get_asset(ctx);

        (kiosk, cap, asset_id, asset)
    }

    public fun kiosk_with_extension(_self: &TestRunner, ctx: &mut TxContext): (Kiosk, KioskOwnerCap, ID, Asset) {
        let (mut kiosk, cap) = kiosk::new(ctx);
        let (asset, asset_id) = test::get_asset(ctx);

        koi::extension::add(
            &mut kiosk, 
            &cap, 
            ctx,
        );
        (kiosk, cap, asset_id, asset)
    }

    public fun kiosk_with_extension_disabled(_self: &TestRunner, ctx: &mut TxContext): (Kiosk, KioskOwnerCap, ID, Asset) {
        let (mut kiosk, cap) = kiosk::new(ctx);
        let (asset, asset_id) = test::get_asset(ctx);

        koi::extension::add(
            &mut kiosk, 
            &cap, 
            ctx,
        );

        koi::extension::disable(&mut kiosk, &cap);

        (kiosk, cap, asset_id, asset)
    }

    public fun kiosk_place(_self: &TestRunner, ctx: &mut TxContext): (Kiosk, KioskOwnerCap, ID) {
        let (mut kiosk, cap) = kiosk::new(ctx);
        let (asset, asset_id) = test::get_asset(ctx);

        kiosk.place(&cap, asset);
        koi::extension::add(
            &mut kiosk, 
            &cap, 
            ctx,
        );
        (kiosk, cap, asset_id)
    }

    public fun policy<T>(self: &TestRunner, ctx: &mut TxContext): TransferPolicy<T> {
        let (policy, cap) = transfer_policy::new_for_testing(ctx);
        self.destroy(cap);
        policy
    }

    public fun asset(_self: &TestRunner, ctx: &mut TxContext): (Asset, ID) {
        test::get_asset(ctx)
    }

    public fun mint_sui(_self: &mut TestRunner, amount: u64, ctx: &mut TxContext): Coin<SUI> {
        coin::mint_for_testing(amount, ctx)
    }

    public fun destroy<T>(self: &TestRunner, t: T): &TestRunner {
        sui::test_utils::destroy(t);
        self
    }
}