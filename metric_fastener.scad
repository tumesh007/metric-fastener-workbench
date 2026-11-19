/* Parametric printable metric fastener workbench.
   ISO coarse pitch sizes M1–M10.
   Extended with standards from FreeCAD Fasteners Workbench:
   - Hexagon head bolts (ISO 4014/4017, DIN 933, EN 1665 flanged)
   - Hexagon socket screws (ISO 4762 cap, ISO 7380 button, ISO 10642 countersunk)
   - Pan and knurled thumb screws (ISO 7045, DIN 464)
   - Multiple drives (Hex socket, Torx/Hexalobular, Phillips, Slotted)
   - Nuts (Standard ISO 4032, Flange DIN 6923, Nyloc DIN 985, Acorn DIN 1587, Wing DIN 315)
   - Washers (Standard flat ISO 7089, Fender ISO 7093)
   - Threaded rods & studs (DIN 975)
   - Set / grub screws (ISO 4026)
   - T-slot drop-in nuts (2020 / 3030 extrusion)
   - Pointed self-tapping screws, knurled heat-set inserts, wall plugs
*/

function nominal_d(s) = s=="M1"?1:s=="M1.2"?1.2:s=="M1.4"?1.4:s=="M1.6"?1.6:s=="M1.8"?1.8:s=="M2"?2:s=="M2.5"?2.5:s=="M3"?3:s=="M3.5"?3.5:s=="M4"?4:s=="M5"?5:s=="M6"?6:s=="M7"?7:s=="M8"?8:s=="M9"?9:10;
function nominal_pitch(s) = s=="M1"?0.25:s=="M1.2"?0.25:s=="M1.4"?0.3:s=="M1.6"?0.35:s=="M1.8"?0.35:s=="M2"?0.4:s=="M2.5"?0.45:s=="M3"?0.5:s=="M3.5"?0.6:s=="M4"?0.7:s=="M5"?0.8:s=="M6"?1:s=="M7"?1:s=="M8"?1.25:s=="M9"?1.25:1.5;
function nominal_af(s) = s=="M1"?2:s=="M1.2"?2.5:s=="M1.4"?2.5:s=="M1.6"?3.2:s=="M1.8"?3.5:s=="M2"?4:s=="M2.5"?5:s=="M3"?5.5:s=="M3.5"?6:s=="M4"?7:s=="M5"?8:s=="M6"?10:s=="M7"?11:s=="M8"?13:s=="M9"?14:17;

part = "bolt"; // [bolt, nut, washer, threaded_rod, set_screw, tslot_nut, self_tapping, heat_set_insert, wall_plug, batch]
size = "M3"; // [M1, M1.2, M1.4, M1.6, M1.8, M2, M2.5, M3, M3.5, M4, M5, M6, M7, M8, M9, M10]
bolt_length = 16; // [2:1:80] mm
head_style = "socket"; // [hex, hex_flange, socket, button, countersunk, pan, thumb]
drive_type = "hex_drive"; // [hex_drive, torx, phillips, slotted, none]
nut_style = "standard"; // [standard, flange, nyloc, acorn, wing]
washer_style = "standard"; // [standard, fender]
tslot_series = 20; // [20, 30]

head_height = 3; // [0.8:0.1:15] mm
head_diameter = 5.5; // [1.5:0.1:25] mm
drive_size = 2.5; // [0.5:0.1:12] mm
drive_width = 0.7; // [0.2:0.1:4] mm
drive_depth = 1.2; // [0.3:0.1:8] mm
nut_height = 2.4; // [0.8:0.1:15] mm
nut_across_flats = 5.5; // [2:0.1:25] mm
thread_clearance = 0.20; // [0:0.05:0.8] mm radial
tapping_pitch = 1; // [0.3:0.1:4] mm (prototype self-tapper)
insert_diameter = 4.6; // [2:0.1:24] mm
insert_length = 4.5; // [1:0.2:25] mm
insert_flange_diameter = 5.2; // [0:0.1:30] mm
insert_flange_height = 0.5; // [0:0.1:3] mm
insert_knurl_count = 8; // [0:1:32]
plug_diameter = 7.5; // [2:0.1:30] mm
plug_length = 18; // [3:1:80] mm
plug_bore_diameter = 1.7; // [0.5:0.1:15] mm
plug_slot_width = 0.8; // [0:0.1:4] mm
bolt_count = 4; // [0:1:30]
nut_count = 4; // [0:1:30]
$fn = 72;

major_d = nominal_d(size);
pitch = nominal_pitch(size);
minor_d = major_d - 1.08*pitch;
thread_depth = 0.60*pitch;

module helix_profile(root_r, depth, p, thread_len) {
    crest=0.12*p; base=0.72*p;
    linear_extrude(height=thread_len+2*p,twist=360*(thread_len+2*p)/p,slices=max(20,ceil((thread_len+2*p)*14/p)),convexity=10)
        translate([root_r,0,0]) polygon([[0,-base/2],[depth,-crest/2],[depth,crest/2],[0,base/2]]);
}
module external_threaded_shaft(len) {
    intersection(){ union(){ cylinder(d=minor_d+0.15,h=len); translate([0,0,-pitch]) helix_profile(minor_d/2-0.03,thread_depth,pitch,len); } cylinder(d=major_d,h=len); }
}
module hex_prism(af,h){cylinder(r=af/sqrt(3),h=h,$fn=6);}

module drive_recess(depth) {
    if(drive_type=="hex_drive") cylinder(r=drive_size/sqrt(3),h=depth+0.05,$fn=6);
    else if(drive_type=="torx") for(i=[0:2]) rotate([0,0,i*60]) cube([drive_size*0.35,drive_size,depth+0.05],center=true);
    else if(drive_type=="phillips") union(){translate([-drive_width/2,-drive_size/2,0]) cube([drive_width,drive_size,depth+0.05]);translate([-drive_size/2,-drive_width/2,0]) cube([drive_size,drive_width,depth+0.05]);}
    else if(drive_type=="slotted") translate([-drive_size/2,-drive_width/2,0]) cube([drive_size,drive_width,depth+0.05]);
}

module bolt_head(){
    drive_cut_depth=min(drive_depth,head_height-0.2);
    if(head_style=="hex") hex_prism(head_diameter,head_height);
    else if(head_style=="hex_flange") union(){cylinder(d=head_diameter*1.28,h=max(0.4,head_height*0.22));translate([0,0,head_height*0.22]) hex_prism(head_diameter,head_height*0.78);}
    else if(head_style=="button") difference(){resize([head_diameter,head_diameter,head_height*1.6]) sphere(d=head_diameter);translate([0,0,-head_height]) cube([head_diameter*2,head_diameter*2,head_height*2],center=true);if(drive_type!="none") translate([0,0,head_height*0.8-drive_cut_depth]) drive_recess(drive_cut_depth);}
    else if(head_style=="countersunk") difference(){cylinder(d1=major_d,d2=head_diameter,h=head_height);if(drive_type!="none") translate([0,0,head_height-drive_cut_depth]) drive_recess(drive_cut_depth);}
    else if(head_style=="thumb") difference(){union(){cylinder(d=head_diameter*1.6,h=head_height);for(i=[0:23]) rotate([0,0,i*15]) translate([head_diameter*0.8,-0.3,0]) cube([0.4,0.6,head_height]);}if(drive_type!="none") translate([0,0,head_height-drive_cut_depth]) drive_recess(drive_cut_depth);}
    else difference(){
        cylinder(d=head_diameter,h=head_height);
        if(drive_type!="none") translate([0,0,head_height-drive_cut_depth]) drive_recess(drive_cut_depth);
    }
}

// Cap face at Z=0 for support-free print
module bolt_model(){translate([0,0,bolt_length+head_height]) rotate([180,0,0]) union(){external_threaded_shaft(bolt_length);translate([0,0,bolt_length]) bolt_head();}}

module nut_model(){
    flange_dia=nut_across_flats*1.32;
    flange_h=max(0.5,nut_height*0.24);
    difference(){
        union(){
            if(nut_style=="flange") {cylinder(d=flange_dia,h=flange_h);translate([0,0,flange_h]) hex_prism(nut_across_flats,nut_height-flange_h);}
            else if(nut_style=="nyloc") {hex_prism(nut_across_flats,nut_height);translate([0,0,nut_height]) cylinder(d=nut_across_flats*0.9,h=nut_height*0.35);}
            else if(nut_style=="acorn") {hex_prism(nut_across_flats,nut_height);translate([0,0,nut_height]) intersection(){sphere(d=nut_across_flats*0.95);cylinder(d=nut_across_flats*0.95,h=nut_across_flats*0.5);}}
            else if(nut_style=="wing") {hex_prism(nut_across_flats,nut_height);for(i=[-1,1]) translate([i*nut_across_flats*0.7,0,nut_height*0.5]) cube([nut_across_flats*0.4,nut_across_flats*0.2,nut_height*1.4],center=true);}
            else hex_prism(nut_across_flats,nut_height);
        }
        union(){
            translate([0,0,-0.1]) cylinder(d=minor_d+2*thread_clearance,h=nut_height*1.8+0.2);
            translate([0,0,-pitch]) helix_profile((minor_d+2*thread_clearance)/2-0.02,thread_depth,pitch,nut_height+0.5);
            translate([0,0,-0.01]) cylinder(d1=major_d+2*thread_clearance,d2=minor_d+2*thread_clearance,h=min(0.45,nut_height/4)+0.02);
            translate([0,0,nut_height-min(0.45,nut_height/4)]) cylinder(d1=minor_d+2*thread_clearance,d2=major_d+2*thread_clearance,h=min(0.45,nut_height/4)+0.02);
        }
    }
}

module washer_model(){
    inner_d = major_d + 0.35;
    outer_d = washer_style=="fender" ? max(major_d*3.2, major_d+6) : max(major_d*2.2, major_d+3.5);
    thickness = washer_style=="fender" ? max(0.8, major_d*0.25) : max(0.5, major_d*0.18);
    difference(){
        cylinder(d=outer_d, h=thickness);
        translate([0,0,-0.1]) cylinder(d=inner_d, h=thickness+0.2);
    }
}

module threaded_rod_model(){
    external_threaded_shaft(bolt_length);
}

module set_screw_model(){
    cut_depth = min(drive_depth, bolt_length*0.4);
    difference(){
        external_threaded_shaft(bolt_length);
        translate([0,0,bolt_length-cut_depth]) cylinder(r=drive_size/sqrt(3),h=cut_depth+0.1,$fn=6);
    }
}

module tslot_nut_model(){
    slot_w = tslot_series==30 ? 8 : 6;
    nut_w = tslot_series==30 ? 14 : 10;
    nut_l = tslot_series==30 ? 16 : 11.5;
    nut_h = tslot_series==30 ? 5 : 4;
    neck_h = tslot_series==30 ? 2 : 1.5;
    difference(){
        union(){
            cube([nut_l,nut_w,nut_h-neck_h],center=true);
            translate([0,0,(nut_h-neck_h)/2]) cube([nut_l*0.65,slot_w-0.4,neck_h],center=true);
        }
        cylinder(d=minor_d+2*thread_clearance,h=nut_h*2,center=true);
    }
}

module self_tapping_shaft(){root=max(0.25,major_d-0.95*tapping_pitch); tip=min(bolt_length*0.32,2.2*tapping_pitch); threaded=max(0.5,bolt_length-tip);
    intersection(){union(){translate([0,0,tip]) cylinder(d=root,h=threaded);cylinder(d1=0.35,d2=root,h=tip);translate([0,0,tip-tapping_pitch]) helix_profile(root/2-0.025,0.58*tapping_pitch,tapping_pitch,threaded);} union(){translate([0,0,tip]) cylinder(d=major_d,h=threaded);cylinder(d1=0.35,d2=major_d,h=tip+0.01);}}
}
module self_tapping_model(){translate([0,0,bolt_length+head_height]) rotate([180,0,0]) union(){self_tapping_shaft();translate([0,0,bolt_length]) bolt_head();}}

module heat_set_insert_model(){inner_root=minor_d+2*thread_clearance;body_h=max(0.5,insert_length-insert_flange_height);
    difference(){union(){translate([0,0,insert_flange_height]) cylinder(d=insert_diameter,h=body_h);if(insert_flange_diameter>0) cylinder(d=insert_flange_diameter,h=insert_flange_height);
        if(insert_knurl_count>0) for(i=[0:insert_knurl_count-1]) rotate([0,0,i*360/insert_knurl_count]) translate([insert_diameter/2-0.10,-0.16,insert_flange_height]) cube([0.30,0.32,body_h]);}
        translate([0,0,-0.1]) cylinder(d=inner_root,h=insert_length+0.2);
        translate([0,0,-pitch]) helix_profile(inner_root/2-0.02,thread_depth,pitch,insert_length);
    }
}

module wall_plug_model(){tip=min(plug_length*0.22,plug_diameter*1.4);body=plug_length-tip;slot_start=plug_length*0.30;
    difference(){union(){cylinder(d=plug_diameter,h=body);translate([0,0,body]) cylinder(d1=plug_diameter,d2=plug_diameter*0.30,h=tip);cylinder(d1=plug_diameter*1.18,d2=plug_diameter,h=min(1.2,plug_length*0.12));
        for(i=[0:3]) rotate([0,0,i*90]) translate([plug_diameter*0.42,-0.28,slot_start]) cube([plug_diameter*0.18,0.56,body-slot_start]);}
        translate([0,0,-0.1]) cylinder(d=plug_bore_diameter,h=plug_length+0.2);
        if(plug_slot_width>0) for(i=[0:1]) rotate([0,0,i*90]) translate([-plug_slot_width/2,-plug_diameter,slot_start]) cube([plug_slot_width,plug_diameter*2,plug_length-slot_start+0.1]);
    }
}

module batch_model(){bolt_spacing=max(head_diameter,major_d)+5;nut_spacing=nut_across_flats+5;nut_row_y=max(head_diameter,nut_across_flats)+6;if(bolt_count>0) for(i=[0:bolt_count-1]) translate([i*bolt_spacing,0,0]) { if(part=="self_tapping") self_tapping_model(); else bolt_model(); } if(nut_count>0) for(i=[0:nut_count-1]) translate([i*nut_spacing,nut_row_y,0]) nut_model();}

if(part=="bolt") bolt_model();
else if(part=="nut") nut_model();
else if(part=="washer") washer_model();
else if(part=="threaded_rod") threaded_rod_model();
else if(part=="set_screw") set_screw_model();
else if(part=="tslot_nut") tslot_nut_model();
else if(part=="self_tapping") self_tapping_model();
else if(part=="heat_set_insert") heat_set_insert_model();
else if(part=="wall_plug") wall_plug_model();
else batch_model();
