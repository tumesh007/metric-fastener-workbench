# Metric Fastener Workbench — Comprehensive Technical Handoff & Audit Specification

**Date:** 2026-11-20  
**Project:** Metric Fastener Workbench (`github.com/tumesh007/metric-fastener-workbench`)  
**Repository Branch:** `main`  
**Target Hardware:** Bambu Lab A1 Mini (0.4 mm nozzle, gold textured PEI plate)  
**Host Environment:** macOS (2017 MacBook Air dual-boot)  
**Live Customizer:** <https://tumesh007.github.io/metric-fastener-workbench/>  

---

## 1. System Constraints & Execution Directives

### 1.1 Strict macOS Toolchain Restriction
- **DO NOT run `/usr/bin/git`, `/usr/bin/python3`, `clang`, or `make`.**
  - **Reason:** macOS developer stub binaries in `/usr/bin` trigger an invasive Xcode GUI installation modal. The host machine has disk space, but the user explicitly directives agents never to prompt for Xcode.
- **Allowed Tools:**
  - Node.js runtime: `/usr/local/bin/node`
  - GitHub CLI: `/usr/local/bin/gh` (API calls via `/usr/local/bin/gh api`)
  - OpenSCAD binary: `/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD`
  - System utilities: `ls`, `zip`, `unzip`, `sips`, `cat`, `find`

---

## 2. Fastener Catalog & Taxonomy (34 Parts)

| Category | Identifier (`part`) | Standard / Basis | Key Geometric Properties |
|---|---|---|---|
| **Hex Bolts** | `hex_bolt` | ISO 4014 / 4017 / DIN 933 | External thread, hex head, flat base at Z=0 for support-free print |
| | `hex_flange_bolt` | EN 1665 / ISO 4162 | Hex head with integrated load-spreading conical flange |
| **Socket Screws** | `socket_cap` | ISO 4762 / DIN 912 | Cylindrical head, recessed internal socket (hex, torx, phillips, slot) |
| | `button_head` | ISO 7380-1 | Low-profile dome head with drive recess |
| | `button_flange` | ISO 7380-2 | Button dome with integrated wide circular flange |
| | `countersunk_screw` | ISO 10642 / DIN 7991 | 90° conical head flush with workpiece surface |
| | `pan_head` | ISO 7045 / DIN 7985 | Rounded top cylindrical machine screw head |
| | `shoulder_screw` | ISO 7379 | Precision unthreaded ground shoulder with threaded shank tip |
| **Thumb & Wing Screws**| `thumb_screw` | DIN 464 | Knurled high head wheel with intermediate cylindrical collar |
| | `flat_thumb_screw` | DIN 653 | Low-profile flat knurled thumb wheel |
| | `wing_screw` | DIN 316 | Traditional upright twin wing screw |
| | `oval_wing_screw` | Custom FDM High-Shear | Elliptical continuous arch for maximum FDM layer-shear strength |
| **Wood / Self-Tapping** | `wood_hex_screw` | DIN 571 | Heavy hex lag screw with coarse tapered thread point |
| | `tapping_screw` | ISO 1481 / DIN 7971 | Pan head self-tapping pointed gimlet screw |
| | `csk_tapping_screw` | ISO 1482 / DIN 7972 | 90° countersunk self-tapping pointed screw |
| **Rods & Set Screws** | `threaded_rod` | DIN 975 | Continuous metric coarse threaded stud |
| | `set_screw_flat` | ISO 4026 / DIN 913 | Headless grub screw with internal socket and flat nose |
| | `set_screw_cone` | ISO 4027 / DIN 914 | Headless grub screw with pointed cone biting tip |
| **Washers** | `flat_washer` | ISO 7089 / DIN 125 | Medium OD (~2.2d), 0.54 mm thickness (M3), flat continuous ring |
| | `fender_washer` | ISO 7093 / DIN 9021 | Large OD (3.0d to 3.2d), 0.80 mm thickness (M3), heavy penny ring |
| | `spring_washer` | DIN 127 | Compact OD (1.8d), 0.80 mm wire, 18° radial split gap, 0.5 mm helical lift |
| **Nuts** | `hex_nut` | ISO 4032 / DIN 934 | Standard hex body with internal helical metric thread |
| | `jam_nut` | ISO 4035 / DIN 439 | Thin hex lock nut (~0.55x height) with internal helical thread |
| | `flange_nut` | DIN 6923 / ISO 4161 | Hex nut with integrated wide bottom flange and internal helical thread |
| | `nyloc_nut` | DIN 985 / ISO 7040 | Prevailing-torque lock nut with internal helical thread |
| | `acorn_nut` | DIN 1587 | Hex nut with closed dome cap and blind internal helical thread |
| | `wing_nut` | DIN 315 | Twin solid wings on central hub with internal helical thread |
| | `thumb_nut` | DIN 466 | Knurled wheel with collar and internal helical thread |
| | `flat_thumb_nut` | DIN 467 | Low-profile knurled wheel with internal helical thread |
| | `square_nut` | DIN 557 / DIN 562 | Square prism body with radially aligned circular internal thread |
| | `tslot_nut` | 2020 / 3030 Extrusion | Stepped drop-in hammer nut with central helical thread |
| **Anchors & Inserts** | `heat_set_insert` | M-series Brass Mockup | Diamond-knurled body with flange and internal helical thread |
| | `wall_plug` | Split Expansion Anchor | Tapered nose with split expansion slots |
| | `winged_wall_plug` | Anti-Pullout Anchor | 3 middle wings (120°) + 3 bottom wings (staggered 60°) for masonry grip |

---

## 3. Critical Technical Defects Diagnosed & Resolved

### 3.1 Helical Internal Metric Threading in Nuts & Inserts
* **Defect:** Web customizer STL generator (`createFastenerTriangles`) originally used a smooth bore hole:
  `R_bore = (minor_d + 2 * thread_clearance) / 2`
  All exported nut models in slicers had no internal threads.
* **Resolution:** Implemented `emitThreadedBore(H, z0_offset)` and `getInternalR(u, rz)`:
  - Internal thread tooth tip (crest): `R_crest = (minor_d + 2*c) / 2`
  - Internal thread groove (root): `R_root = (major_d + 2*c) / 2`
  - Helical tooth phase: base width `0.72p`, crest flat `0.12p`.
  - Inward surface normal winding: `addQuad(x10, y10, z0, x00, y00, z0, x01, y01, z1, x11, y11, z1)`.
  - Fully integrated into all 10 nut/insert parts.

### 3.2 Square Nut & Hex Nut Bore Distortion (Angular Shear Bug)
* **Defect:** In `square_nut`, outer perimeter points were sampled starting at corner `[-hw, -hw]` (polar angle `-135°`), while inner bore points were sampled at `u = 0°`. The annular connecting quads stretched diagonally across the nut with a 135° shear, cutting across the circular bore and turning the opening into a skewed square/diamond.
* **Resolution:** Replaced corner array sampling with exact polar ray function:
  ```javascript
  function getSquareR(u) {
    const cosU = Math.abs(Math.cos(u)), sinU = Math.abs(Math.sin(u));
    return hw / Math.max(cosU, sinU);
  }
  ```
  Outer vertex `(r_sq * cos(u), r_sq * sin(u))` and inner vertex `(r_in * cos(u), r_in * sin(u))` lie on the EXACT same polar ray `u`. Angular delta is identically `0.0°`. The bore opening is a true radial circle.
  The same polar ray formula was applied to regular hexagonal nuts:
  ```javascript
  function getHexR(u) {
    const aMod = ((u + Math.PI / 6) % (Math.PI / 3) + Math.PI / 3) % (Math.PI / 3) - Math.PI / 6;
    return (nut_across_flats / 2) / Math.cos(aMod);
  }
  ```

### 3.3 Washer Homogeneity Bug (Identical STL Exports)
* **Defect:** In `index.html`, `part.includes("washer")` only differentiated `isFender = part === "fender_washer"`. For `spring_washer`, `isFender` evaluated to `false`, falling through to identical geometry and vertex coordinates as `flat_washer` (byte-for-byte identical binary STL).
* **Resolution:**
  - `flat_washer`: ISO 7089 standard ring (`OD = 6.6 mm`, `th = 0.54 mm` for M3, 288 tris, 13.65 mm³).
  - `fender_washer`: ISO 7093 large penny ring (`OD = 9.6 mm`, `th = 0.80 mm` for M3, 288 tris, 50.60 mm³).
  - `spring_washer`: DIN 127 helical split spring lock washer (`OD = 5.5 mm`, `th = 0.80 mm` wire, 18° radial split gap, 0.50 mm axial helical deflection lift, planar cut end caps, 292 tris, 10.58 mm³).

### 3.4 Wing Nut & T-Slot Nut Inversion & Hollowness
* **Defect:** `M3_wing_nut.stl` previously comprised 3 disconnected intersecting shells with inverted quad winding on the wings (`Vol = -89.5 mm³` per wing). Slicers (Bambu Studio / PrusaSlicer) interpreted the inverted intersecting shells as negative void volumes, producing hollow wings with 0% infill. `tslot_nut` had inverted winding and zero bore.
* **Resolution:** Rewrote `wing_nut` using continuous radial boundary function `getWingR(u)` uniting the hub and both wings into a single continuous watertight shell with central helical bore. `tslot_nut` rewritten with stepped extrusion neck and central helical bore. Both have 100% positive volume.

### 3.5 Winged Anti-Pullout Wall Plug
* **Requirement:** Add specialized wall plug with 3 wings at middle and 3 wings at bottom to prevent rotation and axial pull-out.
* **Resolution:** Created `winged_wall_plug` in `index.html` and `metric_fastener.scad`:
  - Middle tier: 3 barbed retention wings at `z = 0.35L` to `0.52L` spaced at 120°.
  - Bottom tier: 3 barbed retention wings at `z = 0.62L` to `0.79L` staggered at 60°.
  - Forward ramp allows smooth entry into drilled wall hole; sharp trailing shoulder bites substrate against pull-out.
  - Watertight single-shell mesh: 2,808 triangles, 697.77 mm³.

---

## 4. Automated Mathematical Audit Script

To verify all 34 parts without launching a browser or running forbidden toolchain binaries, run:

```bash
/usr/local/bin/node -e '
const fs = require("fs");
const html = fs.readFileSync("index.html", "utf8");
const scriptMatch = html.match(/<script>([\s\S]*?)<\/script>/);
const vm = require("vm");
class MockOption { constructor(text, value) { this.text = text; this.value = value; } }
const defaultVals = { size: "M3", bolt_length: "16", drive_type: "hex_drive", tslot_series: "20", knurl_depth: "0.35", thread_clearance: "0.20", nut_across_flats: "5.5", nut_height: "2.4", head_diameter: "5.5", head_height: "3.0", drive_size: "2.5", drive_width: "0.7", drive_depth: "1.2", tapping_pitch: "1.0", insert_diameter: "4.6", insert_length: "4.5", insert_flange_diameter: "5.2", insert_flange_height: "0.5", insert_knurl_count: "8", plug_diameter: "7.5", plug_length: "18", plug_bore_diameter: "1.7", plug_slot_width: "0.8", bolt_count: "4", nut_count: "4" };
const elements = {};
function getEl(id) { if (!elements[id]) { elements[id] = { value: defaultVals[id] !== undefined ? defaultVals[id] : "0", min: "3", max: "60", checked: false, innerHTML: "", textContent: "", options: [], classList: { toggle: () => {} }, add: function(opt) { this.options.push(opt); }, addEventListener: () => {} }; } return elements[id]; }
const context = { console, Math, Option: MockOption, TextEncoder, Blob, document: { getElementById: getEl, querySelectorAll: () => [] }, window: { addEventListener: () => {} } };
vm.createContext(context);
vm.runInContext(scriptMatch[1], context);
const parts = ["socket_cap", "hex_bolt", "hex_flange_bolt", "button_head", "button_flange", "countersunk_screw", "pan_head", "shoulder_screw", "thumb_screw", "flat_thumb_screw", "wing_screw", "oval_wing_screw", "wood_hex_screw", "tapping_screw", "csk_tapping_screw", "threaded_rod", "set_screw_flat", "set_screw_cone", "flat_washer", "fender_washer", "spring_washer", "hex_nut", "jam_nut", "flange_nut", "nyloc_nut", "acorn_nut", "wing_nut", "thumb_nut", "flat_thumb_nut", "square_nut", "tslot_nut", "heat_set_insert", "wall_plug", "winged_wall_plug"];
let pass = true;
for (const p of parts) {
  getEl("part").value = p; context.setDefaults();
  const tris = context.createFastenerTriangles(context.getParams(p));
  const edgeMap = new Map();
  function vKey(x, y, z) { return Math.round(x*1000)+","+Math.round(y*1000)+","+Math.round(z*1000); }
  let vol = 0;
  for (let i = 0; i < tris.length; i += 9) {
    const ax = tris[i], ay = tris[i+1], az = tris[i+2], bx = tris[i+3], by = tris[i+4], bz = tris[i+5], cx = tris[i+6], cy = tris[i+7], cz = tris[i+8];
    vol += (ax*(by*cz - bz*cy) + bx*(cy*az - cz*ay) + cx*(ay*bz - az*by))/6.0;
    for (const [ea, eb] of [[vKey(ax,ay,az), vKey(bx,by,bz)], [vKey(bx,by,bz), vKey(cx,cy,cz)], [vKey(cx,cy,cz), vKey(ax,ay,az)]]) {
      const c = ea < eb ? ea+"->"+eb : eb+"->"+ea;
      const cur = edgeMap.get(c) || { count: 0, dir: 0 };
      cur.count++; cur.dir += (ea < eb ? 1 : -1);
      edgeMap.set(c, cur);
    }
  }
  let open = 0, nonManifold = 0, badNormals = 0;
  for (const [k, v] of edgeMap.entries()) {
    if (v.count !== 2) { if (v.count === 1) open++; else nonManifold++; }
    else if (v.dir !== 0) badNormals++;
  }
  if (open > 0 || nonManifold > 0 || badNormals > 0 || vol <= 0) { console.error(`FAIL ${p}: open=${open}, nonManifold=${nonManifold}, badNormals=${badNormals}, vol=${vol}`); pass = false; }
  else { console.log(`PASS ${p}: vol=${vol.toFixed(2)} mm3, tris=${tris.length/9}`); }
}
console.log(pass ? "AUDIT RESULT: 34/34 PARTS 100% WATERTIGHT AND MANIFOLD" : "AUDIT FAILED");
'
```

---

## 5. Turnkey Audit Prompt for Subsequent AI Agent

Paste the following prompt verbatim into any independent auditing agent:

```markdown
You are an expert CAD engineer and software auditor. Your mission is to audit the Metric Fastener Workbench repository located at `/Users/tumesh/Documents/Metric-Fastener-Workbench` and the live deployment at `https://tumesh007.github.io/metric-fastener-workbench/`.

CRITICAL ENVIRONMENT RULE:
NEVER invoke `/usr/bin/git`, `/usr/bin/python3`, `clang`, or `make`. These trigger an invasive macOS Xcode installation prompt.
Use only:
- Node.js runtime: `/usr/local/bin/node`
- GitHub CLI: `/usr/local/bin/gh`
- OpenSCAD: `/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD`
- Standard macOS utilities: `ls`, `zip`, `unzip`, `cat`, `find`

AUDIT CHECKLIST & VERIFICATION GATES:
1. Inspect `index.html` and confirm all 34 parts are present in the dropdown, parameter extraction, and `createFastenerTriangles()`.
2. Verify that all female parts (`hex_nut`, `jam_nut`, `flange_nut`, `nyloc_nut`, `acorn_nut`, `wing_nut`, `thumb_nut`, `flat_thumb_nut`, `square_nut`, `tslot_nut`, `heat_set_insert`) generate continuous internal helical threads using `emitThreadedBore()`. Confirm bore crest and root radii match clearance equations.
3. Verify `square_nut` top and bottom face vertices: ensure the outer square sampling uses `getSquareR(u) = (W/2)/max(|cos u|, |sin u|)` so outer and inner bore vertices share identical polar angles `u` (0° angular shear), rendering a perfectly circular internal thread entry.
4. Verify all 3 washers:
   - `flat_washer` (ISO 7089): flat continuous closed ring (~6.6 mm OD, 0.54 mm th for M3).
   - `fender_washer` (ISO 7093): large flat continuous closed penny ring (~9.6 mm OD, 0.80 mm th for M3).
   - `spring_washer` (DIN 127): compact ring (~5.5 mm OD, 0.80 mm th wire for M3) with 18° radial split gap, ~0.5 mm helical axial deflection (sprung lift), and closed planar end faces. Confirm the STL files are NOT identical.
5. Verify wall plugs:
   - `wall_plug`: standard split expansion plug.
   - `winged_wall_plug`: plug with 3 retention wings at middle tier (120°) and 3 retention wings at bottom tier (staggered 60°), designed for anti-pullout masonry grip.
6. Verify wing nut and oval wing screw: confirm wings are 100% solid, single manifold shells with positive volume and zero slicer void inversions.
7. Run an automated mesh audit using Node.js across all 34 parts: assert 0 open edges (Euler boundary check), 0 non-manifold edges, 0 bad normal windings, and strictly positive volume (`Vol > 0`).
8. Check `metric_fastener.scad` to confirm OpenSCAD models match the browser taxonomy. Test rendering `spring_washer` and `winged_wall_plug` using the OpenSCAD CLI.
9. Verify GitHub Pages build status using `/usr/local/bin/gh api repos/tumesh007/metric-fastener-workbench/pages/builds/latest`.
10. Deliver a direct, terse conclusion summarizing audit findings, test outputs, and manifoldness stats.
```
