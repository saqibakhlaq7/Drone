"""Print bounding box, solid volume and estimated printed mass of each STL in stl/.

Mass estimate = volume * density * fill_factor, where fill_factor approximates
4 perimeters + 40 % gyroid infill on these fairly thin parts.
"""
import glob
import os
import sys

import numpy as np

DENSITY = 1.30       # g/cm3, PETG-CF
FILL_FACTOR = 0.75   # thin, perimeter-dominated parts


def load_ascii_stl(path):
    verts = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("vertex"):
                verts.append([float(v) for v in line.split()[1:4]])
    return np.array(verts).reshape(-1, 3, 3)


def main(stl_dir):
    total = 0.0
    qty = {"motor_mount": 4, "leg": 4}
    print(f"{'part':14s} {'size X x Y x Z (mm)':>24s} {'cm3':>7s} {'g each':>7s} {'qty':>4s}")
    for path in sorted(glob.glob(os.path.join(stl_dir, "*.stl"))):
        tri = load_ascii_stl(path)
        vol = np.einsum("ij,ij->i", tri[:, 0], np.cross(tri[:, 1], tri[:, 2])).sum() / 6.0 / 1000.0
        size = tri.reshape(-1, 3).max(axis=0) - tri.reshape(-1, 3).min(axis=0)
        name = os.path.splitext(os.path.basename(path))[0]
        n = qty.get(name, 1)
        mass = abs(vol) * DENSITY * FILL_FACTOR
        total += mass * n
        print(f"{name:14s} {size[0]:7.1f} x {size[1]:6.1f} x {size[2]:6.1f} {abs(vol):7.1f} {mass:7.1f} {n:4d}")
    print(f"\nTotal printed mass (all parts, with quantities): {total:.0f} g")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "stl"))
