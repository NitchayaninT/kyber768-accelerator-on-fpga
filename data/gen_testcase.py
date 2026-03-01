import random


def gen_ram32():
    for _ in range(128):
        num0 = random.randint(0, 3328)
        num1 = random.randint(0, 3328)
        print(f"{num1:04x}{num0:04x}")


def gen_ram16():
    for _ in range(256):
        num = random.randint(0, 3328)
        print(f"{num:04x}")


def gen_r():
    for _ in range(256):
        num = random.randint(0, 3328)
        print(f"{num:04x}")


def choose():
    bit = int(input())
    if bit == 16:
        gen_ram16()
    elif bit == 32:
        gen_ram32()


gen_ram16()
