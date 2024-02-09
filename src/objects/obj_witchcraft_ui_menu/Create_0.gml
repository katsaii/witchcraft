/// @desc Initialise common menu properties

var me = self;

// menu properties
menuNav = new WUINavigator();
menuRoot = undefined;
menuDefaultSelection = undefined;
menuPriority = 0;
menuIsTop = true;
menuLayoutUsesFade = false;

// menu fade in/out
menuActive = true;
menuFade = 0;
menuFadeSpeed = self[$ "menuFadeSpeed"] ?? 0.1;

// calculate the actual priority of this menu
var topMenu = wui_menu_top();
menuPriority = topMenu.menuPriority + 1;
if (topMenu.depth < depth) {
    // make sure that menus with higher priorities render on top of
    // those with lower priorities
    depth = topMenu.depth - 1;
}

// call the menu initialiser
event_user(0);
event_user(1);

// focus on the default element immediately
menuNav.setFocusedElement(menuDefaultSelection);