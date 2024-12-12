// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)

/// The core module groups all the common functionalities for the marketplace
/// and let build on top of this functionalities different ways for trading like
/// fixed trade, bid, or some custom trading methodology.
module koi::core {
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap, PurchaseCap};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer_policy::{TransferRequest};

    #[error]
    const EKoiMarketplaceVersionMismatch: vector<u8> = 
        b"The provided KoiMarketplace version mismatch with the deployed version.";

    const VERSION: u8 = 1;

    #[error]
    const EExtensionNotInstalled: vector<u8> =
        b"Koi Kiosk Extension is not installed.";

    #[error]
    const EExtensionDisabled: vector<u8> =
        b"Koi Kiosk Extension is disabled.";

    #[error]
    const ENotListed: vector<u8> =
        b"Item is not listed for sale on this kiosk.";


    /// An object to wrap the `PurchaseCap` from `Kiosk` module to perform exclusive trading inside the marketplace.
    public struct KoiPurchaseCap<phantom MarketType, phantom T: key + store> has store {
        purchase_cap: PurchaseCap<T>
    }

    /// An object to represent a listing inside the marketplace.
    public struct KoiListing<phantom MarketType, phantom T: key + store> has store {
        koi_purchase_cap: KoiPurchaseCap<MarketType, T>,
        listing_price: u64,
    }

    /// A capability to allow the owner to perform certain actions
    /// like modify the fee structure or withdraw profits.
    public struct KoiMarketplaceOwnerCap has key, store {
        id: UID,
    }

    /// A shared object to represent the marketplace rules.
    public struct KoiMarketplace has key, store {
        id: UID,
        treasury: koi::treasury::KoiMarketplaceTreasury,
        fee_structure: koi::fees::KoiMarketplaceFeeStructure,
        version: u8,
    }

    /// Creates the KoiMarketplace with a `base_fee`, and KoiMarketplaceOwnerCap
    fun init(
        ctx: &mut TxContext
    ) {
        let treasury = koi::treasury::new();

        // `base_fee_percentage` = 2.5% = 0.025 * 10^9 = 25_000_000
        // `min_fee_amount` = 0.2 SUI = 0.2 * 10^9 = 200_000_000
        let fee_structure = koi::fees::new(
            25_000_000,
            200_000_000,
        );

        let (marketplace, cap) = create_koi_marketplace(
            treasury,
            fee_structure,
            ctx
        );
    
        transfer::public_share_object(marketplace);
        transfer::public_transfer(cap, ctx.sender());
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init( ctx)
    }


    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_update_version(
        marketplace: &mut KoiMarketplace,
        version: u8
    ) {
        marketplace.version = version;
    }

    /// - PUBLIC METHODS -

    /// Function to enable the owner of the marketplace to update the `base_fee` of the `fee_structure`
    public entry fun update_base_fee(
        _: &KoiMarketplaceOwnerCap,
        marketplace: &mut KoiMarketplace,
        base_fee_percentage: u64,
        min_fee_amount: u64,
    ) {
        assert!(marketplace.version == VERSION, EKoiMarketplaceVersionMismatch);
        let fee_structure = koi::fees::new(base_fee_percentage, min_fee_amount);
        marketplace.fee_structure = fee_structure;
    }

    /// Function to enable the owner of the marketplace to withdraw the `profits`
    public entry fun withdraw_profits(
        _: &KoiMarketplaceOwnerCap,
        marketplace: &mut KoiMarketplace,
        ctx: &mut TxContext,
    ) {
        assert!(marketplace.version == VERSION, EKoiMarketplaceVersionMismatch);
        let profits = koi::treasury::withdraw_profits(
            &mut marketplace.treasury,
            ctx,
        );
        transfer::public_transfer(profits, ctx.sender());
    }

    /// Given a listing, calculates the fee to apply.
    /// Aborts with `ENotListed` if the listing doesn't exists.
    /// Can be dry runed to know the fee for the payment
    public fun calculate_fee<MarketType, T: key + store>(
        kiosk: &Kiosk,
        marketplace: &KoiMarketplace,
        item_id: ID,
    ): (u64, u64, u64) {
        assert!(marketplace.version == VERSION, EKoiMarketplaceVersionMismatch);
        assert!(kiosk.is_listed(item_id), ENotListed);
        
        let listing_price = listing_price<MarketType, T>(kiosk, item_id);

        let fee = koi::fees::calculate_fee(
            listing_price,
            &marketplace.fee_structure,
        );

        let total_price = fee + listing_price;

        (fee, listing_price, total_price)
    }

    /// Given a listing, get the listing price without the fee.
    /// Aborts with `ENotListed` if the listing doesn't exists.
    public fun price<MarketType, T: key + store>(kiosk: &Kiosk, item_id: ID): u64 {
        let KoiListing<MarketType, T> {
            koi_purchase_cap,
            listing_price: _,
        } = koi::extension::storage(kiosk).borrow<ID, KoiListing<MarketType, T>>(item_id);

        let price = koi_purchase_cap.purchase_cap.purchase_cap_min_price();

        (price)
    }

    /// - PRIVATE METHODS -
    
    /// Easy accesor for the `listing_price` from an active listing.
    /// Aborts with `ENotListed` if the listing doesn't exists.
    fun listing_price<MarketType, T: key + store>(
        kiosk: &Kiosk,
        item_id: ID,
    ): u64 {
        assert!(kiosk.is_listed(item_id), ENotListed);
        let listing = koi::extension::storage(kiosk).borrow<ID, KoiListing<MarketType, T>>(item_id);

        (listing.listing_price)
    }

    #[test_only]
    public fun test_listing_price<MarketType, T: key + store>(
        kiosk: &Kiosk,
        item_id: ID,
    ): u64 {
        (listing_price<MarketType, T>(kiosk, item_id))
    }

    /// - FRIEND METHODS -
    
    /// List an item on the KoiMarketplace
    /// Once listed, the `PurchaseCap` is stored on the `Kiosk` extension
    /// This functionality required to have the `Kiosk` extension installed and enabled.
    public(package) fun list<MarketType, T: key + store>(
        kiosk: &mut Kiosk,
        kiosk_owner_cap: &KioskOwnerCap,
        item: T,
        listing_price: u64,
        ctx: &mut TxContext,
    ) {
        assert!(koi::extension::is_installed(kiosk), EExtensionNotInstalled);
        assert!(koi::extension::is_enabled(kiosk), EExtensionDisabled);

        let item_id = object::id(&item);

        sui::kiosk::place(kiosk, kiosk_owner_cap, item);

        let purchase_cap = kiosk::list_with_purchase_cap<T>(
            kiosk,
            kiosk_owner_cap,
            item_id,
            listing_price,
            ctx
        );

        let koi_purchase_cap = KoiPurchaseCap<MarketType, T> { purchase_cap };

        let koi_listing = KoiListing<MarketType, T> {
            koi_purchase_cap,
            listing_price,
        };

        koi::extension::storage_mut(kiosk).add(item_id, koi_listing);
    }

    /// Delist an item from the KoiMarketplace
    /// Once delisted, the `PurchaseCap` is returned to the `Kiosk`
    /// The item is transfered back to the owner.
    /// This functionality required to have the `Kiosk` extension installed and enabled.
    public(package) fun delist<MarketType, T: key + store>(
        kiosk: &mut Kiosk,
        kiosk_owner_cap: &KioskOwnerCap,
        item_id: ID,
        ctx: & TxContext,
    ) {
        assert!(koi::extension::is_installed(kiosk), EExtensionNotInstalled);
        assert!(koi::extension::is_enabled(kiosk), EExtensionDisabled);
        assert!(kiosk.is_listed(item_id), ENotListed);

        let KoiListing<MarketType, T> {
            koi_purchase_cap,
            listing_price: _,
        } = koi::extension::storage_mut(kiosk).remove<ID, KoiListing<MarketType, T>>(item_id);

        let KoiPurchaseCap<MarketType,T> { purchase_cap } = koi_purchase_cap;

        kiosk.return_purchase_cap(purchase_cap);
        let object = kiosk.take<T>(kiosk_owner_cap, item_id);

        transfer::public_transfer(object, ctx.sender());
    }

    /// Purchase an item from the KoiMarketplace
    /// From the given payment, it will take the profit and 
    /// proceed to unpack the `PurchaseCap` to perform the trade
    /// returning to item and the `TransferRequest` back to the caller
    /// so they can approve and resolve all the `TransferPolicy` rules.
    public(package) fun purchase<MarketType, T: key + store>(
        kiosk: &mut Kiosk,
        item_id: ID,
        mut payment: Coin<SUI>,
        marketplace: &mut KoiMarketplace,
        ctx: &mut TxContext,
    ): (T, TransferRequest<T>) {
        assert!(koi::extension::is_installed(kiosk), EExtensionNotInstalled);
        assert!(koi::extension::is_enabled(kiosk), EExtensionDisabled);
        assert!(kiosk.is_listed(item_id), ENotListed);
        assert!(marketplace.version == VERSION, EKoiMarketplaceVersionMismatch);

        let (fee, _, _) = calculate_fee<MarketType, T>(kiosk, marketplace, item_id);
        let fee_payment = coin::split(&mut payment, fee, ctx);
        koi::treasury::collect(&mut marketplace.treasury, fee_payment);

        let KoiListing<MarketType, T> {
            koi_purchase_cap,
            listing_price: _,
        } = koi::extension::storage_mut(kiosk).remove<ID, KoiListing<MarketType, T>>(item_id);

        let KoiPurchaseCap { purchase_cap } = koi_purchase_cap;

        let (item, req) = kiosk.purchase_with_cap(purchase_cap, payment);
    
        (item, req)
    }

    public(package) fun create_koi_marketplace(
        treasury: koi::treasury::KoiMarketplaceTreasury,
        fee_structure: koi::fees::KoiMarketplaceFeeStructure ,
        ctx: &mut TxContext): (KoiMarketplace, KoiMarketplaceOwnerCap) {
        let cap = KoiMarketplaceOwnerCap {
            id: object::new(ctx),
        };

        let marketplace = KoiMarketplace {
            id: object::new(ctx),
            treasury,
            fee_structure,
            version: VERSION,
        };

        (marketplace, cap)
    }

    public(package) fun base_fee_percentage(
        marketplace: &KoiMarketplace,
    ): u64 {
        let fee = marketplace.fee_structure.base_fee_percentage();

        (fee)
    }

    public(package) fun min_fee_amount(
        marketplace: &KoiMarketplace,
    ): u64 {
        let fee = marketplace.fee_structure.min_fee_amount();

        (fee)
    }
}
