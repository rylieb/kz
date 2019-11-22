#include "kz.h"
#include "resource.h"
#include "input.h"
#include "zu.h"

static char *stored_song_text[] = {
    "none", "sonata of awakening", "goron's lullaby", "new wave bossa nova", "elegy of emptiness",
    "oath to order", "saria's song", "song of time", "song of healing", "epona's song",
    "song of soaring", "song of storms", "sun's song", "inverted song of time", 
    "song of double time", "goron's lullaby intro"
};

static uint16_t stored_song_values[] = {
    255, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
};

static int debug_menu(struct menu_item *item, enum menu_callback callback, void *data){
    if(zu_ingame() && z2_game.cutscene_state == 0){
        if(z2_game.pause_ctx.state == 0){
            z2_game.pause_ctx.state = 1;
                z2_pause_persp(&z2_game);
                z2_game.pause_ctx.unk_0x202 = (z2_game.pause_ctx.screen_idx * 2) + 1;
        }
        z2_game.pause_ctx.debug_menu = 1;
        reserve_buttons(BUTTON_D_DOWN | BUTTON_D_RIGHT | BUTTON_D_LEFT | BUTTON_D_RIGHT | BUTTON_L);
        kz.debug_active = 1;
        kz.menu_active = 0;
        kz.pending_frames = -1;
    }else{
        kz_log("cannot debug menu here");
    }
    return 1;
}

static int time_of_day_callback(struct menu_item *item, enum menu_callback callback, void *data, uint32_t value){
    for(z2_actor_t *actor = z2_game.actor_ctxt.actor_list[0].first;actor;actor=actor->next){
        if(actor->id == 0x15A){
            if(z2_file.daynight == 1 && (value>=0xC000 || value < 0x4000)){
                z2_file.daynight = 0;
            }else if(z2_file.daynight == 0 && (value<=0xC000 || value >= 0x4000)){
                z2_file.daynight = 1;
            }
            z2_timer_t *timer = (z2_timer_t*)actor;
            timer->daynight = z2_file.daynight;
            timer->timer_boundaries[0] = (uint16_t)value;
            if(value<0x4000){
                timer->timer_boundaries[1] = 0x4000;
            }else{
                timer->timer_boundaries[1] = 0xC000;
            }
            timer->timer_boundaries[2] = (uint16_t)value;
            break;
        }
    }
    return 0;
}

struct menu *create_file_menu(){
    static struct menu file;
    menu_init(&file,0,0);
    file.selected_item = menu_add_button(&file,0,0,"return",menu_return,NULL);
    draw_info_t draw_info = {
        resource_get(R_KZ_CHECKBOX), 1,-1, 1.f, 1.f, 8,8,{{0xFF,0xFF,0xFF,0xFF}}, {{0xFF,0xFF,0xFF,0xFF}},0,checkbox_bg
    };
    menu_add_gfx_switch(&file,0,1,&z2_file.intro_flag,1,0x01,NULL,NULL,&draw_info);
    menu_add(&file,2,1,"intro watched");
    menu_add_gfx_switch(&file,0,2,&z2_file.week_event_inf[0x17],1,0x02,NULL,NULL,&draw_info);
    menu_add(&file,2,2,"great spin");
    menu_add_button(&file,0,3,"debug menu",debug_menu,NULL);
    menu_add(&file,0,4,"stored song");
    menu_add_list(&file,12,4,stored_song_text,stored_song_values,2,sizeof(stored_song_values)/sizeof(*stored_song_values),&z2_stored_song,NULL,NULL);
    menu_add(&file,0,5,"current day");
    menu_add_number_input(&file,12,5,NULL,NULL,10,1,&z2_file.day,4);
    menu_add(&file,0,6,"time of day");
    menu_add_number_input(&file,12,6,time_of_day_callback,NULL,16,4,&z2_file.time_of_day,2);
    menu_add(&file,0,7,"time speed");
    menu_add_number_input(&file,12,7,NULL,NULL,-10,2,&z2_file.timespeed,4);
    return &file;
}