// Core lib imports
use core::traits::Into;
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::sha256::compute_sha256_byte_array;

// Starknet imports
use starknet::{secp256k1::{Secp256k1Point}, secp256_trait::{Secp256Trait, Secp256PointTrait}};


const TWO_POW_32: u128 = 0x100000000;
const TWO_POW_64: u128 = 0x10000000000000000;
const TWO_POW_96: u128 = 0x1000000000000000000000000;

// 2^16
const MAX_ATTEMPTS_HASH_TO_CURVE: u128 = 65536;

fn domain_separator() -> ByteArray {
    "Secp256k1_HashToCurve_Cashu_"
}

pub fn step1_alice(secret_msg: ByteArray, blinding_factor: u256) -> (Secp256k1Point, u256) {
    let msg_to_hash = domain_separator() + secret_msg;
    println!("msg_to_hash: {msg_to_hash}");
    let _hash = compute_sha256_byte_array(@msg_to_hash);

    let mut counter = 0;
    while counter < MAX_ATTEMPTS_HASH_TO_CURVE {
        counter += 1;
    };

    // let B_ = Secp256Trait::<Secp256k1Point>::secp256_ec_get_point_from_x_syscall(0, false)
    //     .unwrap_syscall()
    //     .unwrap();
    let B_ = Secp256Trait::<Secp256k1Point>::get_generator_point();
    let r = blinding_factor;
    (B_, r)
}


/// Generates a secp256k1 point from a message.
///
/// # Arguments
/// * `message` - The message to hash
///
/// # Returns
/// A point on the secp256k1 curve
pub fn hash_to_curve(message: u256) -> Secp256k1Point {
    // This is a simplified implementation. In practice, you should use a more
    // robust method to ensure the resulting point is uniformly distributed.
    let mut attempt = 0;
    loop {
        let hash_input = message * TWO_POW_32.into() + attempt.into();
        let hash_result = compute_hash(hash_input);
        match Secp256Trait::<
            Secp256k1Point
        >::secp256_ec_get_point_from_x_syscall(hash_result, false) {
            Result::Ok(point_option) => {
                match point_option {
                    Option::Some(point) => { break point; },
                    Option::None => { attempt += 1; }
                }
            },
            Result::Err(_) => { attempt += 1; }
        }
    }
}

/// Computes a hash of the input
///
/// # Arguments
/// * `input` - The input to hash
///
/// # Returns
/// The hash result as a u256
pub fn compute_hash(input: u256) -> u256 {
    let hash_result = compute_sha256_byte_array(@input.into());
    let mut value: u256 = 0;
    let hash_result_span = hash_result.span();
    let len = hash_result_span.len();
    let mut i = 0;
    while i < len {
        let word = hash_result_span[i];
        value *= 0x100000000;
        value = value + (*word).into();
        i += 1;
    };
    value
}

pub impl U256IntoByteArray of Into<u256, ByteArray> {
    fn into(self: u256) -> ByteArray {
        let mut ba = Default::default();
        ba.append_word(self.high.into(), 16);
        ba.append_word(self.low.into(), 16);
        ba
    }
}
