// Copyright (c) Blockus
// Author: Tirso J. Bello Ponce (tirso@blockus.gg)

#[test_only]
module koi::extension_tests {
    #[test]
    fun test_extension_creation() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);

        let (
            mut kiosk,
            kiosk_owner_cap,
            _,
            asset
        ) = test.kiosk( ctx);

        koi::extension::add(
            &mut kiosk, 
            &kiosk_owner_cap, 
            ctx,
        );

        assert!(koi::extension::is_installed(&kiosk) == true, 0);
        assert!(koi::extension::is_enabled(&kiosk) == true, 1);

        test.destroy(asset);
        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
    }

    #[test]
    fun test_extension_enabled_disabled() {
        let mut test = koi::test_utils::new();
        let ctx = &mut test.next_tx(@0x1);

        let (
            mut kiosk,
            kiosk_owner_cap,
            _,
            asset
        ) = test.kiosk( ctx);

        koi::extension::add(
            &mut kiosk, 
            &kiosk_owner_cap, 
            ctx,
        );

        assert!(koi::extension::is_enabled(&kiosk) == true, 2);

        koi::extension::disable(&mut kiosk, &kiosk_owner_cap);

        assert!(koi::extension::is_enabled(&kiosk) == false, 3);

        test.destroy(asset);
        test.destroy(kiosk);
        test.destroy(kiosk_owner_cap);
    }
}