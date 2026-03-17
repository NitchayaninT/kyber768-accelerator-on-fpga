with open("c1.mem", "w") as f:
    for i in range(960):
        f.write(f"{i % 256:02x}\n")

with open("c2.mem", "w") as f:
    for i in range(128):
        f.write(f"{(255 - i) % 256:02x}\n")

print("wrote c1.mem and c2.mem")
