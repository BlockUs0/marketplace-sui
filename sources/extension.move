// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)


/// Kiosk extension to operate with the KoiMarketplace
/// To enforce fees and exclusive trading, the extension will keep 
/// a `PurchaseCap` for the listing to be released upon purchase and pay fees
module koi::extension {
    use sui::kiosk::{Kiosk, KioskOwnerCap};
    use sui::kiosk_extension::{Self};
    use sui::bag::Bag;

    /// A witness for identify the extension
    public struct KoiKioskExtension has drop {}

    /// This extension will need a `list` permission only
    const PERMISSIONS: u128 = 1;

    /// Adds the extension to the provided `Kiosk`
    public fun add(kiosk: &mut Kiosk, cap: &KioskOwnerCap, ctx: &mut TxContext) {
        kiosk_extension::add(KoiKioskExtension {}, kiosk, cap, PERMISSIONS, ctx)
    }

    /// Enables the extension on the provided `Kiosk`
    public fun enable(kiosk: &mut Kiosk, cap: &KioskOwnerCap) {
        kiosk_extension::enable<KoiKioskExtension>(kiosk,  cap)
    }

    /// Disable the extension on the provided `Kiosk`
    public fun disable(kiosk: &mut Kiosk, cap: &KioskOwnerCap) {
        kiosk_extension::disable<KoiKioskExtension>(kiosk,  cap)
    }

    /// Utility function to verify if the extension is installed on the provided `Kiosk`
    public fun is_installed(kiosk: &Kiosk): bool {
        kiosk_extension::is_installed<KoiKioskExtension>(kiosk)
    }

    /// Utility function to verify if the extension is enabled on the provided `Kiosk`
    public fun is_enabled(kiosk: &Kiosk): bool {
        kiosk_extension::is_enabled<KoiKioskExtension>(kiosk)
    }

    /// Refence to the extension `storage`
    public(package) fun storage(kiosk: &Kiosk): &Bag {
        kiosk_extension::storage(KoiKioskExtension {}, kiosk)
    }

    /// Mutable reference to the extension `storage`
    public(package) fun storage_mut(kiosk: &mut Kiosk): &mut Bag {
        kiosk_extension::storage_mut(KoiKioskExtension {}, kiosk)
    }
}