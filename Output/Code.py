with open("image6.hex", "rb") as file:
    binary_data = file.read()  # Read entire binary file

file_size = len(binary_data)
chunk_size = file_size // 4  # Divide into 4 equal parts

# Save each part as a separate file
for i in range(4):
    start = i * chunk_size
    end = (i + 1) * chunk_size if i < 3 else file_size  # Last chunk gets remaining data

    with open(f"output_part_{i+1}.hex", "wb") as output_file:
        output_file.write(binary_data[start:end])

    print(f"Part {i+1} saved: output_part_{i+1}.bin ({end-start} bytes)")
