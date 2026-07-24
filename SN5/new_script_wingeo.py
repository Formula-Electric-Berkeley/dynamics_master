import os
# Get the folder the script is in
script_dir = os.path.dirname(os.path.abspath(__file__))
input_front = os.path.join(script_dir, "SN5-front (1).TXT")
input_rear = os.path.join(script_dir, "SN5-rear (1).TXT")
output_path = os.path.join(script_dir, "SN5_Global_Variables.txt")
def make_safe_variable_name(label):
    label = label.strip().replace(" ", "_")
    label = ''.join(c for c in label if c.isalnum() or c == '_')
    if not label[0].isalpha():
        label = '_' + label
    return label
def parse_coordinates(input_file):
    coordinates = {}
    with open(input_file, 'r') as f:
        for line in f:
            if 'X=' in line and 'Y=' in line and 'Z=' in line:
                parts = line.split()
                idx = parts[0]
                x_val = float(parts[2])
                y_val = float(parts[4])
                z_val = float(parts[6])
                desc_parts = parts[7:]
                if desc_parts and len(desc_parts[-1]) == 1 and desc_parts[-1].isalpha():
                    desc_parts = desc_parts[:-1]
                label = " ".join(desc_parts).strip()
                if not label:
                    label = f"unnamed_point_{idx}"
                coordinates[label] = {'x': x_val, 'y': y_val, 'z': z_val}
    return coordinates
def write_coordinates_to_file(coordinates, output_file, prefix=""):
    with open(output_file, 'a') as fout:  # 'a' mode to append
        for label in sorted(coordinates.keys()):
            safe_label = make_safe_variable_name(label)
            vals = coordinates[label]
            fout.write(f"\"{prefix}{safe_label}_X\" = {vals['x']}mm\n")
            fout.write(f"\"{prefix}{safe_label}_Y\" = {vals['y']}mm\n")
            fout.write(f"\"{prefix}{safe_label}_Z\" = {vals['z']}mm\n")
try:
    # Clear/create output file
    open(output_path, 'w').close()
    # Front file: no prefix
    front_coords = parse_coordinates(input_front)
    write_coordinates_to_file(front_coords, output_path, prefix="")
    # Rear file: "REAR_" prefix
    rear_coords = parse_coordinates(input_rear)
    write_coordinates_to_file(rear_coords, output_path, prefix="REAR_")
    print(":white_check_mark: Done! File created:", output_path)
except Exception as e:
    print(":x: Error occurred:", e)
input("\nPress Enter to close...")
