//! Basic UI element types codified into the Witchcraft UI library.
//! Not necessarily required for the library to work, but nice to have.

//# feather use syntax-errors

/// A simple linear stack view, where elements are displayed in a vertical
/// list adjacent to eachother.
///
/// @remark
///   To display elements horizontally, you should use `WUIElementHStackView`.
///
/// @param {Struct} [schema]
///   A struct containing the same configurable properties as `WUIElement`,
///   with the addition of the following properties:
///
///     - `"align"`: configures `WUIElementVStackView::__align__`, defaults to
///                  0.
///
///     - `"separation"`: configures `WUIElementVStackView::__separation__`,
///                       defaults to 0.
function WUIElementVStackView(schema = { }) : WUIElement(schema) constructor {
    /// The alignment of the inner elements of this stack view. 0 means align
    /// left, 1 means align right.
    ///
    /// @return {Real}
    self.__align__ = schema[$ "align"] ?? 0;
    /// The separation, in pixels, between each element of the stack view.
    ///
    /// @return {Real}
    self.__separation__ = schema[$ "separation"] ?? 0;

    // overrides
    self.__evGetInnerWidth__ = function () {
        var maxW = 0;
        for (var i = array_length(__children__) - 1; i >= 0; i -= 1) {
            var child = __children__[i];
            maxW = max(maxW, child.worldWidth);
        }
        return maxW;
    };
    self.__evGetInnerHeight__ = function () {
        var totalH = 0;
        var childCount = array_length(__children__);
        for (var i = childCount - 1; i >= 0; i -= 1) {
            var child = __children__[i];
            totalH += child.worldHeight;
        }
        if (childCount > 1) {
            totalH += __separation__ * (childCount - 1);
        }
        return totalH;
    };
    self.__evUpdateInnerLayout__ = function () {
        var posX = worldInnerX + lerp(0, worldInnerWidth, __align__);
        var posY = worldInnerY + worldInnerHeight;
        for (var i = array_length(__children__) - 1; i >= 0; i -= 1) {
            var child = __children__[i];
            child.recalculateWorldPosition(posX, posY, __align__, 1);
            posY -= child.worldHeight + __separation__;
        }
    };
}

/// A simple linear stack view, where elements are displayed in a horizontal
/// list adjacent to eachother.
///
/// @remark
///   To display elements vertically, you should use `WUIElementVStackView`.
///
/// @param {Struct} [schema]
///   A struct containing the same configurable properties as `WUIElement`,
///   with the addition of the following properties:
///
///     - `"align"`: configures `WUIElementHStackView::__align__`, defaults to
///                  0.
///
///     - `"separation"`: configures `WUIElementHStackView::__separation__`,
///                       defaults to 0.
function WUIElementHStackView(schema = { }) : WUIElement(schema) constructor {
    /// The alignment of the inner elements of this stack view. 0 means align
    /// to the top, 1 means align to the bottom.
    ///
    /// @return {Real}
    self.__align__ = schema[$ "align"] ?? 0;
    /// The separation, in pixels, between each element of the stack view.
    ///
    /// @return {Real}
    self.__separation__ = schema[$ "separation"] ?? 0;

    // overrides
    self.__evGetInnerWidth__ = function () {
        var totalW = 0;
        var childCount = array_length(__children__);
        for (var i = childCount - 1; i >= 0; i -= 1) {
            var child = __children__[i];
            totalW += child.worldWidth;
        }
        if (childCount > 1) {
            totalW += __separation__ * (childCount - 1);
        }
        return totalW;
    };
    self.__evGetInnerHeight__ = function () {
        var maxH = 0;
        for (var i = array_length(__children__) - 1; i >= 0; i -= 1) {
            var child = __children__[i];
            maxH = max(maxH, child.worldHeight);
        }
        return maxH;
    };
    self.__evUpdateInnerLayout__ = function () {
        var posX = worldInnerX + worldInnerWidth;
        var posY = worldInnerY + lerp(0, worldInnerHeight, __align__);
        for (var i = array_length(__children__) - 1; i >= 0; i -= 1) {
            var child = __children__[i];
            child.recalculateWorldPosition(posX, posY, 1, __align__);
            posX -= child.worldWidth + __separation__;
        }
    };
}

/// A simple navigable button.
///
/// @param {Struct} [schema]
///   A struct containing the same configurable properties as `WUIElement`,
///   with the addition of the following properties:
///
///     - `"callback"`: configures `WUIElementButton::__callback__`.
function WUIElementButton(schema = { }) : WUIElement(schema) constructor {
    /// The callback invoked when clicking this button.
    ///
    /// It accepts a single parameter:
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @return {Function}
    self.__callback__ = schema[$ "callback"];

    // overrides
    self.__navigable__ = true;
    self.__evInputReleased__ = function (nav) {
        if (__callback__ != undefined) {
            __callback__(self);
        }
    };
}

/// A simple navigable button with a toggleable state. Can be used as a
/// foundation for radio buttons, checkboxes, or switches.
///
/// @param {Struct} [schema]
///   A struct containing the same configurable properties as `WUIElement`,
///   with the addition of the following properties:
///
///     - `"startValue"`: configures `WUIElementToggle::__value__`,
///                       defaults to `false`.
///
///     - `"callback"`: configures `WUIElementToggle::__callback__`.
function WUIElementToggle(schema = { }) : WUIElement(schema) constructor {
    /// The active state of this toggleable button.
    ///
    /// @return {Bool}
    self.__value__ = schema[$ "startValue"] ?? false;
    /// The callback invoked when clicking this button.
    ///
    /// It accepts a single parameter:
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @return {Function}
    self.__callback__ = schema[$ "callback"];

    // overrides
    self.__navigable__ = true;
    self.__evInputReleased__ = function (nav) {
        __value__ = !__value__;
        if (__callback__ != undefined) {
            __callback__(self);
        }
    };
    self.__evDrawDebug__ = function (nav) {
        if (__value__) {
            draw_line(
                worldX, worldY,
                worldX + worldWidth, worldY + worldHeight
            );
            draw_line(
                worldX, worldY + worldHeight,
                worldX + worldWidth, worldY
            );
        }
    };
}

/// A simple navigable horizontal slider.
///
/// @param {Struct} [schema]
///   A struct containing the same configurable properties as `WUIElement`,
///   with the addition of the following properties:
///
///     - `"startValue"`: configures `WUIElementSlider::__value__`,
///                       defaults to 0.
///
///     - `"slideSpeed"`: configures `WUIElementSlider::__slideSpeed__`.
///
///     - `"callback"`: configures `WUIElementSlider::__callback__`.
function WUIElementSlider(schema = { }) : WUIElement(schema) constructor {
    /// The normalised thumb position, between 0 and 1, of the slider.
    ///
    /// @return {Real}
    self.__value__ = schema[$ "startValue"] ?? 0;
    /// The speed at which the slider can be navigated using keyboard or
    /// gamepad input.
    ///
    /// @return {Real}
    self.__slideSpeed__ = schema[$ "slideSpeed"];
    /// The callback invoked when the thumb position changes.
    ///
    /// It accepts a single parameter:
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @return {Function}
    self.__callback__ = schema[$ "callback"];

    // overrides
    self.__navigable__ = true;
    self.__evInputDrag__ = function (nav) {
        if (worldInnerWidth <= 0) {
            return;
        }
        var amountX = (nav.input.cursorX - worldInnerX) / worldInnerWidth;
        __value__ = clamp(amountX, 0, 1);
        if (__callback__ != undefined) {
            __callback__(self);
        }
    };
    self.__evMoveX__ = function (dist) {
        var slideSpeed = __slideSpeed__;
        if (slideSpeed == undefined) {
            var ar = worldInnerWidth / max(1, worldInnerHeight);
            slideSpeed = 0.001 * ar;
        }
        __value__ += slideSpeed * dist;
        __value__ = clamp(__value__, 0, 1);
    };
    self.__evDrawDebug__ = function (nav) {
        var thumbX = worldInnerX + lerp(0, worldInnerWidth, __value__);
        draw_line(thumbX, worldY, thumbX, worldY + worldHeight);
    };
}

/// A simple image element.
///
/// @param {Struct} [schema]
///   A struct containing the same configurable properties as `WUIElement`,
///   with the addition of the following properties:
///
///     - `"sprite"`: configures `WUIElementImage::__sprite__`, defaults to -1.
///
///     - `"subimg"`: configures `WUIElementImage::__subimg__`, defaults to 0.
function WUIElementImage(schema = { }) : WUIElement(schema) constructor {
    /// The sprite asset to render.
    ///
    /// @return {Asset.GMSprite}
    self.__sprite__ = schema[$ "sprite"] ?? -1;
    /// The subimage of the sprite to render.
    ///
    /// @return {Real}
    self.__subimg__ = schema[$ "subimg"] ?? 0;

    // overrides
    self.__evGetInnerWidth__ = function () {
        return sprite_get_width(__sprite__);
    };
    self.__evGetInnerHeight__ = function () {
        return sprite_get_height(__sprite__);
    };
    self.__evDraw__ = function (nav) {
        draw_sprite_stretched(
            __sprite__, __subimg__,
            worldInnerX, worldInnerY,
            worldInnerWidth, worldInnerHeight
        );
    }
}