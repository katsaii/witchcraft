//! Misc useful extensions to the GML standard library.

//# feather use syntax-errors

show_debug_message("enchanted with Witchcraft::toolbox by @katsaii");

/// All drawing beyond this point will use a solid colour. Might only
/// work for 2D games with an orthographic projection. Will need some
/// testing.
///
/// @param {Real} [colour]
///   The colour to draw with. Defaults to the current draw colour.
function wdraw_set_solid(colour) {
    gml_pragma("forceinline");
    gpu_set_fog(true, colour ?? draw_get_colour(), 0, 0);
}

/// Stops drawing with a solid colour.
function wdraw_reset_solid() {
    gml_pragma("forceinline");
    gpu_set_fog(false, c_black, 0, 1);
}

/// Draws part of a source surface region to part of a destination surface
/// region.
///
/// TODO: document
function wsurface_copy_part_pos_ext(
    dest, destX1, destY1, destX2, destY2,
    src, srcX1, srcY1, srcX2, srcY2, colour = c_white
) {
    var reflectX = false;
    var reflectY = false;
    if (srcX2 < srcX1) {
        var tx = srcX1;
        srcX1 = srcX2;
        srcX2 = tx;
        reflectX = !reflectX;
    }
    if (srcY2 < srcY1) {
        var ty = srcY1;
        srcY1 = srcY2;
        srcY2 = ty;
        reflectY = !reflectY;
    }
    if (destX2 < destX1) {
        var tx = destX1;
        destX1 = destX2;
        destX2 = tx;
        reflectX = !reflectX;
    }
    if (destY2 < destY1) {
        var ty = destY1;
        destY1 = destY2;
        destY2 = ty;
        reflectY = !reflectY;
    }
    var scaleX = (destX2 - destX1) / (srcX2 - srcX1);
    var scaleY = (destY2 - destY1) / (srcY2 - srcY1);
    var posX, posY;
    if (reflectX) {
        posX = destX2;
        scaleX *= -1;
    } else {
        posX = destX1;
    }
    if (reflectY) {
        posY = destY2;
        scaleY *= -1;
    } else {
        posY = destY1;
    }
    surface_set_target(dest);
    draw_surface_part_ext(
        src, srcX1, srcY1, srcX2 - srcX1, srcY2 - srcY1,
        posX, posY, scaleX, scaleY, colour, 1
    );
    surface_reset_target();
}

/// Draws part of a source surface region scale the the whole size of a
/// destination surface.
///
/// TODO: document
function wsurface_copy_part_pos(
    dest, src, srcX1, srcY1, srcX2, srcY2, colour = undefined
) {
    wsurface_copy_part_pos_ext(
        dest, 0, 0, surface_get_width(dest), surface_get_height(dest),
        src, srcX1, srcY1, srcX2, srcY2, colour
    );
}

/// Takes a rectangle and an aspect ratio, then returns the bounding box of
/// the largest rectangle with the expected aspect ratio that will fit
/// entirely into the target rectangle. The resulting bounding box will be
/// centred within the target rectangle.
///
/// @param {Real} x1
///   The left position of the target rectangle.
///
/// @param {Real} y1
///   The top position of the target rectangle.
///
/// @param {Real} x2
///   The right position of the target rectangle.
///
/// @param {Real} y2
///   The bottom position of the target rectangle.
///
/// @param {Real} width
///   The width component of the aspect ratio.
///
/// @param {Real} height
///   The height component of the aspect ratio.
///
/// @param {Function} [scaleModifier]
///   An optional function which can be used to modify the scale value of
///   the fitted rectangle. For example, clamping scale within a range,
///   or rounding it to whole numbers.
///
/// @return {Array<Real>}
function wrectangle_scale_to_fit(
    x1, y1, x2, y2, width, height, scaleModifier = undefined
) {
    if (x2 < x1) {
        var t = x1;
        x1 = x2;
        x2 = t;
    }
    if (y2 < y1) {
        var t = y1;
        y1 = y2;
        y2 = t;
    }
    var scaleWidth = width == 0 ? infinity : (x2 - x1) / width;
    var scaleHeight = height == 0 ? infinity : (y2 - y1) / height;
    var scale = min(scaleWidth, scaleHeight);
    if (scaleModifier != undefined) {
        scale = scaleModifier(scale);
    }
    var centreX = mean(x1, x2);
    var centreY = mean(y1, y2);
    var fitWidth = width * scale;
    var fitHeight = height * scale;
    var fitLeft = floor(centreX - fitWidth / 2);
    var fitTop = floor(centreY - fitHeight / 2);
    var fitRight = fitLeft + fitWidth;
    var fitBottom = fitTop + fitHeight;
    return [fitLeft, fitTop, fitRight, fitBottom];
}

/// Maps a number from one range to another.
///
/// @param {Real} value
///   The value to map.
///
/// @param {Real} min1
///   The minimum bound of the source range.
///
/// @param {Real} max1
///   The maximum bound of the source range.
///
/// @param {Real} min2
///   The minimum bound of the destination range.
///
/// @param {Real} max2
///   The maximum bound of the destination range.
function wmap_range(value, min1, max1, min2, max2) {
    gml_pragma("forceinline");
    var dx = max1 - min1;
    var dy = max2 - min2;
    return dx == 0 ? NaN : (value - min1) / dx * dy + min2;
}

/// Checks whether the device is a desktop OS.
///
/// @return {Bool}
function wos_is_pc() {
    gml_pragma("forceinline");
    if (os_browser == browser_not_a_browser) {
        switch (os_type) {
        case os_windows:
        case os_linux:
        case os_macosx:
            return true;
        }
    }
    return false;
}

/// Checks whether the device is a browser.
///
/// @return {Bool}
function wos_is_browser() {
    gml_pragma("forceinline");
    return os_browser != browser_not_a_browser;
}

/// Converts a value into a string using its raw representation.
///
/// @param {Any} value
///   The value to convert.
///
/// @return {String}
function wstring_repr(value) {
    if (is_string(value)) {
        return value;
    }
    if (wis_ref(value)) {
        return string(ptr(value));
    }
    return string(value);
}

/// Returns whether this value is a reference type.
///
/// @param {Any} value
///   The argument to check.
///
/// @return {Bool}
function wis_ref(value) {
    return is_struct(value) || is_method(value) || is_array(value);
}

/// Returns whether a value is allowed to be used as a conditional.
///
/// @param {Any} value
///   The argument to check.
///
/// @return {Bool}
function wis_conditional(value) {
    try {
        if (value) {
            return true;
        }
    } catch (_) {
        return false;
    }
    return true;
}

/// Returns whether a value is 'truthy'. This follows basic type checking
/// rules, except any value which would otherwise raise an exception when
/// used as a conditional will return `false` instead.
///
/// @param {Any} value
///   The argument to check.
///
/// @return {Bool}
function wis_truthy(value) {
    try {
        return value ? true : false;
    } catch (_) {
        return false;
    }
}

/// Returns whether a value is 'falsy'. This follows basic type checking
/// rules, except any value which would otherwise raise an exception when
/// used as a conditional will return `true` instead.
///
/// @param {Any} value
///   The argument to check.
///
/// @return {Bool}
function wis_falsy(value) {
    try {
        return value ? false : true;
    } catch (_) {
        return true;
    }
}

/// Computes the weighted sum of an arbitrary number of samples.
///
/// @param {Real} w1
///   The weight of the first sample.
///
/// @param {Real} v1
///   The value of the first sample.
///
/// @param {Real} w2
///   The weight of the second sample.
///
/// @param {Real} v2
///   The value of the second sample.
///
/// @param {Real} ...
///   Addtional samples in the same weight-value format.
///
/// @return {Real}
function wblend() {
    var sum = 0;
    var sum_weight = 0;
    for (var i = 0; i < argument_count; i += 2) {
        sum_weight += argument[i + 0];
    }
    if (sum_weight == 0) {
        sum_weight = 1;
    }
    for (var i = 0; i < argument_count; i += 2) {
        sum += argument[i + 0] / sum_weight * argument[i + 1];
    }
    return sum;
}