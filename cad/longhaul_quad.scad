// =====================================================================
//  LongHaul-520 : 3D-printable 1-hour camera quadcopter frame
//  Parametric OpenSCAD source.  All dimensions in millimetres.
//
//  Render one part:   openscad -D 'part="hub_bottom"' -o hub_bottom.stl longhaul_quad.scad
//  Parts: hub_bottom, hub_top, motor_mount, leg, battery_tray,
//         camera_mount, gps_mast, assembly (preview only)
//
//  Frame concept
//   - Two identical-ish printed hub plates sandwich four 16 mm carbon-fibre
//     tubes (arms).  Bolts beside each tube squeeze the plates together.
//   - A printed motor mount slides onto the outer end of every tube.
//   - A printed landing leg bolts under each motor mount.
//   - The 6S Li-ion pack hangs under the hub on a printed tray with straps.
//   - Front: tiltable camera mount.  Rear: GPS / compass mast.
//   - Motor wires run INSIDE the carbon tubes.
// =====================================================================

part = "assembly";

/* ---------------- main parameters ---------------- */
wheelbase    = 520;     // motor-to-motor diagonal (13" props -> 520 is the minimum)
tube_od      = 16;      // carbon tube outer diameter
tube_clear   = 0.2;     // radial clearance of grooves / sleeves
clamp_gap    = 0.8;     // gap left between the two hub saddles (lets bolts squeeze the tube)
plate_t      = 4;       // hub plate thickness
hub_half     = 62;      // half-width of the square hub body
saddle_r0    = 38;      // tube groove starts at this radius from centre
saddle_r1    = 100;     // tube groove ends at this radius
saddle_w     = tube_od + 16;
boss_r       = 42;      // radius of the 4 spacer bosses (on X/Y axes)

m3           = 3.4;     // M3 clearance hole
m2           = 2.3;     // M2 clearance hole
insert_d     = 4.2;     // hole for M3 brass heat-set insert (M3 x 5 x 4.6 OD typical)
stack_sp     = 30.5;    // FC / ESC stack hole spacing

// motor (defaults: Tarot 4108 380KV, 27 mm triangle mount, 46 mm bell)
motor_d      = 46;
motor_h      = 26;
pad_r        = 27;      // motor pad radius
pad_t        = 5;
sleeve_r     = tube_od/2 + 4;
mm_len       = 48;      // motor-mount sleeve length (behind motor axis)

prop_d       = 13 * 25.4;

// battery (6S4P 21700 upright = 6 x 4 cells -> 129 x 86 x 70)
pack_l       = 132;
pack_w       = 90;
pack_h       = 76;
tray_t       = 3;

// legs
leg_len      = 105;     // from bottom of motor mount to ground

// camera (Walksnail Avatar / DJI O3 style 19-20 mm wide body)
cam_w        = 19.2;
cam_tilt     = 20;      // only used in the assembly preview

arm_angles   = [45, 135, 225, 315];
R_motor      = wheelbase / 2;
zc           = plate_t + tube_od/2;     // tube centre height above bottom of hub
tube_r0      = saddle_r0;
tube_r1      = R_motor - 10;            // tube ends 10 mm before motor axis

$fn = 64;

/* ---------------- helpers ---------------- */
module rounded_square(size, r) {
    offset(r) square([size[0] - 2*r, size[1] - 2*r], center = true);
}

module slot2d(p0, p1, d) { hull() { translate(p0) circle(d = d); translate(p1) circle(d = d); } }

// positions of holes that go through BOTH hub plates (2D, in plate XY)
function clamp_holes() = [
    for (a = arm_angles) for (r = [52, 90]) for (s = [-1, 1])
        let(off = tube_od/2 + 4.5)
        [r*cos(a) - s*off*sin(a), r*sin(a) + s*off*cos(a)]
];
function tube_pin_holes() = [ for (a = arm_angles) [70*cos(a), 70*sin(a)] ];
function boss_holes()     = [ for (a = [0, 90, 180, 270]) [boss_r*cos(a), boss_r*sin(a)] ];
tray_holes   = [[18, 48], [18, -48], [-18, 48], [-18, -48]];
cam_holes    = [[hub_half - 7, 10], [hub_half - 7, -10]];
gps_holes    = [[-(hub_half - 9), 9], [-(hub_half - 9), -9]];
stack_holes  = [ for (x = [-1, 1]) for (y = [-1, 1]) [x*stack_sp/2, y*stack_sp/2] ];

/* =====================================================================
   HUB PLATE  (printed flat, saddles facing up; the top plate is the same
   part flipped over in the assembly, with a different hole set)
   ===================================================================== */
module hub_outline() {
    union() {
        rounded_square([2*hub_half, 2*hub_half], 10);
        for (a = arm_angles) rotate(a)
            translate([0, -saddle_w/2]) square([saddle_r1, saddle_w]);
    }
}

module hub_plate(top = false) {
    saddle_h = tube_od/2 - clamp_gap/2;
    difference() {
        union() {
            linear_extrude(plate_t) hub_outline();
            // tube saddles
            for (a = arm_angles) rotate(a)
                translate([saddle_r0, -saddle_w/2, plate_t])
                    cube([saddle_r1 - saddle_r0, saddle_w, saddle_h]);
            // spacer bosses
            for (p = boss_holes()) translate([p[0], p[1], plate_t])
                cylinder(r = 6, h = saddle_h);
            // stiffening ribs from bosses to saddles
            for (a = [0, 90, 180, 270]) rotate(a)
                translate([boss_r - 2, -hub_half + 6, plate_t]) cube([4, 2*hub_half - 12, 3]);
        }
        // tube grooves
        for (a = arm_angles) rotate(a)
            translate([saddle_r0 - 1, 0, zc]) rotate([0, 90, 0])
                cylinder(r = tube_od/2 + tube_clear, h = saddle_r1 - saddle_r0 + 2);
        // wire hole at the inner end of every tube (wires leave the tube here)
        for (a = arm_angles) rotate(a)
            translate([saddle_r0 - 7, 0, -1]) cylinder(d = 12, h = 40);
        // through-bolts
        for (p = concat(clamp_holes(), tube_pin_holes(), boss_holes()))
            translate([p[0], p[1], -1]) cylinder(d = m3, h = 40);
        if (!top) {
            for (p = concat(tray_holes, cam_holes))
                translate([p[0], p[1], -1]) cylinder(d = m3, h = 40);
            // weight-saving windows
            for (a = [0, 90, 180, 270]) rotate(a)
                translate([0, 0, -1]) linear_extrude(plate_t + 2)
                    polygon([[12, 8], [12, -8], [30, -18], [30, 18]]);
        } else {
            for (p = concat(stack_holes, gps_holes))
                translate([p[0], p[1], -1]) cylinder(d = m3, h = 40);
            // wire pass-throughs either side of the stack
            for (s = [-1, 1]) translate([0, s*26, -1])
                linear_extrude(plate_t + 2) rounded_square([24, 8], 3.9);
            // VTX / receiver zip-tie slots (rear-left / rear-right)
            for (s = [-1, 1]) for (dx = [-10, 10]) translate([-30 + dx, s*44, -1])
                linear_extrude(plate_t + 2) rounded_square([3, 6], 1.4);
            // label
            translate([20, -48, plate_t - 0.6]) linear_extrude(1)
                text("LongHaul-520", size = 5, halign = "center");
        }
    }
}

/* =====================================================================
   MOTOR MOUNT  (local frame: motor axis = Z through origin,
   tube along -X, tube centre at z = 0).  Print upright, pad on top.
   ===================================================================== */
module motor_mount() {
    difference() {
        union() {
            // tube sleeve
            translate([-mm_len, 0, 0]) rotate([0, 90, 0]) cylinder(r = sleeve_r, h = mm_len);
            // motor pad + conical support
            hull() {
                translate([0, 0, sleeve_r - pad_t]) cylinder(r = pad_r, h = pad_t);
                translate([0, 0, -sleeve_r]) cylinder(r = 16, h = 4);
            }
        }
        // tube bore (stops 10 mm before motor axis)
        translate([-mm_len - 1, 0, 0]) rotate([0, 90, 0])
            cylinder(r = tube_od/2 + tube_clear, h = mm_len - 10 + 1);
        // wire tunnel from tube to motor
        translate([-12, 0, 0]) rotate([0, 90, 0]) cylinder(r = 5, h = 12);
        translate([0, 0, -5]) cylinder(r = 6.5, h = 40);
        // motor screw slots: Tarot 27 mm triangle + 25-34 mm cross patterns
        for (a = [90, 210, 330, 0, 180]) rotate(a)
            translate([0, 0, -20]) linear_extrude(60) slot2d([11, 0], [17.5, 0], m3);
        // M3 pin through tube (drill the carbon tube to match)
        translate([-36, 0, -30]) cylinder(d = m3, h = 60);
        // leg heat-set inserts in the flat bottom
        for (x = [-11, 11]) translate([x, 0, -sleeve_r - 1]) cylinder(d = insert_d, h = 7);
    }
}

/* =====================================================================
   LANDING LEG  (print with the flange on the bed)
   ===================================================================== */
module leg() {
    difference() {
        union() {
            hull() {   // flange
                for (x = [-11, 11]) translate([x, 0, 0]) cylinder(r = 5, h = 5);
            }
            cylinder(r1 = 8, r2 = 6, h = leg_len - 6);
            translate([0, 0, leg_len - 6]) sphere(r = 8);
        }
        for (x = [-11, 11]) translate([x, 0, -1]) cylinder(d = m3, h = 10);
        translate([0, 0, -1]) cylinder(r1 = 5.5, r2 = 3.5, h = leg_len - 12);   // hollow
        translate([0, 0, leg_len]) cylinder(r = 20, h = 20);                     // flat foot
    }
}

/* =====================================================================
   BATTERY TRAY  (print flat, rails up; bolts under hub, straps hold pack)
   ===================================================================== */
module battery_tray() {
    // pack is mounted sideways: long side (pack_l) along Y, so the camera
    // mount in front of the hub stays clear of the tray.
    L = pack_l + 18; W = pack_w + 8;
    difference() {
        union() {
            linear_extrude(tray_t) rounded_square([W, L], 6);
            for (s = [-1, 1]) translate([s*(pack_w/2 + 2) - 1.5, -L/2 + 6, 0]) cube([3, L - 12, tray_t + 8]);
        }
        for (p = tray_holes) translate([p[0], p[1], -1]) cylinder(d = m3, h = 20);
        // strap slots for 20-25 mm battery straps
        for (y = [-34, 34]) translate([0, y, -1])
            linear_extrude(tray_t + 20) rounded_square([27, 4.5], 2);
        // lightening
        for (y = [-14, 14]) translate([0, y, -1])
            linear_extrude(tray_t + 2) rounded_square([pack_w - 24, 20], 5);
        for (y = [-58, 58]) translate([0, y, -1])
            linear_extrude(tray_t + 2) rounded_square([pack_w - 56, 14], 4);
    }
}

/* =====================================================================
   CAMERA MOUNT  (bolts under the front of the bottom hub plate)
   Pivot holes take the camera's M2 side screws.
   ===================================================================== */
module camera_mount() {
    wall = 2.6; pivot_z = 14; pivot_x = 22;
    difference() {
        union() {
            translate([-5, -(cam_w/2 + wall), 0]) cube([pivot_x + 15, cam_w + 2*wall, 3]);
            for (s = [-1, 1]) translate([0, s*(cam_w/2 + wall/2), 0]) hull() {
                translate([pivot_x, 0, pivot_z]) rotate([90, 0, 0]) cylinder(r = 6, h = wall, center = true);
                translate([pivot_x - 10, -wall/2, 0]) cube([20, wall, 3]);
            }
        }
        for (p = cam_holes) translate([p[0] - (hub_half - 7), p[1], -1]) cylinder(d = m3, h = 10);
        translate([pivot_x, 0, pivot_z]) rotate([90, 0, 0]) cylinder(d = m2, h = 40, center = true);
    }
}

/* =====================================================================
   GPS MAST  (bolts to the rear of the top plate; keeps the compass
   ~70 mm away from power wiring).  Two coax tubes hold the ELRS antenna.
   ===================================================================== */
module gps_mast() {
    mast_h = 70;
    difference() {
        union() {
            translate([-8, -16, 0]) cube([20, 32, 4]);
            translate([0, 0, 0]) cylinder(r = 6, h = mast_h);
            translate([-14, -14, mast_h]) cube([28, 28, 2.5]);
            hull() { translate([-8, -2, 0]) cube([20, 4, 4]); translate([-2, -2, 30]) cube([4, 4, 1]); }
            // antenna coax tubes (V shape)
            for (s = [-1, 1]) translate([-6, s*12, 4]) rotate([-s*35, -20, 0]) cylinder(r = 3.5, h = 26);
        }
        for (y = [-9, 9]) translate([0, y, -1]) cylinder(d = m3, h = 3.5 + 1);
        for (y = [-9, 9]) translate([0, y, 3]) cylinder(d = 6.2, h = 10);   // screw-head clearance
        translate([0, 0, -1]) cylinder(r = 3.5, h = mast_h - 2);
        for (s = [-1, 1]) translate([-6, s*12, 4]) rotate([-s*35, -20, 0]) translate([0, 0, -2]) cylinder(r = 1.9, h = 40);
        // GPS strap slots
        for (x = [-10, 10]) translate([x - 1.5, -9, mast_h - 1]) cube([3, 18, 5]);
    }
}

/* =====================================================================
   ASSEMBLY PREVIEW (not for printing)
   ===================================================================== */
module assembly() {
    color("DimGray") hub_plate(false);
    color("DimGray") translate([0, 0, 2*zc]) mirror([0, 0, 1]) hub_plate(true);
    for (a = arm_angles) rotate(a) {
        color("Black") translate([tube_r0, 0, zc]) rotate([0, 90, 0]) cylinder(d = tube_od, h = tube_r1 - tube_r0);
        translate([R_motor, 0, zc]) {
            color("SlateGray") motor_mount();
            color("SlateGray") translate([0, 0, -sleeve_r]) mirror([0, 0, 1]) leg();
            color("Silver") translate([0, 0, sleeve_r]) cylinder(d = motor_d, h = motor_h);
            color("SkyBlue", 0.35) translate([0, 0, sleeve_r + motor_h + 4]) cylinder(d = prop_d, h = 1.5);
        }
    }
    color("SlateGray") translate([0, 0, 0]) mirror([0, 0, 1]) battery_tray();
    color("RoyalBlue") translate([0, 0, -tray_t - pack_h/2]) cube([pack_w, pack_l, pack_h], center = true);
    color("SlateGray") translate([hub_half - 7, 0, 0]) mirror([0, 0, 1]) camera_mount();
    color("Orange") translate([hub_half - 7 + 22, 0, -14]) rotate([0, cam_tilt, 0]) cube([cam_w, cam_w, cam_w], center = true);
    color("SlateGray") translate([-(hub_half - 9), 0, 2*zc]) gps_mast();
    color("DarkGreen") translate([-(hub_half - 9), 0, 2*zc + 72.5]) cube([25, 25, 8], center = true);
    color("Red") translate([0, 0, 2*zc]) translate([-18, -18, 0]) cube([36, 36, 20]);
}

/* ---------------- part selector ---------------- */
if      (part == "hub_bottom")   hub_plate(false);
else if (part == "hub_top")      hub_plate(true);
else if (part == "motor_mount")  translate([0, 0, sleeve_r]) motor_mount();
else if (part == "leg")          leg();
else if (part == "battery_tray") battery_tray();
else if (part == "camera_mount") camera_mount();
else if (part == "gps_mast")     gps_mast();
else                             assembly();
