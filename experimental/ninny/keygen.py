# key gen to get PK, SK
# where SK = (s, PK, pre-k, coin), where coin is the last 256 bits
# pip install kyber-py
from kyber_py.kyber import Kyber768

# 1. Generate Keypair
pk, sk = Kyber768.keygen()

# 2. Access keys (bytes)
print(f"Public Key Length: {len(pk)} bytes")
print(f"Secret Key Length: {len(sk)} bytes")

# 3. Display hex representation
print(f"Public Key: {pk.hex()}")
print(f"Secret Key: {sk.hex()}")

# 4. display last 32 bytes of SK as coin
coin = sk[-32:]
print(f"Coin (last 32 bytes of SK): {coin.hex()}")

# 5. display pre-k (bytes 32 to 64 of SK)
pre_k = sk[32:64]
print(f"Pre-K (bytes 32 to 64 of SK): {pre_k.hex()}")