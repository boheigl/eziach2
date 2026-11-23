// echoes the key's heights for key_video.py
include <../key.scad>
part = "none";
echo(GEOM = [["pcb_t", pcb_t], ["z_top", z_top], ["z_bot", z_bot], ["sens_h", sens_h], ["z_cb", z_cb], ["mag_l", mag_l], ["mag_seat", mag_seat],
             ["collar_h", collar_h], ["z_bush0", z_bush[0]], ["bush_l", bush_l], ["z_tt", z_tt], ["z_seat", z_seat],
             ["z_cu", z_cu], ["z_ct", z_ct], ["skirt_l", skirt_l], ["oring_seat", oring_seat], ["oring_cs", oring_cs],
             ["cover_t", cover_t], ["z_sht", z_sht], ["stroke", stroke], ["cap_sock", cap_sock], ["stop_t", stop_t]]);
