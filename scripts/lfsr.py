def lfsr(seed, taps, num_cycles):
    register = seed
    bit_width = seed.bit_length()
    sequence = []

    for _ in range(num_cycles):
        sequence.append(register)

        feedback = 0
        for tap in taps:
            feedback ^= (register >> tap) & 1

        register = ((register << 1) & ((1 << bit_width) - 1)) | feedback

    return sequence


seed = 0xFFFFFFF1 
taps = [31, 21, 1, 0] 
num_cycles = 1000 

lfsr_sequence = lfsr(seed, taps, num_cycles)

print("Generated LFSR sequence:")
for i, value in enumerate(lfsr_sequence):
    print(f"Cycle {i}: 0x{value:08X}")