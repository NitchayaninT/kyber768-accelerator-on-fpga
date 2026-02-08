# Encapsulation Workflow
- Key gen -> creates rho and t_hat
## -- INPUTS -- 
- Input Public Key (rho, t hat)
    - rho = 256 bits seed for A Matrix
    - t hat = PK's polynomial vector, used for NTT
        - t = [t0,t1,t2] where each t is a vector of k=3 polynomials and
        each polynomial is degree-256
- Input R = Random 256 bits from PRNG

## -- Pre/Post Indcpa Encryption -- 
Everything that must happen before the NTT math block can run
- Input Public key (rho, t hat)
- R = random 256 bits
- Output 
    - m = SHA3-256(R), plain text message
    - (coins, pre-k) = SHA3-512(SHA3-256(PK),m)

## -- Public Matrix A generation -- 
- Input PK into Decode PK
    - Output Seed (rho)
- Input seed (rho) of 256 bits into SHAKE128
    - Output bytes stream of 672 bytes or 5376 bits
- Input 9 streams 672 bytes into Rejection Sampling AT A TIME
    - Output : 9 Polynomials with 256 coefficients, collect them 
    in the Public matrix array 

## -- Noise generation -- 
- input R (random 256 bits)
- Apply SHA3-256 to R : SHA3-256(R)
    - Output : m  (plain text msg)
- Construct coins
    - Apply SHA3-512 to (SHA3-256(PK),m)
    - Output : coins, pre-k (512 bits)
        - Coins = first 32 bytes (256 bits)
        - Pre-k = last 32 bytes (256 bits)
- Input coins to SHAKE128 SHAKE128(coins || nonce), while nonce is a counter that increments by 1 for every polynomial we need.
    - Output bytes stream of 1024 bits 
- Input bytes to noise sampling
    - Output : y,e’,e’’ = noise polynomials
        - r = 3 polynomials
        - e1 = 3 polynomials
        - e2 = 1 polynomial