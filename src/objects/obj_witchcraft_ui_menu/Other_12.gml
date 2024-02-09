/// @desc Register input events for this menu.

var input = menuNav.input;
input.cursorEvent(mouse_x, mouse_y);
input.moveEvent(
    keyboard_check(vk_left) || keyboard_check(vk_shift) && mouse_wheel_up(),
    keyboard_check(vk_up) || mouse_wheel_up(),
    keyboard_check(vk_right) || keyboard_check(vk_shift) && mouse_wheel_down(),
    keyboard_check(vk_down) || mouse_wheel_down()
);
input.confirmEvent(
    mouse_check_button(mb_left) ||
    keyboard_check(vk_space) ||
    keyboard_check(vk_enter)
);