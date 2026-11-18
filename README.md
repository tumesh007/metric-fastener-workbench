# Metric Fastener Workbench

Parametric OpenSCAD models and a dependency-free browser customizer for printable M3, M4 and M5 nuts and bolts. Choose Phillips, slotted, hex, or socket-cap bolt heads.

## GitHub Pages

Live customizer: <https://tumesh007.github.io/metric-fastener-workbench/>

The hosted page can customize individual parts or a multi-part batch and download the generated `.scad` file. GitHub Pages is static, so direct OpenSCAD STL rendering is available through the local Mac app/server only. On the hosted page, open the downloaded batch `.scad` in OpenSCAD and export it as one STL.

## Use the web customizer

Open `index.html` in a browser. Select the part and size, adjust the controls, then download the configured `.scad` file. The **Download matching nut/bolt** button creates the mating part with the same thread clearance. Set both batch quantities and use **Download batch .scad** to create a spaced layout of multiple parts in one model. The drawing is an illustrative preview; the downloaded OpenSCAD source defines the actual model.

For a direct one-file STL download from the page, run `node server.mjs` in this folder and open `http://127.0.0.1:4173`. The **Export batch STL** button asks the local OpenSCAD installation to render the full layout and downloads one STL. Node.js and OpenSCAD must be installed.

## Use the OpenSCAD model directly

Open `metric_fastener.scad` in OpenSCAD. Edit the variables at the top or use OpenSCAD's Customizer panel. Choose `bolt`, `nut`, or `batch`. Set `bolt_count` and `nut_count` for batch output. Press **F6** to render, then choose **File → Export → Export as STL**. The bolt is modeled with its drive face opposite the shank; print it vertically with the tip on the build plate, and consider a brim for adhesion. The nut prints flat on one face.

## Fit and printing notes

- The default thread clearance is **0.20 mm radially** (0.40 mm on diameter). Tune it to your printer, material, and slicer; print a short test pair before a larger batch.
- These models use an ISO-like 60° thread profile with printable crest truncation, rather than a certified fastener thread form.
- Plastic nuts and bolts are for prototypes and light-duty use. They are not strength-rated substitutes for metal hardware.
- The bolt head and nut dimensions are customizable. Thread pitch follows the selected M3 (0.5 mm), M4 (0.7 mm), or M5 (0.8 mm) size.
