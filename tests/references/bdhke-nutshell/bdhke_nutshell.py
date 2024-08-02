from cashu.core.base import Proof
from cashu.core.crypto.b_dhke import (
    alice_verify_dleq,
    carol_verify_dleq,
    hash_e,
    hash_to_curve,
    hash_to_curve_deprecated,
    step1_alice,
    step1_alice_deprecated,
    step2_bob,
    step2_bob_dleq,
    step3_alice,
)
from cashu.core.crypto.secp import PrivateKey, PublicKey

# Test functions


def test_hash_to_curve():
    print("\nTesting hash_to_curve function:")

    result = hash_to_curve(
        bytes.fromhex(
            "0000000000000000000000000000000000000000000000000000000000000000"
        )
    )
    print(f"Input: 0x{'0'*64}")
    print(f"Output: {result.serialize().hex()}")
    assert (
        result.serialize().hex()
        == "024cce997d3b518f739663b757deaec95bcd9473c30a14ac2fd04023a739d1a725"
    )

    result = hash_to_curve(
        bytes.fromhex(
            "0000000000000000000000000000000000000000000000000000000000000001"
        )
    )
    print(f"\nInput: 0x{'0'*63}1")
    print(f"Output: {result.serialize().hex()}")
    assert (
        result.serialize().hex()
        == "022e7158e11c9506f1aa4248bf531298daa7febd6194f003edcd9b93ade6253acf"
    )

    result = hash_to_curve(
        bytes.fromhex(
            "0000000000000000000000000000000000000000000000000000000000000002"
        )
    )
    print(f"\nInput: 0x{'0'*63}2")
    print(f"Output: {result.serialize().hex()}")
    assert (
        result.serialize().hex()
        == "026cdbe15362df59cd1dd3c9c11de8aedac2106eca69236ecd9fbe117af897be4f"
    )
