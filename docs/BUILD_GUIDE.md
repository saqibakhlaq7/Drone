# LongHaul-520 build guide

Read it all once before you start. Section 4 (battery) is the only part that is
dangerous if done wrong.

## 1. Print the frame

**v2 is screwless.** The parts slide, twist or snap together. The only screws on
the whole drone are the 3 per motor that come in the motor box, because a spinning
motor has to be bolted down.

| Part file (`stl/`) | Qty | Print orientation (as exported) | Supports |
|--------------------|-----|---------------------------------|----------|
| `hub.stl`          | 1 | upside down: top face on the bed, dovetail rails up | none (bores are teardrop-shaped) |
| `motor_mount.stl`  | 4 | motor pad up | tree supports under the round sleeve only |
| `leg.stl`          | 4 | standing on its foot, bayonet plug up | none |
| `battery_tray.stl` | 1 | flat, grooves up | none |
| `camera_mount.stl` | 1 | standing on the dovetail tongue | none |
| `camera_cradle.stl`| 1 | floor down | none |
| `gps_mast.stl`     | 1 | snap tenon down | small supports under the antenna tubes |
| `pin_hub.stl`      | 5 | lying on its flat side | none |
| `pin_mount.stl`    | 4 | lying on its flat side | none |
| `stack_peg.stl`    | 4 | lying on its flat side | none |
| `stack_spacer.stl` | 4 | upright | none |

**Settings (PETG-CF / ASA):** 0.4 mm hardened nozzle (needed for CF filaments),
0.2 mm layers, **4 walls**, 5 top/bottom layers, 40 % gyroid infill. Print the
**pins, pegs and the camera cradle at 100 % infill**: they are the springs of the
joints. Dry the filament first. CF and PETG soak up moisture fast in monsoon
weather. Total ≈ 500 g of filament.

**Print a test fit first.** Printers differ. Print one `pin_hub`, one `leg` and the
`motor_mount`, then check the fits. If a joint is too tight, raise `fit`
(default 0.2 mm) or `tube_clear` at the top of `cad/longhaul_quad.scad`. If a snap
is too loose, lower them. Then re-export.

**Changing the design:** open `cad/longhaul_quad.scad` in OpenSCAD (free).
Everything is set at the top: `tube_od`, `wheelbase`, `cam_w`, `pack_l/pack_w`,
`leg_len`, `fit` and more. Then run `cad/export_all.sh` (STLs + images) and
`python3 tools/make_models.py` (DXF drawings + USDZ).

## 2. How the joints work

| Joint | Type | How to assemble | How to take apart |
|-------|------|-----------------|-------------------|
| Arm → hub | **slide-in socket + snap pin** | Slide the carbon tube into the hub socket until it stops, push `pin_hub` down through the pin hole until it clicks | Squeeze the two halves of the pin tip under the hub, push it out |
| Arm → motor mount | **slide-on sleeve + snap pin** | Slide the mount onto the tube end, push `pin_mount` through until it clicks | Same as above |
| Leg → motor mount | **bayonet twist-lock** | Line up the 2 lugs with the slots, push up, **twist 45° clockwise** (seen from below) | Twist back, pull down |
| Battery tray → hub | **dovetail slide + flexure latch** | Slide the tray onto the two rails under the hub from the left side (−Y). It clicks when it reaches the end stop | Press the thumb tab down and slide the tray out |
| Camera → cradle | **snap-in clip** | Press the camera down between the cradle walls until the lips click over it | Spread the walls |
| Cradle → camera mount | **snap trunnions** | Spread the cheeks slightly, let the trunnions drop into the holes. Tilt is held by friction | Spread the cheeks |
| Camera mount → hub | **dovetail slide + snap pin** | Slide the tongue sideways into the groove across the front face. Centre it, then push a `pin_hub` down through the hub's front pin hole | Pull the pin, slide out |
| GPS mast → hub | **snap-fit tenon** | Push the square tenon into the socket at the rear of the hub top until the hooks click | Squeeze the two prongs from inside the battery-lead hole, lift |
| FC/ESC stack → hub | **snap pegs + spacers** | Click 4 `stack_peg` into the top skin, drop on the ESC, 4 `stack_spacer`, then the FC with its rubber grommets. Press until the top barbs click | Squeeze each barb |

Snap pins and pegs are cheap (< 1 g). **Print spares and replace any pin that turns
white or loose.** Never re-use a cracked pin on the arms.

## 3. Assemble the frame

```
          FRONT (+X)  camera
             ▲
   M4 (CW)   │   M2 (CCW)       INAV / Betaflight motor numbers (props-in)
        ╲    │    ╱
         ╲ ┌───┐ ╱              ArduPilot numbers differently:
           │HUB│                  1 front-right CCW, 2 rear-left CCW,
         ╱ └───┘ ╲                3 front-left CW,   4 rear-right CW
        ╱    GPS  ╲             The motor-test screen of your firmware is the authority.
   M3 (CCW)      M1 (CW)
```

1. **Cut** the four carbon tubes to **219 mm** (fine hacksaw, wrapped in masking tape).
   Wear a mask and work outdoors. Carbon dust is harmful.
2. **Drill the pin holes in the tubes (4.3 mm).** Slide a tube fully into a hub socket
   and drill through the hub's pin hole (70 mm from the centre), using the printed hole
   as a guide. Then slide the motor mount onto the other end, flush against its stop,
   and drill through the mount's pin hole. **Check the motor pad is level with the hub
   top before you drill the second hole.** These pins stop the arms twisting.
3. **Motors:** fix each motor to its mount with the **3 screws supplied with the motor**
   (Tarot triangle slots). Check the screws cannot touch the windings, then spin the
   bell by hand.
4. **Wires:** extend each motor's 3 wires with 16 AWG silicone wire so they reach about 60 mm
   past the inner end of the tube. Solder, heat-shrink, and stagger the joints so the
   bundle is slim. Feed them down the centre hole of the mount, through the tube, and up
   out of the hub's wire hole.
5. **Arms:** slide each tube into the hub, motor end out, and click in the 8 snap pins
   (4 hub, 4 mounts).
6. **Legs:** bayonet each leg into a motor mount (push, twist 45°).
7. **Stack:** click the 4 pegs into the hub top, then ESC → spacers → FC (arrow forward).
8. **GPS mast:** click it into the rear socket. Stick the GPS on top, **arrow forward**.
   Run the receiver's T-antenna through the two angled tubes.
9. **Camera:** click the camera into the cradle, snap the cradle into the mount, slide the
   mount into the front dovetail and lock it with a pin. Set the tilt to about **15–25° up**.
   This drone flies slowly, so it needs little tilt.
10. **Battery:** strap the pack to the tray (2 straps through the slots, anti-slip pad
    between them). Then slide the tray onto the hub rails until it clicks. Battery swaps
    take seconds: press the tab, slide out, slide a fresh pack in.

## 4. Build the 6S4P battery

> ⚠️ **Li-ion cells can burn violently.** Work on a non-flammable surface. Keep a
> metal bucket of sand nearby. Wear safety glasses. Never solder onto cells.
> Use a spot welder only. If you are not confident, ask a local e-bike/power-bank
> pack builder to make the pack from your cells. The layout below is all they need.

**Layout:** 24 × Molicel P50B, upright, 6 groups × 4 cells in parallel = 6S4P.
**Size:** about 129 × 86 × 70 mm (fits the tray: `pack_l = 132`, `pack_w = 90`).
**Nominal:** 21.6 V, 20 Ah, 432 Wh. Full = 25.2 V, empty (landed) ≈ 19.8 V.

1. **Check every cell** with a multimeter. Use only cells within **0.05 V** of each other
   (ideally all at ~3.6 V from the factory). Reject any dented or used-looking cells.
   Fake "Molicel" cells exist. A genuine P50B weighs about 70 g.
2. Stick an insulator ring on every + terminal.
3. Put the cells in the spacer brackets as a **6 × 4 grid**. Each *row of 4* is one
   parallel group. Alternate the orientation row by row (row 1 + up, row 2 − up, …)
   so the series links are short.
4. Spot-weld the **parallel strips** across each row. Then weld the **series links**
   between rows: **one strip per cell, doubled (two layers)**, so 8 strip-layers
   per group link. Test-weld scrap first and do a pull test. A good weld tears the nickel.
5. Weld the **main leads** (12 AWG to an XT60) to the pack's − end and + end with
   nickel tabs, and solder only onto the tabs, never onto the cell.
6. Fit the **balance lead**: wire 1 (black) = pack −, then one wire to each group
   junction, wire 7 = pack +. **Check with a meter**: each step must read about 3.6 V,
   and the full lead about 21.6 V.
7. Barley-paper over the welds, Kapton tape, then heat-shrink. Hot-glue or tape the
   leads so they can't flex at the weld.
8. **First charge:** Li-ion mode, 4.20 V/cell, **max 8 A** (0.4 C), *balance* mode, inside
   the fire bag, while you stay with it.

**Storage:** store at 3.6–3.7 V/cell (the charger's "storage" mode). Keep it out of
the sun and never in a parked car.

## 5. Wiring

```
 Battery XT60 ──► 4-in-1 ESC (BAT +/−)  ── capacitor (included with stack) on the ESC pads
                     │  motor pads M1–M4  ◄── wires coming up from the arms
                     │  8-pin ribbon (supplied) ──► Flight controller
 Flight controller
   ├─ HD VTX plug ─────────► Walksnail VTX (power + MSP DisplayPort OSD)
   ├─ UART (RX/TX, 5V, G) ──► RadioMaster RP1 (CRSF)        RX→TX, TX→RX
   ├─ UART (RX/TX, 5V, G) ──► GPS                            RX→TX, TX→RX
   └─ SDA / SCL ───────────► GPS compass
```

* Which UART is which depends on the board revision. Use the pinout in the
  **SpeedyBee F405 V4 manual** that came with the stack. The receiver and the HD-VTX plug have
  their own labelled pads.
* Keep motor and battery wires **away from the GPS mast and compass**.
* Mount the stack on the printed snap pegs and spacers (with the FC's rubber grommets), **arrow forward**.
* Mount the Walksnail VTX on the hub top next to the stack (zip-tie slots). It needs
  airflow, so don't wrap it.
* Mount the VTX antenna on the rear, pointing up and back, clear of the carbon.

## 6. Firmware: ArduPilot (recommended) or INAV

**Why ArduPilot:** a 13" home-built frame is very different from stock settings.
ArduPilot's **AutoTune** works out the PIDs for you. It also has the best GPS
position-hold, return-to-launch and battery failsafes for long flights. It supports the
SpeedyBee F405 V4 (`SpeedyBeeF405v4` target). Use **Mission Planner** (Windows) or
**QGroundControl**.

1. Flash **ArduCopter** (stable) for `SpeedyBeeF405v4` from firmware.ardupilot.org
   (DFU mode: hold BOOT while plugging in USB).
2. Mission Planner → *Initial Setup → Mandatory Hardware*: frame **Quad / X**, calibrate
   accelerometer, compass (outdoors, away from metal), radio, ESCs.
3. *Config → Initial Tune Parameters*: prop size **13**, battery cells **6**, cell max **4.2**,
   cell min **3.0**. It sets safe starting gains and filters.
4. Key parameters:

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `MOT_PWM_TYPE` | 5 | DShot300 (BLHeli_S ESC) |
| `SERIALx_PROTOCOL` (receiver UART) | 23 | RC input (ELRS/CRSF). Also set `RSSI_TYPE` = 3 |
| `SERIALx_PROTOCOL` (GPS UART) | 5 | GPS |
| `SERIALx_PROTOCOL` (HD VTX UART) + `OSD_TYPE` | 42 + 5 | Walksnail OSD (MSP DisplayPort) |
| `BATT_MONITOR` | 4 | voltage + current sensor on the ESC |
| `BATT_CAPACITY` | 20000 | mAh (6S4P) |
| `BATT_LOW_VOLT` / `BATT_FS_LOW_ACT` | 19.8 / 2 | 3.3 V/cell → return home |
| `BATT_CRT_VOLT` / `BATT_FS_CRT_ACT` | 19.2 / 1 | 3.2 V/cell → land now |
| `BATT_LOW_MAH` | 3000 | also return home when 3 Ah is left |
| `MOT_BAT_VOLT_MAX` / `MOT_BAT_VOLT_MIN` | 25.2 / 18.0 | Li-ion voltage scaling |
| `FS_THR_ENABLE` | 1 | radio lost → return to launch |
| `RTL_ALT` | 3000 | cm, return height 30 m (set it higher than nearby trees/buildings) |
| `FENCE_ENABLE`, `FENCE_RADIUS` | 1, 500 | safety cylinder |

5. Set the voltage and current scale: measure the pack with a meter and adjust `BATT_VOLT_MULT`.
   Then fly 5 min and compare mAh charged vs mAh shown to adjust `BATT_AMP_PERVLT`.
6. Flight modes on a 3-position switch: **Stabilize / Loiter / RTL**. AltHold is useful too.

**INAV alternative (easier menus, FPV-style):** flash INAV `SPEEDYBEEF405V4`. Set the
mixer to Quad X, receiver CRSF, GPS + compass, OSD type *AVATAR* (Walksnail).
Set battery cell min 3.0 V / warning 3.3 V / max 4.2 V and capacity 20000 mAh.
Set failsafe to RTH. You will have to tune PIDs by hand (lower P and D than the defaults
for 13" props) using blackbox logs.

**ESC:** the stock BLHeli_S firmware works. If the motors stutter at start-up
on the big props, flash **Bluejay** (esc-configurator.com) and raise
"startup power".

## 7. Before the first flight

1. **Props off.** Check the motor order and spin direction in the firmware's motor test.
   Swap any two wires of a motor to reverse it.
2. Balance all props on the balancer (big props + vibration = jello in the video).
3. Check the centre of gravity: lift the drone by two fingers under the hub centre. It should
   hang level. Slide the pack forward or back under its straps to fix it.
4. Pull hard on each arm, leg and the tray. Nothing may move. Replace any loose pin.
5. Range-check the radio (ELRS power 100 mW at first) and set up the failsafe.
6. Bind the Walksnail VTX to the goggles. Set a channel/power legal in your area.

## 8. First flights

1. Open field, calm wind, **Stabilize** mode, 2 m hover. Watch for wobble/oscillation.
2. Run **AutoTune** (ArduPilot): hover in AltHold, switch AutoTune on, and let it
   finish each axis (5–10 min). Land and disarm *in AutoTune* to save the gains.
3. Check GPS: **Loiter** should hold within ~1 m. Test **RTL** from 50 m away.
4. **Endurance test:** start with 20 min, land, measure pack voltage and mAh used.
   Increase flight time step by step, and land at ~3.3 V/cell under load.

**Expected flight time (calm air, hover, 6S4P):** about 62–76 min (69 min baseline).
Slow cruising at 5–8 m/s is about as efficient as hovering. Wind, climbing, cold weather and
a 3P pack all reduce it. See [`tools/endurance.py`](../tools/endurance.py).

## 9. Legal (India)

* At ~3 kg take-off weight this is a **"small" drone (2–25 kg)** under the Drone Rules, 2021.
  Register it on **DigitalSky** (digitalsky.dgca.gov.in) to get a UIN. A **Remote Pilot
  Certificate** is needed for this class.
* Check the **DigitalSky airspace map** before every flight. Fly only in **green zones**.
  Yellow and red zones need permission. Stay below 400 ft (120 m) and in line of sight.
* Use radio and video channels and powers allowed under WPC rules.
* Rules change. Check the current DGCA rules before flying.
