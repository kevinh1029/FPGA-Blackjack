import os

def fill_pix_file(n, m):
    values = []
    for i in range(n-1):
        values.append(f"{i % 8:03b}")

    values.extend(["xxx"] * (m - n + 1))

    output_dir = "pix_mem"
    os.makedirs(output_dir, exist_ok=True)
    with open(os.path.join(output_dir, "pix.txt"), "w") as file:
        file.write("\n".join(values))

n = 176
m = 16384
fill_pix_file(n, m)
