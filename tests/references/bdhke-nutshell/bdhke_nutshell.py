import pytest
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
    verify,
)
from cashu.core.crypto.secp import PrivateKey, PublicKey


def test_e2e_bdhke(capsys):
    def log(message):
        print(message)

    log("Starting end-to-end test for Blind Diffie-Hellman Key Exchange (BDHKE)")

    log("\n***********************************************************")
    log("INIT: Setting up Alice's keys")
    a = PrivateKey(
        privkey=bytes.fromhex(
            "0000000000000000000000000000000000000000000000000000000000000001"
        ),
        raw=True,
    )
    A = a.pubkey
    assert A, "Failed to generate Alice's public key"
    log(f"Alice's private key (a): {a.private_key.hex()}")
    log(f"Alice's public key (A): {A.serialize().hex()}")
    assert (
        A.serialize().hex()
        == "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"
    ), "Alice's public key does not match expected value"
    log("***********************************************************\n")

    log("\n***********************************************************")
    log("PREPARE: Preparing secret message and blinding factor")
    secret_msg = "test_message"
    r = PrivateKey(
        privkey=bytes.fromhex(
            "0000000000000000000000000000000000000000000000000000000000000001"
        ),
        raw=True,
    )
    log(f"Secret message: {secret_msg}")
    log(f"r private key: {r.private_key.hex()}")
    log(f"Blinding factor (r): {r.pubkey.serialize().hex()}")

    x_coord, y_coord = pubkey_to_xy(r.pubkey)
    log("***********************************************************\n")

    log("\n***********************************************************")
    log("STEP 1: Alice blinds the message")
    B_, _ = step1_alice(secret_msg, r)
    log(f"Blinded message (B_): {B_.serialize().hex()}")
    x_coord, y_coord = pubkey_to_xy(B_)
    log(f"S1_Blinded_message_x: {int.from_bytes(x_coord, 'big')}")
    log(f"S1_Blinded_message_y: {int.from_bytes(y_coord, 'big')}")
    log("***********************************************************\n")

    log("\n***********************************************************")
    log("STEP 2: Bob signs the blinded message")
    C_, e, s = step2_bob(B_, a)
    log(f"Blinded signature (C_): {C_.serialize().hex()}")
    log(f"DLEQ proof - e: {e.serialize()}")
    log(f"DLEQ proof - s: {s.serialize()}")
    log("***********************************************************\n")

    log("\n***********************************************************")
    log("ALICE VERIFY: Alice verifies the DLEQ proof")
    alice_verification = alice_verify_dleq(B_, C_, e, s, A)
    assert alice_verification, "Alice's DLEQ verification failed"
    log("Alice successfully verified the DLEQ proof")
    log("***********************************************************\n")

    log("\n***********************************************************")
    log("STEP 3: Alice unblinds the signature")
    C = step3_alice(C_, r, A)
    log(f"Unblinded signature (C): {C.serialize().hex()}")
    log("***********************************************************\n")

    log("\n***********************************************************")
    log("CAROL VERIFY: Carol verifies the unblinded signature")
    carol_verification = carol_verify_dleq(
        secret_msg=secret_msg, C=C, r=r, e=e, s=s, A=A
    )
    assert carol_verification, "Carol's DLEQ verification failed"
    log("Carol successfully verified the unblinded signature")
    log("***********************************************************\n")

    log("End-to-end test completed successfully")

    # Print captured output
    captured = capsys.readouterr()
    print(captured.out)


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])


def is_on_curve_secp256k1(x_bytes: bytes, y_bytes: bytes) -> bool:
    """
    Check if the point (x, y) is on the secp256k1 curve.
    The secp256k1 curve equation is y^2 = x^3 + 7.
    """
    p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
    # Convert bytes to integers
    x = int.from_bytes(x_bytes, 'big')
    y = int.from_bytes(y_bytes, 'big')

    # Curve equation: y^2 % p = (x^3 + 7) % p
    left_side = (y ** 2) % p
    right_side = ((x ** 3) + 7) % p

    return left_side == right_side

def pubkey_to_xy(key: PublicKey) -> (int, int):
    """
    Convert a secp256k1 public key to its x and y coordinates.
    """
    # Serialize the public key in uncompressed format
    uncompressed_key = key.serialize(compressed=False)

    # Extract x and y coordinates
    x_coord = uncompressed_key[1:33]  # Skip the first byte (0x04 prefix)
    y_coord = uncompressed_key[33:65]

    # Check if the point is on the curve
    is_on_curve = is_on_curve_secp256k1(x_coord, y_coord)
    assert is_on_curve, "Point not on curve"

    return x_coord, y_coord