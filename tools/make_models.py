"""Generate the DXF drawing set and the assembled USDZ model from the OpenSCAD source.

Run from the repo root:   python3 tools/make_models.py
Needs: openscad on PATH, and  pip install ezdxf trimesh usd-core

Outputs
  dxf/longhaul520_drawings.dxf   one sheet: front / top / right views of the
                                 assembled drone (one layer per component),
                                 every printed part (top + side outline),
                                 dimensions and title block. Units: mm, 1:1.
  dxf/parts/<part>.dxf           flat outline of each printed part (print orientation)
  models/longhaul520_assembled.usdz   full assembly, real colours, metres, Y-up
                                      (opens in iPhone/iPad Quick Look, Blender, Reality Composer)
"""
import os
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

import ezdxf
import ezdxf.bbox
import numpy as np
import trimesh

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SCAD = os.path.join(ROOT, "cad", "longhaul_quad.scad")
DXF_DIR = os.path.join(ROOT, "dxf")
MODEL_DIR = os.path.join(ROOT, "models")
TMP = os.environ.get("LONGHAUL_TMP") or tempfile.mkdtemp(prefix="longhaul_")

# (assembly item, layer colour index, RGB for USD, metallic, roughness, opacity)
ASM = [
    ("hub",           8, (0.25, 0.25, 0.27), 0.0, 0.6, 1.0),
    ("tubes",         7, (0.05, 0.05, 0.05), 0.2, 0.3, 1.0),
    ("motor_mounts",  8, (0.30, 0.33, 0.38), 0.0, 0.6, 1.0),
    ("legs",          8, (0.30, 0.33, 0.38), 0.0, 0.6, 1.0),
    ("motors",        9, (0.75, 0.75, 0.78), 0.9, 0.3, 1.0),
    ("props",         4, (0.10, 0.10, 0.12), 0.1, 0.4, 1.0),
    ("pins",         30, (1.00, 0.55, 0.00), 0.0, 0.5, 1.0),
    ("battery_tray",  8, (0.30, 0.33, 0.38), 0.0, 0.6, 1.0),
    ("battery",       5, (0.15, 0.30, 0.75), 0.0, 0.5, 1.0),
    ("camera_mount",  8, (0.30, 0.33, 0.38), 0.0, 0.6, 1.0),
    ("camera_cradle", 8, (0.30, 0.33, 0.38), 0.0, 0.6, 1.0),
    ("camera",        7, (0.08, 0.08, 0.08), 0.3, 0.3, 1.0),
    ("gps_mast",      8, (0.30, 0.33, 0.38), 0.0, 0.6, 1.0),
    ("gps",           3, (0.05, 0.35, 0.10), 0.0, 0.5, 1.0),
    ("stack",         3, (0.05, 0.45, 0.15), 0.0, 0.5, 1.0),
    ("stack_pegs",   30, (1.00, 0.55, 0.00), 0.0, 0.5, 1.0),
    ("vtx",           1, (0.65, 0.12, 0.12), 0.3, 0.4, 1.0),
]
PARTS = ["hub", "motor_mount", "leg", "battery_tray", "camera_mount", "camera_cradle",
         "gps_mast", "pin_hub", "pin_mount", "stack_peg", "stack_spacer"]
PART_QTY = {"motor_mount": 4, "leg": 4, "pin_hub": 5, "pin_mount": 4, "stack_peg": 4, "stack_spacer": 4}

# 2D projection matrices: world (x fwd, y left, z up) -> drawing (u, v)
VIEWS = {
    "TOP":   "[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]",     # u = x, v = y
    "FRONT": "[[0,-1,0,0],[0,0,1,0],[1,0,0,0],[0,0,0,1]]",    # looking at the nose: u = -y, v = z
    "RIGHT": "[[-1,0,0,0],[0,0,1,0],[0,-1,0,0],[0,0,0,1]]",   # looking from the right: u = -x, v = z
}


def openscad(code, out):
    if os.path.exists(out) and os.path.getmtime(out) > os.path.getmtime(SCAD) and out.startswith(TMP):
        return out
    src = os.path.join(TMP, os.path.basename(out) + ".scad")
    with open(src, "w") as f:
        f.write(f"use <{SCAD}>\n{code}\n")
    r = subprocess.run(["openscad", "-q", "-o", out, src], capture_output=True, text=True)
    if not os.path.exists(out):
        raise RuntimeError(f"openscad failed for {out}:\n{r.stderr}")
    return out


def jobs():
    j = []
    for name, *_ in ASM:
        j.append((f'print_part("asm:{name}");', os.path.join(TMP, f"asm_{name}.stl")))
        for view, m in VIEWS.items():
            j.append((f'projection() multmatrix({m}) print_part("asm:{name}");',
                      os.path.join(TMP, f"view_{view}_{name}.dxf")))
    for p in PARTS:
        j.append((f'projection() print_part("{p}");', os.path.join(DXF_DIR, "parts", f"{p}.dxf")))
        j.append((f'projection() multmatrix({VIEWS["RIGHT"]}) print_part("{p}");',
                  os.path.join(TMP, f"side_{p}.dxf")))
    return j


def copy_entities(src_path, msp, dx, dy, layer, scale=1.0):
    """Copy every entity of a DXF file into msp, shifted by (dx, dy). Returns 2D bbox."""
    src = ezdxf.readfile(src_path)
    pts = []
    for e in src.modelspace():
        c = e.copy()
        c.dxf.layer = layer
        if scale != 1.0:
            c.scale_uniform(scale)
        c.translate(dx, dy, 0)
        msp.add_entity(c)
        if c.dxftype() == "LINE":
            pts += [c.dxf.start, c.dxf.end]
        elif c.dxftype() == "LWPOLYLINE":
            pts += [(p[0], p[1]) for p in c.get_points()]
        elif c.dxftype() == "POLYLINE":
            pts += [v.dxf.location for v in c.vertices]
    if not pts:
        return None
    a = np.array([(p[0], p[1]) for p in pts])
    return a.min(axis=0), a.max(axis=0)


def build_dxf():
    doc = ezdxf.new("R2010", setup=True)
    doc.units = ezdxf.units.MM
    msp = doc.modelspace()
    for name, aci, *_ in ASM:
        doc.layers.add(name.upper(), color=aci)
    for lay, aci in [("PARTS", 7), ("DIMS", 2), ("TEXT", 7), ("FRAME", 7)]:
        doc.layers.add(lay, color=aci)

    # third-angle layout: TOP above FRONT, RIGHT to the right of FRONT
    origins = {"FRONT": (0, 0), "TOP": (0, 600), "RIGHT": (900, 0)}
    for view, (ox, oy) in origins.items():
        for name, *_ in ASM:
            f = os.path.join(TMP, f"view_{view}_{name}.dxf")
            if os.path.exists(f):
                copy_entities(f, msp, ox, oy, name.upper())
        msp.add_text(f"{view} VIEW", height=14, dxfattribs={"layer": "TEXT"}).set_placement(
            (ox - 120, oy - 190 if view != "TOP" else oy - 460))

    # key dimensions
    ds = {"layer": "DIMS"}
    DIMO = {"dimtxt": 10, "dimasz": 8, "dimlfac": 1, "dimdec": 1, "dimexe": 3, "dimexo": 3}
    m = 260 * np.cos(np.radians(45))
    tx, ty = origins["TOP"]
    msp.add_linear_dim(base=(tx, ty + 470), p1=(tx - m, ty + m), p2=(tx + m, ty + m), dxfattribs=ds,
                       override=DIMO).render()
    msp.add_aligned_dim(p1=(tx - m, ty - m), p2=(tx + m, ty + m), distance=-40, dxfattribs=ds,
                        text="<> WHEELBASE", override=DIMO).render()
    fx, fy = origins["FRONT"]
    msp.add_linear_dim(base=(fx + 460, fy), p1=(fx + m, fy - 109), p2=(fx - 11, fy + 106.5), angle=90,
                       dxfattribs=ds, override=DIMO).render()
    msp.add_text("13 in PROP DISC (330 mm)", height=9, dxfattribs={"layer": "TEXT"}).set_placement(
        (tx + m - 80, ty + m + 180))

    # printed-parts sheet
    px0, py0 = 1500, 650
    x, y, row_h = px0, py0, 0
    msp.add_text("PRINTED PARTS - print orientation (top) and side outline", height=14,
                 dxfattribs={"layer": "TEXT"}).set_placement((px0, py0 + 230))
    for p in PARTS:
        top = os.path.join(DXF_DIR, "parts", f"{p}.dxf")
        side = os.path.join(TMP, f"side_{p}.dxf")
        bb = ezdxf.bbox.extents(ezdxf.readfile(top).modelspace())
        sb = ezdxf.bbox.extents(ezdxf.readfile(side).modelspace())
        qty = PART_QTY.get(p, 1)
        w = max(bb.size.x, sb.size.x, len(f"{p.upper()}  x{qty}") * 7.5)
        if x + w > px0 + 900:
            x, y, row_h = px0, y - row_h - 120, 0
        cx = x + w / 2
        copy_entities(top, msp, cx - bb.center.x, y - bb.center.y, "PARTS")
        copy_entities(side, msp, cx - sb.center.x, y - bb.size.y / 2 - 20 - sb.size.y / 2 - sb.center.y, "PARTS")
        msp.add_text(f"{p.upper()}  x{qty}", height=8, dxfattribs={"layer": "TEXT"}).set_placement(
            (x, y + bb.size.y / 2 + 12))
        msp.add_text(f"{bb.size.x:.1f} x {bb.size.y:.1f}", height=5, dxfattribs={"layer": "TEXT"}).set_placement(
            (x, y + bb.size.y / 2 + 4))
        row_h = max(row_h, bb.size.y + sb.size.y + 40)
        x += w + 60

    # frame + title block
    ext = ezdxf.bbox.extents(msp)
    x0, y0, x1, y1 = ext.extmin.x - 60, ext.extmin.y - 160, ext.extmax.x + 60, ext.extmax.y + 60
    msp.add_lwpolyline([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], close=True, dxfattribs={"layer": "FRAME"})
    msp.add_lwpolyline([(x1 - 700, y0), (x1, y0), (x1, y0 + 120), (x1 - 700, y0 + 120)], close=True,
                       dxfattribs={"layer": "FRAME"})
    for i, t in enumerate(["LONGHAUL-520 v2  -  SCREWLESS 3D-PRINTED CAMERA QUAD",
                           "Units: mm   Scale 1:1   Third-angle projection",
                           "Joints: slide-in arms + snap pins, bayonet legs, dovetail battery & camera, snap GPS/stack",
                           "Source: cad/longhaul_quad.scad  (regenerate: python3 tools/make_models.py)"]):
        msp.add_text(t, height=14 if i == 0 else 9, dxfattribs={"layer": "TEXT"}).set_placement(
            (x1 - 690, y0 + 95 - i * 26))
    out = os.path.join(DXF_DIR, "longhaul520_drawings.dxf")
    doc.saveas(out)
    return out


def build_usdz():
    from pxr import Gf, Sdf, Usd, UsdGeom, UsdShade, UsdUtils, Vt

    usdc = os.path.join(TMP, "longhaul520.usdc")
    stage = Usd.Stage.CreateNew(usdc)
    UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
    UsdGeom.SetStageMetersPerUnit(stage, 1.0)
    root = UsdGeom.Xform.Define(stage, "/LongHaul520")
    stage.SetDefaultPrim(root.GetPrim())
    UsdGeom.Xform.Define(stage, "/LongHaul520/Materials")
    min_y = 0.0
    for name, _, rgb, metal, rough, opac in ASM:
        mesh_t = trimesh.load(os.path.join(TMP, f"asm_{name}.stl"))
        mesh_t.merge_vertices()
        v = np.asarray(mesh_t.vertices) / 1000.0                 # mm -> m
        pts = np.column_stack([v[:, 0], v[:, 2], -v[:, 1]])      # Z-up -> Y-up
        prim_name = "".join(w.capitalize() for w in name.split("_"))
        mesh = UsdGeom.Mesh.Define(stage, f"/LongHaul520/{prim_name}")
        mesh.CreatePointsAttr(Vt.Vec3fArray.FromNumpy(pts.astype(np.float32)))
        mesh.CreateFaceVertexCountsAttr(Vt.IntArray([3] * len(mesh_t.faces)))
        mesh.CreateFaceVertexIndicesAttr(Vt.IntArray.FromNumpy(mesh_t.faces.astype(np.int32).ravel()))
        mesh.CreateSubdivisionSchemeAttr(UsdGeom.Tokens.none)
        mesh.CreateDoubleSidedAttr(False)
        lo, hi = pts.min(axis=0), pts.max(axis=0)
        min_y = min(min_y, float(lo[1]))
        mesh.CreateExtentAttr([Gf.Vec3f(*lo.tolist()), Gf.Vec3f(*hi.tolist())])
        mat = UsdShade.Material.Define(stage, f"/LongHaul520/Materials/{prim_name}Mat")
        sh = UsdShade.Shader.Define(stage, f"/LongHaul520/Materials/{prim_name}Mat/Surface")
        sh.CreateIdAttr("UsdPreviewSurface")
        sh.CreateInput("diffuseColor", Sdf.ValueTypeNames.Color3f).Set(Gf.Vec3f(*rgb))
        sh.CreateInput("metallic", Sdf.ValueTypeNames.Float).Set(metal)
        sh.CreateInput("roughness", Sdf.ValueTypeNames.Float).Set(rough)
        sh.CreateInput("opacity", Sdf.ValueTypeNames.Float).Set(opac)
        mat.CreateSurfaceOutput().ConnectToSource(sh.ConnectableAPI(), "surface")
        UsdShade.MaterialBindingAPI.Apply(mesh.GetPrim()).Bind(mat)
    # stand the model on the floor (feet at y = 0) for AR Quick Look
    root.AddTranslateOp().Set(Gf.Vec3d(0, -min_y, 0))
    stage.GetRootLayer().Save()
    os.makedirs(MODEL_DIR, exist_ok=True)
    out = os.path.join(MODEL_DIR, "longhaul520_assembled.usdz")
    if os.path.exists(out):
        os.remove(out)
    ok = UsdUtils.CreateNewARKitUsdzPackage(Sdf.AssetPath(usdc), out)
    if not ok:
        raise RuntimeError("USDZ packaging failed")
    return out


def main():
    os.makedirs(os.path.join(DXF_DIR, "parts"), exist_ok=True)
    todo = jobs()
    print(f"running {len(todo)} OpenSCAD jobs ...")
    with ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as ex:
        for out in ex.map(lambda j: openscad(*j), todo):
            pass
    print("DXF :", build_dxf())
    print("USDZ:", build_usdz())


if __name__ == "__main__":
    sys.exit(main())
