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

    # Step 1: Set up Alice's keys
    log("Step 1: Setting up Alice's keys")
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

    # Step 2: Prepare the secret message and blinding factor
    log("Step 2: Preparing secret message and blinding factor")
    secret_msg = "test_message"
    r = PrivateKey(
        privkey=bytes.fromhex(
            "0000000000000000000000000000000000000000000000000000000000000001"
        ),
        raw=True,
    )
    log(f"Secret message: {secret_msg}")
    log(f"Blinding factor (r): {r.private_key.hex()}")

    # Step 3: Alice blinds the message
    log("Step 3: Alice blinds the message")
    B_, _ = step1_alice(secret_msg, r)
    log(f"Blinded message (B_): {B_.serialize().hex()}")

    # Step 4: Bob signs the blinded message
    log("Step 4: Bob signs the blinded message")
    C_, e, s = step2_bob(B_, a)
    log(f"Blinded signature (C_): {C_.serialize().hex()}")
    log(f"DLEQ proof - e: {e.serialize()}")
    log(f"DLEQ proof - s: {s.serialize()}")

    # Step 5: Alice verifies the DLEQ proof
    log("Step 5: Alice verifies the DLEQ proof")
    alice_verification = alice_verify_dleq(B_, C_, e, s, A)
    assert alice_verification, "Alice's DLEQ verification failed"
    log("Alice successfully verified the DLEQ proof")

    # Step 6: Alice unblinds the signature
    log("Step 6: Alice unblinds the signature")
    C = step3_alice(C_, r, A)
    log(f"Unblinded signature (C): {C.serialize().hex()}")

    # Step 7: Carol verifies the unblinded signature
    log("Step 7: Carol verifies the unblinded signature")
    carol_verification = carol_verify_dleq(
        secret_msg=secret_msg, C=C, r=r, e=e, s=s, A=A
    )
    assert carol_verification, "Carol's DLEQ verification failed"
    log("Carol successfully verified the unblinded signature")

    log("End-to-end test completed successfully")

    # Print captured output
    captured = capsys.readouterr()
    print(captured.out)


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
