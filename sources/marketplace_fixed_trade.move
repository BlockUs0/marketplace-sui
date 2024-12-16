// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)

/// An implementation of a fixed trade marketplace using `koi::core` module
module koi::marketplace_fixed_trade {
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::transfer_policy::{TransferRequest};
    use sui::coin::{Coin};
    use sui::sui::SUI;

    #[error]
    const EPaymentInsufficientAmount: vector<u8> =
        b"The payment provided does not cover the fee + listing price amount.";

    public struct KoiMarketplaceFixedTrade {}

    fun new_listing<T:key + store>(
        item: T, 
        listing_price: u64,
        ctx: &mut TxContext,
    ): (Kiosk, KioskOwnerCap) {
        let (mut kiosk, kiosk_owner_cap) = kiosk::new(ctx);

        koi::extension::add(
            &mut kiosk, 
            &kiosk_owner_cap, 
            ctx,
        );

        koi::core::list<KoiMarketplaceFixedTrade, T>(
            &mut kiosk, 
            &kiosk_owner_cap, 
            item, 
            listing_price,
            ctx,
        );

        (kiosk, kiosk_owner_cap)
    }

    /// List an item on the KoiMarketplace, this function creates a `Kiosk` and install the extension on it
    #[allow(lint(share_owned))]
    public entry fun list<T: key + store>(
        item: T, 
        listing_price: u64,
        ctx: &mut TxContext,
    ) {
        let item_id = object::id(&item);
        let (kiosk, kiosk_owner_cap) = new_listing<T>(item, listing_price, ctx);
    
        koi::events::emit_item_listed_event<KoiMarketplaceFixedTrade, T>(
            object::id(&kiosk),
            ctx.sender(),
            listing_price,
            item_id,
        );

        transfer::public_share_object(kiosk);
        transfer::public_transfer(kiosk_owner_cap, ctx.sender());
    }

    /// Delist an item from the KoiMarketplace, this function is not intended to detroy the `Kiosk` after the delist
    public entry fun delist<T: key + store>(
        kiosk: &mut Kiosk,
        kiosk_owner_cap: &KioskOwnerCap,
        item_id: ID,
        ctx: &mut TxContext,
    ) {
        koi::core::delist<KoiMarketplaceFixedTrade, T>(
            kiosk,
            kiosk_owner_cap,
            item_id, 
            ctx,
        );
        koi::events::emit_item_delisted_event<KoiMarketplaceFixedTrade, T>(
            object::id(kiosk),
            ctx.sender(),
            item_id,
        );
    }

    /// Purchase an item from the KoiMarketplace, since it's a fixed trading, the amount provided as a payment
    /// needs to match the fee + price to proceed
    /// the `item` is returned with a `transfer_request`
    /// so the caller is the reponsible to confirm the request and satisfy all the policy rules.
    public fun purchase<T: key + store>(
        kiosk: &mut Kiosk,
        item_id: ID,
        payment: Coin<SUI>,
        marketplace: &mut koi::core::KoiMarketplace,
        buyer: address,
        ctx: &mut TxContext,
    ): (T, TransferRequest<T>) {

        let (fee, listing_price, _) = koi::core::calculate_fee<KoiMarketplaceFixedTrade, T>(kiosk, marketplace, item_id);

        assert!(payment.value() == (fee + listing_price), EPaymentInsufficientAmount);

        let (item, transfer_request) = koi::core::purchase<KoiMarketplaceFixedTrade, T>(
            kiosk, 
            item_id, 
            payment,
            marketplace,
            ctx,
        );

        koi::events::emit_item_purchased_fixed_price_event<KoiMarketplaceFixedTrade, T>(
            object::id(kiosk),
            item_id,
            buyer,
            transfer_request.paid(),
        );

        (item, transfer_request)
    }

    public fun calculate_fee<T: key + store>(
        kiosk: &mut Kiosk,
        marketplace: &mut koi::core::KoiMarketplace,
        item_id: ID,
    ): (u64, u64, u64) {
        let (fee, listing_price, total_price) = koi::core::calculate_fee<KoiMarketplaceFixedTrade, T>(kiosk, marketplace, item_id);

        (fee, listing_price, total_price)
    }

    #[test_only]
    public fun list_for_test<T: key + store>(
        item: T, 
        listing_price: u64,
        ctx: &mut TxContext,
    ): (Kiosk, KioskOwnerCap) {
        let (kiosk, kiosk_owner_cap) = new_listing<T>(item, listing_price, ctx);

        (kiosk, kiosk_owner_cap)
    }
}