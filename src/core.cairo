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

/// Represents the Mint (Bob) in the BDHKE protocol
#[derive(Destruct)]
pub struct Mint {
    pub k: u256, // Private key of the mint
    pub K: Secp256k1Point, // Public key of the mint
}

/// Represents a User (Alice or Carol) in the BDHKE protocol
#[derive(Destruct)]
pub struct User {
    /// Secret message
    pub x: u256,
    /// Point on the curve corresponding to x
    pub Y: Secp256k1Point,
    /// Blinding factor (private key for blinding)
    pub r: u256,
}

/// Implements the Mint functionality
#[generate_trait()]
pub impl MintTraitImpl of MintTrait {
    /// Creates a new Mint with a random private key
    fn new(k: u256) -> Mint {
        let K = Secp256Trait::<Secp256k1Point>::get_generator_point().mul(k).unwrap_syscall();
        Mint { k, K }
    }

    /// Signs a blinded message
    ///
    /// # Arguments
    /// * `B_` - The blinded message point
    ///
    /// # Returns
    /// The blinded signature point C_
    fn sign(ref self: Mint, B_: Secp256k1Point) -> Secp256k1Point {
        B_.mul(self.k).unwrap_syscall()
    }

    /// Verifies a token
    ///
    /// # Arguments
    /// * `x` - The secret message
    /// * `C` - The unblinded signature point
    ///
    /// # Returns
    /// True if the token is valid, false otherwise
    fn verify(self: Mint, x: u256, C: Secp256k1Point) -> bool {
        let Y = hash_to_curve(x);
        let expected_C_coordinates = Y
            .mul(self.k)
            .unwrap_syscall()
            .get_coordinates()
            .unwrap_syscall();
        let c_coordinates = C.get_coordinates().unwrap_syscall();
        expected_C_coordinates == c_coordinates
    }
}

/// Implements the User functionality
#[generate_trait()]
pub impl UserTraitImpl of UserTrait {
    /// Creates a new User with a random secret message and blinding factor
    fn new(x: u256, r: u256) -> User {
        let Y = hash_to_curve(x);
        User { x, Y, r }
    }

    /// Blinds the message
    ///
    /// # Returns
    /// The blinded message point B_
    fn blind(ref self: User) -> Secp256k1Point {
        let G = Secp256Trait::<Secp256k1Point>::get_generator_point();
        self.Y.add(G.mul(self.r).unwrap_syscall()).unwrap_syscall()
    }

    /// Unblinds the signature
    ///
    /// # Arguments
    /// * `C_` - The blinded signature point
    /// * `K` - The mint's public key
    ///
    /// # Returns
    /// The unblinded signature point C
    fn unblind(ref self: User, C_: Secp256k1Point, K: Secp256k1Point) -> Secp256k1Point {
        C_.add(K.mul(self.r).unwrap_syscall()).unwrap_syscall()
    }

    /// Creates a token
    ///
    /// # Returns
    /// A tuple containing the secret message and the unblinded signature point
    fn create_token(ref self: User, C: Secp256k1Point) -> (u256, Secp256k1Point) {
        (self.x, C)
    }
}


/// Hashes a message to a point on the secp256k1 curve
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
