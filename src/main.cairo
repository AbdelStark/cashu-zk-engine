use bdhke::core::MintTrait;
use bdhke::core::MintTraitImpl;
use bdhke::core::UserTrait;
use bdhke::core::UserTraitImpl;
use starknet::{secp256k1::{Secp256k1Point}, secp256_trait::{Secp256Trait, Secp256PointTrait}};
use core::starknet::SyscallResultTrait;

fn main() {
    println!("Running Blind Diffie-Hellmann Key Exchange (BDHKE) scheme");

    // Create a mint (Bob)
    let mint_private_key: u256 = 0xe907831f80848d1069a5371b402410364bdf1c5f8307b0084c55f1ce2dca8215;
    let mut mint = MintTraitImpl::new(mint_private_key);

    // Create a user (Alice)
    let alice_random_secret: u256 =
        0xe907831f80848d1069a5371b402410364bdf1c5f8307b0084c55f1ce2dca8215;
    let alice_blinding_factor: u256 =
        0xe907831f80848d1069a5371b402410364bdf1c5f8307b0084c55f1ce2dca8215;

    let mut alice = UserTraitImpl::new(alice_random_secret, alice_blinding_factor);

    // Alice blinds her message
    let B_ = alice.blind();

    // Mint signs the blinded message
    let C_ = mint.sign(B_);

    // Alice unblinds the signature
    let C = alice.unblind(C_, mint.K);

    // Alice creates a token
    let (x, C) = alice.create_token(C);

    // Mint verifies the token
    let is_valid = mint.verify(x, C);

    if is_valid {
        println!("Token is valid");
    } else {
        println!("Token is invalid");
    }
}
