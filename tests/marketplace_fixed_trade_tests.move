// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)

#[test_only]
module koi::marketplace_fixed_trade_tests {
    use sui::kiosk_test_utils::{Asset};
    use sui::event;
    use sui::test_utils::assert_eq;

    const PRICE: u64 = 100_000;

    #[test]
    fun test_list() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            asset,
            _,
        ) = test.asset(ctx);

        koi::marketplace_fixed_trade::list<Asset>(
            asset,
            PRICE,
            ctx
        );

        assert_eq(event::num_events(), 1);

    }

    #[test]
    fun test_delist() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            asset,
            asset_id,
        ) = test.asset(ctx);

        let (mut kiosk, kiosk_cap) = koi::marketplace_fixed_trade::list_for_test<Asset>(
            asset,
            PRICE,
            ctx
        );

        koi::marketplace_fixed_trade::delist<Asset>(
            &mut kiosk,
            &kiosk_cap,
            asset_id,
            ctx
        );

        assert!(!kiosk.is_listed(asset_id), 0);

        assert_eq(event::num_events(), 1);

        test.destroy(kiosk);
        test.destroy(kiosk_cap);
    }

    #[test]
    fun test_purchase() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            asset,
            asset_id,
        ) = test.asset(ctx);

        let (mut kiosk, kiosk_cap) = koi::marketplace_fixed_trade::list_for_test<Asset>(
            asset,
            PRICE,
            ctx
        );

        let treasury = koi::treasury::new();

        // `base_fee_percentage` = 2.5% = 0.025 * 10^9 = 25_000_000
        // `min_fee_amount` = 0.2 SUI = 0.2 * 10^9 = 200_000_000
        let fee_structure = koi::fees::new(
            25_000_000,
            200_000_000,
        );

        let (
            mut marketplace,
            koi_marketplace_owner_cap
        ) = koi::core::create_koi_marketplace(
            treasury,
            fee_structure,
            ctx
        );

        let (_, _, amount) = koi::core::calculate_fee<koi::marketplace_fixed_trade::KoiMarketplaceFixedTrade, Asset>(
            &kiosk, 
            &marketplace, 
            asset_id
        );
    
        let payment = test.mint_sui(amount, ctx);

        let policy = test.policy<Asset>(ctx);

        let (asset, request) = koi::marketplace_fixed_trade::purchase<Asset>(
            &mut kiosk, 
            asset_id, 
            payment, 
            &mut marketplace, 
            @0x0, 
            ctx,
        );

        assert!(!kiosk.is_listed(asset_id), 1);

        sui::transfer_policy::confirm_request(&policy, request);

        assert_eq(event::num_events(), 1);

        test.destroy(kiosk);
        test.destroy(koi_marketplace_owner_cap);
        test.destroy(kiosk_cap);
        test.destroy(asset);
        test.destroy(marketplace);
        test.destroy(policy);

    }

    #[test]
    #[expected_failure(abort_code = koi::marketplace_fixed_trade::EPaymentInsufficientAmount)]
    fun test_purchase_wrong_amount_error() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            asset,
            asset_id,
        ) = test.asset(ctx);

        let (mut kiosk, kiosk_cap) = koi::marketplace_fixed_trade::list_for_test<Asset>(
            asset,
            PRICE,
            ctx
        );

        let treasury = koi::treasury::new();

        // `base_fee_percentage` = 2.5% = 0.025 * 10^9 = 25_000_000
        // `min_fee_amount` = 0.2 SUI = 0.2 * 10^9 = 200_000_000
        let fee_structure = koi::fees::new(
            25_000_000,
            200_000_000,
        );

        let (
            mut marketplace,
            koi_marketplace_owner_cap
        ) = koi::core::create_koi_marketplace(
            treasury,
            fee_structure,
            ctx
        );
    
        let payment = test.mint_sui(1, ctx);

        let policy = test.policy<Asset>(ctx);

        let (asset, request) = koi::marketplace_fixed_trade::purchase<Asset>(
            &mut kiosk, 
            asset_id, 
            payment, 
            &mut marketplace, 
            @0x0, 
            ctx,
        );

        test.destroy(kiosk);
        test.destroy(koi_marketplace_owner_cap);
        test.destroy(kiosk_cap);
        test.destroy(asset);
        test.destroy(marketplace);
        test.destroy(policy);
        test.destroy(request);

    }
}