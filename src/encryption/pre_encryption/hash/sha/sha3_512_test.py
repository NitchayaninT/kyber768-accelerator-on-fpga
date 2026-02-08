# python code for sha3_256
import binascii, hashlib

# 64-byte input (512 bits) as hex
# for SHA3-256(PK) || message bits
msg_hex = "ccfe46740b8c497c45165b4c584570c7d8801b74ec88127cbe5ab1ce686f9b5624a0701c421866cadb1c950d6c3e076ee0d1d1e2b8538a5105e2f2434d385723"

# verify it's valid hex + check size
msg_bytes = bytes.fromhex(msg_hex)

print("bytes:", len(msg_bytes)) # should be 64
print("hex chars:", len(msg_hex)) # should be 128

# the continuous hex string (no spaces)
print(msg_hex)

msg = binascii.unhexlify(msg_hex)

sha3_512 = hashlib.sha3_512()
sha3_512.update(msg)

print("SHA3-512 output:", sha3_512.hexdigest())

# Input = SHA3-256(PK) || message bits = 512 bits
# Output from py :  a24231cf7a008e3586327032ce19b0f46bd4c6989eea0f43dee63d89f13f1e64afbd729a418e200b78515804d57dced7bc95bc19f5bb1d1a7cc08216bffd2a67
# Real Output from Verilog : a24231cf7a008e3586327032ce19b0f46bd4c6989eea0f43dee63d89f13f1e64afbd729a418e200b78515804d57dced7bc95bc19f5bb1d1a7cc08216bffd2a67
# Verified, 10/1/26