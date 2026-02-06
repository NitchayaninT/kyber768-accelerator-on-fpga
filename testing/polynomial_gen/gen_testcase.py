import random

for i in range(128):
    num0 = random.randint(0, 3328)
    num1 = random.randint(0, 3328)
    print(f"{num1:04x}{num0:04x}")
