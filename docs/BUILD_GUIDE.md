# LongHaul-520 build guide

Read it all once before you start. Section 4 (battery) is the only part that is
dangerous if done wrong.

## 1. Print the frame

| Part file (`stl/`) | Qty | Orientation | Notes |
|--------------------|-----|-------------|-------|
| `hub_bottom.stl`   | 1 | flat, saddles up | 164 × 164 mm, fits a 220 mm bed |
| `hub_top.stl`      | 1 | flat, saddles up | flipped over during assembly |
| `motor_mount.stl`  | 4 | motor pad up | tree supports under the round tube sleeve only |
| `leg.stl`          | 4 | flange on bed | |
| `battery_tray.stl` | 1 | flat, rails up | |
| `camera_mount.stl` | 1 | flat, cheeks up | |
| `gps_mast.stl`     | 1 | base on bed | supports for the antenna tubes |

**Settings (PETG-CF / ASA):** 0.4 mm hardened nozzle (needed for CF filaments),
0.2 mm layers, **4 walls**, 5 top/bottom layers, 40 % gyroid infill, 100 % infill
around holes is ideal (use a modifier, or 6 walls). Dry the filament first. CF and
PETG soak up moisture fast in Indian monsoon weather. Total ≈ 450 g of filament.

**Changing the design:** open `cad/longhaul_quad.scad` in OpenSCAD (free).
Everything is set at the top of the file: `tube_od`, `wheelbase`, `cam_w`,
`pack_l/pack_w`, `leg_len` and more. Then run `cad/export_all.sh`.

## 2. Prepare arms and motors

1. Cut the four carbon tubes to **212 mm** (fine hacksaw, wrapped in masking tape). Wear a mask and work outdoors.
   Carbon dust is harmful.
2. Dry-fit each tube into the hub saddle and the motor mount sleeve. It should be a firm push fit.
   If it is too tight, sand the print. If it is too loose, wrap one layer of tape.
3. **Pin each tube**: with the tube in the motor mount, drill through the 3.3 mm hole
   (36 mm behind the motor axis). Then put the tube in the hub sandwich and drill
   through the hub's tube-pin hole (70 mm from centre). The pins stop the arms
   twisting, so the motors stay level.
4. Melt two **M3 heat-set inserts** into the bottom of each motor mount (soldering iron at ~230 °C).
5. Bolt each motor to its mount (3 × M3 × 8 in the triangle slots). **Check the screws
   cannot touch the windings.** Spin the bell by hand.
6. Extend each motor's 3 wires with 16 AWG silicone wire so they reach about 60 mm past the
   inner end of the tube. Solder, heat-shrink, and stagger the joints so the bundle is slim.
   Pull the wires through the tube (use a string).

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

1. Lay `hub_bottom` on the bench, saddles up. Push the four arms into the grooves with
   the inner tube ends at the groove start. Feed the motor wires up through the wire holes.
2. Put `hub_top` on, saddles down. Bolt everything with **M3 × 30 + nylock nuts**:
   16 clamp bolts, 4 boss bolts and 4 tube pins. Tighten in a cross pattern until
   the tube cannot turn. **Don't crush the plates**: the 0.8 mm gap should almost close.
3. Bolt the legs under the motor mounts (M3 × 10 into the inserts).
4. Bolt `battery_tray` under the hub (4 × M3 × 12 + nuts), rails pointing down. Stick an
   anti-slip pad on it and thread the two battery straps through the slots.
5. Bolt `camera_mount` under the front of the hub (2 × M3 × 12). Fit the camera with its M2
   side screws at about **15–25° up-tilt**. This drone flies slowly, so it needs little tilt.
6. Bolt `gps_mast` to the rear of the top plate. Stick the GPS on top, **arrow forward**.
   Run the receiver's T-antenna through the two angled tubes.

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
* Mount the stack on the top plate with the supplied rubber grommets, **arrow forward**.
* Mount the Walksnail VTX on the top plate next to the stack (zip-tie slots). It needs
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
   hang level. Slide the battery forward or back in the straps to fix it.
4. Range-check the radio (ELRS power 100 mW at first) and set up the failsafe.
5. Bind the Walksnail VTX to the goggles. Set a channel/power legal in your area.

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
