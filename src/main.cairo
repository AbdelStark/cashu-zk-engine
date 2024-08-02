use starknet::{secp256k1::{Secp256k1Point}, secp256_trait::{Secp256Trait, Secp256PointTrait}};
use core::starknet::SyscallResultTrait;

use bdhke::core::step1_alice;

fn main() {
    println!("Running Blind Diffie-Hellmann Key Exchange (BDHKE) scheme");

    let mut secret_msg = "test_message";
    let blinding_factor: u256 = 0xe907831f80848d1069a5371b402410364bdf1c5f8307b0084c55f1ce2dca8215;

    let (B_, r) = step1_alice(secret_msg, blinding_factor);
}
