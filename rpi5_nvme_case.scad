// ==============================================================================
// OBUDOWA RASPBERRY PI 5 + M.2 HAT+ (WERSJA V11 - WYŻSZE OKNA USB-A +2 MM)
// - Przednie okna na porty USB-A podwyższone o 2 mm (z 15.8 mm na 17.8 mm)
// - Nóżki przeprojektowane specjalnie pod druk z elastycznego TPU (wcisk z nadwymiarowym
//   czopem +0.15 mm, pierścieniem rozporowym +0.35 mm oraz 4 żebrami dociskowymi w gnieździe 5.4 mm!)
// - Zwiększony luz wokół płytki PCB: pcb_clearance = 1.0 mm (łatwiejsze wkładanie płytki)
// - Zablokowany na sztywno rozstaw otworów montażowych pod już wydrukowany "Badge":
//   badge_pin_dx = 83.8 mm oraz badge_pin_dy = 46.8 mm
// - Czyste wycięcie górnej komory bez Z-fightingu
// - Dolna obudowa z pełnymi okienkami z przodu i z boku oraz gładkim tyłem (bez okien SD)
// - Płaski dekiel górny z ciągłą prowadnicą 2.4 mm dookoła + nakładka "badge" + 4 nóżki TPU
// ==============================================================================

$fn = 60;

// --- CO CHCESZ WYGENEROWAĆ? ---
// "all"       = dół, płaski dekiel górny, nakładka logo + 4 nóżki (gotowe do druku)
// "both"      = dół i dekiel górny obok siebie (bez badge'a, skoro już wydrukowany)
// "bottom"    = tylko dół
// "top"       = tylko dekiel górny
// "badge"     = tylko nakładka logo
// "feet"      = tylko 4 nóżki dystansowe (do osobnego wydruku z TPU!)
// "assembled" = podgląd złożenia 3D z nakładką i nóżkami
render_mode = "all"; 

// --- KONFIGURACJA PEŁNOWYMIAROWEJ NAKŁADKI LOGO (BADGE) ---
logo_type = "custom_text";            // ["custom_text", "raspberry", "svg", "none"]
logo_string = "ToMati";               // Tekst dla trybu "custom_text"
logo_subtext = "NAS // RPi5";         // Podpis pod napisem
logo_svg_file = "logo.svg";           // Plik SVG (dla logo_type = "svg")
logo_depth = 1.0;                     // Głębokość graweru/reliefu na nakładce [mm]

logo_standoff_h = 8.0;                // Odstęp nakładki od góry obudowy [mm]
badge_thick = 2.8;                    // Grubość płytki nakładki logo [mm]
badge_pin_d = 4.4;                    // Średnica czopów montażowych nakładki [mm]
badge_pin_tol = 0.20;                 // Luz pasowania kołków w otworach obudowy [mm]
badge_pin_depth = 2.4;                // Głębokość gniazd pod kołki w górnym deklu [mm]

logo_scale = 1.45;                    // Skala logo dopasowana do pełnego obrysu obudowy
logo_svg_target_w = 50.0;             // Szerokość bazowa SVG w mm (przed skalowaniem)
logo_rot = 0;                         // Obrót logo w stopniach
logo_offset_x = 0.0;                  // Przesunięcie X
logo_offset_y = 0.0;                  // Przesunięcie Y

// --- GŁÓWNE PARAMETRY WYMIAROWE I PRZEDŁUŻENIE TYŁU NA TAŚMĘ PCIe ---
rear_pcie_ext = 8.0;                  // Przedłużenie tyłu obudowy na łuk taśmy M.2 HAT+ i kartę SD [mm]
nvme_heatsink_extra_h = 18.0;         // Zapas wysokości na radiator NVMe [mm]
wall = 2.8;                           // Grubość ścianek bocznych [mm]
bottom_thick = 3.2;                   // Grubość dna (mieści gniazda pod nóżki) [mm]
top_thick = 2.8;                      // Grubość górnego dekla [mm]
pcb_clearance = 1.0;                  // Zwiększony luz wokół płytki PCB (1.0 mm)

// --- ŚRUBY M2.5 OD DOŁU (TYLKO 1.0 MM ŚCIANKI DO PŁYTKI PCB!) + NÓŻKI Z TPU NA WCISK ---
m25_through_d = 2.75;                 // Przelot dla gwintu śruby M2.5 (przez 1.0 mm ścianki pod PCB)
m25_wall_to_pcb = 1.0;                // Grubość ścianki oddzielającej łeb śruby M2.5 od płytki PCB [mm]
m25_head_pocket_d = 5.4;              // Średnica dodatkowego wycięcia na łeb śruby M2.5 w kołku [mm]
foot_socket_d = 8.0;                  // Średnica szerszego gniazda od spodu pod wciskaną nóżkę [mm]
foot_socket_h = 2.2;                  // Głębokość gniazda w dnie obudowy pod czop nóżki [mm]
foot_air_gap_h = 5.0;                 // Wysokość nóżek (prześwit pod obudową na wlot powietrza) [mm]
foot_outer_d = 12.5;                  // Średnica zewnętrzna podstawy nóżki [mm]

// Parametry pasowania na wcisk pod elastyczne TPU (ujemny luz = nadwymiar!):
foot_tpu_oversize = 0.15;             // Nadwymiar czopa 8 mm (+0.15 mm -> czop ma 8.15 mm i wchodzi ciasno w gniazdo 8.0 mm!)
foot_tpu_rib_oversize = 0.35;         // Nadwymiar pierścienia zaciskowego (+0.35 mm -> 8.35 mm dla pewnego zakleszczenia TPU)
foot_inner_collar_h = 1.4;            // Dodatkowy górny kołnierz wchodzący w głębszy otwór 5.4 mm (nad gniazdem 8.0 mm)

// --- WYMIARY BAZOWE RASPBERRY PI 5 ---
pcb_l = 85.0;
pcb_w = 56.0;
pcb_thick = 1.6;
corner_r = 3.5;

// Kołki montażowe RPi 5
hole_dx = 58.0;
hole_dy = 49.0;
hole_offset = 3.5;
standoff_h = 3.0;                     // Wysokość kołka dystansowego nad dnem obudowy [mm]
standoff_od = 7.8;                    // Poszerzony kołek (mieści wewnątrz kieszeń 5.4 mm na łeb śruby M2.5)

// Wysokość bazowa do M.2 HAT+ i całkowite wymiary
hat_base_h = standoff_h + pcb_thick + 16.0 + 1.6; 
inner_l = pcb_l + 2 * pcb_clearance + rear_pcie_ext;
inner_w = pcb_w + 2 * pcb_clearance;
inner_h = hat_base_h + nvme_heatsink_extra_h;

outer_l = inner_l + 2 * wall;
outer_w = inner_w + 2 * wall;
outer_h = inner_h + bottom_thick + top_thick;

// --- ZABLOKOWANE WYMIARY I ROZSTAW KOŁKÓW DLA JUŻ WYDRUKOWANEGO "BADGE" ---
badge_l = 99.8;                       // Długość wydrukowanego badge'a (z wersji pcb_clearance = 0.6)
badge_w = 62.8;                       // Szerokość wydrukowanego badge'a (z wersji pcb_clearance = 0.6)
badge_corner_r = corner_r + wall;
badge_pin_dx = 83.8;                  // STAŁY ROZSTAW KOŁKÓW X (99.8 - 16.0 = 83.8 mm)
badge_pin_dy = 46.8;                  // STAŁY ROZSTAW KOŁKÓW Y (62.8 - 16.0 = 46.8 mm)

// Pozycja startowa płytki PCB (przesunięta o rear_pcie_ext od pełnej tylnej ścianki)
pcb_x0 = wall + pcb_clearance + rear_pcie_ext;
pcb_y0 = wall + pcb_clearance;
pcb_z0 = bottom_thick + standoff_h + pcb_thick;

// --- PODZIAŁ OBUDOWY: CAŁA ŚCIANKA BOCZNA W DOLNEJ CZĘŚCI, GÓRA TO PŁASKI DEKIEL ---
split_z = outer_h - top_thick;
lip_h = 4.0;                          // Wysokość prowadnicy wchodzącej w dolną obudowę [mm]
lip_thick = 2.4;                      // Grubość prowadnicy dookoła (2.4 mm = 6 obrysów dyszy 0.4 mm)
lip_tol = 0.20;                       // Luz pasowania między prowadnicą a dolną ścianką [mm]

// ==============================================================================
// MODUŁY POMOCNICZE I KSZTAŁT LOGO 2D
// ==============================================================================

module rounded_box(l, w, h, r) {
    hull() {
        translate([r, r, 0]) cylinder(r=r, h=h);
        translate([l-r, r, 0]) cylinder(r=r, h=h);
        translate([r, w-r, 0]) cylinder(r=r, h=h);
        translate([l-r, w-r, 0]) cylinder(r=r, h=h);
    }
}

module fdm_slot_x(w_slot, len_y, h_slot) {
    chamfer = w_slot / 2;
    hull() {
        translate([0, 0, chamfer])
            cube([w_slot, len_y, max(0.1, h_slot - 2 * chamfer)]);
        translate([chamfer, 0, 0])
            cube([0.01, len_y, h_slot]);
    }
}

module logo_2d_shape() {
    translate([logo_offset_x, logo_offset_y])
    rotate([0, 0, logo_rot])
    scale([logo_scale, logo_scale]) {
        if (logo_type == "custom_text") {
            difference() {
                hull() {
                    translate([-14, 0]) circle(r=12, $fn=6);
                    translate([14, 0]) circle(r=12, $fn=6);
                }
                hull() {
                    translate([-14, 0]) circle(r=10.4, $fn=6);
                    translate([14, 0]) circle(r=10.4, $fn=6);
                }
                square([6, 30], center=true);
            }
            translate([0, 2])
                text(logo_string, size=7.2, font="Liberation Sans:style=Bold", halign="center", valign="center");
            translate([0, -5.5])
                text(logo_subtext, size=3.2, font="Liberation Mono:style=Bold", halign="center", valign="center");
        } else if (logo_type == "raspberry") {
            scale([0.85, 0.85]) {
                for (pos = [[-5.5, 4], [5.5, 4], [-7, -2.5], [7, -2.5], [-3.8, -8.5], [3.8, -8.5], [0, -2], [0, 5.5], [0, -10]]) {
                    translate(pos) difference() {
                        circle(r=4.2);
                        circle(r=2.6);
                    }
                }
                translate([-3.5, 12.5]) rotate([0, 0, 35]) scale([1.6, 0.85]) circle(r=3.5);
                translate([3.5, 12.5]) rotate([0, 0, -35]) scale([1.6, 0.85]) circle(r=3.5);
            }
        } else if (logo_type == "svg") {
            resize([logo_svg_target_w, 0], auto=true)
                import(file = logo_svg_file, center = true, dpi = 96);
                
            translate([0, - (logo_svg_target_w * 0.45) - 3.5])
                text("NAS // RPi5", size=3.2, font="Liberation Mono:style=Bold", halign="center", valign="center");
        }
    }
}

// ==============================================================================
// PEŁNOWYMIAROWA NAKŁADKA LOGO (STAŁY ROZSTAW OTWORÓW 83.8 x 46.8 MM)
// ==============================================================================

module badge_mount_holes() {
    if (logo_type != "none") {
        cx = outer_l / 2;
        cy = outer_w / 2;
        for (dx = [-badge_pin_dx/2, badge_pin_dx/2]) {
            for (dy = [-badge_pin_dy/2, badge_pin_dy/2]) {
                translate([cx + dx, cy + dy, outer_h - badge_pin_depth])
                    cylinder(d = badge_pin_d + badge_pin_tol, h = badge_pin_depth + 1.0);
            }
        }
    }
}

module logo_badge_assembled() {
    cx = outer_l / 2;
    cy = outer_w / 2;
    badge_z0 = outer_h + logo_standoff_h;

    union() {
        difference() {
            translate([cx - badge_l/2, cy - badge_w/2, badge_z0])
                rounded_box(badge_l, badge_w, badge_thick, badge_corner_r);

            if (logo_type != "none") {
                translate([cx, cy, badge_z0 + badge_thick - logo_depth])
                    linear_extrude(height = logo_depth + 1.0)
                        logo_2d_shape();
            }
        }

        for (dx = [-badge_pin_dx/2, badge_pin_dx/2]) {
            for (dy = [-badge_pin_dy/2, badge_pin_dy/2]) {
                translate([cx + dx, cy + dy, 0]) {
                    translate([0, 0, outer_h])
                        cylinder(d1 = badge_pin_d + 2.8, d2 = badge_pin_d + 4.5, h = logo_standoff_h + 0.2);
                    translate([0, 0, outer_h - badge_pin_depth + 0.2])
                        cylinder(d1 = badge_pin_d - 0.5, d2 = badge_pin_d, h = 0.6);
                    translate([0, 0, outer_h - badge_pin_depth + 0.8])
                        cylinder(d = badge_pin_d, h = badge_pin_depth);
                }
            }
        }
    }
}

// ==============================================================================
// DWUSTOPNIOWE WYCIĘCIE POD NÓŻKĘ I ŚRUBĘ M2.5 (ŚCIANKA TYLKO 1.0 MM DO PCB!)
// ==============================================================================

module bottom_m25_and_foot_holes() {
    pcb_bottom_z = bottom_thick + standoff_h;
    screw_head_top_z = pcb_bottom_z - m25_wall_to_pcb;

    for (dx = [hole_offset, hole_offset + hole_dx]) {
        for (dy = [hole_offset, hole_offset + hole_dy]) {
            translate([pcb_x0 + dx, pcb_y0 + dy, 0]) {
                // 1. Szerokie gniazdo od spodu (d = 8.0 mm, h = 2.2 mm) pod wciskaną nóżkę
                translate([0, 0, -0.5])
                    cylinder(d = foot_socket_d, h = foot_socket_h + 0.5);

                // 2. Dodatkowe wycięcie na łeb śruby M2.5 (d = 5.4 mm) aż na 1.0 mm przed płytką PCB!
                translate([0, 0, -0.5])
                    cylinder(d = m25_head_pocket_d, h = screw_head_top_z + 0.5);

                // 3. Otwór przelotowy pod gwint M2.5 (d = 2.75 mm) przez pozostałą ściankę 1.0 mm
                translate([0, 0, -0.5])
                    cylinder(d = m25_through_d, h = pcb_bottom_z + 1.0);
            }
        }
    }
}

// ==============================================================================
// WYCIĘCIA NA PORTY (OKNA USB-A PODWYŻSZONE O 2 MM: Z 15.8 MM NA 17.8 MM!)
// ==============================================================================
module port_cutouts() {
    translate([pcb_x0, pcb_y0, 0]) {
        // 1. PRZÓD (x = pcb_l): Ethernet (14.8 mm) oraz 2x podwójne USB-A podwyższone o 2 mm (17.8 mm!)
        translate([pcb_l - 2, 10.25 - 8.5, pcb_z0 - 0.5]) cube([wall + 10, 17.0, 14.8]);
        translate([pcb_l - 2, 29.0 - 7.8, pcb_z0 - 0.5]) cube([wall + 10, 15.6, 17.8]);
        translate([pcb_l - 2, 47.0 - 7.8, pcb_z0 - 0.5]) cube([wall + 10, 15.6, 17.8]);

        // 2. BOK LEWY (y = 0): Całe okienka na USB-C (zasilanie) oraz 2x micro-HDMI
        translate([11.2 - 5.5, -wall - 5, pcb_z0 - 1.0]) cube([11.0, wall + 10, 6.2]);
        translate([25.8 - 5.5, -wall - 5, pcb_z0 - 1.0]) cube([(39.2 - 25.8) + 11.0, wall + 10, 6.5]);

        // 3. TYŁ (od strony karty SD i taśmy PCIe): całkowicie zamknięty (brak okien).
    }
}

// ==============================================================================
// WENTYLACJA (ROZDZIELONA CZYSTO MIĘDZY DOLNĄ WANNĘ A GÓRNY DEKIEL)
// ==============================================================================

module bottom_ventilation_cuts() {
    slot_w = 2.2;
    slot_step = 5.0;

    long_z_start = bottom_thick + 2.5;
    vent_top_z = split_z - lip_h - 1.5;
    long_z_h = vent_top_z - long_z_start;

    for (x = [14 : slot_step : outer_l - 14]) {
        translate([x, outer_w - wall - 2.0, long_z_start])
            fdm_slot_x(slot_w, wall + 4.0, long_z_h);

        in_hdmi_usbc_zone = (x >= (pcb_x0 + 2.0)) && (x <= (pcb_x0 + 48.0));
        left_z_start = in_hdmi_usbc_zone ? (pcb_z0 + 8.5) : long_z_start;
        left_z_h = vent_top_z - left_z_start;

        translate([x, -2.0, left_z_start])
            fdm_slot_x(slot_w, wall + 4.0, left_z_h);
    }

    standoff_x1 = pcb_x0 + hole_offset;
    standoff_x2 = pcb_x0 + hole_offset + hole_dx;

    for (x = [12 : 5.5 : outer_l - 12]) {
        near_standoff = (abs(x + 1.2 - standoff_x1) < 7.5) || (abs(x + 1.2 - standoff_x2) < 7.5);
        y_margin = near_standoff ? 16.5 : 8.0;
        translate([x, y_margin, -1.0])
            cube([2.4, outer_w - 2 * y_margin, bottom_thick + 2.0]);
    }
}

module top_ventilation_cuts() {
    top_slot_margin_x = wall + lip_tol + lip_thick + 3.0;
    top_slot_margin_y = wall + lip_tol + lip_thick + 2.5;
    cx = outer_l / 2;

    for (x = [top_slot_margin_x : 4.5 : outer_l - top_slot_margin_x]) {
        near_pin_x = (abs(x - (cx - badge_pin_dx/2)) < 5.5) || (abs(x - (cx + badge_pin_dx/2)) < 5.5);
        if (!near_pin_x) {
            translate([x - 1.1, top_slot_margin_y, split_z - 1.0])
                cube([2.2, outer_w - 2 * top_slot_margin_y, top_thick + 2.0]);
        } else {
            translate([x - 1.1, (outer_w - (badge_pin_dy - 12)) / 2, split_z - 1.0])
                cube([2.2, badge_pin_dy - 12, top_thick + 2.0]);
        }
    }
}

// ==============================================================================
// BRYŁY GŁÓWNE (BEZPOŚREDNIE MODELOWANIE BEZ Z-FIGHTINGU NA PŁASZCZYŹNIE SPLIT_Z!)
// ==============================================================================

module bottom_part() {
    difference() {
        union() {
            difference() {
                rounded_box(outer_l, outer_w, split_z, corner_r + wall);
                translate([wall, wall, bottom_thick])
                    rounded_box(inner_l, inner_w, inner_h + 2.0, corner_r);
                port_cutouts();
                bottom_ventilation_cuts();
            }

            // Poszerzone (7.8 mm) kołki dystansowe pod Raspberry Pi 5
            for (dx = [hole_offset, hole_offset + hole_dx]) {
                for (dy = [hole_offset, hole_offset + hole_dy]) {
                    translate([pcb_x0 + dx, pcb_y0 + dy, bottom_thick]) {
                        cylinder(d=standoff_od, h=standoff_h);
                        cylinder(d1=standoff_od + 2.8, d2=standoff_od, h=1.6);
                    }
                }
            }
        }
        bottom_m25_and_foot_holes();
    }
}

// Ciągła prowadnica (360° dookoła) na płaskim górnym deklu
module top_perimeter_lip() {
    difference() {
        union() {
            translate([wall + lip_tol, wall + lip_tol, split_z - lip_h + 0.8])
                rounded_box(inner_l - 2*lip_tol, inner_w - 2*lip_tol, lip_h - 0.8 + 0.6, corner_r);

            hull() {
                translate([wall + lip_tol, wall + lip_tol, split_z - lip_h + 0.8])
                    rounded_box(inner_l - 2*lip_tol, inner_w - 2*lip_tol, 0.1, corner_r);
                translate([wall + lip_tol + 0.7, wall + lip_tol + 0.7, split_z - lip_h])
                    rounded_box(inner_l - 2*(lip_tol + 0.7), inner_w - 2*(lip_tol + 0.7), 0.1, max(0.5, corner_r - 0.7));
            }
        }

        translate([wall + lip_tol + lip_thick, wall + lip_tol + lip_thick, split_z - lip_h - 1.0])
            rounded_box(inner_l - 2*(lip_tol + lip_thick), inner_w - 2*(lip_tol + lip_thick), lip_h + 3.0, max(0.5, corner_r - lip_thick));
    }
}

module top_part() {
    difference() {
        union() {
            translate([0, 0, split_z])
                rounded_box(outer_l, outer_w, top_thick, corner_r + wall);

            top_perimeter_lip();
        }
        top_ventilation_cuts();
        badge_mount_holes();
    }
}

// ==============================================================================
// NÓŻKA ZOPTYMALIZOWANA POD DRUK Z TPU (CIASNY WCISK + PIERŚCIEŃ ROZPOROWY + 2 STOPNIE)
// ==============================================================================
module single_foot_for_print() {
    plug1_d = foot_socket_d + foot_tpu_oversize;
    plug1_rib_d = foot_socket_d + foot_tpu_rib_oversize;
    plug1_h = foot_socket_h;

    plug2_d = m25_head_pocket_d + foot_tpu_oversize;
    plug2_h = foot_inner_collar_h;

    difference() {
        union() {
            // Szeroka stopka dystansowa (5 mm prześwitu pod obudową)
            cylinder(d1 = foot_outer_d, d2 = foot_outer_d - 1.2, h = foot_air_gap_h);

            // Stopień 1: Czop główny 8.15 mm wchodzący w dno obudowy
            translate([0, 0, foot_air_gap_h])
                cylinder(d = plug1_d, h = plug1_h - 0.3);

            // Pierścień rozporowy (barb) 8.35 mm w połowie wysokości gniazda 8.0 mm (klinuje TPU w gnieździe!)
            translate([0, 0, foot_air_gap_h + 0.6])
                cylinder(d1 = plug1_d, d2 = plug1_rib_d, h = 0.6);
            translate([0, 0, foot_air_gap_h + 1.2])
                cylinder(d1 = plug1_rib_d, d2 = plug1_d - 0.3, h = 0.7);

            // Fazka wprowadzająca na czopie 8 mm
            translate([0, 0, foot_air_gap_h + plug1_h - 0.3])
                cylinder(d1 = plug1_d - 0.3, d2 = plug2_d, h = 0.3);

            // Stopień 2: Dodatkowy kołnierz 5.55 mm wchodzący w głębszy otwór 5.4 mm (z fazką na końcu)
            translate([0, 0, foot_air_gap_h + plug1_h])
                cylinder(d = plug2_d, h = plug2_h - 0.4);
            translate([0, 0, foot_air_gap_h + plug1_h + plug2_h - 0.4])
                cylinder(d1 = plug2_d, d2 = plug2_d - 0.8, h = 0.4);
        }

        // Wewnętrzna kieszeń odciążająca (d = 3.6 mm)
        translate([0, 0, 2.2])
            cylinder(d = 3.6, h = foot_air_gap_h + plug1_h + plug2_h + 1.0);

        // 2 krzyżowe nacięcia kompensacyjne na samym czubku czopa
        for (rot_a = [0, 90]) {
            rotate([0, 0, rot_a])
                translate([-0.4, -plug1_rib_d, foot_air_gap_h + 0.8])
                    cube([0.8, 2 * plug1_rib_d, plug1_h + plug2_h + 1.0]);
        }
    }
}

module feet_set_for_print() {
    for (i = [0 : 3]) {
        translate([i * (foot_outer_d + 5), 0, 0])
            single_foot_for_print();
    }
}

module feet_assembled() {
    for (dx = [hole_offset, hole_offset + hole_dx]) {
        for (dy = [hole_offset, hole_offset + hole_dy]) {
            translate([pcb_x0 + dx, pcb_y0 + dy, -foot_air_gap_h])
                single_foot_for_print();
        }
    }
}

module logo_badge_for_print() {
    translate([0, 0, outer_h + logo_standoff_h + badge_thick])
        rotate([180, 0, 0])
            logo_badge_assembled();
}

// ==============================================================================
// RENDEROWANIE
// ==============================================================================
if (render_mode == "bottom") {
    bottom_part();
} else if (render_mode == "top") {
    translate([0, outer_w, outer_h])
        rotate([180, 0, 0])
            top_part();
} else if (render_mode == "badge") {
    logo_badge_for_print();
} else if (render_mode == "feet") {
    feet_set_for_print();
} else if (render_mode == "both") {
    bottom_part();
    translate([0, outer_w * 2 + 10, outer_h])
        rotate([180, 0, 0])
            top_part();
} else if (render_mode == "all") {
    // 1. Pełna dolna obudowa (z pcb_clearance = 1.0 mm i wyższymi o 2 mm oknami USB-A)
    bottom_part();
    // 2. Płaski dekiel górny (ze stałym rozstawem otworów 83.8 x 46.8 mm pod wydrukowany Badge!)
    translate([0, outer_w * 2 + 10, outer_h])
        rotate([180, 0, 0])
            top_part();
    // 3. Pełnowymiarowa nakładka logo
    translate([0, outer_w * 2 + 18 + badge_w, 0])
        logo_badge_for_print();
    // 4. Komplet 4 wciskanych nóżek dystansowych (pod druk z TPU!)
    translate([outer_l + 15, 10, 0])
        feet_set_for_print();
} else if (render_mode == "assembled") {
    bottom_part();
    color("DodgerBlue", 0.85) top_part();
    color("Crimson", 0.95) logo_badge_assembled();
    color("DimGray", 1.0) feet_assembled();
}
