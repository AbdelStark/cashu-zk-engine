use core::traits::{Into, TryInto};

pub fn hash_to_u256(input: [u32; 8]) -> u256 {
    let mut value: u256 = 0;
    for word in input.span() {
        value *= 0x100000000;
        value = value + (*word).into();
    };
    value
}

pub fn u32_to_byte_array(input: u32) -> ByteArray {
    let mut ba = Default::default();
    ba.append_word(input.into(), 4);
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
        u32_to_byte_array(self)
    }
}
