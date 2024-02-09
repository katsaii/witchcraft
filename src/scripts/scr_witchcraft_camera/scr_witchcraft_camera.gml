//! A micro-library for improved rendering of the application surface, GUI,
//! and cameras.
//!
//! @remark
//!   May result in strange behaviour when used in conjunction with the
//!   standard `application` functions.

//# feather use syntax-errors

show_debug_message("enchanted with Witchcraft::camera by @katsaii");

/// The number of views supported by GameMaker.
///
/// @return {Real}
#macro WCAM_VIEW_COUNT 8

/// @ignore
///
/// @return {Bool}
function __wcam_view_first_visible() {
    if (view_enabled) {
        for (var i = 0; i < WCAM_VIEW_COUNT; i += 1) {
            if (view_visible[i]) {
                return i;
            }
        }
    }
    return undefined;
}

/// @ignore
///
/// @return {Bool}
function __wcam_view_first_invisible() {
    for (var i = 0; i < WCAM_VIEW_COUNT; i += 1) {
        if (!view_visible[i]) {
            return i;
        }
    }
    return undefined;
}

/// @ignore
///
/// @return {Bool}
function __wcam_use_default_view() {
    gml_pragma("forceinline");
    return __wcam_view_first_visible() == undefined;
}

/// @ignore
///
/// @param {Real} dividend
/// @param {Real} divisor
/// @return {Real}
function __wcam_safe_div(dividend, divisor) {
    gml_pragma("forceinline");
    return divisor == 0 ? 1 : dividend / divisor;
}

/// Returns an array containing the left, top, right, and bottom positions
/// of the smallest bounding box capable of surrounding all visible view ports.
///
/// @return {Array<Real>}
function wcam_view_ports_get_position() {
    if (__wcam_use_default_view()) {
        // views aren't enabled, use the default camera size
        var cam = camera_get_default();
        return [0, 0, camera_get_view_width(cam), camera_get_view_height(cam)];
    }
    var left = infinity;
    var top = infinity;
    var right = -infinity;
    var bottom = -infinity;
    for (var i = WCAM_VIEW_COUNT - 1; i >= 0; i -= 1) {
        if (!view_visible[i]) {
            continue;
        }
        var ox = view_xport[i];
        var oy = view_yport[i];
        left = min(left, ox);
        top = min(top, oy);
        right = max(right, ox + view_wport[i]);
        bottom = max(bottom, oy + view_hport[i]);
    }
    return [left, top, right, bottom];
}

/// Resizes the application surface to be pixel-perfect, using the primary
/// view as a basis for the scale.
///
/// @param {Real} [primaryView]
///   The ID of the primary view, guaranteed to have zero pixel distortion.
///   If the remaining views and their ports are not a similar scale to this
///   view, there is a possibility of pixel distortion.
function wcam_application_fix_surface_size(primaryView = undefined) {
    if (!application_surface_is_enabled()) {
        return;
    }
    var appW, appH;
    if (__wcam_use_default_view()) {
        // views aren't enabled, use the default camera size
        var cam = camera_get_default();
        appW = camera_get_view_width(cam);
        appH = camera_get_view_height(cam);
    } else {
        // scale the application surface based off of the total view port
        // bounding box and the size of the primary view camera
        primaryView ??= __wcam_view_first_visible();
        var portsMax = wcam_view_ports_get_position();
        var portsW = portsMax[2] - portsMax[0];
        var portsH = portsMax[3] - portsMax[1];
        var camScaleX = __wcam_safe_div(portsW, view_wport[primaryView]);
        var camScaleY = __wcam_safe_div(portsH, view_hport[primaryView]);
        var camW = camera_get_view_width(view_camera[primaryView]);
        var camH = camera_get_view_height(view_camera[primaryView]);
        appW = round(camScaleX * camW);
        appH = round(camScaleY * camH);
    }
    appW = clamp(appW, 0, window_get_width());
    appH = clamp(appH, 0, window_get_height());
    surface_resize(application_surface, appW, appH);
}

/// @ignore
///
/// @return {Array<Struct>}
function __wcam_transform_create_result() {
    var views = array_create(WCAM_VIEW_COUNT);
    for (var i = WCAM_VIEW_COUNT - 1; i >= 0; i -= 1) {
        views[@ i] = { posX : 0, posY : 0, inView : false };
    }
    return views;
}

/// Transforms a position relative to the top-left corner of the game window
/// into world positions for every active view.
///
/// @param {Real} posX
///   The X position of the point to transform.
///
/// @param {Real} posY
///   The Y position of the point to transform.
///
/// @param {Array<Real>} [posApp]
///   The bounding box of the application surface, obtained by calling
///   `application_get_position()`.
///
/// @param {Array<Real>} [cachedResult]
///   The previous result of this call, used to avoid creating lots of garbage
///   every frame.
///
/// @return {Array<Struct>}
function wcam_transform_window_to_views(
    posX, posY, posApp = undefined, cachedResult = undefined
) {
    posApp ??= application_get_position();
    var result = cachedResult ?? __wcam_transform_create_result();
    // window position -> normalised application surface position (0,1)
    posX = (posX - posApp[0]) / (posApp[2] - posApp[0]);
    posY = (posY - posApp[1]) / (posApp[3] - posApp[1]);
    if (__wcam_use_default_view()) {
        // views aren't enabled, use the default camera position
        var cam = camera_get_default();
        var view = result[0];
        view.posX = camera_get_view_x(cam) + posX * camera_get_view_width(cam);
        view.posY = camera_get_view_y(cam) + posY * camera_get_view_height(cam);
        view.inView = true;
        return result;
    }
    // application surface position (0,1) -> view port position
    var posPort = wcam_view_ports_get_position();
    // NOTE: the rendered view port actually ignores any offsets, we just care
    //       about the total width, this might be a bug by YYG but who knows!
    posX *= posPort[2] - posPort[0];
    posY *= posPort[3] - posPort[1];
    for (var i = WCAM_VIEW_COUNT - 1; i >= 0; i -= 1) {
        if (!view_visible[i]) {
            continue;
        }
        var view = result[i];
        // view port position -> normalised view position (0,1)
        var viewPosX = (posX - view_xport[i]) / view_wport[i];
        var viewPosY = (posY - view_yport[i]) / view_hport[i];
        view.inView = point_in_rectangle(viewPosX, viewPosY, 0, 0, 1, 1);
        // view position -> room world position
        var cam = view_camera[i];
        view.posX = camera_get_view_x(cam) + viewPosX * camera_get_view_width(cam);
        view.posY = camera_get_view_y(cam) + viewPosY * camera_get_view_height(cam);
    }
    return result;
}

/// Utility function for converting window mouse positions to room positions.
/// If you are not manually drawing your application surface at a custom
/// position, you likely don't need this.
///
/// @param {Array<Real>} [posApp]
///   The bounding box of the application surface, obtained by calling
///   `application_get_position()`.
///
/// @return {Array<Struct>}
function wcam_transform_mouse_to_views(posApp = undefined) {
    static result = undefined;
    result = wcam_transform_window_to_views(
        window_mouse_get_x(), window_mouse_get_y(), posApp, result
    );
    return result;
}

/// Disables all views.
function wcam_view_reset_views() {
    view_enabled = false;
    for (var i = WCAM_VIEW_COUNT - 1; i >= 0; i -= 1) {
        view_visible[i] = false;
    }
}

/// Sets up a new view camera with the desired width and height, and returns
/// its ID. Returns `undefined` if the view could not be set up.
///
/// @param {Real} width
///   The width, in pixels, of the view to set up. 
///
/// @param {Real} height
///   The height, in pixels, of the view to set up.
///
/// @param {Real} [portX]
///   The X offset of the view port to set up. Defaults to 0.
///
/// @param {Real} [portY]
///   The Y offset of the view port to set up. Defaults to 0.
///
/// @param {Real} [portW]
///   The width of the view port to set up. Defaults to the view width.
///
/// @param {Real} [portH]
///   The height of the view port to set up. Defaults to the view height.
///
/// @return {Real}
function wcam_view_setup_1p(
    width, height, portX = 0, portY = 0, portW = undefined, portH = undefined
) {
    var idx = __wcam_view_first_invisible();
    if (idx == undefined) {
        // TODO: actual error message here?
        return idx;
    }
    view_enabled = true;
    view_visible[idx] = true;
    view_xport[idx] = portX;
    view_yport[idx] = portY;
    view_wport[idx] = portW ?? width;
    view_hport[idx] = portH ?? height;
    camera_set_view_size(view_camera[idx], width, height);
}