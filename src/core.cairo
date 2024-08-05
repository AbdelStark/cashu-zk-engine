// Core lib imports
use core::traits::Into;
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::sha256::compute_sha256_byte_array;

// Starknet imports
use starknet::{secp256k1::{Secp256k1Point}, secp256_trait::{Secp256Trait, Secp256PointTrait}};

// Internal imports
use bdhke::utils::{U256IntoByteArray, U32IntoByteArray, slice_to_byte_array, hash_to_u256};

const TWO_POW_32: u128 = 0x100000000;
const TWO_POW_64: u128 = 0x10000000000000000;
const TWO_POW_96: u128 = 0x1000000000000000000000000;

// 2^16
const MAX_ATTEMPTS_HASH_TO_CURVE: u32 = 65536;

fn domain_separator() -> ByteArray {
    "Secp256k1_HashToCurve_Cashu_"
}

/// Blind a message.
/// # Arguments
/// - *secret_msg*: The message to blind.
/// - *blinding_factor*: The blinding factor to use.
/// # Returns
/// - The blinded message.
pub fn step1_alice(secret_msg: ByteArray, blinding_factor: Secp256k1Point) -> Secp256k1Point {
    let Y = hash_to_curve(secret_msg).expect('ERR_HASH_TO_CURVE');
    Y.add(blinding_factor).unwrap()
}


/// Generates a secp256k1 point from a message.
///
/// # Arguments
/// * `message` - The message to hash
///
/// # Returns
/// A point on the secp256k1 curve
pub fn hash_to_curve(message: ByteArray) -> Option<Secp256k1Point> {
    // This is a simplified implementation. In practice, you should use a more
    // robust method to ensure the resulting point is uniformly distributed.
    let msg_to_hash_input = domain_separator() + message;
    println!("msg_to_hash_input: {msg_to_hash_input}");
    let msg_to_hash = compute_sha256_byte_array(@msg_to_hash_input);
    let msg_byte_array = slice_to_byte_array(msg_to_hash);

    let mut counter = 0;
    loop {
        if counter == MAX_ATTEMPTS_HASH_TO_CURVE {
            break Option::None;
        }
        let counter_byte_array = counter.into();
        let msg_with_nonce = msg_byte_array.clone() + counter_byte_array;
        let _hash = compute_sha256_byte_array(@msg_with_nonce);
        let x_from_hash = hash_to_u256(_hash);
        match Secp256Trait::<
            Secp256k1Point
        >::secp256_ec_get_point_from_x_syscall(x_from_hash, false) {
            Result::Ok(point_option) => {
                match point_option {
                    Option::Some(point) => { break Option::Some(point); },
                    Option::None => { counter += 1; }
                }
            },
            Result::Err(_) => { counter += 1; }
        }
    }
}
