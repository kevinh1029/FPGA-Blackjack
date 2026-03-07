import sys

def txt_to_mif(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]

    if not lines:
        raise ValueError("Input file is empty.")

    width = len(lines[0])
    depth = len(lines)

    # Validate format
    for line in lines:
        if any(c not in '01' for c in line):
            raise ValueError(f"Invalid binary value: {line}")
        if len(line) != width:
            raise ValueError("All lines must have the same number of bits.")

    with open(output_file, 'w') as f:
        f.write(f"WIDTH={width};\n")
        f.write(f"DEPTH={depth};\n\n")
        f.write("ADDRESS_RADIX=HEX;\n")
        f.write("DATA_RADIX=BIN;\n\n")
        f.write("CONTENT BEGIN\n")

        for addr, value in enumerate(lines):
            f.write(f"\t{addr:X} : {value};\n")

        f.write("END;\n")

    print(f"Generated {output_file}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python txt_to_mif.py input.txt output.mif")
        sys.exit(1)

    txt_to_mif(sys.argv[1], sys.argv[2])