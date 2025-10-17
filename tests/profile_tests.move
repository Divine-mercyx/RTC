// #[test_only]
// module rtc::profile_tests {
//     use std::string;
//     use sui::test_scenario;
//     use rtc::profile;

//     // Test constants
//     const E_NOT_OWNER: u64 = 0;

//     #[test]
//     fun test_create_profile_public_function() {
//         let admin = @0x1;
//         let mut scenario = test_scenario::begin(admin);
        
//         // Test the public function directly
//         let profile = profile::create_profile(
//             string::utf8(b"Alice"),
//             string::utf8(b"avatar1"),
//             string::utf8(b"Web3 Developer"),
//             test_scenario::ctx(&mut scenario)
//         );
        
//         // Verify using public getter functions
//         assert!(*profile::get_name(&profile) == string::utf8(b"Alice"), 0);
//         assert!(*profile::get_avatar(&profile) == string::utf8(b"avatar1"), 0);
//         assert!(*profile::get_bio(&profile) == string::utf8(b"Web3 Developer"), 0);
//         assert!(profile::get_owner(&profile) == admin, 0);
        
//         test_scenario::end(scenario);
//     }

//     #[test]
//     fun test_create_profile_entry_function() {
//         let admin = @0xADMIN;
//         let mut scenario = test_scenario::begin(admin);
        
//         // Test the entry function
//         profile::create_profile_entry(
//             string::utf8(b"Bob"),
//             string::utf8(b"avatar2"),
//             string::utf8(b"Blockchain Enthusiast"),
//             test_scenario::ctx(&mut scenario)
//         );
        
//         test_scenario::end(scenario);
//     }

//     #[test]
//     fun test_update_profile() {
//         let admin = @0xADMIN;
//         let mut scenario = test_scenario::begin(admin);
        
//         // Create profile first using public function
//         let mut profile = profile::create_profile(
//             string::utf8(b"Original"),
//             string::utf8(b"original_avatar"),
//             string::utf8(b"original_bio"),
//             test_scenario::ctx(&mut scenario)
//         );
        
//         // Test update function
//         test_scenario::next_tx(&mut scenario, admin);
//         profile::update_profile(
//             &mut profile,
//             string::utf8(b"Updated"),
//             string::utf8(b"updated_avatar"),
//             string::utf8(b"updated_bio"),
//             test_scenario::ctx(&mut scenario)
//         );
        
//         // Verify updates using public getters
//         assert!(*profile::get_name(&profile) == string::utf8(b"Updated"), 0);
//         assert!(*profile::get_avatar(&profile) == string::utf8(b"updated_avatar"), 0);
//         assert!(*profile::get_bio(&profile) == string::utf8(b"updated_bio"), 0);
        
//         test_scenario::end(scenario);
//     }

//     #[test]
//     #[expected_failure(abort_code = E_NOT_OWNER)]
//     fun test_update_profile_unauthorized() {
//         let admin = @0xADMIN;
//         let attacker = @0x2;
//         let mut scenario = test_scenario::begin(admin);
        
//         // Admin creates profile
//         let mut profile = profile::create_profile(
//             string::utf8(b"AdminProfile"),
//             string::utf8(b"avatar"),
//             string::utf8(b"bio"),
//             test_scenario::ctx(&mut scenario)
//         );
        
//         // Attacker tries to update (should fail)
//         test_scenario::next_tx(&mut scenario, attacker);
//         profile::update_profile(
//             &mut profile,
//             string::utf8(b"Hacked"),
//             string::utf8(b"hacked_avatar"),
//             string::utf8(b"hacked_bio"),
//             test_scenario::ctx(&mut scenario)
//         );
        
//         test_scenario::end(scenario);
//     }

//     #[test]
//     fun test_transfer_profile() {
//         let alice = @0x3;
//         let bob = @0x4;
//         let mut scenario = test_scenario::begin(alice);
        
//         // Alice creates profile
//         let profile = profile::create_profile(
//             string::utf8(b"AliceProfile"),
//             string::utf8(b"avatar"),
//             string::utf8(b"bio"),
//             test_scenario::ctx(&mut scenario)
//         );
        
//         // Verify original owner
//         assert!(profile::get_owner(&profile) == alice, 0);
        
//         // Alice transfers to Bob
//         test_scenario::next_tx(&mut scenario, alice);
//         profile::transfer_profile(profile, bob);
        
//         test_scenario::end(scenario);
//     }

//     #[test]
//     fun test_getter_functions() {
//         let owner = @0x5;
//         let mut scenario = test_scenario::begin(owner);
        
//         // Create profile
//         let profile = profile::create_profile(
//             string::utf8(b"TestUser"),
//             string::utf8(b"test_avatar"),
//             string::utf8(b"test_bio"),
//             test_scenario::ctx(&mut scenario)
//         );
        
//         // Test all public getter functions
//         assert!(*profile::get_name(&profile) == string::utf8(b"TestUser"), 0);
//         assert!(*profile::get_avatar(&profile) == string::utf8(b"test_avatar"), 0);
//         assert!(*profile::get_bio(&profile) == string::utf8(b"test_bio"), 0);
//         assert!(profile::get_owner(&profile) == owner, 0);
        
//         test_scenario::end(scenario);
//     }
//     #[test]
//     fun test_delete_profile() {
//         let owner = @0x8; // replaced @0xOWNER with a valid address
//         let mut scenario = test_scenario::begin(owner);
        
//         // Create profile
//         let profile = profile::create_profile(
//             string::utf8(b"ToDelete"),
//             string::utf8(b"avatar"),
//             string::utf8(b"bio"),
//             test_scenario::ctx(&mut scenario)
//         );
        
//         // Delete profile (should not panic)
//         test_scenario::next_tx(&mut scenario, owner);
//         profile::delete_profile(profile, test_scenario::ctx(&mut scenario));
        
//         test_scenario::end(scenario);
//     }

//     #[test]
//     #[expected_failure(abort_code = E_NOT_OWNER)]
//     fun test_delete_profile_unauthorized() {
//         let owner = @0x8; // replaced @0xOWNER with a valid address
//         let attacker = @0x9; // replaced @0xATTACKER with a valid address
//         let mut scenario = test_scenario::begin(owner);
        
//         // Owner creates profile
//         let profile = profile::create_profile(
//             string::utf8(b"Protected"),
//             string::utf8(b"avatar"),
//             string::utf8(b"bio"),
//             test_scenario::ctx(&mut scenario)
//         );
        
//         // Attacker tries to delete (should fail)
//         test_scenario::next_tx(&mut scenario, attacker);
//         profile::delete_profile(profile, test_scenario::ctx(&mut scenario));
        
//         test_scenario::end(scenario);
//     }

//     #[test]
//     fun test_multiple_profiles() {
//         let user1 = @0x6;
//         let user2 = @0x7;
//         let mut scenario = test_scenario::begin(user1);
        
//         // User1 creates profile
//         let profile1 = profile::create_profile(
//             string::utf8(b"User1"),
//             string::utf8(b"avatar1"),
//             string::utf8(b"bio1"),
//             test_scenario::ctx(&mut scenario)
//         );
        
//         // User2 creates profile in separate transaction
//         test_scenario::next_tx(&mut scenario, user2);
//         let profile2 = profile::create_profile(
//             string::utf8(b"User2"),
//             string::utf8(b"avatar2"),
//             string::utf8(b"bio2"),
//             test_scenario::ctx(&mut scenario)
//         );
        
//         // Verify both profiles have correct data
//         assert!(*profile::get_name(&profile1) == string::utf8(b"User1"), 0);
//         assert!(*profile::get_name(&profile2) == string::utf8(b"User2"), 0);
//         assert!(profile::get_owner(&profile1) == user1, 0);
//         assert!(profile::get_owner(&profile2) == user2, 0);
        
//         test_scenario::end(scenario);
//     }
// }