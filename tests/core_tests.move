// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)

#[test_only]
module koi::core_tests {
    use sui::kiosk_test_utils::{Asset};

    const PRICE: u64 = 100_000;

    public struct TestMarket has drop {}

    #[test]
    fun test_list_delist_item() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            mut kiosk,
            kiosk_owner_cap,
            asset_id,
            asset
        ) = test.kiosk(ctx);

        koi::core::list<TestMarket, Asset>(
            &mut kiosk, 
            &kiosk_owner_cap,
            asset, 
            PRICE,
            ctx
        );

        assert!(kiosk.is_listed(asset_id), 0);
        assert!(koi::core::price<TestMarket, Asset>(&kiosk, asset_id) == PRICE, 1);

        koi::core::delist<TestMarket, Asset>(
            &mut kiosk,
            &kiosk_owner_cap,
            asset_id,
            ctx
        );

        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
    }
}