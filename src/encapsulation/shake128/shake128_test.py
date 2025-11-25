import binascii, hashlib

# your 32-byte input (256 bits) as hex
msg_hex = "f8f11229044dfea54ddc214aaa439e7ea06b9b4ede8a3e3f6dfef500c9665598"
msg = binascii.unhexlify(msg_hex)

shake = hashlib.shake_128()
shake.update(msg)

# example: 1024-bit output = 128 bytes
out_1024 = shake.digest(128)
print("1024-bit output:", out_1024.hex())

# for 5376 bits = 672 bytes
shake = hashlib.shake_128()
shake.update(msg)
out_5376 = shake.digest(672)
print("5376-bit output:", out_5376.hex())
