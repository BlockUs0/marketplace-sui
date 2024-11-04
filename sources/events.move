// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)

module koi::events {
    use sui::event;

    public struct ItemListed<phantom KoiMarketplace, phantom T> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        listing_price: u64,
        seller: address,
    }

    public struct ItemDelisted<phantom KoiMarketplace, phantom T> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        seller: address,
    }

    public struct ItemPurchasedFixedPrice<phantom KoiMarketplace, phantom T> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        buyer: address,
        paid: u64,
    }

    public struct TreasuryProfitsWithdrawed has copy, drop {
        amount: u64,
        owner: address,
    }

    public(package) fun emit_item_listed_event<KoiMarketplace, T>(
        kiosk_id: ID,
        seller: address,
        listing_price: u64,
        item_id: ID,
    ) {
        event::emit(ItemListed<KoiMarketplace, T> {
            kiosk_id,
            item_id,
            listing_price,
            seller,
        });
    }

    public(package) fun emit_item_delisted_event<KoiMarketplace, T>(
        kiosk_id: ID,
        seller: address,
        item_id: ID,
    ) {
        event::emit(ItemDelisted<KoiMarketplace, T> {
            kiosk_id,
            item_id,
            seller,
        });
    }

    public(package) fun emit_item_purchased_fixed_price_event<KoiMarketplace, T>(
        kiosk_id: ID,
        item_id: ID,
        buyer: address,
        paid: u64,
    ) {
        event::emit(ItemPurchasedFixedPrice<KoiMarketplace, T> {
            kiosk_id,
            item_id,
            buyer,
            paid,
        });
    }

    public(package) fun emit_profits_withdrawed_event(
        amount: u64,
        owner: address,
    ) {
        event::emit(TreasuryProfitsWithdrawed {
            amount,
            owner,
        });
    }
}