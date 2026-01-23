# Post-Quantum Cryptography Accelerator on FPGA
This undergraduate senior project focuses on accelerating key operations in KyberKEM, a lattice-based post-quantum cryptographic scheme on FPGA. 

Goal : Implement and optimize cryptographic modules using FPGA hardware to achieve faster and more energy-efficient computation 

## What is KyberKEM?
Kyber is a post-quantum key exchange mechanism.
Its purpose is to allow two parties to securely agree on a shared secret key, even in the presence of a future quantum computer.

Kyber does not encrypt data directly.
Instead, it is used to establish a shared secret, which can then be used with fast symmetric encryption (e.g., AES) to protect communication.

## Operations
- Key Generation (Simulated)

    One party generates:
    - a public key 
    - a secret key (kept private)
- Encapculation 

    The other party uses the public key to:
    - generate a random shared secret
    - encrypt (encapsulate) it into a ciphertext
- Decapsulation

    The first party uses its secret key to:
    - recover the same "shared secret" from the ciphertext

## Why Kyber?
- It is designed to be secure against quantum attacks
- Efficient and suitable for hardware acceleration
- Standardized by NIST as a post-quantum key encapsulation mechanism

## Hardware Modules
### Encapsulation
- Pre/Post Indcpa Encryption
- Decode PK
- Decode Decompress Msg
- Hash (SHAKE128)
- Sampling Rejection, CBD
- Compress Encode

### Main Computation
- NTT (Number theoretic transform)
- Addition
- PACC
- INTT
- Subtraction
- Reduce

### Decapsulation
- Pre/Post Indcpa Decryption
- Decode Decompress Ct
- Decode Decompress sk
- Compress Encode

## Group members
### 1.Pakin Panawattanakul
### 2.Nitchayanin Thamkunanon
### 3.Panupong Sangaphunchai

