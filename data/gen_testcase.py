import random


def gen_ram32():
    for i in range(128):
        num0 = random.randint(0, 3328)
        num1 = random.randint(0, 3328)
        print(f"{num1:04x}{num0:04x}")


def gen_ram16():
    for i in range(256):
        num = random.randint(0, 3328)
        print(f"{num:04x}")


gen_ram16()
