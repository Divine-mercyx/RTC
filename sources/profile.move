#[allow(lint(custom_state_change))]
module rtc::profile;

use std::string;
use sui::event;


public struct ProfileCreated has copy, drop {
    object_id: ID,
    owner: address,
    name: string::String,
}

public struct Profile has key, store {
    id: UID,
    name: string::String,
    owner: address,
    avatar: string::String,
    bio: string::String,
}

public fun create_profile(
    name: string::String,
    avatar: string::String,
    bio: string::String,
    ctx: &mut TxContext
): Profile {
    let sender = tx_context::sender(ctx);
    let profile = Profile {
        id: object::new(ctx),
        name,
        owner: sender,
        avatar,
        bio,
    };

    event::emit(ProfileCreated {
        object_id: object::id(&profile),
        owner: sender,
        name,
    });
    
    profile
}

entry fun create_profile_entry(
    name: string::String,
    avatar: string::String,
    bio: string::String,
    ctx: &mut TxContext
) {
    let sender = tx_context::sender(ctx);
    let profile = create_profile(name, avatar, bio, ctx);
    transfer::transfer(profile, sender);
}

entry fun update_profile(
    profile: &mut Profile,
    new_name: string::String,
    new_avatar: string::String,
    new_bio: string::String,
    ctx: &TxContext
) {
    let sender = tx_context::sender(ctx);
    assert!(sender == profile.owner, 0);
    profile.name = new_name;
    profile.avatar = new_avatar;
    profile.bio = new_bio;
}

entry fun transfer_profile(
    profile: Profile,
    new_owner: address
) {
    transfer::transfer(profile, new_owner);
}

entry fun delete_profile(profile: Profile, ctx: &TxContext) {
    let sender = tx_context::sender(ctx);
    assert!(sender == profile.owner, 0);
    let Profile { id, name: _, owner: _, avatar: _, bio: _ } = profile;
    object::delete(id);
}

public fun get_owner(profile: &Profile): address {
    profile.owner
}

public fun get_name(profile: &Profile): &string::String {
    &profile.name
}

public fun get_avatar(profile: &Profile): &string::String {
    &profile.avatar
}

public fun get_bio(profile: &Profile): &string::String {
    &profile.bio
}

