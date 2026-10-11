# Parts list: everything from Amazon India

Every part below was found as an **amazon.in** listing in October 2026. Amazon India
listings change fast. Sellers swap, go out of stock, or change specs. So:

* Click through and **check the spec line**, not just the title, before you buy.
* When a listing is gone, use the *search link* in the same row to find the same part from another seller.
* Prices marked "≈" come from Amazon.in search snapshots. They are only a guide.
  "check" means no reliable price was visible.

Quantities are for **one drone + 1 spare prop set**.

## 1. Flight hardware

| # | Part | Why this one | Qty | Amazon.in | ≈ Price |
|---|------|--------------|-----|-----------|---------|
| 1 | **Tarot 4108 380KV** multirotor motor (sold by IDUINO, Tarot-made) | A low-KV, large-stator motor is very efficient on 13" props. 90 g, up to 1.62 kg thrust each on 6S | 4 | [B0DQHPYGKH](https://www.amazon.in/IDUINO-4108-Multi-Rotor-Multicopter-Quadcopter/dp/B0DQHPYGKH) · [search](https://www.amazon.in/s?k=4108+380KV+motor) | ₹3,299 each |
| 2 | **13" carbon-fibre props 1355** (CW+CCW pair) | Big, slow props are what make 60+ min possible | 3 pairs (1 spare) | [B07WTWQ961](https://www.amazon.in/ELECTROPRIME-High-end-Carbon-Fiber-Propeller/dp/B07WTWQ961) · [search](https://www.amazon.in/s?k=1355+carbon+propeller) | check |
| 2b | *Alt:* 12" HD Propellers 1238 carbon-nylon pair | Cheaper and tougher, about 5–8 % less flight time | 3 pairs | [B0C1XBMSC5](https://www.amazon.in/Propellers-12X3-8-Carbon-Nylon-1CCW-1pair/dp/B0C1XBMSC5) | check |
| 3 | **Carbon-fibre tube 16 × 12 × 500 mm** (2-pack) | Arms. Each 500 mm tube gives two 212 mm arms | 2 packs (4 tubes) | [B0DDFRQQ87](https://www.amazon.in/Quadcopter-Hexacopter-Landing-Multicopter-16X12X500mm/dp/B0DDFRQQ87) · [search](https://www.amazon.in/s?k=16mm+carbon+fiber+tube+500mm) | check |
| 3b | *Alt:* ARRIS 18 mm OD × 16 mm ID × 500 mm tube (2-pack) | If you use this one, set `tube_od = 18` in the CAD file and re-export | 2 packs | [B00RX7TVVW](https://www.amazon.in/ARRIS-Wrapped-Carbon-Glossy-Surface/dp/B00RX7TVVW) | check |
| 4 | **SpeedyBee F405 V4 stack** (F405 FC + 55A 4-in-1 ESC, 30×30) | 3–6S, has a barometer, Bluetooth setup, an HD-VTX plug and blackbox. Runs ArduPilot and INAV | 1 | [B0CL3ZCWJW](https://www.amazon.in/SPEEDY-BEE-F405-V4-Controller/dp/B0CL3ZCWJW) · [search](https://www.amazon.in/s?k=speedybee+f405+v4+stack) | check |
| 4b | *Alt:* SpeedyBee F405 V3 BLS 50A stack | Same mounting, works just as well | 1 | [B0CW6GWHVY](https://www.amazon.in/REES52-SpeedyBee-F405-30x30-Stack/dp/B0CW6GWHVY) | check |
| 5 | **GPS + compass, M10 chip** (HGLRC M100-5883) | Needed for position hold, return-to-home and failsafe | 1 | [B0CB5N8RQ8](https://www.amazon.in/HGLRC-M100-5883-GPS-Generation-Compatible/dp/B0CB5N8RQ8) · alt [Holybro M10](https://www.amazon.in/Holybro-Module-u-blox-JST-GH-Compass/dp/B0GWJGD842) | check |

## 2. Remote control (radio link)

| # | Part | Why | Qty | Amazon.in | ≈ Price |
|---|------|-----|-----|-----------|---------|
| 6 | **RadioMaster Pocket ELRS** (Mode 2) transmitter | ExpressLRS 2.4 GHz gives long range and telemetry. EdgeTX, hall gimbals, small | 1 | [B0CG93QM4T](https://www.amazon.in/Radiomaster-Transmitter-Portable-Lightweight-Antenna%EF%BC%88Black/dp/B0CG93QM4T) · [B0FG2VRMVW](https://www.amazon.in/Radiomaster-Pocket-Controller-Transmitter-Helicopter/dp/B0FG2VRMVW) | ≈ ₹15,756 |
| 6b | *Alt (bigger hands):* RadioMaster Zorro ELRS / TX12 MKII ELRS | Same ELRS system, full-size body | 1 | [Zorro](https://www.amazon.in/Radiomaster-Controller-Remote-2-4GHz-Transmitter/dp/B0GC536Q4B) · [TX12 MKII](https://www.amazon.in/Radiomaster-TX12-MKII-Multi-Module-Transmitter/dp/B0DXZNBZCH) | ≈ ₹22,000 |
| 7 | **RadioMaster RP1 V2 ELRS receiver** (T-antenna) | Small, 2.4 GHz, full telemetry | 1 | [B0GCCZNNKX](https://www.amazon.in/Radiomaster-ExpressLRS-Receiver-Telemetry-T-Antenna/dp/B0GCCZNNKX) · [search](https://www.amazon.in/s?k=radiomaster+rp1+elrs) | check |
| 8 | 18650 Li-ion cells for the Pocket radio | The radio takes 2 × 18650 (not included) | 2 | [search](https://www.amazon.in/s?k=18650+3000mAh+li-ion+cell) | check |

## 3. Video: "good video feed"

**Recommended: Walksnail Avatar HD (digital, 1080p).** It shows a sharp, low-latency HD
image in the goggles. It also records 1080p onboard and works with ArduPilot/INAV
on-screen display (OSD).

| # | Part | Why | Qty | Amazon.in | ≈ Price |
|---|------|-----|-----|-----------|---------|
| 9 | **Walksnail Avatar HD Pro Kit** (VTX + camera, 32 GB onboard recording) | 1080p, up to 4 km range, records onboard. The Starlight sensor is good in low light | 1 | [B0CD32V9X8](https://www.amazon.in/Walksnail-Avatar-120fps-Latency-Storage/dp/B0CD32V9X8) · [B0F3BWZZSY](https://www.amazon.in/CADDXFPV-Walksnail-Avatar-Pro-Kit/dp/B0F3BWZZSY) · [search](https://www.amazon.in/s?k=walksnail+avatar+hd+kit) | check |
| 10 | **Walksnail Avatar HD goggles** (4.5" 1080p with DVR, *or* Goggles X OLED) | Receiver and screen for the kit above | 1 | [4.5" goggles B0F3C6P5LV](https://www.amazon.in/CADDXFPV-Walksnail-4-5-Inch-Goggles-Tracking/dp/B0F3C6P5LV) · [Goggles X B0F2FGNMJ8](https://www.amazon.in/CADDXFPV-Walksnail-Avatar-FPV-Goggles/dp/B0F2FGNMJ8) | check |
| 9-alt | DJI O3 Air Unit (+ compatible DJI goggles) | Best image (4K recording), but more expensive and works only with DJI goggles. Check that the goggle listing names O3 compatibility | 1 | [B0BBQQWYG6](https://www.amazon.in/DJI-Air-Unit-Transmission-Module/dp/B0BBQQWYG6) | check |
| 9-budget | Analog: TX800 5.8 GHz VTX + any 19 mm FPV camera + SoloGood EV800D goggles | Cheapest option, but standard-definition picture | 1 | [TX800](https://www.amazon.in/TX800-5-8GHz-FPV-Video-Transmitter/dp/B0GPD48LGY) · [EV800D](https://www.amazon.in/SoloGood-EV800D-Goggles-800x480-Diversity/dp/B08ZXQW67F) | ≈ ₹4,499 VTX |

> The camera mount is made for **19–20 mm wide** cameras: Walksnail, DJI O3 and most
> analog cameras. Change `cam_w` in the CAD file if yours is different.

## 4. Battery: 6S4P Li-ion pack, built by you

A LiPo of the same weight gives only ~30 min. Li-ion 21700 cells hold about twice the energy per
gram, and that is what gets this drone past 1 hour. No ready-made 6S 21700 pack
of this size was on Amazon.in, so you build it. See the [Build guide](BUILD_GUIDE.md#4-build-the-6s4p-battery).

| # | Part | Why | Qty | Amazon.in | ≈ Price |
|---|------|-----|-----|-----------|---------|
| 11 | **Molicel P50B 21700** cell (5000 mAh, 60 A) | Best energy + current combination. 24 for the pack + 2 spare | 26 | [B0G7HV7F9G](https://www.amazon.in/Lipix-21700-Molicel-INR-21700-P50B-Battery/dp/B0G7HV7F9G) · [search](https://www.amazon.in/s?k=molicel+p50b+21700) | check |
| 12 | Pure-nickel strip 0.15 × 8 mm, 10 m roll | Cell links | 1 | [B0BNH2GPLR](https://www.amazon.in/Nickel-Strips-Battery-Welding-Soldering/dp/B0BNH2GPLR) | ≈ ₹3,000 |
| 13 | Portable battery spot welder (5000 W class, welds 0.15 mm) | Never solder directly onto cells | 1 | [amiciTools B0C23GYMWN](https://www.amazon.in/amiciTools-Spot-Machine-Portable-Spot-Welding/dp/B0C23GYMWN) · [Docreate B0BCTWYQC5](https://www.amazon.in/Docreate-Handheld-Portable-Adjustable-Soldering/dp/B0BCTWYQC5) | check |
| 14 | 21700 cell holder/spacer brackets | Hold the cells in a 6 × 4 grid | 1 pack | [Fielect B084V1SZQ7](https://www.amazon.in/Fielect-Battery-Brackets-Plastic-Lithium/dp/B084V1SZQ7) | check |
| 15 | 21700 insulator rings (fish paper) | Stop short circuits at the + terminal | 1 pack (40) | [B0F899Y6V1](https://www.amazon.in/AXY-Insulator-Adhesive-Electrical-Insulating/dp/B0F899Y6V1) | ≈ ₹140 |
| 16 | XT60 connectors with 12 AWG silicone wire | Pack main lead + FC lead | 1 set (3 pairs) | [B07QH249CR](https://www.amazon.in/Pairs-Female-Connector-Silicon-Battery/dp/B07QH249CR) | check |
| 17 | 6S balance lead (JST-XH 7-pin) | Lets the charger balance the cells | 2 | [search](https://www.amazon.in/s?k=6S+balance+lead+JST+XH+7+pin) | check |
| 18 | Kapton tape + large PVC heat-shrink (≥ 150 mm flat) + barley-paper sheet | Wrap the pack | 1 each | [search kapton](https://www.amazon.in/s?k=kapton+tape) · [search heat shrink](https://www.amazon.in/s?k=pvc+heat+shrink+battery+wrap) | check |

## 5. Charging

| # | Part | Why | Qty | Amazon.in | ≈ Price |
|---|------|-----|-----|-----------|---------|
| 19 | **ISDT 608AC** (6S, 8 A, 200 W, built-in AC mains supply) | Plugs straight into the wall. Li-ion mode, balances 6S. Charges the 20 Ah pack in about 2.5–3 h | 1 | [B07YWLWVCW](https://www.amazon.in/ISDT-Battery-Charger-Balance-Discharger/dp/B07YWLWVCW) | ≈ ₹18,225 |
| 19b | *Budget:* SkyRC B6Neo + a 24 V / 10 A DC power supply | DC-only charger, so it needs the separate PSU | 1 | [B0CCT2WGNS](https://www.amazon.in/SKYRC-B6Neo-Balance-Battery-Discharger/dp/B0CCT2WGNS) · [PSU search](https://www.amazon.in/s?k=24V+10A+SMPS+power+supply) | ≈ ₹6,548 + PSU |
| 20 | LiPo-safe fire-resistant bag | Charge and store the pack inside it | 1 | [search](https://www.amazon.in/s?k=lipo+safe+bag) | check |

## 6. Printing & hardware

| # | Part | Why | Qty | Amazon.in | ≈ Price |
|---|------|-----|-----|-----------|---------|
| 21 | **PETG-CF filament** 1.75 mm, 1 kg (needs a hardened nozzle) | Stiff, heat-resistant, light. The frame uses about 450 g | 1 kg | [IEMAI B09XPXD1XD](https://www.amazon.in/IEMAI-Reinforced-Resistance-Industrial-Functional/dp/B09XPXD1XD) | ≈ ₹4,433 |
| 21b | *Alt:* Polymaker ASA (brass nozzle OK, enclosure recommended) or plain PETG | ASA survives Indian summer heat. **Do not use PLA**, which softens in a hot car | 1 kg | [ASA B09DKN3S9J](https://www.amazon.in/Polymaker-Filament-Resistant-Weather-Cardboard/dp/B09DKN3S9J) · [PETG search](https://www.amazon.in/s?k=petg+filament+1.75mm) | ≈ ₹4,780 |
| 22 | M3 brass heat-set inserts (M3 × 5 mm) | Motor-mount legs | 1 pack | [B0CH32W3W5](https://www.amazon.in/Threaded-Inserts-Embedment-Printing-Automotive/dp/B0CH32W3W5) | check |
| 23 | M3 socket-head screw kit (stainless) incl. nylock nuts & washers | General assembly | 1 kit | [OnlyScrews M3/M4 kit](https://www.amazon.in/s?k=OnlyScrews+M3+M4+3D+printer+screw+assortment) | ≈ ₹2,240 |
| 24 | **M3 × 30 mm** socket-head screws + M3 nylock nuts | 28 needed: 16 arm clamps, 4 spacer bosses, 4 hub tube pins, 4 motor-mount tube pins | 40 + 40 | [search](https://www.amazon.in/s?k=M3+x+30mm+socket+head+screw+stainless) | check |
| 25 | M3 × 8 mm (motors, 12 pcs) and M3 × 10–12 mm screws + nuts (legs 8, battery tray 4, camera mount 2, GPS mast 2) | Small fixings | 15 + 20 | (in kit #23) | |
| 26 | Battery straps, 20–25 mm × 300 mm, rubberised | Hold the pack | 2 (+1 spare) | [search](https://www.amazon.in/s?k=lipo+battery+strap+20mm+300mm) | check |
| 27 | Anti-slip silicone/foam pad (2–3 mm) | Under the battery and the stack | 1 | [search](https://www.amazon.in/s?k=anti+slip+silicone+pad+sheet) | check |
| 28 | Zip ties (small), 3 mm heat-shrink, double-sided foam tape | Wiring | 1 each | [search](https://www.amazon.in/s?k=zip+ties+small) | check |
| 29 | 16 AWG silicone wire, red/black 1 m | Extending motor leads through the arms | 1 m each | [search](https://www.amazon.in/s?k=16+AWG+silicone+wire) | check |

## 7. Tools (if you don't have them)

Soldering iron (60 W+, e.g. TS101 or similar), multimeter, hex driver set (1.5/2/2.5 mm),
drill + 3.3 mm bit (to pin the carbon tubes; wear a mask), a prop balancer, and
a USB-C cable to set up the flight controller.

## Rough budget

| Block | ≈ ₹ |
|-------|-----|
| Motors, props, tubes, stack, GPS | 25,000 – 32,000 |
| Radio + receiver | 17,000 – 24,000 |
| Walksnail kit + goggles | 45,000 – 70,000 (analog: 10,000 – 15,000) |
| 26 cells + pack materials + welder | 25,000 – 35,000 |
| Charger | 9,000 – 19,000 |
| Filament + hardware | 6,000 – 9,000 |
| **Total** | **≈ ₹1.3 – 1.9 lakh** (≈ ₹75k–1 lakh with analog video) |

These figures are estimates. Re-price them when you order.
