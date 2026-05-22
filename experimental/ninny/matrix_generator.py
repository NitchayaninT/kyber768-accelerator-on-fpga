# Step 1 : generates a random seed of 32 bytes
# Step 2 : hash the previous 32-byte with SHA3-512 to split into rho (first 32 bytes) and sigma (last 32 bytes)

import secrets, hashlib #secrets is used to generate secure random numbers for managing secrets
eta1_kem512 = 3
eta1_kem768 = eta1_kem1024 = eta2_kem512 = eta2_kem768 = eta2_kem1024 = 2

# bytes to bits converter
def bytes_to_bits(bytes_data):
    return ''.join(f'{byte:08b}' for byte in bytes_data)

# gets seed and coins
def generate_rho_sigma():
    random = secrets.token_bytes(32) #Return a random byte string containing 32 number of bytes (PRNG)
    g = hashlib.sha3_512(random).digest() # use sha3_512 module, which products 64 bytes output
    rho, sigma = g[:32], g[32:] # Split into rho and sigma
    return rho, sigma # rho is for public matrix, sigma is for noise. These are then feed to SHAKE128

# generate shake128
def shake128_hash(bytes_data, output_len):
    shake128 = hashlib.shake_128()
    shake128.update(bytes_data)
    # Generate a hash of the desired length
    hash_output = shake128.digest(output_len)
    #print("SHAKE128 Hash:", hash_output.hex())
    #print("Bytes Count:", len(hash_output))
    return hash_output

# generate shake256 (uses in Kyber1024 only to gen noise)
def shake256_hash(bytes_data, output_len):
    shake256 = hashlib.shake_128()
    shake256.update(bytes_data)
    # Generate a hash of the desired length
    hash_output = shake256.digest(output_len)
    #print("SHAKE256 Hash:", hash_output.hex())
    #print("Bytes Count:", len(hash_output))
    return hash_output

# transform bytes stream from SHAKE to polynomial with 256 coefficients
def rejection_sampling(bytes_data,q,n):
    i = 0
    j = 0
    coef={}
    while (j < n) & (i + 2 < len(bytes_data)):
        # d1 and d2 has 12 bits, value 0-4095
        d1 = bytes_data[i] | ((bytes_data[i+1]& 0x0F) << 8)
        d2 = ((bytes_data[i+1]) >> 4) | ((bytes_data[i+2]) << 4)
        # Rejection rule
        if d1 < q :
            coef[j] = d1
            j+=1
        if d2 < q & j < n:
            coef[j] = d2
            j+=1
        i+=3
    return coef

# generates noise polynomial. eta can be 2 or 3
def cbd(byte_data, eta):
    bits_stream = [int(b) for b in bytes_to_bits(byte_data)]
    need = 256 * 2 * eta  # total bits 
    if len(bits_stream) < need:
        raise ValueError(f"Need {need} bits, got {len(bits_stream)}")
    coef = [0] * 256
    bit_position = 0

    for i in range(256):
        # take eta bits for a, then eta bits for b
        sum_a = sum(bits_stream[bit_position : bit_position + eta])
        bit_position += eta
        sum_b = sum(bits_stream[bit_position : bit_position + eta])
        bit_position += eta
        coef[i] = sum_a - sum_b
    return coef

# MAIN
rho, sigma = generate_rho_sigma()
# Generate bytes stream for A 
public_matrix_bytes = shake128_hash(rho,672)
# Generate bytes stream for noise char
noise_bytes = shake256_hash(sigma,128)

# Generate public matrix polynomial
# for Kyber, q = 3329, n = 256
poly_public_matrix = rejection_sampling(public_matrix_bytes,3329,256)
#print(poly_public_matrix)

# Generate noise polynomial
# For example, if we use kem768. we input 64n bytes at a time
no_of_bytes_eta1 = 64 * eta1_kem768
no_of_bytes_eta2 = 64 * eta2_kem768
noise_poly = []
for i in range(0, len(noise_bytes), no_of_bytes_eta1):
    block = noise_bytes[i : i + no_of_bytes_eta1]
    coeffs256 = cbd(block, eta1_kem768) 
    noise_poly.append(coeffs256)
print(noise_poly)
