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
        ) = test.kiosk_with_extension(ctx);

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

        assert!(!kiosk.is_listed(asset_id), 2);

        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
    }

    #[test]
    #[expected_failure(abort_code = koi::core::EExtensionNotInstalled)]
    fun test_list_item_no_extension_installed() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            mut kiosk,
            kiosk_owner_cap,
            _,
            asset
        ) = test.kiosk(ctx);

        koi::core::list<TestMarket, Asset>(
            &mut kiosk, 
            &kiosk_owner_cap,
            asset, 
            PRICE,
            ctx
        );

        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
    }

    #[test]
    #[expected_failure(abort_code = koi::core::EExtensionDisabled)]
    fun test_list_item_no_extension_enabled() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            mut kiosk,
            kiosk_owner_cap,
            _,
            asset
        ) = test.kiosk_with_extension_disabled(ctx);

        koi::core::list<TestMarket, Asset>(
            &mut kiosk, 
            &kiosk_owner_cap,
            asset, 
            PRICE,
            ctx
        );

        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
    }


    #[test]
    #[expected_failure(abort_code = koi::core::EExtensionDisabled)]
    fun test_delist_item_no_extension_enabled() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            mut kiosk,
            kiosk_owner_cap,
            asset_id,
            asset,
        ) = test.kiosk_with_extension_disabled(ctx);

        koi::core::delist<TestMarket, Asset>(
            &mut kiosk, 
            &kiosk_owner_cap,
            asset_id, 
            ctx
        );

        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
        test.destroy(asset);
    }

    #[test]
    #[expected_failure(abort_code = koi::core::EExtensionNotInstalled)]
    fun test_delist_item_no_extension_installed() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            mut kiosk,
            kiosk_owner_cap,
            asset_id,
            asset,
        ) = test.kiosk(ctx);

        koi::core::delist<TestMarket, Asset>(
            &mut kiosk, 
            &kiosk_owner_cap,
            asset_id, 
            ctx
        );

        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
        test.destroy(asset);
    }
    
    #[test]
    #[expected_failure(abort_code = koi::core::ENotListed)]
    fun test_delist_item_not_placed_in_kiosk() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            mut kiosk,
            kiosk_owner_cap,
            asset_id,
            asset,
        ) = test.kiosk_with_extension(ctx);

        koi::core::delist<TestMarket, Asset>(
            &mut kiosk, 
            &kiosk_owner_cap,
            asset_id, 
            ctx
        );

        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
        test.destroy(asset);
    }

    #[test]
    fun listing_price_check() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            mut kiosk,
            kiosk_owner_cap,
            asset_id,
            asset,
        ) = test.kiosk_with_extension(ctx);

        koi::core::list<TestMarket, Asset>(
            &mut kiosk, 
            &kiosk_owner_cap,
            asset, 
            PRICE,
            ctx
        );

        let price = koi::core::price<TestMarket, Asset>(&kiosk, asset_id);

        assert!(price == PRICE, 0);

        koi::core::delist<TestMarket, Asset>(
            &mut kiosk,
            &kiosk_owner_cap,
            asset_id,
            ctx
        );

        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
    }


    #[test]
    fun test_buy_item() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            mut kiosk,
            kiosk_owner_cap,
            asset_id,
            asset,
        ) = test.kiosk_with_extension(ctx);

        koi::core::list<TestMarket, Asset>(
            &mut kiosk, 
            &kiosk_owner_cap,
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

        let (_, _, amount) = koi::core::calculate_fee<TestMarket, Asset>(
            &kiosk, 
            &marketplace, 
            asset_id
        );
    
        let payment = test.mint_sui(amount, ctx);

        let policy = test.policy<Asset>(ctx);

        let (asset, request) = koi::core::purchase<TestMarket, Asset>(
            &mut kiosk,
            asset_id,
            payment,
            &mut marketplace,
            ctx,
        );

        assert!(!kiosk.is_listed(asset_id), 0);

        sui::transfer_policy::confirm_request(&policy, request);

        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
        test.destroy(asset);
        test.destroy(koi_marketplace_owner_cap);
        test.destroy(marketplace);
        test.destroy(policy);
    }

    #[test]
    #[expected_failure(abort_code = sui::kiosk::EIncorrectAmount)]
    fun test_buy_item_incorrect_payment() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            mut kiosk,
            kiosk_owner_cap,
            asset_id,
            asset,
        ) = test.kiosk_with_extension(ctx);

        koi::core::list<TestMarket, Asset>(
            &mut kiosk, 
            &kiosk_owner_cap,
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

        let (_, _, amount) = koi::core::calculate_fee<TestMarket, Asset>(
            &kiosk, 
            &marketplace, 
            asset_id
        );
    
        let payment = test.mint_sui(amount - 1_000, ctx);

        let policy = test.policy<Asset>(ctx);

        let (asset, request) = koi::core::purchase<TestMarket, Asset>(
            &mut kiosk,
            asset_id,
            payment,
            &mut marketplace,
            ctx,
        );

        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
        test.destroy(asset);
        test.destroy(koi_marketplace_owner_cap);
        test.destroy(marketplace);
        test.destroy(policy);
        test.destroy(request);
    }

    #[test]
    #[expected_failure(abort_code = koi::core::EExtensionNotInstalled)]
    fun test_buy_item_no_extension_installed() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            mut kiosk,
            kiosk_owner_cap,
            asset_id,
            asset,
        ) = test.kiosk(ctx);

        koi::core::list<TestMarket, Asset>(
            &mut kiosk, 
            &kiosk_owner_cap,
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

        let (_, _, amount) = koi::core::calculate_fee<TestMarket, Asset>(
            &kiosk, 
            &marketplace, 
            asset_id
        );
    
        let payment = test.mint_sui(amount - 1_000, ctx);

        let policy = test.policy<Asset>(ctx);

        let (asset, request) = koi::core::purchase<TestMarket, Asset>(
            &mut kiosk,
            asset_id,
            payment,
            &mut marketplace,
            ctx,
        );

        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
        test.destroy(asset);
        test.destroy(koi_marketplace_owner_cap);
        test.destroy(marketplace);
        test.destroy(policy);
        test.destroy(request);
    }

    #[test]
    #[expected_failure(abort_code = koi::core::EExtensionDisabled)]
    fun test_buy_item_no_extension_enabled() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            mut kiosk,
            kiosk_owner_cap,
            asset_id,
            asset,
        ) = test.kiosk_with_extension_disabled(ctx);

        koi::core::list<TestMarket, Asset>(
            &mut kiosk, 
            &kiosk_owner_cap,
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

        let (_, _, amount) = koi::core::calculate_fee<TestMarket, Asset>(
            &kiosk, 
            &marketplace, 
            asset_id
        );
    
        let payment = test.mint_sui(amount - 1_000, ctx);

        let policy = test.policy<Asset>(ctx);

        let (asset, request) = koi::core::purchase<TestMarket, Asset>(
            &mut kiosk,
            asset_id,
            payment,
            &mut marketplace,
            ctx,
        );

        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
        test.destroy(asset);
        test.destroy(koi_marketplace_owner_cap);
        test.destroy(marketplace);
        test.destroy(policy);
        test.destroy(request);
    }

    #[test]
    #[expected_failure(abort_code = koi::core::ENotListed)]
    fun test_buy_item_no_item_listed() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);
        let (
            mut kiosk,
            kiosk_owner_cap,
            asset_id,
            asset_minted,
        ) = test.kiosk_with_extension(ctx);

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

        let payment = test.mint_sui(PRICE - 1_000, ctx);

        let policy = test.policy<Asset>(ctx);

        let (asset, request) = koi::core::purchase<TestMarket, Asset>(
            &mut kiosk,
            asset_id,
            payment,
            &mut marketplace,
            ctx,
        );

        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
        test.destroy(asset);
        test.destroy(koi_marketplace_owner_cap);
        test.destroy(marketplace);
        test.destroy(policy);
        test.destroy(request);
        test.destroy(asset_minted);
    }
}