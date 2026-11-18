/* Parametric printable metric fasteners: M3 / M4 / M5
   Open with OpenSCAD. Set `part` to "bolt", "nut", or "batch" in Customizer.
   FDM fit is printer/material dependent. Start with 0.20 mm radial clearance.
   These are functional prototypes, not strength-rated replacements for metal hardware.
*/

part = "bolt"; // [bolt, nut, batch]
size = "M3"; // [M3, M4, M5]
bolt_length = 16; // [6:1:50] Length under head (mm)
head_style = "socket"; // [hex, socket, phillips, slotted]
head_height = head_style == "hex" ? (size == "M3" ? 2 : size == "M4" ? 2.8 : 3.5) : (size == "M3" ? 3 : size == "M4" ? 4 : 5); // [1:0.2:8] mm
head_diameter = head_style == "hex" ? (size == "M3" ? 5.5 : size == "M4" ? 7 : 8) : (size == "M3" ? 5.5 : size == "M4" ? 7 : 8.5); // [4:0.1:12] mm (hex across flats; round-head diameter)
drive_size = size == "M3" ? 2.5 : size == "M4" ? 3 : 4; // [1:0.1:8] Socket size, Phillips span, or slot length (mm)
drive_width = 0.7; // [0.3:0.1:2.5] Phillips arm / slot width (mm)
drive_depth = 1.2; // [0.4:0.1:5] Recess depth (mm)
nut_height = size == "M3" ? 2.4 : size == "M4" ? 3.2 : 4; // [1:0.2:8] mm
nut_across_flats = size == "M3" ? 5.5 : size == "M4" ? 7 : 8; // [4:0.1:12] mm
thread_clearance = 0.20; // [0:0.05:0.6] Radial clearance, mm
bolt_count = 4; // [0:1:16] Used when part is batch
nut_count = 4; // [0:1:16] Used when part is batch
$fn = 72;

major_d = size == "M3" ? 3 : size == "M4" ? 4 : 5;
pitch = size == "M3" ? 0.5 : size == "M4" ? 0.7 : 0.8;
minor_d = major_d - 1.08*pitch;
thread_depth = 0.60*pitch;

// ISO-like 60-degree thread approximated by a swept trapezoid. Small flat
// crests improve printability; clearance is applied to the mating thread.
module helix_profile(root_r, depth, p, thread_len) {
    crest = 0.12*p;
    base = 0.72*p;
    linear_extrude(height=thread_len + 2*p, twist=360*(thread_len + 2*p)/p,
                   slices=max(24, ceil((thread_len+2*p)*18/p)), convexity=10)
        translate([root_r, 0, 0])
            polygon([[0,-base/2],[depth,-crest/2],[depth,crest/2],[0,base/2]]);
}

module external_threaded_shaft() {
    // Start the sweep below the end so the thread is continuous after trimming.
    intersection() {
        union() {
            cylinder(d=minor_d + 0.15, h=bolt_length);
            translate([0,0,-pitch]) helix_profile(minor_d/2 - 0.03, thread_depth, pitch, bolt_length);
        }
        cylinder(d=major_d, h=bolt_length);
    }
}

module hex_prism(af, h) {
    cylinder(r=af/sqrt(3), h=h, $fn=6);
}

module bolt_model() {
    drive_cut_depth = min(drive_depth, head_height-0.2);
    union() {
        // Physically correct orientation: the shank joins the underside of the head;
        // the drive recess opens on the opposite, exposed face.
        external_threaded_shaft();
        translate([0,0,bolt_length])
            if (head_style == "hex") hex_prism(head_diameter, head_height);
            // Render this small boolean locally so OpenSCAD's fast preview shows
            // the cavity, instead of coloring the subtractor as a solid green plug.
            else render() difference() {
                cylinder(d=head_diameter, h=head_height);
                if (head_style == "socket")
                    translate([0,0,head_height-drive_cut_depth])
                        cylinder(r=drive_size/sqrt(3), h=drive_cut_depth+0.05, $fn=6);
                else if (head_style == "phillips")
                    translate([0,0,head_height-drive_cut_depth])
                        union() {
                            translate([-drive_width/2,-drive_size/2,0]) cube([drive_width,drive_size,drive_cut_depth+0.05]);
                            translate([-drive_size/2,-drive_width/2,0]) cube([drive_size,drive_width,drive_cut_depth+0.05]);
                        }
                else if (head_style == "slotted")
                    translate([0,0,head_height-drive_cut_depth])
                        translate([-drive_size/2,-drive_width/2,0]) cube([drive_size,drive_width,drive_cut_depth+0.05]);
        }
    }
}

module nut_model() {
    difference() {
        hex_prism(nut_across_flats, nut_height);
        union() {
            // Through bore with radial allowance, then the internal helical void.
            translate([0,0,-0.1]) cylinder(d=minor_d + 2*thread_clearance, h=nut_height+0.2);
            // Overlap the bore slightly to avoid coincident cutter faces and
            // non-manifold exports, especially on M5's coarser pitch.
            translate([0,0,-pitch]) helix_profile((minor_d + 2*thread_clearance)/2 - 0.02,
                                                   thread_depth, pitch, nut_height);
            // Lead-in on both faces eases engagement and avoids a fragile first crest.
            translate([0,0,-0.01])
                cylinder(d1=major_d+2*thread_clearance, d2=minor_d+2*thread_clearance,
                         h=min(0.45,nut_height/4)+0.02);
            translate([0,0,nut_height-min(0.45,nut_height/4)])
                cylinder(d1=minor_d+2*thread_clearance, d2=major_d+2*thread_clearance,
                         h=min(0.45,nut_height/4)+0.02);
        }
    }
}

module batch_model() {
    bolt_spacing = max(head_diameter, major_d) + 5;
    nut_spacing = nut_across_flats + 5;
    nut_row_y = max(head_diameter, nut_across_flats) + 6;
    if (bolt_count > 0)
        for (i = [0:bolt_count-1])
            translate([i*bolt_spacing,0,0]) bolt_model();
    if (nut_count > 0)
        for (i = [0:nut_count-1])
            translate([i*nut_spacing,nut_row_y,0]) nut_model();
}

if (part == "bolt") bolt_model();
else if (part == "nut") nut_model();
else batch_model();
