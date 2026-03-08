// POST INDCPA DECRYPTION MODULE
/*
Re-Encrypt the plain text message again and compare new and received ciphertext
Input : 
- message 256 bits (32 bytes)
- pre_k 256 bits (32 bytes)
- ciphertext c1,c2 (960 bytes + 128 bytes) = 1088 bytes from post-encryption
    - 7680 bits for c1 (3 polys) = 960 bytes
    - 1024 bits for c2 (1 poly) = 128 bytes

Output :
If Ct=Ct', output
- shared secret 256 bits (32 bytes), ss= shake256(sha3-256(Ct), coin)
- boolean true/false after comparing with enc's Ct

If Ct!=Ct', output
- FAKE shared secret 256 bits (32 bytes) = shake256(SHA3-256(ct), pre-k)
- boolean false

Process :
1. (c', pre-k') = SHA3-512(pre-k, m)
2. Ct' = IND-CPA-KyberEncryption(m',PK,c'), from decode PK to after post-encryption

IND-CPA-KyberEncryption(m',PK,c'): 
    1. Decode PK to get rho
    2. Decode msg to get msg poly
    3. Generate noise polynomials using c' as seed
    4. Generate matrix A from PK
    5. Main computation to get Ct' = (u', v'):
    6. Reduce, Compress encode, post-enc
    7. Output Ct' = (u', v') with coef 10 bits for u' and coef 4 bits for v'
    8. Compare Ct' with received Ct, if they are the same, 
    output shared secret = SHA3-256(pre-k || Ct'), else output shared secret = SHA3-256(pre-k || m')
*/
