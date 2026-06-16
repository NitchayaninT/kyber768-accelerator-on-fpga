# Hash Optimization
Hash algorithms used
- SHA256 (x2 in pre-enc), (x1 in post-enc)
- SHA512 (x1 in pre-enc)
- SHAKE128 (x1 in pre-enc)
- SHAKE256 (x1 in pre-enc), (x1 in post-enc)

Idea : Each algorithm is represented as a flag (2 bits)
- SHA256 : 00
- SHA512 : 01
- SHAKE128 : 10
- SHAKE256 : 11

## Name : hash_controller (Control Hash Modes)
receives hash requests from encryption top
*- Inputs*
    - flag for choosing hash
    - input length
    - output length (for SHAKE), if for SHA, then just input actual output length
    - message
*- Logic*
    - if sha3-256 (mode 00)
        - rate = 1088
        - domain suffix = 0x06
        - output length = 256
    - if sha3-512 (mode 01)
        - rate = 576
        - domain suffix = 0x06
        - output length = 512
    - if shake128 (mode 10)
        - rate = 1344
        - domain suffix = 0x1F
        - output length = variable
    - if shake256 (mode 11)
        - rate = 1088
        - domain suffix = 0x1F
        - output length = variable
*- Outputs*
    - message
    - flag

## sponge_controller (Control absorb/pad/squeeze)= handles SHA3/SHAKE behavior
replaces the old seperated hashes into "sponge controller"
- rate selection
- padding/domain suffix
- absorb
- squeeze
- output length