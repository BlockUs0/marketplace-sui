// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)

#[test_only]
module koi::events_tests {
    use sui::kiosk_test_utils::{Asset};
    use sui::event;
    use sui::test_utils::assert_eq;

    public struct TestMarket has drop {}

    #[test]
    fun test_emit_item_listed_event() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);

        let seller: address = ctx.fresh_object_address();

        let (
            kiosk,
            kiosk_owner_cap,
            assetID,
            asset
        ) = test.kiosk( ctx);

        koi::events::emit_item_listed_event<TestMarket, Asset>(
            assetID,
            seller,
            10000,
            assetID,
        );

        assert_eq(event::num_events(), 1);

        test.destroy(asset);
        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
    }

    #[test]
    fun test_emit_item_delisted_event() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);

        let seller: address = ctx.fresh_object_address();

        let (
            kiosk,
            kiosk_owner_cap,
            assetID,
            asset
        ) = test.kiosk( ctx);

        koi::events::emit_item_delisted_event<TestMarket, Asset>(
            assetID,
            seller,
            assetID,
        );

        assert_eq(event::num_events(), 1);

        test.destroy(asset);
        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
    }

    #[test]
    fun test_emit_item_purchased_fixed_price_event() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);

        let seller: address = ctx.fresh_object_address();

        let (
            kiosk,
            kiosk_owner_cap,
            assetID,
            asset
        ) = test.kiosk( ctx);

        koi::events::emit_item_purchased_fixed_price_event<TestMarket, Asset>(
            assetID,
            assetID,
            seller,
            1000,
        );

        assert_eq(event::num_events(), 1);

        test.destroy(asset);
        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
    }

    #[test]
    fun test_emit_profits_withdrawed_event() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);

        let seller: address = ctx.fresh_object_address();

        let (
            kiosk,
            kiosk_owner_cap,
            _,
            asset
        ) = test.kiosk( ctx);

        koi::events::emit_profits_withdrawed_event(
            1000,
            seller,
        );

        assert_eq(event::num_events(), 1);

        test.destroy(asset);
        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
    }
}