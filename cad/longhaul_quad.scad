// =====================================================================
//  LongHaul-520 v2 : 3D-printable 1-hour camera quadcopter - SCREWLESS
//  Parametric OpenSCAD source.  All dimensions in millimetres.
//
//  Export one part:   openscad -D 'part="hub"' -o hub.stl longhaul_quad.scad
//  Printable parts (in print orientation):
//     hub, motor_mount, leg, battery_tray, camera_mount, camera_cradle,
//     gps_mast, pin_hub, pin_mount, stack_peg, stack_spacer
//  Assembly pieces (world position, for USDZ / drawings):  "asm:<name>"
//  Full assembly preview:  part = "assembly"
//
//  How the parts join - no screws in the frame:
//   - ARMS: 16 mm carbon tubes SLIDE into closed sockets in the one-piece hub
//     and into the motor mounts; each joint is locked by a printed SNAP PIN.
//   - LEGS: BAYONET twist-lock into the bottom of each motor mount.
//   - BATTERY TRAY: SLIDES onto two DOVETAIL rails under the hub and clicks
//     home with a flexure LATCH (press the thumb tab to release).
//   - CAMERA: cradle snaps the camera, TRUNNIONS snap into the mount, the
//     mount SLIDES into a DOVETAIL groove across the hub's front face.
//   - GPS MAST: SNAP-FIT tenon into a square socket in the hub top.
//   - FC/ESC STACK: double-ended SNAP PEGS + printed spacers.
//   Only the motors keep the 3 screws they come with (motor -> mount),
//   because a spinning motor must be bolted; props use the motor's adapter.
// =====================================================================

part = "assembly";

/* ---------------- main parameters ---------------- */
wheelbase    = 520;     // motor-to-motor diagonal (13" props)
tube_od      = 16;      // carbon tube outer diameter
tube_clear   = 0.2;     // radial clearance of sockets / sleeves
fit          = 0.2;     // sliding-joint clearance (per side)

hub_half     = 62;      // half-width of the square hub body
hub_h        = 26;      // hub height
skin         = 3;       // top / bottom skin thickness
wall         = 3;       // hub wall thickness
sock_r       = 12.5;    // outer radius of the arm sockets
sock_r0      = 31;      // tube inner end (radius from centre)
arm_r1       = 100;     // socket outer end
pin_r_hub    = 70;      // radius of the hub snap pins
pin_d        = 4.0;     // snap pin diameter
pin_hole     = 4.3;

rail_x       = 30;      // battery dovetail rails at x = +-rail_x
rail_len     = 110;
rail_base    = 10;      // dovetail width at the hub
rail_tip     = 16;      // dovetail width at the tip
rail_h       = 5;

stack_sp     = 30.5;
peg_hole     = 3.2;

// motor (Tarot 4108 380KV, 27 mm triangle mount, 46 mm bell)
motor_d      = 46;
motor_h      = 26;
pad_r        = 27;
pad_t        = 5;
sleeve_r     = tube_od/2 + 4;
mm_len       = 48;
bay_r        = 10;      // bayonet socket radius
bay_lug      = 12.6;    // bayonet lug outer radius
bay_depth    = 10;

prop_d       = 13 * 25.4;

// battery 6S4P 21700, mounted sideways (long side along Y)
pack_l       = 132;
pack_w       = 90;
pack_h       = 76;
tray_t       = 3;
tray_blk_h   = rail_h + 0.3;

leg_len      = 110;

cam_w        = 19.2;    // camera body width (Walksnail / O3 style 19 mm)
cam_tilt     = 20;      // assembly preview only
cam_pivot_x  = 88;
cam_wall     = 1.8;

arm_angles   = [45, 135, 225, 315];
R_motor      = wheelbase / 2;
zc           = hub_h / 2;
gps_pos      = [-48, 12];
lead_hole    = [-50, -10];

$fn = 64;

/* ---------------- helpers ---------------- */
module rounded_square(size, r) {
    offset(r) square([size[0] - 2*r, size[1] - 2*r], center = true);
}
module slot2d(p0, p1, d) { hull() { translate(p0) circle(d = d); translate(p1) circle(d = d); } }

// Horizontal bore along +X starting at the origin. Teardrop point up or
// down so it prints without supports.
module teardrop_bar(r, len, point_up = true) {
    rotate([0, 90, 0]) linear_extrude(len)
        rotate(point_up ? 180 : 0) hull() { circle(r); translate([r * 1.41, 0]) square(0.01, center = true); }
}

// Dovetail profile (2D): width wb at y=0, wt at y=h.
module dovetail2d(wb, wt, h) { polygon([[-wb/2, 0], [wb/2, 0], [wt/2, h], [-wt/2, h]]); }

// Profile drawn in the XZ plane, extruded along Y from y0 to y1.
module along_y(y0, y1) { translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children(); }

/* =====================================================================
   SNAP PIN : head + shank + split arrow tip.  Flats on two sides so it
   prints lying down (strong along its length).  grip = material thickness.
   Local frame: head at z<0, shank from z=0 to grip, tip beyond.
   ===================================================================== */
module snap_pin_body(grip, d = pin_d, tip = 6, head_d = 8.5) {
    difference() {
        intersection() {
            union() {
                translate([0, 0, -2.5]) cylinder(d = head_d, h = 2.5);
                cylinder(d = d, h = grip + 0.3);
                translate([0, 0, grip + 0.3]) cylinder(d1 = d + 1.2, d2 = d - 0.8, h = tip);
            }
            translate([-10, -(d - 0.6)/2, -5]) cube([20, d - 0.6, grip + tip + 10]);
        }
        // split so the barb can squeeze through the hole
        translate([-0.7, -10, grip - 3]) cube([1.4, 20, tip + 10]);
    }
}
// Double-ended peg for the FC/ESC stack (snaps into the hub top skin,
// then through ESC, spacer and FC, and snaps over the FC).
module stack_peg_body() {
    shaft = 1.6 + 6 + 1.6 + 2.5;      // ESC + spacer + FC + grommet slack
    d = 2.9;
    difference() {
        intersection() {
            union() {
                translate([0, 0, -5]) cylinder(d1 = d - 0.8, d2 = d + 1.0, h = 5);   // bottom barb
                cylinder(d = d, h = skin + 0.2);
                translate([0, 0, skin + 0.2]) cylinder(d = 6, h = 3);            // collar under ESC
                translate([0, 0, skin + 3.2]) cylinder(d = d, h = shaft);
                translate([0, 0, skin + 3.2 + shaft]) cylinder(d1 = d + 1.0, d2 = d - 0.8, h = 5);
            }
            translate([-10, -(d - 0.5)/2, -10]) cube([20, d - 0.5, 60]);
        }
        translate([-0.55, -10, -6]) cube([1.1, 20, 6 + skin - 0.5]);
        translate([-0.55, -10, skin + 3.2 + shaft - 2]) cube([1.1, 20, 10]);
    }
}
module stack_spacer() { difference() { cylinder(d = 6, h = 6); translate([0, 0, -1]) cylinder(d = 3.3, h = 8); } }

/* =====================================================================
   HUB : one piece.  Closed sockets take the arms, dovetail rails below
   carry the battery tray, a dovetail groove in front carries the camera.
   World orientation (z = 0 bottom).  PRINT IT UPSIDE DOWN (top on bed).
   ===================================================================== */
module hub_outline() {
    union() {
        rounded_square([2*hub_half, 2*hub_half], 10);
        for (a = arm_angles) rotate(a) translate([0, -16]) square([arm_r1, 32]);
    }
}

module hub() {
    difference() {
        union() {
            linear_extrude(skin) hub_outline();
            translate([0, 0, hub_h - skin]) linear_extrude(skin) hub_outline();
            linear_extrude(hub_h) difference() {
                rounded_square([2*hub_half, 2*hub_half], 10);
                offset(-wall) rounded_square([2*hub_half, 2*hub_half], 10);
            }
            for (a = arm_angles) rotate(a)
                translate([26, 0, zc]) rotate([0, 90, 0]) cylinder(r = sock_r, h = arm_r1 - 26);
            // cross ribs
            translate([-hub_half + 1, -1.5, 0]) cube([2*hub_half - 2, 3, hub_h]);
            translate([-1.5, -hub_half + 1, 0]) cube([3, 2*hub_half - 2, hub_h]);
            // solid front block for the camera dovetail
            translate([hub_half - 9, -42, 0]) cube([9, 84, hub_h]);
            // pin bosses (solid round the snap pins)
            for (a = arm_angles) rotate(a) translate([pin_r_hub, 0, 0]) cylinder(r = 6, h = hub_h);
            // battery dovetail rails (male, pointing down)
            for (s = [-1, 1]) translate([s*rail_x, 0, 0])
                along_y(-rail_len/2, rail_len/2) mirror([0, 1]) dovetail2d(rail_base, rail_tip, rail_h);
        }
        // arm bores (tube slides in from outside)
        for (a = arm_angles) rotate(a)
            translate([sock_r0, 0, zc]) teardrop_bar(tube_od/2 + tube_clear, arm_r1 - sock_r0 + 1, point_up = false);
        // wire exits: from the inner end of each bore up through the top
        for (a = arm_angles) rotate(a)
            translate([sock_r0 + 1, 0, zc]) cylinder(d = 12, h = hub_h);
        // snap-pin holes (drill the tube to match, see build guide)
        for (a = arm_angles) rotate(a) translate([pin_r_hub, 0, -1]) cylinder(d = pin_hole, h = hub_h + 2);
        // stack peg holes
        for (x = [-1, 1]) for (y = [-1, 1])
            translate([x*stack_sp/2, y*stack_sp/2, hub_h - skin - 1]) cylinder(d = peg_hole, h = skin + 2);
        // GPS mast square socket (through boss + top skin)
        translate([gps_pos[0] - 5.15, gps_pos[1] - 5.15, hub_h - skin - 1]) cube([10.3, 10.3, skin + 2]);
        // battery lead pass-through (bottom -> cavity -> top)
        translate([lead_hole[0], lead_hole[1], -1]) cylinder(d = 14, h = hub_h + 2);
        // camera dovetail groove across the front face (open both ends)
        along_y(-hub_half - 1, hub_half + 1)
            polygon([[hub_half + 0.5, zc - 4], [hub_half - 5, zc - 8.5], [hub_half - 5, zc + 8.5], [hub_half + 0.5, zc + 4]]);
        // vertical snap-pin hole that locks the camera mount's tongue
        translate([hub_half - 2.5, 0, -1]) cylinder(d = pin_hole, h = hub_h + 2);
        // VTX / receiver zip-tie slots in the top skin
        for (s = [-1, 1]) for (dx = [-8, 8]) translate([-26 + dx, s*44, hub_h - skin - 1])
            linear_extrude(skin + 2) rounded_square([3, 6], 1.4);
        // vents in the top skin over the cavity
        for (q = [[30, 0], [-30, 0], [0, 30], [0, -30]]) translate([q[0], q[1], hub_h - skin - 1])
            cylinder(d = 10, h = skin + 2);
        // name on top
        translate([30, -50, hub_h - 0.6]) linear_extrude(1) text("LongHaul-520", size = 5, halign = "center");
    }
}

/* =====================================================================
   MOTOR MOUNT  (local frame: motor axis = Z, tube along -X, tube centre
   z = 0).  Print upright, motor pad on top.
   ===================================================================== */
module motor_mount() {
    difference() {
        union() {
            translate([-mm_len, 0, 0]) rotate([0, 90, 0]) cylinder(r = sleeve_r, h = mm_len);
            hull() {
                translate([0, 0, sleeve_r - pad_t]) cylinder(r = pad_r, h = pad_t);
                translate([0, 0, -sleeve_r]) cylinder(r = 16, h = 4);
            }
            translate([-36, 0, -sleeve_r]) cylinder(r = 5.5, h = 2*sleeve_r);   // pin boss
        }
        translate([-mm_len - 1, 0, 0]) teardrop_bar(tube_od/2 + tube_clear, mm_len - 10 + 1, point_up = true);
        translate([-12, 0, 0]) rotate([0, 90, 0]) cylinder(r = 5, h = 12);
        translate([0, 0, -2]) cylinder(r = 6.5, h = 40);
        // motor screw slots (the only screws: the 3 that come with the motor)
        for (a = [90, 210, 330, 0, 180]) rotate(a)
            translate([0, 0, -20]) linear_extrude(60) slot2d([11, 0], [17.5, 0], 3.4);
        // snap pin through sleeve + tube
        translate([-36, 0, -30]) cylinder(d = pin_hole, h = 60);
        // bayonet socket for the leg
        translate([0, 0, -sleeve_r]) bayonet_socket();
    }
}

// Female bayonet, opening downward at z = 0, depth bay_depth.
module bayonet_socket() {
    translate([0, 0, -1]) cylinder(r = bay_r + fit, h = bay_depth + 1);
    for (a = [0, 180]) rotate(a) {
        // entry slot
        translate([0, -3.2, -1]) cube([bay_lug + 0.4, 6.4, bay_depth + 1]);
        // 45-degree locking channel at the top of the socket
        translate([0, 0, bay_depth - 3.6]) rotate_extrude(angle = 65) translate([0, -0.0]) square([bay_lug + 0.4, 3.6]);
    }
}

/* =====================================================================
   LANDING LEG  - bayonet plug on top.  Push up, twist 45 deg to lock.
   Local frame: plug top at z = 0, leg goes to z = -leg_len.
   ===================================================================== */
module leg() {
    difference() {
        union() {
            cylinder(r = bay_r - fit, h = bay_depth - 0.3);                                  // plug
            for (a = [0, 180]) rotate(a + 45) translate([0, -2.9, bay_depth - 3.4])
                cube([bay_lug, 5.8, 3.2]);                                                   // lugs (locked position)
            translate([0, 0, -8]) cylinder(r1 = 8, r2 = 16, h = 8);                         // conical shoulder
            translate([0, 0, -leg_len + 6]) cylinder(r1 = 6, r2 = 8, h = leg_len - 14);
            translate([0, 0, -leg_len + 6]) sphere(r = 8);
            for (a = [0, 90, 180, 270]) rotate(a) translate([0, -1.5, -24]) cube([13, 3, 16]);   // twist grip
        }
        translate([0, 0, -leg_len + 10]) cylinder(r1 = 3.5, r2 = 5.5, h = leg_len - 22);   // hollow
        translate([0, 0, -leg_len - 20]) cylinder(r = 20, h = 20);                          // flat foot
    }
}

/* =====================================================================
   BATTERY TRAY - slides onto the hub's dovetail rails from the -Y side,
   stops against the closed groove ends, clicks home with a flexure latch.
   Local frame: plate bottom z = 0, grooves on top.  Print as-is.
   ===================================================================== */
blk_y0 = -62; blk_y1 = rail_len/2 + 4;
module battery_tray() {
    L = pack_l + 18; W = pack_w + 8;
    tongue_x = -rail_x; tongue_w = 8; tongue_root = -32; tongue_end = -L/2;
    difference() {
        union() {
            linear_extrude(tray_t) rounded_square([W, L], 6);
            for (s = [-1, 1]) translate([s*rail_x - 12.5, blk_y0, tray_t]) cube([25, blk_y1 - blk_y0, tray_blk_h]);
        }
        // female dovetail grooves, open at -Y, closed at +Y
        for (s = [-1, 1]) translate([s*rail_x, 0, tray_t + tray_blk_h])
            along_y(blk_y0 - 1, rail_len/2 + 0.3)
                mirror([0, 1]) dovetail2d(rail_base + 2*fit, rail_tip + 2*fit, tray_blk_h + 0.01);
        // latch tongue cut-out (U slot) in the left groove floor + block wall
        translate([tongue_x, 0, -1]) linear_extrude(tray_t + tray_blk_h + 2) difference() {
            translate([-tongue_w/2 - 1.2, tongue_end - 1]) square([tongue_w + 2.4, tongue_root - tongue_end + 1]);
            translate([-tongue_w/2, tongue_end - 1]) square([tongue_w, tongue_root - tongue_end + 1]);
        }
        // tongue must be free of the groove block above it
        translate([tongue_x - tongue_w/2 - 1.2, tongue_end - 1, tray_t]) cube([tongue_w + 2.4, tongue_root - tongue_end + 1, 20]);
        // strap slots for 20-25 mm battery straps
        for (y = [-34, 34]) translate([0, y, -1]) linear_extrude(tray_t + 20) rounded_square([27, 4.5], 2);
        // lightening
        for (y = [-14, 14]) translate([0, y, -1]) linear_extrude(tray_t + 2) rounded_square([24, 20], 5);
        for (y = [-58, 58]) translate([0, y, -1]) linear_extrude(tray_t + 2) rounded_square([24, 12], 4);
    }
    // latch bump on the tongue: ramp toward -Y, sharp face toward +Y
    translate([tongue_x - tongue_w/2, 0, tray_t]) rotate([90, 0, 90]) linear_extrude(tongue_w)
        polygon([[-rail_len/2 - 6, 0], [-rail_len/2 - 0.6, 1.2], [-rail_len/2 - 0.6, 0]]);
    // thumb tab
    translate([tongue_x - tongue_w/2, tongue_end, tray_t]) cube([tongue_w, 5, 4]);
}

/* =====================================================================
   CAMERA MOUNT - dovetail tongue slides across the hub's front groove,
   detent bumps centre it.  Two cheeks hold the cradle's trunnions.
   Built in WORLD coordinates (hub front face at x = hub_half).
   ===================================================================== */
cam_cheek_gap = cam_w + 2*cam_wall + 0.6;
module camera_mount() {
    y_half = 15;
    difference() { union() {
        // tongue (matches the hub groove minus clearance)
        along_y(-y_half, y_half)
            polygon([[hub_half + 0.2, zc - 3.8], [hub_half - 4.8, zc - 8.3], [hub_half - 4.8, zc + 8.3], [hub_half + 0.2, zc + 3.8]]);
        // neck (45 deg, prints without support) + front plate
        hull() {
            translate([hub_half + 0.2, -y_half, zc - 3.8]) cube([0.01, 2*y_half, 7.6]);
            translate([hub_half + 8, -y_half, zc - 12]) cube([3, 2*y_half, 24]);
        }
        // cheeks with trunnion holes
        for (s = [-1, 1]) difference() {
            hull() {
                translate([hub_half + 8, s*(cam_cheek_gap/2 + 1.2) - 1.2, zc - 12]) cube([3, 2.4, 24]);
                translate([cam_pivot_x, s*(cam_cheek_gap/2 + 1.2), zc]) rotate([90, 0, 0]) cylinder(r = 8, h = 2.4, center = true);
            }
            translate([cam_pivot_x, s*(cam_cheek_gap/2 + 1.2), zc]) rotate([90, 0, 0]) cylinder(d = 5.4, h = 10, center = true);
        }
    }
    translate([hub_half - 2.5, 0, -1]) cylinder(d = pin_hole, h = hub_h + 2);
    }
}

/* CAMERA CRADLE - camera clicks in from the top between two flexing walls
   with retaining lips; trunnions snap into the cheeks.  Local frame: pivot
   at origin, lens toward +X.  Print floor-down. */
module camera_cradle() {
    d = 16; h = cam_w + 3.2; // grip depth, wall height
    difference() {
        union() {
            translate([-d/2, -cam_w/2 - cam_wall, -cam_w/2 - 2]) cube([d, cam_w + 2*cam_wall, 2]);     // floor
            for (s = [-1, 1]) translate([-d/2, s*(cam_w/2 + cam_wall/2) - cam_wall/2, -cam_w/2 - 2])
                cube([d, cam_wall, h]);
            for (s = [-1, 1]) translate([0, s*(cam_w/2 + cam_wall), 0]) rotate([s*-90, 0, 0])
                cylinder(d1 = 5.0, d2 = 4.2, h = 3.2);                                                   // trunnions
            // retaining lips over the camera's top edges
            for (s = [-1, 1]) translate([-d/2, s > 0 ? cam_w/2 - 1 : -cam_w/2, cam_w/2 + 0.1]) cube([d, 1, 1]);
        }
        translate([-d/2 - 1, -4, -cam_w/2 - 3]) cube([d + 2, 8, 3]);   // cable / weight slot in floor
    }
}

/* =====================================================================
   GPS MAST - snap-fit tenon into the hub top socket.
   Local frame: base pad bottom at z = 0 (sits on the hub top skin).
   ===================================================================== */
module gps_mast() {
    mast_h = 70;
    difference() {
        union() {
            translate([-8, -8, 0]) cube([16, 16, 4]);
            cylinder(r = 6, h = mast_h);
            translate([-14, -14, mast_h]) cube([28, 28, 2.5]);
            for (s = [-1, 1]) translate([-4, s*8, 4]) rotate([-s*35, -20, 0]) cylinder(r = 3.5, h = 24);
            // tenon prongs (two, split) with hooks under the skin
            for (s = [-1, 1]) translate([-5, s > 0 ? 1 : -5, -skin - 3]) cube([10, 4, skin + 3]);
            for (s = [-1, 1]) translate([-5, s*5, -skin - 0.2]) rotate([0, 90, 0])
                linear_extrude(10) polygon([[0, 0], [2.8, 0], [0.2, s*0.9]]);
        }
        translate([0, 0, 4]) cylinder(r = 3.5, h = mast_h - 6);
        for (s = [-1, 1]) translate([-4, s*8, 4]) rotate([-s*35, -20, 0]) translate([0, 0, -2]) cylinder(r = 1.9, h = 40);
        for (x = [-10, 10]) translate([x - 1.5, -9, mast_h - 1]) cube([3, 18, 5]);
    }
}

/* =====================================================================
   NON-PRINTED STAND-INS (for drawings / USDZ only)
   ===================================================================== */
module motor_model() {
    color("Silver") cylinder(d = 30, h = 4);
    color("Silver") translate([0, 0, 4]) cylinder(d = motor_d, h = motor_h - 4);
    color("DimGray") translate([0, 0, motor_h]) cylinder(d = 14, h = 6);
    color("Silver") translate([0, 0, motor_h]) cylinder(d = 4, h = 14);
}
module prop_model() {
    // two tapered, slightly pitched blades
    for (a = [0, 180]) rotate(a) hull() {
        translate([12, 0, 0]) rotate([12, 0, 0]) scale([1, 1, 0.25]) cylinder(d = 26, h = 4, center = true);
        translate([prop_d/2 - 12, 0, 0]) rotate([8, 0, 0]) scale([1, 1, 0.25]) cylinder(d = 12, h = 3, center = true);
    }
    cylinder(d = 18, h = 8, center = true);
}
module battery_model() {
    minkowski() { cube([pack_w - 6, pack_l - 6, pack_h - 6], center = true); sphere(r = 3, $fn = 16); }
}
module stack_model() {
    for (z = [0, 9.5]) translate([0, 0, z]) difference() {
        translate([-18, -18, 0]) cube([36, 36, 1.6]);
        for (x = [-1, 1]) for (y = [-1, 1]) translate([x*stack_sp/2, y*stack_sp/2, -1]) cylinder(d = 3, h = 4);
    }
}
module camera_model() {
    cube([18, cam_w - 0.2, cam_w - 0.2], center = true);
    translate([9, 0, 0]) rotate([0, 90, 0]) cylinder(d = 14, h = 7);
}

/* =====================================================================
   ASSEMBLY  (world: hub bottom at z = 0, front = +X)
   ===================================================================== */
tray_z = -(tray_t + tray_blk_h);             // tray plate bottom

module asm(name) {
    if (name == "hub") hub();
    if (name == "tubes") for (a = arm_angles) rotate(a)
        translate([sock_r0, 0, zc]) rotate([0, 90, 0]) cylinder(d = tube_od, h = R_motor - 10 - sock_r0);
    if (name == "motor_mounts") for (a = arm_angles) rotate(a) translate([R_motor, 0, zc]) motor_mount();
    if (name == "legs") for (a = arm_angles) rotate(a) translate([R_motor, 0, zc - sleeve_r]) leg();
    if (name == "motors") for (a = arm_angles) rotate(a) translate([R_motor, 0, zc + sleeve_r]) motor_model();
    if (name == "props") for (i = [0:3]) rotate(arm_angles[i]) translate([R_motor, 0, zc + sleeve_r + motor_h + 4])
        rotate(i * 37) prop_model();
    if (name == "pins") {
        for (a = arm_angles) rotate(a) translate([pin_r_hub, 0, hub_h]) mirror([0, 0, 1]) snap_pin_body(hub_h);
        for (a = arm_angles) rotate(a) translate([R_motor - 36, 0, zc + sleeve_r]) mirror([0, 0, 1]) snap_pin_body(2*sleeve_r);
        translate([hub_half - 2.5, 0, hub_h]) mirror([0, 0, 1]) snap_pin_body(hub_h);
    }
    if (name == "battery_tray") translate([0, 0, tray_z]) battery_tray();
    if (name == "battery") translate([0, 0, tray_z - pack_h/2]) battery_model();
    if (name == "camera_mount") camera_mount();
    if (name == "camera_cradle") translate([cam_pivot_x, 0, zc]) rotate([0, -cam_tilt, 0]) camera_cradle();
    if (name == "camera") translate([cam_pivot_x, 0, zc]) rotate([0, -cam_tilt, 0]) camera_model();
    if (name == "gps_mast") translate([gps_pos[0], gps_pos[1], hub_h]) gps_mast();
    if (name == "gps") translate([gps_pos[0], gps_pos[1], hub_h + 76.5]) cube([25, 25, 8], center = true);
    if (name == "stack") translate([0, 0, hub_h + 3]) stack_model();
    if (name == "stack_pegs") for (x = [-1, 1]) for (y = [-1, 1])
        translate([x*stack_sp/2, y*stack_sp/2, hub_h - skin]) stack_peg_body();
    if (name == "vtx") translate([-26, -44, hub_h]) cube([30, 30, 8]);
}

asm_items = [
    ["hub", "DimGray"], ["tubes", "Black"], ["motor_mounts", "SlateGray"], ["legs", "SlateGray"],
    ["motors", "Silver"], ["props", "SkyBlue"], ["pins", "Orange"], ["battery_tray", "SlateGray"],
    ["battery", "RoyalBlue"], ["camera_mount", "SlateGray"], ["camera_cradle", "SlateGray"],
    ["camera", "Black"], ["gps_mast", "SlateGray"], ["gps", "DarkGreen"], ["stack", "Green"],
    ["stack_pegs", "Orange"], ["vtx", "Firebrick"]
];
module assembly() { for (it = asm_items) color(it[1]) asm(it[0]); }

/* ---------------- part selector (print orientation) ---------------- */
module print_part(p) {
    if      (p == "hub")           translate([0, 0, hub_h]) mirror([0, 0, 1]) hub();
    else if (p == "motor_mount")   translate([0, 0, sleeve_r]) motor_mount();
    else if (p == "leg")           translate([0, 0, leg_len]) leg();
    else if (p == "battery_tray")  battery_tray();
    else if (p == "camera_mount")  translate([0, 0, -(hub_half - 4.8)]) rotate([0, -90, 0]) camera_mount();
    else if (p == "camera_cradle") translate([0, 0, cam_w/2 + 2]) camera_cradle();
    else if (p == "gps_mast")      translate([0, 0, skin + 3]) gps_mast();
    else if (p == "pin_hub")       translate([0, 0, (pin_d - 0.6)/2]) rotate([90, 0, 0]) snap_pin_body(hub_h);
    else if (p == "pin_mount")     translate([0, 0, (pin_d - 0.6)/2]) rotate([90, 0, 0]) snap_pin_body(2*sleeve_r);
    else if (p == "stack_peg")     translate([0, 0, 1.2]) rotate([90, 0, 0]) stack_peg_body();
    else if (p == "stack_spacer")  stack_spacer();
    else if (len(p) > 4 && p[0] == "a" && p[1] == "s" && p[2] == "m" && p[3] == ":")
    asm(chr([for (i = [4:len(p) - 1]) ord(p[i])]));
    else                              assembly();
}

print_part(part);
