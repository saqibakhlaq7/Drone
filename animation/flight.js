// LongHaul-520 take-off & landing animation.
// A small physics model flies the real CAD model (drone.glb):
//   vertical: thrust from per-motor RPM (T = k*rpm^2), motor lag, ground effect,
//             landing-gear spring contact, altitude PID following a min-jerk profile
//   horizontal: wind gusts + GPS position hold (tilt = commanded accel / g)
//   power: rotor power ~ rpm^3, Li-ion pack with internal resistance
// Open index.html through any web server; add ?record to drive it frame by frame.

import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { Sky } from 'three/addons/objects/Sky.js';

const RECORD = new URLSearchParams(location.search).has('record');
const DURATION = 33;

/* ------------------------------------------------------------------ */
/* deterministic helpers                                               */
/* ------------------------------------------------------------------ */
function mulberry32(a) {
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const lerp = (a, b, u) => a + (b - a) * u;
const smooth = (u) => { u = clamp(u, 0, 1); return u * u * (3 - 2 * u); };

// min-jerk segment: returns [position, velocity]
function minJerk(t, t0, T, p0, p1) {
  if (t <= t0) return [p0, 0];
  if (t >= t0 + T) return [p1, 0];
  const u = (t - t0) / T;
  const s = 10 * u ** 3 - 15 * u ** 4 + 6 * u ** 5;
  const ds = (30 * u ** 2 - 60 * u ** 3 + 30 * u ** 4) / T;
  return [p0 + (p1 - p0) * s, (p1 - p0) * ds];
}

/* ------------------------------------------------------------------ */
/* flight plan (seconds)                                               */
/* ------------------------------------------------------------------ */
const PLAN = {
  arm: 2.5,          // ESCs arm, motors spin up to idle
  takeoff: 5.0,      // climb 0 -> 1 m
  climb: 9.0,        // 1 -> 6 m
  hoverEnd: 19.0,    // position hold at 6 m (slow yaw)
  descent: 19.0,     // 6 -> 1.2 m
  final: 24.5,       // 1.2 m -> ground, slow
};
function altitudeSetpoint(t) {
  const segs = [
    [PLAN.takeoff, 2.6, 0.0, 1.0],
    [PLAN.climb, 5.0, 1.0, 6.0],
    [PLAN.descent, 5.2, 6.0, 1.2],
    [PLAN.final, 4.2, 1.2, -0.25],   // aim slightly below ground: firm touchdown
  ];
  let p = 0, v = 0;
  for (const [t0, T, p0, p1] of segs) {
    if (t >= t0) { [p, v] = minJerk(t, t0, T, p0, p1); }
  }
  return [p, v];
}
function yawSetpoint(t) { return minJerk(t, 12.5, 5.5, 0, THREE.MathUtils.degToRad(35))[0]; }

/* ------------------------------------------------------------------ */
/* vehicle constants                                                   */
/* ------------------------------------------------------------------ */
const G = 9.81;
const MASS = 2.98;                  // kg (6S4P build)
const RPM_MAX = 7800;               // loaded, 6S, 13" prop
const T_MAX = 1.62 * G;             // N per motor
const K_T = T_MAX / (RPM_MAX * RPM_MAX);
const RPM_IDLE = 1150;
const TAU_MOTOR = 0.06;             // s, spin-up time constant
const TAU_SPINDOWN = 0.9;           // s, free-wheel decay after disarm
const PROP_R = 0.165;               // m
const ROTOR_H = 0.164;              // prop plane above the feet
const FOOT_Y = 0.109;               // GLB origin above the feet
const HOVER_RPM = Math.sqrt(MASS * G / 4 / K_T);
const P_HOVER_MOTOR = MASS * 1000 / 9.5 / 4;            // W per motor at hover (9.5 g/W)
const C_POWER = P_HOVER_MOTOR / HOVER_RPM ** 3;
const AVIONICS_W = 8;
const BAT_OCV = 24.7, BAT_R = 0.022;                     // 6S4P P50B, nearly full

const MOTORS = [ // glTF frame: x fwd, y up, z = right; SCAD angle a -> (cos a, -sin a)
  { a: 45,  dir: -1 },   // front-left  CW
  { a: 135, dir: +1 },   // rear-left   CCW
  { a: 225, dir: -1 },   // rear-right  CW
  { a: 315, dir: +1 },   // front-right CCW
].map((m) => ({ ...m, x: 0.26 * Math.cos(m.a * Math.PI / 180), z: -0.26 * Math.sin(m.a * Math.PI / 180) }));

/* ------------------------------------------------------------------ */
/* simulation state                                                    */
/* ------------------------------------------------------------------ */
function newSim() {
  return {
    t: 0, y: -MASS * G / 6000, vy: 0,                 // feet height (m), settled on the legs
    px: 0, pz: 0, vx: 0, vz: 0, tx: 0, tz: 0,          // horizontal pos/vel, tilt (rad)
    yaw: 0, integ: 0,
    rpm: [0, 0, 0, 0], rpmTrim: [0, 0, 0, 0],
    armed: false, airborne: false, landed: false, landTimer: 0, disarmAt: Infinity,
    mode: 'DISARMED', power: 0, volts: BAT_OCV, amps: 0,
  };
}
let sim = newSim();
const DT = 1 / 480;

function wind(t) {
  return [
    0.9 * Math.sin(0.31 * t) + 0.5 * Math.sin(0.83 * t + 1.1) + 0.25 * Math.sin(2.3 * t + 0.4),
    0.7 * Math.sin(0.27 * t + 2.0) + 0.45 * Math.sin(0.97 * t + 0.3) + 0.2 * Math.sin(2.9 * t + 1.7),
  ];
}

function step(s) {
  const t = s.t;
  const h = Math.max(s.y + ROTOR_H, 0.05);
  const ge = 1 / Math.max(1 - (PROP_R / (4 * h)) ** 2, 0.85);        // ground effect
  const onGround = s.y <= 0.002;

  // --- arming / landing logic ---
  if (!s.armed && t >= PLAN.arm && t < PLAN.final) { s.armed = true; }
  if (s.armed && t > PLAN.final + 1 && onGround && Math.abs(s.vy) < 0.15) {
    s.landTimer += DT;
    if (s.landTimer > 0.6 && !s.landed) { s.landed = true; s.disarmAt = t + 1.2; }
  }
  if (t >= s.disarmAt) s.armed = false;

  // --- vertical controller ---
  const [zs, vs] = altitudeSetpoint(t);
  let rpmCmd = 0;
  const flying = s.armed && !s.landed && t >= PLAN.takeoff;
  if (flying) {
    const ez = zs - s.y, ev = vs - s.vy;
    s.integ = clamp(s.integ + ez * DT, -1.5, 1.5);
    const aCmd = 3.2 * ez + 3.0 * ev + 0.8 * s.integ;
    const tilt = Math.hypot(s.tx, s.tz);
    const Ttot = clamp(MASS * (G + aCmd) / (ge * Math.cos(tilt)), 0, 4 * T_MAX);
    rpmCmd = Math.max(Math.sqrt(Ttot / 4 / K_T), RPM_IDLE);
    s.mode = t < PLAN.climb ? 'TAKEOFF' : t < PLAN.hoverEnd ? (t < PLAN.climb + 5 ? 'CLIMB' : 'LOITER') : (t < PLAN.final ? 'DESCEND' : 'LAND');
  } else if (s.armed) {
    rpmCmd = RPM_IDLE * smooth((t - PLAN.arm) / 1.2);
    s.mode = s.landed ? 'LANDED' : 'ARMED';
  } else {
    s.mode = s.landed ? 'DISARMED' : (t < PLAN.arm ? 'DISARMED' : s.mode);
  }

  // --- motors (each with a little attitude-control trim noise) ---
  let Tsum = 0, P = 0;
  for (let i = 0; i < 4; i++) {
    const n = s.airborne ? 0.012 * Math.sin(7.1 * t + i * 1.7) + 0.008 * Math.sin(17.3 * t + i * 2.9) : 0;
    const target = rpmCmd * (1 + n);
    const tau = s.armed ? TAU_MOTOR : TAU_SPINDOWN;
    s.rpm[i] += (target - s.rpm[i]) * (DT / tau);
    if (s.rpm[i] < 1) s.rpm[i] = 0;
    Tsum += K_T * s.rpm[i] ** 2;
    P += C_POWER * s.rpm[i] ** 3;
  }
  s.power = P + AVIONICS_W;
  s.amps = s.power / s.volts;
  s.volts = BAT_OCV - BAT_R * s.amps - 0.00004 * t;

  // --- vertical dynamics with spring/damper landing gear ---
  const tilt = Math.hypot(s.tx, s.tz);
  let Fy = Tsum * ge * Math.cos(tilt) - MASS * G - 0.25 * s.vy * Math.abs(s.vy);
  if (s.y < 0) Fy += Math.max(-6000 * s.y - 160 * s.vy, 0);
  s.vy += (Fy / MASS) * DT;
  s.y += s.vy * DT;
  if (s.y > 0.03) s.airborne = true;

  // --- horizontal: wind + position hold ---
  if (s.y > 0.004) {
    const [wx, wz] = wind(t);
    const gust = clamp((s.y + 0.2) / 2.5, 0, 1);                     // less wind near the ground
    const fx = 0.38 * (wx * gust - s.vx), fz = 0.38 * (wz * gust - s.vz);
    const ax = (1.1 * (0 - s.px) + 1.9 * (0 - s.vx)) - fx / MASS * 0.6;
    const az = (1.1 * (0 - s.pz) + 1.9 * (0 - s.vz)) - fz / MASS * 0.6;
    const txCmd = clamp(ax / G, -0.25, 0.25), tzCmd = clamp(az / G, -0.25, 0.25);
    s.tx += (txCmd - s.tx) * (DT / 0.14);
    s.tz += (tzCmd - s.tz) * (DT / 0.14);
    s.vx += (G * Math.tan(s.tx) * (Tsum * ge / (MASS * G)) + fx / MASS) * DT;
    s.vz += (G * Math.tan(s.tz) * (Tsum * ge / (MASS * G)) + fz / MASS) * DT;
    s.px += s.vx * DT; s.pz += s.vz * DT;
  } else {
    s.vx *= 0.9; s.vz *= 0.9; s.tx *= 0.9; s.tz *= 0.9;
  }
  if (s.armed && t >= PLAN.takeoff) s.yaw += (yawSetpoint(t) - s.yaw) * (DT / 0.4);
  s.t += DT;
}
function advanceTo(t) { while (sim.t + DT <= t) step(sim); }

/* ------------------------------------------------------------------ */
/* scene                                                               */
/* ------------------------------------------------------------------ */
const renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: RECORD });
renderer.setPixelRatio(RECORD ? 1 : Math.min(devicePixelRatio, 2));
renderer.setSize(innerWidth, innerHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 0.55;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
document.body.prepend(renderer.domElement);

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(38, innerWidth / innerHeight, 0.1, 1500);
addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight; camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});

// sky + image-based lighting from the same sky
const sky = new Sky();
sky.scale.setScalar(450000);
const su = sky.material.uniforms;
su.turbidity.value = 5.5; su.rayleigh.value = 1.4; su.mieCoefficient.value = 0.004; su.mieDirectionalG.value = 0.8;
const sunDir = new THREE.Vector3().setFromSphericalCoords(1, THREE.MathUtils.degToRad(90 - 32), THREE.MathUtils.degToRad(215));
su.sunPosition.value.copy(sunDir);
scene.add(sky);
{
  const pmrem = new THREE.PMREMGenerator(renderer);
  const envScene = new THREE.Scene();
  const s2 = new Sky(); s2.scale.setScalar(450000); s2.material.uniforms.sunPosition.value.copy(sunDir);
  Object.assign(s2.material.uniforms.turbidity, { value: 5.5 });
  envScene.add(s2);
  scene.environment = pmrem.fromScene(envScene, 0.02).texture;
}
scene.fog = new THREE.Fog(0xbfd0dc, 70, 420);

const sun = new THREE.DirectionalLight(0xfff1dc, 2.6);
sun.position.copy(sunDir).multiplyScalar(30);
sun.castShadow = true;
sun.shadow.mapSize.set(2048, 2048);
Object.assign(sun.shadow.camera, { left: -5, right: 5, top: 5, bottom: -5, near: 1, far: 80 });
sun.shadow.bias = -0.0004; sun.shadow.normalBias = 0.02;
scene.add(sun, sun.target);
scene.add(new THREE.HemisphereLight(0xcfe3ff, 0x4a5a2a, 0.35));

// ground: procedural grass
function canvasTexture(size, draw, repeat) {
  const c = document.createElement('canvas'); c.width = c.height = size;
  draw(c.getContext('2d'), size);
  const tx = new THREE.CanvasTexture(c);
  tx.colorSpace = THREE.SRGBColorSpace;
  tx.wrapS = tx.wrapT = THREE.RepeatWrapping;
  tx.repeat.set(repeat, repeat);
  tx.anisotropy = renderer.capabilities.getMaxAnisotropy();
  return tx;
}
const rnd = mulberry32(1234);
const grass = canvasTexture(512, (g, n) => {
  g.fillStyle = '#56702f'; g.fillRect(0, 0, n, n);
  for (let i = 0; i < 900; i++) {               // soft patches
    g.fillStyle = `hsla(${78 + rnd() * 30},${30 + rnd() * 25}%,${22 + rnd() * 16}%,0.18)`;
    g.beginPath(); g.arc(rnd() * n, rnd() * n, 6 + rnd() * 28, 0, 7); g.fill();
  }
  for (let i = 0; i < 16000; i++) {             // blades
    const x = rnd() * n, y = rnd() * n, a = rnd() * Math.PI, l = 2 + rnd() * 6;
    g.strokeStyle = `hsl(${70 + rnd() * 35},${35 + rnd() * 30}%,${18 + rnd() * 30}%)`;
    g.lineWidth = 0.6 + rnd() * 0.8;
    g.beginPath(); g.moveTo(x, y); g.lineTo(x + Math.cos(a) * l, y - Math.sin(a) * l); g.stroke();
  }
}, 140);
const ground = new THREE.Mesh(new THREE.PlaneGeometry(1200, 1200),
  new THREE.MeshStandardMaterial({ map: grass, roughness: 1, metalness: 0 }));
ground.rotation.x = -Math.PI / 2; ground.receiveShadow = true;
scene.add(ground);

// landing pad
const pad = canvasTexture(1024, (g, n) => {
  g.fillStyle = '#8d8f8c'; g.fillRect(0, 0, n, n);
  for (let i = 0; i < 40000; i++) {
    const v = 120 + rnd() * 50; g.fillStyle = `rgba(${v},${v},${v - 4},0.35)`;
    g.fillRect(rnd() * n, rnd() * n, 1 + rnd() * 2, 1 + rnd() * 2);
  }
  g.strokeStyle = '#e8b631'; g.lineWidth = 34;
  g.beginPath(); g.arc(n / 2, n / 2, n * 0.42, 0, 7); g.stroke();
  g.fillStyle = '#f2f2ee'; g.font = `bold ${n * 0.5}px Helvetica, Arial, sans-serif`;
  g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillText('H', n / 2, n / 2 + n * 0.02);
  for (let i = 0; i < 300; i++) {                // tyre / dirt stains
    g.fillStyle = `rgba(60,55,45,${0.03 + rnd() * 0.05})`;
    g.beginPath(); g.arc(rnd() * n, rnd() * n, 4 + rnd() * 30, 0, 7); g.fill();
  }
}, 1);
const padMesh = new THREE.Mesh(new THREE.CircleGeometry(1.5, 96),
  new THREE.MeshStandardMaterial({ map: pad, roughness: 0.92, polygonOffset: true, polygonOffsetFactor: -4, polygonOffsetUnits: -4 }));
padMesh.rotation.x = -Math.PI / 2; padMesh.position.y = 0.006; padMesh.receiveShadow = true;
padMesh.material.map.rotation = Math.PI / 2; padMesh.material.map.center.set(0.5, 0.5);
scene.add(padMesh);

// tree line for depth
{
  const trunkGeo = new THREE.CylinderGeometry(0.12, 0.2, 1, 6);
  const leafGeo = new THREE.ConeGeometry(1, 1, 7);
  const trunks = new THREE.InstancedMesh(trunkGeo, new THREE.MeshStandardMaterial({ color: 0x4a3626, roughness: 1 }), 280);
  const leaves = new THREE.InstancedMesh(leafGeo, new THREE.MeshStandardMaterial({ color: 0x2d4a22, roughness: 0.95, flatShading: true }), 280);
  const m = new THREE.Matrix4(), q = new THREE.Quaternion(), c = new THREE.Color();
  for (let i = 0; i < 280; i++) {
    const ang = rnd() * Math.PI * 2, r = 48 + rnd() * 140;
    const x = Math.cos(ang) * r, z = Math.sin(ang) * r, h = 4 + rnd() * 6, w = 1.2 + rnd() * 1.6, th = 1.2 + rnd() * 1.5;
    m.compose(new THREE.Vector3(x, th / 2, z), q, new THREE.Vector3(1, th, 1)); trunks.setMatrixAt(i, m);
    m.compose(new THREE.Vector3(x, th + h / 2 - 0.3, z), q, new THREE.Vector3(w, h, w)); leaves.setMatrixAt(i, m);
    leaves.setColorAt(i, c.setHSL(0.25 + rnd() * 0.08, 0.35 + rnd() * 0.2, 0.18 + rnd() * 0.1));
  }
  scene.add(trunks, leaves);
}

/* ------------------------------------------------------------------ */
/* drone                                                               */
/* ------------------------------------------------------------------ */
const drone = new THREE.Group();
scene.add(drone);
const props = [];
const blurTex = canvasTexture(256, (g, n) => {
  const gr = g.createRadialGradient(n / 2, n / 2, n * 0.06, n / 2, n / 2, n / 2);
  gr.addColorStop(0, 'rgba(40,40,44,0.0)');
  gr.addColorStop(0.12, 'rgba(45,45,50,0.6)');
  gr.addColorStop(0.55, 'rgba(70,70,76,0.36)');
  gr.addColorStop(0.93, 'rgba(95,95,102,0.26)');
  gr.addColorStop(1, 'rgba(95,95,102,0)');
  g.fillStyle = gr; g.fillRect(0, 0, n, n);
  g.strokeStyle = 'rgba(200,200,205,0.10)'; g.lineWidth = 2;
  g.beginPath(); g.arc(n / 2, n / 2, n * 0.47, 0, 7); g.stroke();
}, 1);

const dust = (() => {
  const N = 900;
  const geo = new THREE.BufferGeometry();
  const pos = new Float32Array(N * 3), alpha = new Float32Array(N), size = new Float32Array(N);
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  geo.setAttribute('alpha', new THREE.BufferAttribute(alpha, 1));
  geo.setAttribute('size', new THREE.BufferAttribute(size, 1));
  const mat = new THREE.ShaderMaterial({
    transparent: true, depthWrite: false,
    uniforms: { color: { value: new THREE.Color(0xc8b994) }, scale: { value: innerHeight / 2 } },
    vertexShader: `attribute float alpha; attribute float size; varying float vA; uniform float scale;
      void main(){ vA=alpha; vec4 mv=modelViewMatrix*vec4(position,1.0); gl_PointSize=size*scale/-mv.z; gl_Position=projectionMatrix*mv; }`,
    fragmentShader: `uniform vec3 color; varying float vA;
      void main(){ float d=length(gl_PointCoord-0.5); if(d>0.5) discard; gl_FragColor=vec4(color, vA*smoothstep(0.5,0.0,d)); }`,
  });
  const pts = new THREE.Points(geo, mat);
  pts.frustumCulled = false;
  scene.add(pts);
  const P = Array.from({ length: N }, () => ({ life: 0, max: 1, x: 0, y: 0, z: 0, vx: 0, vy: 0, vz: 0, s: 0 }));
  const r = mulberry32(99);
  let cursor = 0, acc = 0;
  return {
    mat,
    update(dt, cx, cz, intensity) {
      acc += intensity * 420 * dt;
      while (acc >= 1) {
        acc -= 1;
        const p = P[cursor]; cursor = (cursor + 1) % N;
        const a = r() * Math.PI * 2, rad = 0.15 + r() * 0.4, sp = 1.2 + r() * 2.4;
        Object.assign(p, { life: 0, max: 1.2 + r() * 1.6, x: cx + Math.cos(a) * rad, y: 0.02, z: cz + Math.sin(a) * rad,
          vx: Math.cos(a) * sp, vy: 0.15 + r() * 0.6, vz: Math.sin(a) * sp, s: 0.08 + r() * 0.12 });
      }
      for (let i = 0; i < N; i++) {
        const p = P[i];
        if (p.life >= p.max) { alpha[i] = 0; continue; }
        p.life += dt;
        const drag = Math.exp(-1.6 * dt);
        p.vx *= drag; p.vz *= drag; p.vy = p.vy * drag - 0.15 * dt;
        p.x += p.vx * dt; p.y = Math.max(0.01, p.y + p.vy * dt); p.z += p.vz * dt;
        const u = p.life / p.max;
        pos[i * 3] = p.x; pos[i * 3 + 1] = p.y; pos[i * 3 + 2] = p.z;
        alpha[i] = 0.5 * Math.sin(Math.PI * Math.min(u * 1.4, 1)) * (1 - u);
        size[i] = p.s * (1 + 3.5 * u);
      }
      geo.attributes.position.needsUpdate = true; geo.attributes.alpha.needsUpdate = true; geo.attributes.size.needsUpdate = true;
    },
  };
})();

// realistic finishes: matte charcoal PETG-CF, glossy carbon tubes, metal motors
const FINISH = {
  hub: [0x2a2c30, 0.0, 0.72], motor_mounts: [0x2a2c30, 0.0, 0.72], legs: [0x2a2c30, 0.0, 0.72],
  battery_tray: [0x2a2c30, 0.0, 0.72], camera_mount: [0x2a2c30, 0.0, 0.72], camera_cradle: [0x2a2c30, 0.0, 0.72],
  gps_mast: [0x2a2c30, 0.0, 0.72], tubes: [0x0b0b0c, 0.3, 0.28], motors: [0xa7a9ad, 0.95, 0.32],
  pins: [0xe07b22, 0.0, 0.55], stack_pegs: [0xe07b22, 0.0, 0.55], battery: [0x1c3f9e, 0.0, 0.42],
  camera: [0x0d0d0e, 0.4, 0.3], gps: [0x1e2a1f, 0.0, 0.5], stack: [0x0f5c2c, 0.1, 0.45],
  vtx: [0x8f1d1d, 0.5, 0.35], prop: [0x121315, 0.25, 0.3],
};
async function loadDrone() {
  const gltf = await new GLTFLoader().loadAsync('./drone.glb');
  let propMesh = null;
  gltf.scene.traverse((o) => {
    if (!o.isMesh) return;
    o.castShadow = true; o.receiveShadow = true;
    const f = FINISH[o.name] || FINISH[o.parent?.name];
    if (f) o.material = new THREE.MeshStandardMaterial({ color: f[0], metalness: f[1], roughness: f[2] });
    if (o.name === 'prop' || o.parent?.name === 'prop') propMesh = o;
  });
  propMesh.removeFromParent();
  drone.add(gltf.scene);
  for (const m of MOTORS) {
    const hub = new THREE.Group();
    hub.position.set(m.x, 0.055, m.z);
    const blade = propMesh.clone();
    blade.material = propMesh.material.clone();
    blade.material.transparent = true;
    const disc = new THREE.Mesh(new THREE.CircleGeometry(PROP_R, 64),
      new THREE.MeshBasicMaterial({ map: blurTex, transparent: true, depthWrite: false, opacity: 0, side: THREE.DoubleSide }));
    disc.rotation.x = -Math.PI / 2; disc.position.y = 0.001;
    hub.add(blade, disc);
    drone.add(hub);
    props.push({ hub, blade, disc, dir: m.dir, angle: Math.random() * 6.28 });
  }
  props.forEach((p, i) => { p.angle = i * 0.65; });
}

/* ------------------------------------------------------------------ */
/* camera direction & HUD                                              */
/* ------------------------------------------------------------------ */
const camTarget = new THREE.Vector3(0, 0.1, 0);
const camFollowY = { v: 0 };
function keyed(t, keys) {           // keys: [[t, value], ...] smooth interpolation
  if (t <= keys[0][0]) return keys[0][1];
  for (let i = 1; i < keys.length; i++) {
    if (t <= keys[i][0]) {
      const [t0, v0] = keys[i - 1], [t1, v1] = keys[i];
      return lerp(v0, v1, smooth((t - t0) / (t1 - t0)));
    }
  }
  return keys[keys.length - 1][1];
}
function updateCamera(t, dt) {
  const dy = sim.y + FOOT_Y;
  camFollowY.v += (dy - camFollowY.v) * Math.min(1, dt * 1.6);
  camTarget.x += (sim.px - camTarget.x) * Math.min(1, dt * 2);
  camTarget.z += (sim.pz - camTarget.z) * Math.min(1, dt * 2);
  camTarget.y = camFollowY.v + 0.02;
  const ang = 0.55 + 0.034 * t;
  const dist = keyed(t, [[0, 2.5], [4, 2.2], [9, 3.6], [14, 4.6], [19, 4.2], [24, 3.2], [29, 2.4], [33, 2.3]]);
  const baseH = keyed(t, [[0, 0.32], [6, 0.45], [14, 1.6], [20, 1.4], [26, 0.5], [33, 0.35]]);
  const shake = 0.012 * Math.sin(1.7 * t) + 0.007 * Math.sin(3.9 * t + 1);
  camera.position.set(
    camTarget.x + Math.cos(ang) * dist,
    Math.max(0.18, baseH + 0.55 * camFollowY.v + shake),
    camTarget.z - Math.sin(ang) * dist);
  camera.lookAt(camTarget.x, camTarget.y + shake * 0.5, camTarget.z);
}

const $ = (id) => document.getElementById(id);
const captions = [
  [0, 'Pre-flight: GPS lock, 6S4P pack at 24.7 V'],
  [PLAN.arm, 'Arming: ESCs spin the 13" props up to idle'],
  [PLAN.takeoff, 'Take-off: gentle lift-off out of ground effect, hover check at 1 m'],
  [PLAN.climb, 'Climb to 6 m'],
  [PLAN.climb + 5, 'GPS position hold: wind gusts corrected by small tilts, slow yaw pan'],
  [PLAN.descent, 'Descent'],
  [PLAN.final, 'Final approach: slow down through ground effect'],
  [PLAN.final + 3.6, 'Touchdown: land detected, motors disarm and free-wheel to a stop'],
];
function updateHud(t) {
  const thr = (sim.rpm.reduce((a, b) => a + b) / 4) / RPM_MAX * 100;
  $('t-mode').textContent = sim.mode;
  $('t-alt').textContent = `${Math.max(0, sim.y).toFixed(2)} m`;
  $('t-vs').textContent = `${sim.vy >= 0 ? '+' : ''}${sim.vy.toFixed(2)} m/s`;
  $('t-thr').textContent = `${thr.toFixed(0)} %`;
  $('t-rpm').textContent = `${Math.round(sim.rpm.reduce((a, b) => a + b) / 4)}`;
  $('t-bat').textContent = `${sim.volts.toFixed(2)} V  ${sim.amps.toFixed(1)} A`;
  $('t-pwr').textContent = `${sim.power.toFixed(0)} W`;
  const m = Math.floor(t / 60), s = t - m * 60;
  $('t-time').textContent = `${String(m).padStart(2, '0')}:${s.toFixed(1).padStart(4, '0')}`;
  let cap = captions[0][1];
  for (const [ct, txt] of captions) if (t >= ct) cap = txt;
  $('caption').textContent = cap;
}

/* ------------------------------------------------------------------ */
/* frame                                                               */
/* ------------------------------------------------------------------ */
const qYaw = new THREE.Quaternion(), qTilt = new THREE.Quaternion(), axis = new THREE.Vector3();
let lastT = 0;
const audioLog = [];
function frame(t) {
  const dt = Math.max(1e-4, t - lastT); lastT = t;
  advanceTo(t);
  // pose
  drone.position.set(sim.px, sim.y + FOOT_Y, sim.pz);
  qYaw.setFromAxisAngle(axis.set(0, 1, 0), sim.yaw);
  const tilt = Math.hypot(sim.tx, sim.tz);
  if (tilt > 1e-6) qTilt.setFromAxisAngle(axis.set(sim.tz, 0, -sim.tx).normalize(), tilt); else qTilt.identity();
  drone.quaternion.copy(qTilt).multiply(qYaw);
  // props: real rotation + motion-blur disc as RPM rises
  props.forEach((p, i) => {
    const rpm = sim.rpm[i];
    p.angle += p.dir * rpm * Math.PI / 30 * dt;
    p.blade.rotation.y = p.angle;
    p.blade.material.opacity = clamp(1 - (rpm - 700) / 1400, 0.06, 1);
    p.blade.visible = p.blade.material.opacity > 0.07 || rpm < 2000;
    p.disc.material.opacity = clamp((rpm - 400) / 2600, 0, 1) * 0.85;
    p.disc.rotation.z = p.angle;
  });
  // rotor wash dust
  const h = sim.y + ROTOR_H;
  const wash = clamp(1 - (h - 0.15) / 1.6, 0, 1) * clamp((sim.rpm[0] - 2500) / 2800, 0, 1.3);
  dust.update(dt, sim.px, sim.pz, wash);
  sun.position.copy(drone.position).addScaledVector(sunDir, 30);   // shadow frustum follows the drone
  sun.target.position.copy(drone.position);
  updateCamera(t, dt);
  updateHud(t);
  dust.mat.uniforms.scale.value = renderer.domElement.height / 2 / Math.tan(THREE.MathUtils.degToRad(camera.fov / 2)) * 0.5;
  renderer.render(scene, camera);
  audioLog.push([t, ...sim.rpm.map((r) => Math.round(r)), camera.position.distanceTo(drone.position), Math.max(0, sim.y), sim.px, sim.pz]);
}

await loadDrone();
if (RECORD) {
  window.__frame = (t) => frame(t);
  window.__audioLog = () => audioLog;
  window.__duration = DURATION;
  window.__ready = true;
} else {
  let start = performance.now();
  const loop = () => {
    let t = (performance.now() - start) / 1000;
    if (t > DURATION) { start = performance.now(); t = 0; sim = newSim(); lastT = 0; }
    frame(t);
    requestAnimationFrame(loop);
  };
  loop();
}
