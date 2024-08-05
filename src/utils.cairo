use core::traits::{Into, TryInto};
use core::fmt::{Display, Formatter, Error};
use core::to_byte_array::AppendFormattedToByteArray;

/// Converts an array of 8 u32 values into a u256 value.
///
/// # Arguments
///
/// * `input` - An array of 8 u32 values to be converted.
///
/// # Returns
///
/// A u256 value representing the concatenated input array.
pub fn hash_to_u256(input: [u32; 8]) -> u256 {
    let mut value: u256 = 0;
    for word in input.span() {
        // Shift left by 32 bits (multiply by 2^32)
        value *= 0x100000000;
        // Add the current word
        value = value + (*word).into();
    };
    value
}

/// Converts a u32 to a byte array in big endian format.
///
/// # Arguments
///
/// * `input` - A u32 value to be converted.
///
/// # Returns
///
/// A ByteArray representing the input in big endian format.
pub fn u32_to_byte_array(input: u32) -> ByteArray {
    let mut ba = Default::default();
    ba.append_word(input.into(), 4);
    ba
}

/// Converts a u32 to a byte array in little endian format.
///
/// # Arguments
///
/// * `input` - A u32 value to be converted.
///
/// # Returns
///
/// A ByteArray representing the input in little endian format.
pub fn u32_to_byte_array_little_endian(input: u32) -> ByteArray {
    let mut ba = Default::default();
    // Extract bytes using bit manipulation and masks
    let byte1 = (input % 256);
    let byte2 = ((input / 256) % 256);
    let byte3 = ((input / 65536) % 256);
    let byte4 = ((input / 16777216) % 256);

    // Append bytes in little endian order
    ba.append_byte(byte1.try_into().unwrap());
    ba.append_byte(byte2.try_into().unwrap());
    ba.append_byte(byte3.try_into().unwrap());
    ba.append_byte(byte4.try_into().unwrap());
    ba
}

/// Converts an array of 8 u32 values into a ByteArray.
///
/// # Arguments
///
/// * `input` - An array of 8 u32 values to be converted.
///
/// # Returns
///
/// A ByteArray representing the concatenated input array.
pub fn slice_to_byte_array(input: [u32; 8]) -> ByteArray {
    let mut ba = Default::default();
    for word in input.span() {
        ba.append_word((*word).into(), 4);
    };
    ba
}

/// Implements the Into trait for converting u256 to ByteArray.
pub impl U256IntoByteArray of Into<u256, ByteArray> {
    fn into(self: u256) -> ByteArray {
        let mut ba = Default::default();
        ba.append_word(self.high.into(), 16);
        ba.append_word(self.low.into(), 16);
        ba
    }
}

/// Implements the Into trait for converting u32 to ByteArray.
pub impl U32IntoByteArray of Into<u32, ByteArray> {
    fn into(self: u32) -> ByteArray {
        u32_to_byte_array_little_endian(self)
    }
}

/// Converts a ByteArray to a hexadecimal string representation.
///
/// # Arguments
///
/// * `value` - A ByteArray to be converted to hex.
///
/// # Returns
///
/// A ByteArray containing the hexadecimal string representation of the input.
pub fn byte_array_to_hex(value: ByteArray) -> ByteArray {
    let mut f: Formatter = Default::default();
    let len = value.len();
    let mut i = 0;
    write!(f, "0x").unwrap();
    while i < len {
        let b = value.at(i).unwrap();
        // Append a 0 if the byte is less than 16
        if b < 16 {
            write!(f, "0").unwrap();
        }
        b.append_formatted_to_byte_array(ref f.buffer, 16);
        i += 1;
    };
    f.buffer
}
