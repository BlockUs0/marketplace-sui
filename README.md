# Koi Marketplace Move Package Documentation :package:

Author: Tirso J. Bello Ponce (tirso@blockus.gg)

# Useful resources

### Github repository

https://github.com/BlockUs0/marketplace-sui

### Audit

[20241119-BlockUs-Final-Audit-Report.pdf](assets/20241119-BlockUs-Final-Audit-Report.pdf)

Conducted by: https://www.movebit.xyz/

# Module organization and structure

Koi Marketplace was built on top of the `Sui Kiosk` in order to make it compatible with Sui Ecosystem and enchance security, performance and good practices.

The marketplace is agnostic to any trade implementation so the main idea is that `koi_core` is just a module that offers tools to list, delist, purchase and cofigure a marketplace to impose different fees and allow different types to be listed.

`koi_core` itself depends on the `Sui Kiosk` module so it is required to have a Kiosk to operate in the marketplace.

Since the main feature of the marketplace is the `Fixed Trade` we have build a module using `koi_core` that handles all the fixed trade logic, the module is called `module_koi_markeplace_fixed_trade` and it’s the entry point for leverage our dApp. Depending our needs we can build any other trade logic on top of our `koi_core` like a Bid system or Item trading using the same principles.

We decided to manage the `Kiosk` in behalf of the user since we feel it gives a better UX to the final user and we leverage our marketplace using SUI features.

The diagram shows the relationship between the diferent modules of the project.

- **module_koi_markeplace_fixed_trade:** Fixed trade implementation for purchases using module_koi_core features. This package will create and manage the kiosk in behalf of the user.
- **module_koi_core:** Package to manage all the core implementations for the marketplace. Esentially manages the fee, treasury and offers utilities like list, delist and purchase. This module assumes that the user already has a kiosk and the extension is installed.
- **module_koi_events:** On-chain events dispatcher.
- **module_koi_tresury:** Contains all the functionalities related to the treasury like collect and withdraw.
- **module_koi_fees:** Package with a set of utilities to calculate the imposed fee on-chain during the purchase transaction. This module can also be updated on-chain so the owner can change the fee structure on demand.
- **module_koi_kiosk_extension: A**llows other modules to install and manage the Koi marketplace kiosk extension to safely operate in the Koi marketplace.

```mermaid
    classDiagram

        class module_koi_core {
            +KoiMarketplace marketplace
            +update_base_fee()
            +withdraw_profits()
            +calculate_fee() u64
            +price() u64, u64, u64
            +list()
            +delist()
            +purchase()
        }

        class module_koi_fees {
        +KoiMarketplaceFeeStructure fee_structure
        +new(base_fee_percentage: u64, min_fee_amount: u64) KoiMarketplaceFeeStructure
        +calculate_fee(price: u64) u64
        %% Getters
        +base_fee_percentage() u64
        +min_fee_amount() u64
      }

        class module_koi_treasury {
        +KoiMarketplaceTreasury treasury
        +new()KoiMarketplaceTreasury
        +collect(profit: Coin&lt;SUI&gt;) void
        +withdraw_profits() Coin&lt;SUI&gt;
        %% Getters
        +profits() u64
        }

        class module_koi_kiosk_extension {
            +KoiKioskExtension extension
            +add()
            +enable()
            +disable()
            +is_installed()
            +is_enabled()
            +storage()
            +storage_mut()
        }

        class module_koi_events {
            +emit_item_listed_event()
            +emit_item_delisted_event()
            +emit_item_purchased_fixed_price_event()
        }


        class module_koi_marketplace_fixed_trade {
            +KoiMarketplace marketplace
            +list()
            +delist()
            +purchase()
            +calculate_fee()
        }

        class module_sui_kiosk {
            +Kiosk kiosk
            +KoiKioskExtension extension
            +new()
            +list_with_purchase_cap()
            +purchase_with_cap()
        }



    module_sui_kiosk --> module_koi_kiosk_extension : uses

    module_koi_core --> module_koi_treasury: uses
    module_koi_core --> module_koi_fees: uses
    module_koi_core --> module_koi_kiosk_extension: uses
    module_koi_core --> module_sui_kiosk: uses

    module_koi_marketplace_fixed_trade --> module_koi_events: uses
    module_koi_marketplace_fixed_trade --> module_koi_kiosk_extension: uses
    module_koi_marketplace_fixed_trade --> module_koi_core: implements
    module_koi_marketplace_fixed_trade --> module_sui_kiosk: uses

```

# Koi Marketplace Data Model

The on-chain object that holds the treasury and the configuration is KoiMarketplace. The key part of the architecture, this object will identify the markplace on-chain and will be required to authorize any transaction.

KoiMarkeplace object has a `version` property for upgradeability purposes.

```mermaid
classDiagram
    class KoiMarketplace {
        +UID id
        +KoiMarketplaceTreasury treasury
        +KoiMarketplaceFeeStructure fee_structure
        +u8 version
        +update_base_fee(owner_cap: &KoiMarketplaceOwnerCap, base_fee_percentage: u64, min_fee_amount: u64) void
            +withdraw_profits(owner_cap: &KoiMarketplaceOwnerCap) void
            +calculate_fee(item_id: ID) u64, u64, u64
            %% Getters
        +base_fee_percentage() u64
        +min_fee_amount() u64
    }

    class KoiMarketplaceFeeStructure {
        +u64 base_fee_percentage
        +u64 min_fee_amount
        +new(base_fee_percentage: u64, min_fee_amount: u64) KoiMarketplaceFeeStructure
        +calculate_fee(price: u64) u64
        %% Getters
        +base_fee_percentage() u64
        +min_fee_amount() u64
    }

    class KoiMarketplaceTreasury {
        +Balance&lt;SUI&gt; profits
        +new() KoiMarketplaceTreasury
        +collect(profit: Coin&lt;SUI&gt;) void
        +withdraw_profits() Coin&lt;SUI&gt;
        %% Getters
        +profits() u64
    }

    KoiMarketplace --> KoiMarketplaceFeeStructure : uses
    KoiMarketplace --> KoiMarketplaceTreasury : uses
```

# Deployment

```mermaid
sequenceDiagram
    actor A as Admin
  box White koi_marketplace
    participant koi_core
  end
    participant sui_blockchain

    A ->> koi_core: Publish package
  koi_core ->> koi_core: Create empty KoiMarketplaceTreasury
  koi_core ->> koi_core: Create default KoiMarketplaceFeeStructure
  koi_core ->> koi_core: Create KoiMarketplace
  koi_core ->> sui_blockchain: Share object KoiMarketplace
    koi_core ->> sui_blockchain: Publish package
    koi_core ->> A: Transfer KoiMarketplaceOwnerCap


```

# List an item

```mermaid
sequenceDiagram
    actor A as User
    box White koi_marketplace
      participant koi_marketplace_fixed_trade
    end
    participant sui_kiosk
    participant koi_kiosk_extension
    participant koi_core
    participant sui_blockchain

    A ->> koi_marketplace_fixed_trade: list<T: key + store>(item: T, listing_price: u64)
    koi_marketplace_fixed_trade ->> sui_kiosk: new()
    sui_kiosk ->> koi_marketplace_fixed_trade: Kiosk
    koi_marketplace_fixed_trade ->> koi_kiosk_extension: extension::add(kiosk: Kiosk)
    koi_marketplace_fixed_trade ->> koi_core: koi::core::list<KoiMarketplaceFixedTrade, T>(item: T, listing_price: u64, kiosk: Kiosk)
    koi_core ->> sui_kiosk: place(kiosk, kiosk_owner_cap, item);
    koi_core ->> sui_kiosk: list_with_purchase_cap()
    sui_kiosk ->> koi_core: PurchaseCap
    koi_core ->> koi_kiosk_extension: Store the PurchaseCap on extension storage
    koi_marketplace_fixed_trade ->> sui_blockchain: Share object Kiosk
    koi_marketplace_fixed_trade ->> A: Transfer kiosk_owner_cap
```

# Delist an item

```mermaid
sequenceDiagram
    actor A as User
    box White koi_marketplace
        participant koi_marketplace_fixed_trade
    end
    participant sui_kiosk
    participant koi_kiosk_extension

    A ->> koi_marketplace_fixed_trade:  delist<T: key + store>(item_id: ID)
    koi_marketplace_fixed_trade ->> koi_kiosk_extension: Remove purchase_cap from extension storage
    koi_kiosk_extension ->> koi_marketplace_fixed_trade: purchase_cap
    koi_marketplace_fixed_trade ->> sui_kiosk: return_purchase_cap
    koi_marketplace_fixed_trade ->> sui_kiosk: take
    sui_kiosk ->> koi_marketplace_fixed_trade: item: T
    koi_marketplace_fixed_trade ->> A: Transfer back item: T
```

# Purchase an item

```mermaid
sequenceDiagram
    actor A as User
    participant sui_transfer_request
    box White koi_marketplace
        participant koi_marketplace_fixed_trade
    end
    participant koi_core
    participant koi_fee
    participant koi_treasury

    participant koi_kiosk_extension
    participant sui_kiosk


    A ->> koi_marketplace_fixed_trade: purchase<T: key + store>(item_id: ID, payment: Coin)
    koi_marketplace_fixed_trade ->> koi_core: purchase<T: key + store>(item_id: ID, payment: Coin)
    koi_core ->> koi_fee: calculate_fee()
    koi_fee ->> koi_core: fee
    koi_core ->> koi_treasury: Collect fee
    koi_kiosk_extension ->> koi_core: Unwrap the KioskPurchaseCap
    koi_core ->> sui_kiosk: purchase_with_cap(KioskPurchaseCap)
    sui_kiosk ->> koi_marketplace_fixed_trade: item: T, transfer_request: TransferRequest
    koi_marketplace_fixed_trade ->> A: transfer_request: TransferRequest
    A ->> sui_transfer_request: Approve transfer_request: TransferRequest
    sui_transfer_request ->> A: Transfer item: T

```

# Testing and coverage

**# of unit tests:** 40 unit test ✅

**% of coverage:** 98.78 % ✅

![coverage.png](assets/coverage.png)

![test_passing.png](assets/test_passing.png)
