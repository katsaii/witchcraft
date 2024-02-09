/// @desc Update menu input

// fade the menu in/out
var prevFade = menuFade;
if (menuActive) {
    menuFade += menuFadeSpeed;
} else {
    menuFade -= menuFadeSpeed;
    if (menuFade < 0) {
        instance_destroy();
        exit;
    }
}
menuFade = clamp(menuFade, 0, 1);
if (menuLayoutUsesFade && menuFade != prevFade) {
    // dynamic menu, maybe it slides in/out from off-screen
    event_user(1);
}

// ignore input if not the top menu
var topMenu = wui_menu_top();
menuIsTop = topMenu == self;
if (!menuIsTop) {
    exit;
}

// register events for the top menu
event_user(2);

// handle events
if (menuRoot != undefined) {
    menuNav.navigate(menuRoot, menuDefaultSelection);
}