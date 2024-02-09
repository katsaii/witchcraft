/// @desc Draw menu.

if (menuLayoutUsesFade || menuActive) {
    menuRoot.draw(menuNav);
    if (__wui_menu_debug().enabled) {
        menuRoot.drawDebug(menuNav);
    }
}