#include <stdlib.h>
#include "menu.h"
#include "resource.h"

struct bit_switch_data{
    void                   *addr;
    uint8_t                 addr_len;
    uint32_t                bitmask;
    gfx_texture            *texture;
    uint16_t                tex_width;
    uint16_t                tex_height;
    int                     tile;
    _Bool                   has_off_tile;
    uint32_t                color;
    uint32_t                off_color;
    menu_generic_callback   callback;
    void                   *callback_data;
    _Bool                   load_item;
};

static void draw_bit_switch_proc(struct menu_item *item){
    struct bit_switch_data *data = item->data;
    gfx_texture *texture = data->texture;
    int tile = data->tile;
    if(data->load_item){
        texture = get_item_texture(tile);
        tile = 0;
    }
    if(item->owner->selected_item == item){
        gfx_draw_rectangle(get_item_x_pos(item),get_item_y_pos(item),data->tex_width,data->tex_height,GPACK_RGBA8888(0x80,0x80,0xFF,0x80));
    }

    uint32_t val = 0;
    switch(data->addr_len){
        case 1:
            val = *(uint8_t*)data->addr;
            break;
        case 2:
            val = *(uint16_t*)data->addr;
            break;
        case 4:
        default:
            val = *(uint32_t*)data->addr;
            break;
    }
    uint32_t color = data->color;
    if(!(val & data->bitmask)){
        if(data->has_off_tile){
            size_t tiles_cnt = texture->x_tiles * texture->y_tiles;
            if(tiles_cnt==2) tile++;
            else{
                tile = tile + (texture->x_tiles * texture->y_tiles)/2;
            }
        }else{
            color = data->off_color;
        }
    }
    gfx_draw_sprite_color(texture,get_item_x_pos(item),get_item_y_pos(item),tile,data->tex_width,data->tex_height,color);
}

static void activate_bit_switch_proc(struct menu_item *item){
    struct bit_switch_data *data = item->data;
    if(data->callback && data->callback(item, MENU_CALLBACK_ACTIVATE, data->callback_data)){
        return;
    }
    switch(data->addr_len){
        case 1:
            *(uint8_t*)(data->addr) = *(uint8_t*)(data->addr) ^ data->bitmask;
            break;
        case 2:
            *(uint16_t*)(data->addr) = *(uint16_t*)(data->addr) ^ data->bitmask;
            break;
        case 4:
        default:
            *(uint32_t*)(data->addr) = *(uint32_t*)(data->addr) ^ data->bitmask;
            break;
    }
}

struct menu_item *menu_add_bit_switch(struct menu *menu, uint16_t x, uint16_t y,
                                            void *addr, uint8_t addr_len, uint32_t bitmask,
                                            menu_generic_callback callback, void *callback_data,
                                            gfx_texture *texture, uint16_t tex_width, uint16_t tex_height,
                                            uint16_t tile, _Bool has_off_tile, char *tooltip,
                                            uint32_t on_color, uint32_t off_color, _Bool load_item){
    struct menu_item *item = menu_add(menu,x,y,NULL);
    if(item){
        struct bit_switch_data *data = malloc(sizeof(*data));
        data->addr = addr;
        data->addr_len = addr_len;
        data->bitmask = bitmask;
        data->texture = texture;
        data->tile = tile;
        data->tex_width = tex_width;
        data->tex_height = tex_height;
        data->has_off_tile = has_off_tile;
        data->color = on_color;
        data->off_color = off_color;
        data->callback = callback;
        data->callback_data = callback_data;
        data->load_item = load_item;
        item->draw_proc = draw_bit_switch_proc;
        item->activate_proc = activate_bit_switch_proc;
        item->tooltip = tooltip;
        item->interactive = 1;
        item->data = data;
    }
    return item;
}