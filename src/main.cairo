use starknet::{
    secp256k1::{Secp256k1Point},
    secp256_trait::{
        Secp256Trait, Secp256PointTrait, recover_public_key, is_signature_entry_valid, Signature,
    },
    SyscallResult, SyscallResultTrait
};

use bdhke::core::step1_alice;

fn main() {
    println!("Running Blind Diffie-Hellmann Key Exchange (BDHKE) scheme");

    let mut secret_msg = "test_message";
    let blinding_factor_x: u256 =
        0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798;
    let blinding_factor_y: u256 =
        0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8;
    let blinding_factor = Secp256Trait::<
        Secp256k1Point
    >::secp256_ec_new_syscall(blinding_factor_x, blinding_factor_y)
        .unwrap_syscall()
        .unwrap();

    let B_ = step1_alice(secret_msg, blinding_factor);
    let (B_x, B_y) = B_.get_coordinates().unwrap();
    println!("S1_Blinded_message_x: {B_x}");
    println!("S1_Blinded_message_y: {B_y}");
}
