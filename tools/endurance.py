"""Hover-endurance estimate for the LongHaul-520 quad.

Run:  python3 tools/endurance.py
Edit the numbers below if you change parts.  Masses are grams.

Model
  hover power (W)  = all-up weight (g) / hover efficiency (g/W)  + avionics power
  usable energy    = cells * cell Wh * usable fraction
  hover time (min) = usable energy / hover power * 60

The hover efficiency is the uncertain number.  Published data for 41xx
~380 KV motors with 13" carbon props on 6S gives roughly 10-11 g/W at
40-50 % thrust; 9.5 g/W is used as the baseline to allow for a budget
motor, prop adapters and ESC losses.  The script prints a range.
"""

AIRFRAME = {
    "printed parts incl. snap pins (PETG-CF, see tools/stl_stats.py)": 498,
    "4x carbon tube 16x12 mm, 219 mm long": 118,
    "4x Tarot 4108 380KV motors": 360,
    "4x 13 inch carbon props + adapters": 92,
    "FC + 4-in-1 ESC stack": 30,
    "Walksnail VTX + camera + antenna": 35,
    "ELRS receiver + antenna": 3,
    "GPS + compass module": 12,
    "power wiring, XT60, capacitor": 60,
    "motor screws (supplied with motors) + battery straps": 15,
}

CELL = {"name": "Molicel P50B 21700", "mass_g": 70, "Wh": 18.0}   # 3.6 V x 5.0 Ah
PACK_OVERHEAD_G = {3: 65, 4: 80}       # nickel strip, wrap, leads, balance plug
USABLE_FRACTION = 0.85                  # land at ~3.3 V/cell under load, keeps reserve
AVIONICS_W = 8                          # FC, GPS, RX, Walksnail VTX (~6 W)
MAX_THRUST_PER_MOTOR_G = 1620           # Tarot 4108 380KV + 1355 prop, 6S (retailer spec)
EFFICIENCIES = [8.5, 9.5, 10.5, 11.5]   # g/W at hover
BASELINE_EFF = 9.5


def analyse(parallel):
    cells = 6 * parallel
    pack_mass = cells * CELL["mass_g"] + PACK_OVERHEAD_G[parallel]
    auw = sum(AIRFRAME.values()) + pack_mass
    energy = cells * CELL["Wh"] * USABLE_FRACTION
    print(f"\n=== 6S{parallel}P {CELL['name']} pack ({cells} cells) ===")
    print(f"pack mass            : {pack_mass:6.0f} g")
    print(f"all-up weight        : {auw:6.0f} g")
    print(f"nominal / usable     : {cells * CELL['Wh']:6.0f} Wh / {energy:.0f} Wh")
    print(f"thrust-to-weight     : {4 * MAX_THRUST_PER_MOTOR_G / auw:6.2f} : 1")
    print(f"hover thrust / motor : {auw / 4:6.0f} g ({auw / 4 / MAX_THRUST_PER_MOTOR_G:.0%} of max)")
    for eff in EFFICIENCIES:
        power = auw / eff + AVIONICS_W
        minutes = energy / power * 60
        amps = power / (6 * 3.6)
        tag = "  <- baseline" if eff == BASELINE_EFF else ""
        print(f"  {eff:4.1f} g/W : {power:5.0f} W, {amps:4.1f} A, hover {minutes:5.1f} min{tag}")


if __name__ == "__main__":
    print("Airframe without battery:", sum(AIRFRAME.values()), "g")
    for item, grams in AIRFRAME.items():
        print(f"  {grams:5d} g  {item}")
    analyse(3)
    analyse(4)
