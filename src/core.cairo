// Core lib imports
use core::traits::Into;
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::sha256::compute_sha256_byte_array;

// Starknet imports
use starknet::{secp256k1::{Secp256k1Point}, secp256_trait::{Secp256Trait, Secp256PointTrait}};

// Internal imports
use bdhke::utils::{
    U256IntoByteArray, U32IntoByteArray, slice_to_byte_array, hash_to_u256, byte_array_to_hex,
};

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
    let msg_to_hash_input = domain_separator() + message;
    let msg_to_hash = compute_sha256_byte_array(@msg_to_hash_input);
    let msg_byte_array = slice_to_byte_array(msg_to_hash);

    let mut counter = 0;
    loop {
        // 2^16 is the maximum number of attempts we allow to find a valid point
        if counter == 65536_u32 {
            break Option::None;
        }
        let counter_byte_array = counter.into();
        let msg_with_nonce = msg_byte_array.clone() + counter_byte_array;
        let _hash = compute_sha256_byte_array(@msg_with_nonce);
        let x_from_hash = hash_to_u256(_hash);

        // Check if the point is on the curve
        match Secp256Trait::<
            Secp256k1Point
        >::secp256_ec_get_point_from_x_syscall(x_from_hash, false) {
            // If the point is on the curve, return it
            Result::Ok(point_option) => {
                match point_option {
                    Option::Some(point) => { break Option::Some(point); },
                    Option::None => { counter += 1; }
                }
            },
            // If the point is not on the curve, try again
            Result::Err(_) => { counter += 1; }
        }
    }
}

#[cfg(test)]
mod tests {
    // Core lib imports
    use core::traits::Into;
    use core::option::OptionTrait;
    use core::starknet::SyscallResultTrait;
    use core::sha256::compute_sha256_byte_array;

    // Starknet imports
    use starknet::{secp256k1::{Secp256k1Point}, secp256_trait::{Secp256Trait, Secp256PointTrait}};

    // Internal imports
    use super::step1_alice;

    #[test]
    fn test_step1_alice() {
        let mut secret_msg = "cashu_is_awesome";
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
        let (B_x, B_y) = B_.get_coordinates().unwrap_syscall();
        assert_eq!(
            B_x, 7251890153986281463605170076970606306709929329294412392501289486404935708927
        );
        assert_eq!(
            B_y, 62522301855385909426306784582581203106222070169030966725919390414709383605932
        );
    }
}
