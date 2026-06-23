"""Generate ML-KEM-768 decryption intermediates for RTL comparison."""

from pathlib import Path

Q = 3329
QINV = -3327
ZETAS = [
    -1044, -758, -359, -1517, 1493, 1422, 287, 202, -171, 622, 1577, 182,
    962, -1202, -1474, 1468, 573, -1325, 264, 383, -829, 1458, -1602,
    -130, -681, 1017, 732, 608, -1542, 411, -205, -1571, 1223, 652, -552,
    1015, -1293, 1491, -282, -1544, 516, -8, -320, -666, -1618, -1162,
    126, 1469, -853, -90, -271, 830, 107, -1421, -247, -951, -398, 961,
    -1508, -725, 448, -1065, 677, -1275, -1103, 430, 555, 843, -1251,
    871, 1550, 105, 422, 587, 177, -235, -291, -460, 1574, 1653, -246,
    778, 1159, -147, -777, 1483, -602, 1119, -1590, 644, -872, 349, 418,
    329, -156, -75, 817, 1097, 603, 610, 1322, -1285, -1465, 384, -1215,
    -136, 1218, -1335, -874, 220, -1187, -1659, -1185, -1530, -1278, 794,
    -1510, -854, -870, 478, -108, -308, 996, 991, 958, -1460, 1522, 1628,
]


def i16(value):
    value &= 0xFFFF
    return value - 0x10000 if value & 0x8000 else value


def montgomery_reduce(value):
    t = i16(i16(value) * QINV)
    return i16((value - t * Q) >> 16)


def fqmul(a, b):
    return montgomery_reduce(a * b)


def barrett_reduce(value):
    value = i16(value)
    quotient = (20159 * value + (1 << 25)) >> 26
    return i16(value - quotient * Q)


def ntt(poly):
    poly = poly[:]
    k = 1
    length = 128
    while length >= 2:
        for start in range(0, 256, 2 * length):
            zeta = ZETAS[k]
            k += 1
            for j in range(start, start + length):
                t = fqmul(zeta, poly[j + length])
                poly[j + length] = i16(poly[j] - t)
                poly[j] = i16(poly[j] + t)
        length //= 2
    return [barrett_reduce(x) for x in poly]


def inverse_ntt(poly):
    poly = poly[:]
    k = 127
    length = 2
    while length <= 128:
        for start in range(0, 256, 2 * length):
            zeta = ZETAS[k]
            k -= 1
            for j in range(start, start + length):
                t = poly[j]
                poly[j] = barrett_reduce(t + poly[j + length])
                poly[j + length] = fqmul(zeta, i16(poly[j + length] - t))
        length *= 2
    return [fqmul(x, 1441) for x in poly]


def basemul(a, b, zeta):
    return [
        i16(fqmul(fqmul(a[1], b[1]), zeta) + fqmul(a[0], b[0])),
        i16(fqmul(a[0], b[1]) + fqmul(a[1], b[0])),
    ]


def unpack_poly(data):
    result = []
    for i in range(0, len(data), 3):
        result.extend([
            (data[i] | data[i + 1] << 8) & 0xFFF,
            ((data[i + 1] >> 4) | data[i + 2] << 4) & 0xFFF,
        ])
    return list(map(i16, result))


def unpack_ciphertext(data):
    u = [[], [], []]
    for p in range(3):
        packed = data[p * 320:(p + 1) * 320]
        for i in range(0, 320, 5):
            x = packed[i:i + 5]
            compressed = [
                x[0] | (x[1] & 3) << 8,
                (x[1] >> 2) | (x[2] & 15) << 6,
                (x[2] >> 4) | (x[3] & 63) << 4,
                (x[3] >> 6) | x[4] << 2,
            ]
            u[p].extend(i16((x * Q + 512) >> 10) for x in compressed)

    v = []
    for value in data[960:]:
        v.extend([
            i16(((value & 15) * Q + 8) >> 4),
            i16(((value >> 4) * Q + 8) >> 4),
        ])
    return u, v


def main():
    root = Path(__file__).parent
    ct = bytes(int(x, 16) for x in (root / "ct.mem").read_text().split())
    sk = bytes(int(x, 16) for x in (root / "sk.mem").read_text().split())

    u, v = unpack_ciphertext(ct)
    secret = [unpack_poly(sk[p * 384:(p + 1) * 384]) for p in range(3)]
    u_ntt = [ntt(poly) for poly in u]

    product = [0] * 256
    for i in range(64):
        for sign, offset in ((1, 0), (-1, 2)):
            total = [0, 0]
            for p in range(3):
                value = basemul(
                    secret[p][4 * i + offset:4 * i + offset + 2],
                    u_ntt[p][4 * i + offset:4 * i + offset + 2],
                    sign * ZETAS[64 + i],
                )
                total = [i16(total[j] + value[j]) for j in range(2)]
            product[4 * i + offset:4 * i + offset + 2] = map(
                barrett_reduce, total
            )

    a = inverse_ntt(product)
    b = [barrett_reduce(i16(v[i] - a[i])) for i in range(256)]

    for name, poly in (
        ("u_ntt[0]", u_ntt[0]),
        ("product", product),
        ("a", a),
        ("b", b),
    ):
        print(name, " ".join(f"{x & 0xffff:04x}" for x in poly[:16]))


if __name__ == "__main__":
    main()
