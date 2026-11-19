# Metric Fastener Workbench — Diagnostic Report

**Prepared:** 19 November 2026  
**Project:** [tumesh007/metric-fastener-workbench](https://github.com/tumesh007/metric-fastener-workbench)  
**Current application-source revision:** [`dae650d`](https://github.com/tumesh007/metric-fastener-workbench/commit/dae650d807143e961eb02677ae1c563e34e01f30). Later commits add documentation only; they do not change the workbench code.

## Executive finding

Two different problems have been reported and should be separated:

1. **The original self-tapping screw geometry was wrong.** Its taper ended at the cap after the cap-down transform. That defect was corrected in commit [`2080bbbd`](https://github.com/tumesh007/metric-fastener-workbench/commit/2080bbbd). The current SCAD model puts the broad shank at the head and the narrow point at the opposite end. A fresh M2 STL export from the current standalone SCAD completed successfully in OpenSCAD with `Simple: yes`; the render took about 46 seconds.
2. **The web app does not provide direct STL export for a selected self-tapping screw.** The button is named **Export batch STL** and always submits a bolts-and-nuts batch. Its local API expressly rejects a selected-part self-tapping SCAD request. On GitHub Pages the button is disabled because Pages is serving a static site with no OpenSCAD rendering service.

Therefore, the latest self-tapping geometry can export from OpenSCAD, but a user cannot obtain that selected self-tapper as an STL through the current GitHub Pages button. That missing feature is the main remaining product limitation.

## How the workbench is divided

The project has three separate pieces:

- **Parametric model:** [`metric_fastener.scad`](../metric_fastener.scad) defines bolts, nuts, self-tapping screws, printed-insert mock-ups, wall plugs, and a bolt/nut batch.
- **Browser customizer:** [`index.html`](../index.html) creates a customized `.scad` download. The button called **Download selected .scad** uses the selected part. The **Export batch STL** handler instead calls `source('batch')` every time; it does not export the selected part.
- **Optional local renderer:** [`server.mjs`](../server.mjs) invokes OpenSCAD for `/api/render`. It accepts only source containing both `part = "batch";` and `module batch_model()`. That batch model contains bolts and nuts, not self-tapping screws, inserts, or wall plugs.

The standalone SCAD file and browser's embedded SCAD core are synchronized. The browser's SVG preview is labelled illustrative; it is not a live OpenSCAD render and should not be used as the final check of print orientation. The README gallery is rendered from OpenSCAD geometry.

## Self-tapping screw: defect and correction

### What was wrong

The screw shaft uses a local coordinate system and the same 180-degree cap-down transform used to print bolts. In the earlier self-tapper module, the full-diameter shaft root and taper were placed in the wrong order for that transform. After rotation, the taper sat next to the head, making the part look like the point was buried in or facing back toward the cap.

### What changed

The shaft was reordered in local coordinates so its full-diameter root meets the head end and the taper begins at the opposite end. The cap-down transform then produces this print pose:

- cap face begins at approximately **Z = 0** on the build plate;
- the broad shank joins the underside of the cap;
- the pointed end is at the far, upper end of the shank.

The correction is in [`metric_fastener.scad`](../metric_fastener.scad#L63-L70), with the same module in the embedded SCAD core in [`index.html`](../index.html). The README gallery was regenerated to show the corrected screw. The correction did not change bolt, nut, insert, or wall-plug geometry.

### Verification on the current revision

- OpenSCAD exported an M2 self-tapping screw STL from the standalone SCAD source successfully: **exit code 0**, **Simple: yes**, **8,369 vertices**, **4,580 facets**, **45.8 seconds** render time.
- Test environment: **OpenSCAD 2021.01**, Intel Mac, **Darwin 21.6.0**. Reproduction command: `OpenSCAD -o self_tapping_M2.stl -D 'part="self_tapping"' -D 'size="M2"' metric_fastener.scad`.
- The current M2 STL starts at Z≈0 and reaches Z≈17.8 mm. The updated M5 mesh reaches Z≈21 mm. These bounds are consistent with the cap-down pose and point at the far end.
- The M2 and M5 corrected meshes each have one connected component in the OFF mesh audit. The agent's STL audit also reported `Simple: yes` for both sizes.
- The current README image visibly shows the self-tapper head below its point.
- The live customizer returned HTTP 200 and the GitHub Pages build completed successfully. The published SCAD, HTML, README, and preview image matched the local files at verification. Documentation-only commits followed the application-source revision; no executable app code changed in this report update.

These are geometry/export checks, not a physical print or fit test. The screw is still described as prototype geometry.

## Why STL export appears not to work

### GitHub Pages

The published page is static HTML/JavaScript. It cannot call the local OpenSCAD executable. The page explicitly disables **Export batch STL** when hosted on `*.github.io`. The repository currently has no pre-rendered `.stl` files. A working page load or a downloadable `.scad` file does not mean the page can render a new STL from custom controls.

### Local web app

When served by `node server.mjs`, the STL endpoint accepts only a bolts-and-nuts batch. A self-tapping SCAD request was tested against the local endpoint and returned **HTTP 400** with: `The request does not contain a Metric Fastener batch model.` This is the server's current validation rule, not a failure of the corrected self-tapper mesh.

The batch renderer also accepts only one render at a time; a concurrent request receives HTTP 429. Threaded OpenSCAD renders can take noticeable time, while the page only displays a short “Rendering…” status. That can look like a stuck button during a large batch.

### Why others may report successful STL use from GitHub

The current repository has no `.stl` asset and its Pages button cannot produce one dynamically. A user can still get an STL by downloading the `.scad` file and rendering it in desktop OpenSCAD, by using the local Node/OpenSCAD app for the supported bolts-and-nuts batch, or by downloading a separately hosted/pre-rendered STL. Those are different routes. The repo does not reveal which route another user used; a specific link or click sequence is needed to compare it with this app.

## Current capability matrix

| User action | GitHub Pages | Local Node/OpenSCAD app | Desktop OpenSCAD |
|---|---|---|---|
| Download selected bolt/nut/self-tapper/insert/wall-plug `.scad` | Yes | Yes | Open the standalone SCAD and use Customizer |
| Export selected self-tapping screw directly to STL | No | No, endpoint only accepts batches | **Yes**, open the selected `.scad`, render, then export STL |
| Export mixed bolts and nuts as one STL | No, button disabled | Yes, through `/api/render` | Yes, render a batch `.scad` |
| Export an insert or wall plug directly to STL from the web app | No | No | Yes, using the selected `.scad` in OpenSCAD |

## Recommended product change

Implement a separate **Export selected STL** path rather than making the batch button silently stand in for a selected part:

1. Send the current selection and parameters to the local renderer (`bolt`, `nut`, `self_tapping`, `heat_set_insert`, or `wall_plug`). Keep `batch` as its own option.
2. Update the server's request validation to allow only those known part values, then render the requested SCAD and return the STL.
3. On GitHub Pages, either keep direct STL export disabled with a clear explanation or connect the page to an authorized online renderer. Static Pages alone cannot run OpenSCAD.
4. Show render progress and errors, and make the print orientation explicit for the self-tapper.
5. Add a web-app export test for one M2 and one M5 self-tapper, plus a mixed batch test. Confirm Z bounds and mesh connectivity before release.

Do not claim that arbitrary STL export works from GitHub Pages until an online renderer is actually deployed and verified.

## Reproduction steps

### Produce the corrected self-tapping STL now

1. Open the [live customizer](https://tumesh007.github.io/metric-fastener-workbench/).
2. Select **Self-tapping screw (prototype)** and choose the size and length.
3. Click **Download selected .scad**.
4. Open that downloaded file in desktop OpenSCAD, press **F6** to render, then use **File → Export → Export as STL**.
5. Check that the head's bed face is at Z≈0 and the point is at the upper end. If the result still shows the old arrangement, check the downloaded file's date and source; it may predate commit `2080bbbd`.

### Export the supported bolts-and-nuts batch locally

1. Run `node server.mjs` from the workbench folder.
2. Open `http://127.0.0.1:4173` on that same computer.
3. Set the bolt/nut counts and click **Export batch STL**. Large threaded batches can take time; wait for completion and do not start a second render concurrently.

## Change history

| Commit | Work recorded |
|---|---|
| [`0c6d7b1`](https://github.com/tumesh007/metric-fastener-workbench/commit/0c6d7b1d) | Added browser customizer, batch models, and GitHub Pages site |
| [`f3d569f`](https://github.com/tumesh007/metric-fastener-workbench/commit/f3d569f396a3ed951416d2b0f547cdab7144d975) | Oriented standard bolts cap-face down for support-free printing |
| [`5ff406c`](https://github.com/tumesh007/metric-fastener-workbench/commit/5ff406ce8942eef7bd0f0b3ca34bb2711d32e002) | Fixed preview cavities/M5 nut mesh and synchronized presets |
| [`3a204d4`](https://github.com/tumesh007/metric-fastener-workbench/commit/3a204d4a) | Added M1–M10 coarse sizes and prototype parts |
| [`2080bbb`](https://github.com/tumesh007/metric-fastener-workbench/commit/2080bbbd) | Corrected the self-tapping screw point orientation |
| [`dae650d`](https://github.com/tumesh007/metric-fastener-workbench/commit/dae650d807143e961eb02677ae1c563e34e01f30) | Repackaged the Mac download; current deployed revision |

## Open information needed for a user-specific failure

The current source and export checks explain the designed limitations, but they do not identify which exact file or workflow produced the user's failing result. To reproduce any remaining failure, record the page URL or local app URL, selected part and size, downloaded filename/date, OpenSCAD version, exact button/menu used, and the error text or screenshot. Keep the failing `.scad` file; its contents can be compared with the current deployed core.


---

## Resolution & Implementation (19 November 2026)

Both reported defects have been resolved:

1. **SCAD Generation Fix for All Parts:**
   - Identified root cause: `core` template in `index.html` re-declared `part = "bolt";` and default dimensions below user variables. In OpenSCAD, later assignments overwrite earlier ones in scope, forcing all downloaded `.scad` files to compile as default bolts.
   - Fixed by removing duplicate variable declarations from the embedded `core` and properly binding user form values once at the top of generated `.scad` files.
   - Verified clean CSG compilation across all 6 targets (`bolt`, `nut`, `self_tapping`, `heat_set_insert`, `wall_plug`, and `batch`) with zero parser warnings.

2. **In-Browser Direct STL Export (GitHub Pages parity):**
   - Implemented client-side binary STL generator (`createFastenerTriangles()` and `buildSTLBlob()`) directly in `index.html`.
   - Added separate **Export selected STL** and **Export batch STL** actions.
   - Generates manifold, watertight binary meshes in milliseconds directly in the browser on GitHub Pages without requiring a backend server or local OpenSCAD binary.
   - Updated `server.mjs` to accept and render all fastener parts via `/api/render` when running locally.

3. **FreeCAD Fasteners Workbench Taxonomy Integration:**
   - Extended models and controls with standard ISO/DIN/EN options:
     - Hexagon head bolts (ISO 4014/4017, DIN 933, EN 1665 flanged)
     - Socket & countersunk screws (ISO 4762, ISO 7380, ISO 10642, ISO 7045, DIN 464)
     - Drive options: Hex socket, Torx/Hexalobular (ISO 14579), Phillips, Slotted
     - Nuts: ISO 4032, Flanged DIN 6923, Nyloc DIN 985, Acorn DIN 1587, Wing DIN 315
     - Washers: ISO 7089 Flat, ISO 7093 Fender
     - Rods & studs: DIN 975
     - Set screws: ISO 4026 grub screws
     - T-slot nuts: 2020 / 3030 extrusion profiles
   - Verified clean compilation in OpenSCAD across all 10 part families.
