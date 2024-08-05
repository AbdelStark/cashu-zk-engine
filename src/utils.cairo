use core::traits::{Into, TryInto};
use core::fmt::{Display, Formatter, Error};
use core::to_byte_array::AppendFormattedToByteArray;

pub fn hash_to_u256(input: [u32; 8]) -> u256 {
    let mut value: u256 = 0;
    for word in input.span() {
        value *= 0x100000000;
        value = value + (*word).into();
    };
    value
}


/// Converts a u32 to a byte array in big endian format
/// Example: 0x12345678 -> [0x12, 0x34, 0x56, 0x78]
/// Example: 1 -> [0x00, 0x00, 0x00, 0x01]
pub fn u32_to_byte_array(input: u32) -> ByteArray {
    let mut ba = Default::default();
    ba.append_word(input.into(), 4);
    ba
}

/// Converts a u32 to a byte array in little endian format
// Example: 0x12345678 -> [0x78, 0x56, 0x34, 0x12]
// Example: 1 -> [0x01, 0x00, 0x00, 0x00]
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

pub fn slice_to_byte_array(input: [u32; 8]) -> ByteArray {
    let mut ba = Default::default();
    for word in input.span() {
        ba.append_word((*word).into(), 4);
    };
    ba
}

pub impl U256IntoByteArray of Into<u256, ByteArray> {
    fn into(self: u256) -> ByteArray {
        let mut ba = Default::default();
        ba.append_word(self.high.into(), 16);
        ba.append_word(self.low.into(), 16);
        ba
    }
}

pub impl U32IntoByteArray of Into<u32, ByteArray> {
    fn into(self: u32) -> ByteArray {
        u32_to_byte_array_little_endian(self)
    }
}

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
