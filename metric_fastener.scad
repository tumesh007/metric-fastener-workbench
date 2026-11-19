/* Parametric printable metric fastener workbench.
   ISO coarse pitch sizes M1–M10. New tapping screw, printed insert and wall plug
   geometry are prototypes and are not certified fasteners or anchors.
*/
function nominal_d(s) = s=="M1"?1:s=="M1.2"?1.2:s=="M1.4"?1.4:s=="M1.6"?1.6:s=="M1.8"?1.8:s=="M2"?2:s=="M2.5"?2.5:s=="M3"?3:s=="M3.5"?3.5:s=="M4"?4:s=="M5"?5:s=="M6"?6:s=="M7"?7:s=="M8"?8:s=="M9"?9:10;
function nominal_pitch(s) = s=="M1"?0.25:s=="M1.2"?0.25:s=="M1.4"?0.3:s=="M1.6"?0.35:s=="M1.8"?0.35:s=="M2"?0.4:s=="M2.5"?0.45:s=="M3"?0.5:s=="M3.5"?0.6:s=="M4"?0.7:s=="M5"?0.8:s=="M6"?1:s=="M7"?1:s=="M8"?1.25:s=="M9"?1.25:1.5;
function nominal_af(s) = s=="M1"?2:s=="M1.2"?2.5:s=="M1.4"?2.5:s=="M1.6"?3.2:s=="M1.8"?3.5:s=="M2"?4:s=="M2.5"?5:s=="M3"?5.5:s=="M3.5"?6:s=="M4"?7:s=="M5"?8:s=="M6"?10:s=="M7"?11:s=="M8"?13:s=="M9"?14:17;
part = "bolt"; // [bolt, nut, self_tapping, heat_set_insert, wall_plug, batch]
size = "M3"; // [M1, M1.2, M1.4, M1.6, M1.8, M2, M2.5, M3, M3.5, M4, M5, M6, M7, M8, M9, M10]
bolt_length = 16; // [3:1:60] mm
head_style = "socket"; // [hex, socket, phillips, slotted]
head_height = head_style=="hex"?(size=="M3"?2:size=="M4"?2.8:size=="M5"?3.5:max(1,nominal_d(size)*0.7)):(size=="M3"?3:size=="M4"?4:size=="M5"?5:max(1,nominal_d(size)*0.9)); // [1:0.2:12] mm
head_diameter = head_style=="hex"?nominal_af(size):(size=="M3"?5.5:size=="M4"?7:size=="M5"?8.5:max(nominal_d(size)+0.8,nominal_d(size)*1.7)); // [2:0.1:20] mm
drive_size = size=="M3"?2.5:size=="M4"?3:size=="M5"?4:max(0.8,nominal_d(size)*0.75); // [0.5:0.1:10] mm
drive_width = 0.7; // [0.2:0.1:3] mm
drive_depth = 1.2; // [0.3:0.1:8] mm
nut_height = size=="M3"?2.4:size=="M4"?3.2:size=="M5"?4:max(0.8,nominal_d(size)*0.8); // [0.8:0.2:12] mm
nut_across_flats = nominal_af(size); // [2:0.1:24] mm
thread_clearance = 0.20; // [0:0.05:0.8] mm radial
tapping_pitch = 1; // [0.3:0.1:4] mm (prototype, not ISO)
insert_diameter = 4.6; // [2:0.1:24] mm outside diameter
insert_length = 4.5; // [1:0.2:25] mm
insert_flange_diameter = 5.2; // [0:0.1:30] mm (0 disables flange)
insert_flange_height = 0.5; // [0:0.1:3] mm
insert_knurl_count = 8; // [0:1:32]
plug_diameter = 7.5; // [2:0.1:30] mm
plug_length = 18; // [3:1:80] mm
plug_bore_diameter = 1.7; // [0.5:0.1:15] mm
plug_slot_width = 0.8; // [0:0.1:4] mm
bolt_count = 4; // [0:1:30]
nut_count = 4; // [0:1:30]
$fn = 72;

// ISO coarse pitch series (ISO 261). The printable thread remains an approximation.
major_d = nominal_d(size);
pitch = nominal_pitch(size);
minor_d = major_d - 1.08*pitch;
thread_depth = 0.60*pitch;

module helix_profile(root_r, depth, p, thread_len) {
    crest=0.12*p; base=0.72*p;
    linear_extrude(height=thread_len+2*p,twist=360*(thread_len+2*p)/p,slices=max(24,ceil((thread_len+2*p)*18/p)),convexity=10)
        translate([root_r,0,0]) polygon([[0,-base/2],[depth,-crest/2],[depth,crest/2],[0,base/2]]);
}
module external_threaded_shaft() {
    intersection(){ union(){ cylinder(d=minor_d+0.15,h=bolt_length); translate([0,0,-pitch]) helix_profile(minor_d/2-0.03,thread_depth,pitch,bolt_length); } cylinder(d=major_d,h=bolt_length); }
}
module hex_prism(af,h){cylinder(r=af/sqrt(3),h=h,$fn=6);}
module bolt_head(){
    drive_cut_depth=min(drive_depth,head_height-0.2);
    if(head_style=="hex") hex_prism(head_diameter,head_height);
    else render() difference(){
        cylinder(d=head_diameter,h=head_height);
        if(head_style=="socket") translate([0,0,head_height-drive_cut_depth]) cylinder(r=drive_size/sqrt(3),h=drive_cut_depth+0.05,$fn=6);
        else if(head_style=="phillips") translate([0,0,head_height-drive_cut_depth]) union(){translate([-drive_width/2,-drive_size/2,0]) cube([drive_width,drive_size,drive_cut_depth+0.05]);translate([-drive_size/2,-drive_width/2,0]) cube([drive_size,drive_width,drive_cut_depth+0.05]);}
        else translate([0,0,head_height-drive_cut_depth]) translate([-drive_size/2,-drive_width/2,0]) cube([drive_size,drive_width,drive_cut_depth+0.05]);
    }
}
// Existing bolt pose retained: cap face at Z=0, shaft rises from the bed.
module bolt_model(){translate([0,0,bolt_length+head_height]) rotate([180,0,0]) union(){external_threaded_shaft();translate([0,0,bolt_length]) bolt_head();}}
module nut_model(){difference(){hex_prism(nut_across_flats,nut_height);union(){translate([0,0,-0.1]) cylinder(d=minor_d+2*thread_clearance,h=nut_height+0.2);translate([0,0,-pitch]) helix_profile((minor_d+2*thread_clearance)/2-0.02,thread_depth,pitch,nut_height);translate([0,0,-0.01]) cylinder(d1=major_d+2*thread_clearance,d2=minor_d+2*thread_clearance,h=min(0.45,nut_height/4)+0.02);translate([0,0,nut_height-min(0.45,nut_height/4)]) cylinder(d1=minor_d+2*thread_clearance,d2=major_d+2*thread_clearance,h=min(0.45,nut_height/4)+0.02);}}}

// Separate prototype for a pointed plastic self-tapping screw. Pitch is adjustable.
module self_tapping_shaft(){root=max(0.25,major_d-0.95*tapping_pitch); tip=min(bolt_length*0.32,2.2*tapping_pitch); threaded=max(0.5,bolt_length-tip);
    intersection(){union(){cylinder(d=root,h=threaded);translate([0,0,threaded]) cylinder(d1=root,d2=0.35,h=tip);translate([0,0,-tapping_pitch]) helix_profile(root/2-0.025,0.58*tapping_pitch,tapping_pitch,bolt_length);} union(){cylinder(d=major_d,h=threaded);translate([0,0,threaded]) cylinder(d1=major_d,d2=0.35,h=tip+0.01);}}
}
module self_tapping_model(){translate([0,0,bolt_length+head_height]) rotate([180,0,0]) union(){self_tapping_shaft();translate([0,0,bolt_length]) bolt_head();}}

// Printable mock-up for an insert envelope: knurled sleeve and modeled internal thread.
module heat_set_insert_model(){inner_root=minor_d+2*thread_clearance;body_h=max(0.5,insert_length-insert_flange_height);
    difference(){union(){translate([0,0,insert_flange_height]) cylinder(d=insert_diameter,h=body_h);if(insert_flange_diameter>0) cylinder(d=insert_flange_diameter,h=insert_flange_height);
        if(insert_knurl_count>0) for(i=[0:insert_knurl_count-1]) rotate([0,0,i*360/insert_knurl_count]) translate([insert_diameter/2-0.10,-0.16,insert_flange_height]) cube([0.30,0.32,body_h]);}
        translate([0,0,-0.1]) cylinder(d=inner_root,h=insert_length+0.2);
        translate([0,0,-pitch]) helix_profile(inner_root/2-0.02,thread_depth,pitch,insert_length);
    }
}

// Split, tapered wall-plug prototype. Not a tested or certified masonry anchor.
module wall_plug_model(){tip=min(plug_length*0.22,plug_diameter*1.4);body=plug_length-tip;slot_start=plug_length*0.30;
    difference(){union(){cylinder(d=plug_diameter,h=body);translate([0,0,body]) cylinder(d1=plug_diameter,d2=plug_diameter*0.30,h=tip);cylinder(d1=plug_diameter*1.18,d2=plug_diameter,h=min(1.2,plug_length*0.12));
        for(i=[0:3]) rotate([0,0,i*90]) translate([plug_diameter*0.42,-0.28,slot_start]) cube([plug_diameter*0.18,0.56,body-slot_start]);}
        translate([0,0,-0.1]) cylinder(d=plug_bore_diameter,h=plug_length+0.2);
        if(plug_slot_width>0) for(i=[0:1]) rotate([0,0,i*90]) translate([-plug_slot_width/2,-plug_diameter,slot_start]) cube([plug_slot_width,plug_diameter*2,plug_length-slot_start+0.1]);
    }
}
module batch_model(){bolt_spacing=max(head_diameter,major_d)+5;nut_spacing=nut_across_flats+5;nut_row_y=max(head_diameter,nut_across_flats)+6;if(bolt_count>0) for(i=[0:bolt_count-1]) translate([i*bolt_spacing,0,0]) bolt_model();if(nut_count>0) for(i=[0:nut_count-1]) translate([i*nut_spacing,nut_row_y,0]) nut_model();}
if(part=="bolt") bolt_model(); else if(part=="nut") nut_model(); else if(part=="self_tapping") self_tapping_model(); else if(part=="heat_set_insert") heat_set_insert_model(); else if(part=="wall_plug") wall_plug_model(); else batch_model();
