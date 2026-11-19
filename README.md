# Metric Fastener Workbench

Parametric OpenSCAD models and a browser customizer for ISO coarse metric sizes **M1, M1.2, M1.4, M1.6, M1.8, M2, M2.5, M3, M3.5, M4, M5, M6, M7, M8, M9 and M10**.

![OpenSCAD rendered prototype parts](assets/workbench-preview.png)

The image shows the actual OpenSCAD geometry. The self-tapping screw prints head-down: its full-diameter root joins the head and its tapered point rises at the far end of the shank.

## Web app

Live customizer: <https://tumesh007.github.io/metric-fastener-workbench/>  
[Download the Mac app package](Metric-Fastener-Workbench-Mac.zip)

GitHub Pages serves a static web app. It downloads parametric `.scad` files, but cannot render STL in the browser. For a selected part—including a self-tapping screw, insert, or wall plug—open its downloaded `.scad` in OpenSCAD and export STL there. The local `Export batch STL` action supports a combined bolts-and-nuts batch only; it does not export the currently selected part. See the [diagnostic report](docs/WORKBENCH_DIAGNOSTIC_REPORT.md) for the verified limitations and troubleshooting steps.

## Part options

- **Bolt and nut:** approximate printable threads, style-selectable hex, socket, Phillips, or slotted bolt heads. The bolt rests cap-face down with the shaft rising from the build plate.
- **Self-tapping screw prototype:** separate pointed screw geometry with adjustable prototype pitch and the same head options.
- **Printed insert prototype:** adjustable sleeve, flange, knurls and internal thread. This is a printed geometric mock-up, not a commercial heat-set insert.
- **Wall plug prototype:** adjustable tapered split plug geometry. It has not been tested as a masonry anchor.

Open `metric_fastener.scad` in OpenSCAD and use the Customizer panel, or open `index.html` for the browser controls. The browser drawing is illustrative; the OpenSCAD-rendered image above shows the generated geometry.

## Print and fit notes

- Thread pitch values use the ISO coarse series (ISO 261); the swept thread form is an approximation for FDM printing, not a certified thread profile. See [ISO 261 coarse pitch table](https://cdn.standards.iteh.ai/samples/4165/ec50482690954e82931c52fdce3bc8bb/ISO-261-1998.pdf) and [ISO 724 basic dimensions](https://standards.iteh.ai/catalog/standards/iso/e95db92c-4080-4105-9dd6-5d42b9923765/iso-724).
- Default thread clearance is **0.20 mm radially** (0.40 mm diametral). Tune for printer, material and slicer; print a short fit sample first.
- Plastic bolts and nuts are prototypes for light-duty use, not strength-rated metal replacements. The new self-tapping screws, printed insert mock-ups and wall plugs are experimental geometry, not certified hardware or anchors.

## Troubleshooting and export limits

See the [diagnostic report](docs/WORKBENCH_DIAGNOSTIC_REPORT.md) for the self-tapping screw orientation history, STL export workflow, verified limits on GitHub Pages, and the recommended selected-part STL feature.
