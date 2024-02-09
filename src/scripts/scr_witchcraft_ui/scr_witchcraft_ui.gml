//! A batteries-not-included UI system inspired loosely by the box model
//! system. Fully customisable and extendible with very few moving parts.

//# feather use syntax-errors

show_debug_message("enchanted with Witchcraft::ui by @katsaii");

/// The method of input most likely being used when navigating a menu.
enum WUIInputHint {
    INDETERMINATE,
    CURSOR,
    KEYBOARD,
}

/// Converts keyboard and mouse events into a consumable format used by
/// `WUINavigator`.
function WUIInputManager() constructor {
    /// The type of input most likely being used at the current point in time.
    ///
    /// @return {Enum.WUIInputHint}
    self.inputMethod = WUIInputHint.INDETERMINATE;
    /// The position of the mouse cursor in the X direction, or `undefined`
    /// if the mouse is inactive.
    ///
    /// @return {Real}
    self.cursorX = undefined;
    /// The position of the mouse cursor in the Y direction, or `undefined`
    /// if the mouse is inactive.
    ///
    /// @return {Real}
    self.cursorY = undefined;
    /// The difference between the current and previous cursor positions, in
    /// the X direction.
    ///
    /// @return {Real}
    self.cursorXDelta = 0;
    /// The difference between the current and previous cursor positions, in
    /// the Y direction.
    ///
    /// @return {Real}
    self.cursorYDelta = 0;
    /// Whether the current mouse event has caused the cursor to move. Only
    /// returns `true` if the cursor was active in the previous frame and the
    /// difference between the current and previous cursor positions is
    /// non-zero.
    ///
    /// @return {Bool}
    self.cursorUpdated = false;
    /// The movement vector in the X direction when using keyboard navigation.
    /// A positive value means movement to the right, a negative value means
    /// movement to the left, and zero means no movement.
    ///
    /// @return {Real}
    self.moveX = 0;
    /// The movement vector in the Y direction when using keyboard navigation.
    /// A positive value means movement downards, a negative value means
    /// movement upwards, and zero means no movement.
    ///
    /// @return {Real}
    self.moveY = 0;
    /// The number of consecutive frames the same movement deltas have been
    /// active for.
    ///
    /// @return {Real}
    self.moveDuration = 0;
    /// Whether a movement event has been detected. This is likely triggered
    /// when a new input delta is received, or if the same delta has been held
    /// for a prolonged period of time.
    ///
    /// @return {Bool}
    self.moveUpdated = false;
    /// Whether a tabbing navigation input was detected.
    ///
    /// @return {Bool}
    self.tab = false;
    /// The difference between the current and previous tabbing input values.
    /// A positive value means the input was just pressed, and a negative value
    /// means the input was just released.
    ///
    /// @return {Real}
    self.tabDelta = 0;
    /// Whether a confirmation input was detected.
    ///
    /// @return {Bool}
    self.confirm = false;
    /// The difference between the current and previous confirmation input
    /// values. A positive value means the input was just pressed, and a
    /// negative value means the input was just released.
    ///
    /// @return {Real}
    self.confirmDelta = 0;
    /// Whether a cancel input was detected.
    ///
    /// @return {Bool}
    self.cancel = false;
    /// The difference between the current and previous cancel input values.
    /// A positive value means the input was just pressed, and a negative
    /// value means the input was just released.
    ///
    /// @return {Real}
    self.cancelDelta = 0;

    /// Updates the cursor position and registers any interesting events.
    ///
    /// If a cursor movement is detected, the `WUIInputManager::inputMethod`
    /// for this manager will be changed to `WUIInputHint.CURSOR`.
    ///
    /// @param {Real} newCursorX
    ///   The new cursor position in the X direction.
    ///
    /// @param {Real} newCursorY
    ///   The new cursor position in the Y direction.
    static cursorEvent = function (newCursorX, newCursorY) {
        if (cursorX != undefined && newCursorX != undefined) {
            cursorXDelta = newCursorX - cursorX;
        } else {
            cursorXDelta = 0;
        }
        cursorX = newCursorX;
        if (cursorY != undefined && newCursorY != undefined) {
            cursorYDelta = newCursorY - cursorY;
        } else {
            cursorYDelta = 0;
        }
        cursorY = newCursorY;
        cursorUpdated = cursorXDelta != 0 || cursorYDelta != 0;
        if (cursorUpdated) {
            inputMethod = WUIInputHint.CURSOR;
            moveDuration = 0;
            moveUpdated = false;
        }
    };

    /// Updates the keyboard movement state and registers any interesting
    /// events.
    ///
    /// If a movement is detected, the `WUIInputManager::inputMethod` for this
    /// manager will be changed to `WUIInputHint.KEYBOARD`.
    ///
    /// @param {Real} moveLeft
    ///   The amount of movement in the left direction.
    ///
    /// @param {Real} moveUp
    ///   The amount of movement in the upwards direction.
    ///
    /// @param {Real} moveRight
    ///   The amount of movement in the right direction.
    ///
    /// @param {Real} moveDown
    ///   The amount of movement in the downwards direction.
    static moveEvent = function (moveLeft, moveUp, moveRight, moveDown) {
        var newXDelta = clamp(moveRight - moveLeft, -1, 1);
        var newYDelta = clamp(moveDown - moveUp, -1, 1);
        var sameState = newXDelta == moveX && newYDelta == moveY;
        var nullState = newXDelta == 0 && newYDelta == 0;
        moveX = newXDelta;
        moveY = newYDelta;
        if (!sameState) {
            moveDuration = 0;
        }
        if (!nullState) {
            moveDuration += 1;
        }
        // magic numbers :3c
        // yummy!
        if (moveDuration < 30) {
            moveUpdated = moveDuration == 1;
        } else {
            moveUpdated = moveDuration % 4 == 0;
        }
        if (moveUpdated) {
            inputMethod = WUIInputHint.KEYBOARD;
            cursorUpdated = false;
        }
    };

    /// Updates the tabbing navigation button state.
    ///
    /// @param {Bool} held
    ///   Whether the tab button is held down.
    static tabEvent = function (held) {
        tabDelta = held - tab;
        tab = held;
    };

    /// Updates the confirm button state.
    ///
    /// @param {Bool} held
    ///   Whether the confirm button is held down.
    static confirmEvent = function (held) {
        confirmDelta = held - confirm;
        confirm = held;
    };

    /// Updates the cancel button state.
    ///
    /// @param {Bool} held
    ///   Whether the cancel button is held down.
    static cancelEvent = function (held) {
        cancelDelta = held - cancel;
        cancel = held;
    };

    /// Resets all event data. Most importantly, this will also update the
    /// `WUIInputManager::inputMethod` of this manager to be
    /// `WUIInputHint.INDETERMINATE`.
    static clearEvents = function () {
        inputMethod = WUIInputHint.INDETERMINATE;
        cursorX = undefined;
        cursorY = undefined;
        cursorXDelta = 0;
        cursorYDelta = 0;
        cursorUpdated = false;
        moveX = 0;
        moveY = 0;
        moveDuration = 0;
        moveUpdated = false;
        tab = false;
        tabDelta = 0;
        confirm = false;
        confirmDelta = 0;
        cancel = false;
        cancelDelta = 0;
    };
}

/// Manages the keyboard and mouse navigation events of a menu. Does not
/// assume knowledge of a root node, and can therefore be reused between
/// menus or support cross-menu navigation.
///
/// @param {Struct.WUIInputManager} [manager]
///   The input manager to consume input events from. Defaults to the shared
///   global input manager.
function WUINavigator(manager = undefined) constructor {
    /// The previous UI element being hovered or interacted with.
    ///
    /// @return {Struct.WUIElement}
    self.lastElementInFocus = undefined;
    /// The current UI element being hovered or interacted with.
    ///
    /// @return {Struct.WUIElement}
    self.elementInFocus = undefined;
    /// The input manager for this navigator. Stores and registers input
    /// events for interactive menus.
    ///
    /// @return {Struct.WUIInputManager}
    self.input = manager ?? new WUIInputManager();

    /// Sets the focused element for this navigator, invoking the enter and
    /// exit events for the current focused element in the process.
    ///
    /// @remark
    ///   The exit event for `WUINavigator::lastElementInFocus` is invoked
    ///   before the enter event for `WUINavigator::elementInFocus`.
    ///
    /// @param {Struct.WUIElement} elem
    static setFocusedElement = function (elem) {
        lastElementInFocus = elementInFocus;
        elementInFocus = elem;
        if (elementInFocus != lastElementInFocus) {
            if (lastElementInFocus != undefined) {
                lastElementInFocus.invokeEventExit();
            }
            if (elementInFocus != undefined) {
                elementInFocus.invokeEventEnter();
            }
        }
    };

    /// Uses the input events raised by `WUINavigator::input` to navigate
    /// the `rootElem` menu.
    ///
    /// @param {Struct.WUIElement} rootElem
    ///   The root element for the menu to navigate. Typically this is some
    ///   kind of view element with subelements attached to it, but it can
    ///   also be used on trivial elements like buttons and sliders.
    ///
    /// @param {Struct.WUIElement} [defaultElem]
    ///   The default starting element to use if a keyboard event is received.
    ///   This element must have its `__navigable__` meta flag set to true,
    ///   otherwise it will be ignored.
    static navigate = function (rootElem, defaultElem = undefined) {
        if (defaultElem != undefined && !defaultElem.__navigable__) {
            defaultElem = undefined;
        }
        var elementInFocus_ = elementInFocus;
        var input_ = input;
        // button states
        var confirmPressed = input_.confirmDelta > 0;
        var confirm = input_.confirm;
        var confirmReleased = input_.confirmDelta < 0;
        // events for the focused element
        if (elementInFocus_ != undefined) {
            if (confirmPressed) {
                // press event
                elementInFocus_.invokeEventPressed(self);
            }
            if (
                confirm && input_.cursorUpdated ||
                confirmPressed && input_.inputMethod == WUIInputHint.CURSOR
            ) {
                // drag event
                elementInFocus_.invokeEventDrag(self);
            }
            if (confirmReleased) {
                // release event
                elementInFocus_.invokeEventReleased(self);
            }
            elementInFocus_.invokeEventStep(self);
        }
        if (confirm) {
            // all future events should only be triggered if the confirmation
            // button is not being held
            return;
        }
        if (input_.cursorUpdated) {
            // cursor navigation
            var newElementInFocus = rootElem.findElementAtPosition(
                input_.cursorX, input_.cursorY
            );
            setFocusedElement(newElementInFocus);
        }
        // movement override
        var moveX = input_.moveX;
        var moveY = input_.moveY;
        if (
            elementInFocus_ != undefined &&
            elementInFocus_.tryMove(moveX, moveY)
        ) {
            return;
        }
        if (input_.moveUpdated) {
            // keyboard navigation
            if (elementInFocus_ == undefined) {
                // default element
                setFocusedElement(defaultElem);
            } else {
                // neighbour element
                var newElementInFocus = undefined;
                if (moveX < 0) {
                    newElementInFocus = elementInFocus.__navLeft__;
                } else if (moveX > 0) {
                    newElementInFocus = elementInFocus.__navRight__;
                } else if (moveY < 0) {
                    newElementInFocus = elementInFocus.__navUp__;
                } else if (moveY > 0) {
                    newElementInFocus = elementInFocus.__navDown__;
                }
                if (newElementInFocus == undefined) {
                    // TODO :: could be improved!
                    var rootLeft = rootElem.worldX;
                    var rootTop = rootElem.worldY;
                    var rootRight = rootLeft + rootElem.worldWidth;
                    var rootBottom = rootTop + rootElem.worldHeight;
                    var focusLeft = elementInFocus.worldX;
                    var focusTop = elementInFocus.worldY;
                    var focusRight = focusLeft + elementInFocus.worldWidth;
                    var focusBottom = focusTop + elementInFocus.worldHeight;
                    var left = focusLeft + 1;
                    var right = focusRight - 1;
                    if (moveX < 0) {
                        left = lerp(focusLeft - 1, rootLeft, -moveX);
                        right = focusLeft - 1;
                    } else if (moveX > 0) {
                        left = lerp(rootRight, focusRight + 1, moveX);
                        right = rootRight;
                    }
                    var top = focusTop + 1;
                    var bottom = focusBottom - 1;
                    if (moveY < 0) {
                        top = lerp(focusTop - 1, rootTop, -moveY);
                        bottom = focusTop - 1;
                    } else if (moveY > 0) {
                        top = lerp(rootBottom, focusBottom + 1, moveY);
                        bottom = rootBottom;
                    }
                    var targetX = mean(focusLeft, focusRight);
                    var targetY = mean(focusTop, focusBottom);
                    if (lastElementInFocus != undefined) {
                        // slight bias towards previous element to break ties
                        var lastX =
                                lastElementInFocus.worldX +
                                lastElementInFocus.worldWidth / 2;
                        var lastY =
                                lastElementInFocus.worldY +
                                lastElementInFocus.worldHeight / 2;
                        var biasStrength = 3;
                        targetX += biasStrength * sign(lastX - targetX);
                        targetY += biasStrength * sign(lastY - targetY);
                    }
                    newElementInFocus = rootElem.findElementNearest(
                        targetX, targetY,
                        left, top, right, bottom
                    );
                }
                if (newElementInFocus != undefined) {
                    setFocusedElement(newElementInFocus);
                }
            }
        }
    };
}

/// The draw colour used for unfocused elements when rendering the debug
/// overlay.
///
/// @return {Constant.Color}
#macro WUI_ELEMENT_DEBUG_COLOUR c_red

/// The draw colour used for navigable elements when rendering the debug
/// overlay.
///
/// @return {Constant.Color}
#macro WUI_ELEMENT_DEBUG_COLOUR_NAVIGABLE c_green

/// The draw colour used for focused elements when rendering the debug overlay.
///
/// @return {Constant.Color}
#macro WUI_ELEMENT_DEBUG_COLOUR_FOCUSED c_yellow

/// The single generic base element type for menus, menu elements, and menu
/// views of the Witchcraft UI system.
///
/// @param {Struct} [schema]
///   A struct containing the following configurable properties for elements:
///
///     - `"padding"`: configures `WUIElement::__padding__`, defaults to 0.
///
///     - `"width"`: configures `WUIElement::__width__`.
///
///     - `"height"`: configures `WUIElement::__height__`.
///
///     - `"offsetX"`: configures `WUIElement::__offsetX__`, defaults to 0.
///
///     - `"offsetY"`: configures `WUIElement::__offsetY__`, defaults to 0.
///
///     - `"children"`: configures `WUIElement::__children__`.
///
///     - `"navLeft"`: the navigation override when moving the keyboard cursor
///                  to the left.
///
///     - `"navUp"`: the navigation override when moving the keyboard cursor
///                upwards.
///
///     - `"navRight"`: the navigation override when moving the keyboard cursor
///                   to the right.
///
///     - `"navDown"`: the navigation override when moving the keyboard cursor
///                  downwards.
function WUIElement(schema = { }) constructor {
    /// The number of pixels of padding between the full width of the element
    /// and its inner elements.
    ///
    /// @return {Real}
    self.__padding__ = schema[$ "padding"] ?? 0;
    /// The full width of the element in pixels. If set to `undefined`, the
    /// width of the element will be estimated using the width of its
    /// inner elements.
    ///
    /// @return {Real}
    self.__width__ = schema[$ "width"];
    /// The full height of the element in pixels. If set to `undefined`, the
    /// height of the element will be estimated using the height of its
    /// inner elements.
    ///
    /// @return {Real}
    self.__height__ = schema[$ "height"];
    /// An additional offset applied to the element in the X direction after
    /// its world position has been calculated.
    ///
    /// @return {Real}
    self.__offsetX__ = schema[$ "offsetX"] ?? 0;
    /// An additional offset applied to the element in the Y direction after
    /// its world position has been calculated.
    ///
    /// @return {Real}
    self.__offsetY__ = schema[$ "offsetY"] ?? 0;
    /// An array of inner elements, inheriting the world position of their
    /// parent element.
    ///
    /// @return {Array<Struct.WUIElement>}
    self.__children__ = schema[$ "children"] ?? [];
    /// The navigation override when moving the keyboard cursor to the left.
    ///
    /// @return {Struct.WUIElement}
    self.__navLeft__ = schema[$ "navLeft"];
    /// The navigation override when moving the keyboard cursor upwards.
    ///
    /// @return {Struct.WUIElement}
    self.__navUp__ = schema[$ "navUp"];
    /// The navigation override when moving the keyboard cursor to the right.
    ///
    /// @return {Struct.WUIElement}
    self.__navRight__ = schema[$ "navRight"];
    /// The navigation override when moving the keyboard cursor downwards.
    ///
    /// @return {Struct.WUIElement}
    self.__navDown__ = schema[$ "navDown"];
    /// Whether this element is navigable by an instance of `WUINavigator`.
    ///
    /// If set to `false`, this element will ignore any input events.
    ///
    /// @return {Bool}
    self.__navigable__ = false;
    /// Whether this element is visible, both when navigating and drawing.
    ///
    /// If set to `false`, this element will not be drawn and will ignore
    /// any input events.
    self.__visible__ = true;

    /// An event raised for this element when calling the
    /// `WUIElement::recalculateWorldPosition` method. It is used to give a
    /// specific layout to the inner elements.
    ///
    /// It accepts a single parameter:
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evUpdateInnerLayout__ = function (elem) { /* ... */ };
    ///   ```
    ///
    /// @return {Function}
    self.__evUpdateInnerLayout__ = undefined;
    /// An event raised for this element when calling the
    /// `WUIElement::recalculateWorldSize` method. It will be raised only when
    /// `WUIElement::__width__` is `undefined`, and can be used to override the
    /// inference behaviour or dynamically shrink and grow the width of the
    /// element.
    ///
    /// It accepts a single parameter:
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// It should also return a positive real number representing the inner
    /// width of the element.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evGetInnerWidth__ = function (elem) {
    ///     return 60;
    ///   };
    ///   ```
    ///
    /// @return {Function}
    self.__evGetInnerWidth__ = undefined;
    /// An event raised for this element when calling the
    /// `WUIElement::recalculateWorldSize` method. It will be raised only when
    /// `WUIElement::__height__` is `undefined`, and can be used to override the
    /// inference behaviour or dynamically shrink and grow the height of the
    /// element.
    ///
    /// It accepts a single parameter:
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// It should also return a positive real number representing the inner
    /// height of the element.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evGetInnerHeight__ = function (elem) {
    ///     return 30;
    ///   };
    ///   ```
    ///
    /// @return {Function}
    self.__evGetInnerHeight__ = undefined;
    /// An event raised for this element when calling the
    /// `WUIElement::findElementAtPosition` method. It can be used to give
    /// elements with abnormal shapes a more precise collision check.
    ///
    /// It accepts three parameters:
    ///
    ///   - `"posX"`: the position of the point to check for a collision with,
    ///               in the X direction.
    ///
    ///   - `"posY"`: the position of the point to check for a collision with,
    ///               in the Y direction.
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evCheckCollision__ = function (posX, posY, elem) {
    ///     // ...
    ///   };
    ///   ```
    ///
    /// @return {Function}
    self.__evCheckCollision__ = undefined;
    /// An event raised for this element when calling the `WUIElement::draw`
    /// method. It is raised before all other draw events, and can be used to
    /// set a clipping shader or some other pre-draw configuration.
    ///
    /// It accepts two parameters:
    ///
    ///   - `"nav"`: a reference to the `WUINavigator` passed into the
    ///              `WUIElement::draw` call.
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evDrawBegin__ = function (nav, elem) { /* ... */ };
    ///   ```
    ///
    /// @return {Function}
    self.__evDrawBegin__ = undefined;
    /// An event raised for this element when calling the
    /// `WUIElement::drawDebug` method.
    ///
    /// It accepts two parameters:
    ///
    ///   - `"nav"`: a reference to the `WUINavigator` passed into the
    ///              `WUIElement::drawDebug` call.
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evDrawDebug__ = function (nav, elem) { /* ... */ };
    ///   ```
    ///
    /// @return {Function}
    self.__evDrawDebug__ = undefined;
    /// An event raised for this element when calling the `WUIElement::draw`
    /// method. It is raised immediately after the
    /// `WUIElement::__evDrawBegin__` event, but prior to drawing any of the
    /// inner elements.
    ///
    /// It accepts two parameters:
    ///
    ///   - `"nav"`: a reference to the `WUINavigator` passed into the
    ///              `WUIElement::draw` call.
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evDraw__ = function (nav, elem) { /* ... */ };
    ///   ```
    ///
    /// @return {Function}
    self.__evDraw__ = undefined;
    /// An event raised for this element when calling the `WUIElement::draw`
    /// method. It is raised after all other draw events, and can be used to
    /// finalise any drawing configurations made in the
    /// `WUIElement::__evDrawBegin__` event.
    ///
    /// It accepts two parameters:
    ///
    ///   - `"nav"`: a reference to the `WUINavigator` passed into the
    ///              `WUIElement::draw` call.
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evDrawEnd__ = function (nav, elem) { /* ... */ };
    ///   ```
    ///
    /// @return {Function}
    self.__evDrawEnd__ = undefined;
    /// An event raised for this element when calling the
    /// `WUIElement::invokeEventPressed` method.
    ///
    /// It accepts two parameters:
    ///
    ///   - `"nav"`: a reference to the `WUINavigator` passed into the
    ///              `WUIElement::invokeEventPressed` call.
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evInputPressed__ = function (nav, elem) { /* ... */ };
    ///   ```
    ///
    /// @return {Function}
    self.__evInputPressed__ = undefined;
    /// An event raised for this element when calling the
    /// `WUIElement::invokeEventDrag` method.
    ///
    /// It accepts two parameters:
    ///
    ///   - `"nav"`: a reference to the `WUINavigator` passed into the
    ///              `WUIElement::invokeEventDrag` call.
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evInputDrag__ = function (nav, elem) { /* ... */ };
    ///   ```
    ///
    /// @return {Function}
    self.__evInputDrag__ = undefined;
    /// An event raised for this element when calling the
    /// `WUIElement::invokeEventPressed` method.
    ///
    /// It accepts two parameters:
    ///
    ///   - `"nav"`: a reference to the `WUINavigator` passed into the
    ///              `WUIElement::invokeEventPressed` call.
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evInputReleased__ = function (nav, elem) { /* ... */ };
    ///   ```
    ///
    /// @return {Function}
    self.__evInputReleased__ = undefined;
    /// An event raised for this element when calling the
    /// `WUIElement::tryMove` method.
    ///
    /// It accepts two parameters:
    ///
    ///   - `"dist"`: the non-zero distance in the X direction to move.
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evMoveX__ = function (dist, elem) { /* ... */ };
    ///   ```
    ///
    /// @return {Function}
    self.__evMoveX__ = undefined;
    /// An event raised for this element when calling the
    /// `WUIElement::tryMove` method.
    ///
    /// It accepts two parameters:
    ///
    ///   - `"dist"`: the non-zero distance in the Y direction to move.
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evMoveY__ = function (dist, elem) { /* ... */ };
    ///   ```
    ///
    /// @return {Function}
    self.__evMoveY__ = undefined;
    /// An event raised for this element when calling the
    /// `WUIElement::invokeEventEnter` method.
    ///
    /// It accepts two parameters:
    ///
    ///   - `"nav"`: a reference to the `WUINavigator` passed into the
    ///              `WUIElement::invokeEventEnter` call.
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evEnter__ = function (nav, elem) { /* ... */ };
    ///   ```
    ///
    /// @return {Function}
    self.__evEnter__ = undefined;
    /// An event raised for this element when calling the
    /// `WUIElement::invokeEventExit` method.
    ///
    /// It accepts two parameters:
    ///
    ///   - `"nav"`: a reference to the `WUINavigator` passed into the
    ///              `WUIElement::invokeEventEnter` call.
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evExit__ = function (nav, elem) { /* ... */ };
    ///   ```
    ///
    /// @return {Function}
    self.__evExit__ = undefined;
    /// An event raised for this element when calling the
    /// `WUIElement::invokeEventStep` method.
    ///
    /// It accepts two parameters:
    ///
    ///   - `"nav"`: a reference to the `WUINavigator` passed into the
    ///              `WUIElement::invokeEventStep` call.
    ///
    ///   - `"elem"`: a reference to the element itself.
    ///
    /// @example
    ///   ```
    ///   var elem = new WUIElement();
    ///   elem.__evStep__ = function (nav, elem) { /* ... */ };
    ///   ```
    ///
    /// @return {Function}
    self.__evStep__ = undefined;

    /// The world position of the top-left corner of this element in the
    /// X direction.
    ///
    /// @return {Real}
    self.worldX = 0;
    /// The world position of the top-left corner of this element in the
    /// Y direction.
    ///
    /// @return {Real}
    self.worldY = 0;
    /// The full width of this element.
    ///
    /// Will either be `WUIElement::__width__` or estimated from the width
    /// of the inner elements and `WUIElement::__padding__`.
    ///
    /// @return {Real}
    self.worldWidth = self.__width__ ?? 0;
    /// The full height of this element.
    ///
    /// Will either be `WUIElement::__height__` or estimated from the height
    /// of the inner elements and `WUIElement::__padding__`.
    ///
    /// @return {Real}
    self.worldHeight = self.__height__ ?? 0;

    /// The world position of the top-left corner of this element in the
    /// X direction, plus padding:
    /// ```
    /// worldInnerX = worldX + __padding__
    /// ```
    ///
    /// @return {Real}
    self.worldInnerX = self.worldX;
    /// The world position of the top-left corner of this element in the
    /// Y direction, plus padding:
    /// ```
    /// worldInnerY = worldY + __padding__
    /// ```
    ///
    /// @return {Real}
    self.worldInnerY = self.worldY;
    /// The inner width of this element:
    /// ```
    /// worldInnerWidth = worldWidth - 2 * __padding__
    /// ```
    ///
    /// @return {Real}
    self.worldInnerWidth = self.worldWidth - 2 * self.__padding__;
    /// The inner height of this element:
    /// ```
    /// worldInnerHeight = worldHeight - 2 * __padding__
    /// ```
    ///
    /// @return {Real}
    self.worldInnerHeight = self.worldHeight - 2 * self.__padding__;

    /// Recursively updates the `WUIElement::worldWidth`,
    /// `WUIElement::worldHeight`, `WUIElement::worldInnerWidth`, and
    /// `WUIElement::worldInnerHeight` properties of this element and its
    /// children.
    static recalculateWorldSize = function () {
        var maxChildWidth = 0;
        var maxChildHeight = 0;
        for (var i = array_length(__children__) - 1; i >= 0; i -= 1) {
            var child = __children__[i];
            child.recalculateWorldSize();
            maxChildWidth = max(maxChildWidth, child.worldWidth);
            maxChildHeight = max(maxChildHeight, child.worldHeight);
        }
        worldWidth = __width__;
        if (worldWidth == undefined) {
            worldWidth = maxChildWidth;
            if (__evGetInnerWidth__ != undefined) {
                worldWidth = __evGetInnerWidth__(self);
            }
            worldWidth += __padding__ * 2;
        }
        worldWidth = floor(worldWidth);
        worldInnerWidth = worldWidth - __padding__ * 2;
        worldHeight = __height__;
        if (worldHeight == undefined) {
            worldHeight = maxChildHeight;
            if (__evGetInnerHeight__ != undefined) {
                worldHeight = __evGetInnerHeight__(self);
            }
            worldHeight += __padding__ * 2;
        }
        worldHeight = floor(worldHeight);
        worldInnerHeight = worldHeight - __padding__ * 2;
    };

    /// Recursively updates the `WUIElement::worldX`, `WUIElement::worldY`,
    /// `WUIElement::worldInnerX`, and `WUIElement::worldInnerY` properties of
    /// this element and its children.
    ///
    /// @param {Real} posX
    ///   The position, in the X direction, to anchor this element to.
    ///
    /// @param {Real} posY
    ///   The position, in the Y direction, to anchor this element to.
    ///
    /// @param {Real} [alignX]
    ///   The alignment, in the X direction, of this element relative to the
    ///   anchor position. 0 means align left, 1 means align right. Defaults
    ///   to 0.
    ///
    /// @param {Real} [alignY]
    ///   The alignment, in the Y direction, of this element relative to the
    ///   anchor position. 0 means align top, 1 means align bottom. Defaults
    ///   to 0.
    static recalculateWorldPosition = function (posX, posY, alignX = 0, alignY = 0) {
        worldX = floor(posX - lerp(0, worldWidth, alignX) + __offsetX__);
        worldY = floor(posY - lerp(0, worldHeight, alignY) + __offsetY__);
        worldInnerX = worldX + __padding__;
        worldInnerY = worldY + __padding__;
        if (__evUpdateInnerLayout__ == undefined) {
            for (var i = array_length(__children__) - 1; i >= 0; i -= 1) {
                var child = __children__[i];
                child.recalculateWorldPosition(worldInnerX, worldInnerY, 0, 0);
            }
        } else {
            __evUpdateInnerLayout__(self);
        }
    };

    /// Calculates the smallest distance of this element from a point.
    ///
    /// @param {Real} posX
    ///   The position of the point to check in the X direction.
    ///
    /// @param {Real} posY
    ///   The position of the point to check in the Y direction.
    ///
    /// @return {Real}
    static distanceToPosition = function (posX, posY) {
        var cornerX = clamp(posX, worldX, worldX + worldWidth);
        var cornerY = clamp(posY, worldY, worldY + worldHeight);
        return point_distance(posX, posY, cornerX, cornerY);
    };

    /// Searches for a visible, navigable element at some precise location.
    /// Returns `undefined` if no element, or inner element was found.
    ///
    /// @param {Real} posX
    ///   The position of the point to check in the X direction.
    ///
    /// @param {Real} posY
    ///   The position of the point to check in the Y direction.
    ///
    /// @return {Struct.WUIElement}
    static findElementAtPosition = function (posX, posY) {
        if (!__visible__) {
            return undefined;
        }
        var collision = point_in_rectangle(
            posX, posY,
            worldX, worldY,
            worldX + worldWidth, worldY + worldHeight
        );
        if (collision && __evCheckCollision__ != undefined) {
            collision = __evCheckCollision__(posX, posY, self);
        }
        if (!collision) {
            return undefined;
        }
        var result = undefined;
        // iterate forwards to avoid through-click
        var n = array_length(__children__);
        for (var i = 0; i < n && result == undefined; i += 1) {
            var child = __children__[i];
            result = child.findElementAtPosition(posX, posY);
        }
        result ??= self;
        return result.__navigable__ ? result : undefined;
    };

    /// Searches for the nearest visible, navigable element to a point.
    /// Returns `undefined` if no element, or inner element was found.
    ///
    /// @param {Real} posX
    ///   The position of the point to check in the X direction.
    ///
    /// @param {Real} posY
    ///   The position of the point to check in the Y direction.
    ///
    /// @param {Real} [clipLeft]
    ///   The left edge of the clipping region to search for elements in.
    ///   Defaults to `-infinity`.
    ///
    /// @param {Real} [clipTop]
    ///   The top edge of the clipping region to search for elements in.
    ///   Defaults to `-infinity`.
    ///
    /// @param {Real} [clipRight]
    ///   The right edge of the clipping region to search for elements in.
    ///   Defaults to `infinity`.
    ///
    /// @param {Real} [clipBottom]
    ///   The left-side edge of the clipping region to search for elements in.
    ///   Defaults to `infinity`.
    ///
    /// @return {Struct.WUIElement}
    static findElementNearest = function (
        posX,
        posY,
        clipLeft = -infinity,
        clipTop = -infinity,
        clipRight = infinity,
        clipBottom = infinity
    ) {
        if (!__visible__) {
            return undefined;
        }
        var collision = rectangle_in_rectangle(
            clipLeft, clipTop, clipRight, clipBottom,
            worldX, worldY,
            worldX + worldWidth, worldY + worldHeight
        ) != 0;
        if (!collision) {
            return undefined;
        }
        var result = undefined;
        var currentDistance = infinity;
        // iterate forwards for parity with `findElementAtPosition`
        var n = array_length(__children__);
        for (var i = 0; i < n; i += 1) {
            var child = __children__[i];
            var localNearest = child.findElementNearest(
                    posX, posY, clipLeft, clipTop, clipRight, clipBottom);
            if (localNearest == undefined) {
                continue;
            }
            var localDistance = localNearest.distanceToPosition(posX, posY);
            if (localDistance < currentDistance) {
                result = localNearest;
                currentDistance = localDistance;
            }
        }
        result ??= self;
        return result.__navigable__ ? result : undefined;
    };

    /// Draws the canonical representation of this element.
    ///
    /// @param {Struct.WUINavigator} nav
    ///   The navigator used for this element. Used to check which element
    ///   is currently focused, and the state of the input manager.
    static draw = function (nav) {
        if (!__visible__) {
            return;
        }
        if (__evDrawBegin__ != undefined) {
            __evDrawBegin__(nav, self);
        }
        if (__evDraw__ != undefined) {
            __evDraw__(nav, self);
        }
        for (var i = array_length(__children__) - 1; i >= 0; i -= 1) {
            var child = __children__[i];
            child.draw(nav);
        }
        if (__evDrawEnd__ != undefined) {
            __evDrawEnd__(nav, self);
        }
    };

    /// Draws the debug overlay of this element.
    ///
    /// @param {Struct.WUINavigator} nav
    ///   The navigator used for this element. Used to check which element
    ///   is currently focused, and the state of the input manager.
    static drawDebug = function (nav) {
        if (!__visible__) {
            return;
        }
        var debugColour = WUI_ELEMENT_DEBUG_COLOUR;
        if (__navigable__) {
            debugColour = WUI_ELEMENT_DEBUG_COLOUR_NAVIGABLE;
            if (nav.elementInFocus == self) {
                debugColour = WUI_ELEMENT_DEBUG_COLOUR_FOCUSED;
            }
        }
        var oldColour = draw_get_colour();
        draw_set_colour(debugColour);
        draw_rectangle(
            worldX, worldY,
            worldX + worldWidth, worldY + worldHeight,
            true
        );
        if (__evDrawDebug__ != undefined) {
            __evDrawDebug__(nav, self);
        }
        for (var i = array_length(__children__) - 1; i >= 0; i -= 1) {
            var child = __children__[i];
            child.drawDebug(nav);
        }
        draw_set_colour(oldColour);
    };

    /// Invokes the step event for this element, if it has one. Does not
    /// apply recursively to the inner elements.
    ///
    /// @remark
    ///   Typically used by `WUINavigator` to do some additional update
    ///   step, whilst an element is focused.
    ///
    /// @param {Struct.WUINavigator} nav
    ///   The navigator used for this element.
    static invokeEventStep = function (nav) {
        if (__evStep__ != undefined) {
            __evStep__(nav, self);
        }
    };

    /// Invokes this elements pressed event, if one exists.
    ///
    /// @param {Struct.WUINavigator} nav
    ///   The navigator used for this element.
    static invokeEventPressed = function (nav) {
        if (__evInputPressed__ != undefined) {
            __evInputPressed__(nav, self);
        }
    };

    /// Invokes this elements drag event, if one exists.
    ///
    /// @param {Struct.WUINavigator} nav
    ///   The navigator used for this element.
    static invokeEventDrag = function (nav) {
        if (__evInputDrag__ != undefined) {
            __evInputDrag__(nav, self);
        }
    };

    /// Invokes this elements released event, if one exists.
    ///
    /// @param {Struct.WUINavigator} nav
    ///   The navigator used for this element.
    static invokeEventReleased = function (nav) {
        if (__evInputReleased__ != undefined) {
            __evInputReleased__(nav, self);
        }
    };

    /// Invokes this elements enter event, if one exists.
    ///
    /// @param {Struct.WUINavigator} nav
    ///   The navigator used for this element.
    static invokeEventEnter = function (nav) {
        if (__evEnter__ != undefined) {
            __evEnter__(nav, self);
        }
    };

    /// Invokes this elements exit event, if one exists.
    ///
    /// @param {Struct.WUINavigator} nav
    ///   The navigator used for this element.
    static invokeEventExit = function (nav) {
        if (__evExit__ != undefined) {
            __evExit__(nav, self);
        }
    };

    /// Invokes this elements move events, if one exists. Returns `true` or
    /// `false` depending on whether a move event was raised.
    ///
    /// @param {Real} distX
    ///   The distance in the X direction to move.
    ///
    /// @param {Real} distY
    ///   The distance in the Y direction to move.
    ///
    /// @return {Bool}
    static tryMove = function (distX, distY) {
        var moved = false;
        if (__evMoveX__ != undefined && distX != 0) {
            __evMoveX__(distX, self);
            moved = true;
        }
        if (__evMoveY__ != undefined && distY != 0) {
            __evMoveY__(distY, self);
            moved = true;
        }
        return moved;
    };
}

/// @ignore
///
/// @return {Bool}
function __wui_menu_is_supported() {
    static init = true;
    static supported = false;
    if (init) {
        if (asset_get_type("obj_witchcraft_ui_menu") == asset_object) {
            supported = true;
        } else {
            try {
                supported = object_exists(obj_witchcraft_ui_menu);
            } catch (_) { }
        }
        init = false;
        if (!supported) {
            show_debug_message(
                "Witchcraft::ui is missing 'obj_witchcraft_ui_menu'"
            );
        }
    }
    return supported;
}

/// @ignore
///
/// @param {Any} menuObject
/// @return {Bool}
function __wui_menu_exists(menuObject) {
    var exists = false;
    try {
        if (object_exists(menuObject)) {
            if (object_is_ancestor(menuObject, obj_witchcraft_ui_menu)) {
                exists = true;
            }
        }
    } catch (_) { }
    return exists;
}

/// Get a reference to the active menu with the highest priority. Returns
/// `undefined` if no menus are currently active.
///
/// @return {Struct}
function wui_menu_top() {
    if (!__wui_menu_is_supported()) {
        return undefined;
    }
    var menu = undefined;
    var maxPriority = -infinity;
    with (obj_witchcraft_ui_menu) {
        if (!menuActive) {
            continue;
        }
        if (menuPriority > maxPriority) {
            maxPriority = menuPriority;
            menu = self;
        }
    }
    return menu;
}

/// Pushes a new menu onto the menu stack for this room.
///
/// @param {Any} obj
///   Any value representing a menu object. The object must be an
///   ancestor of `obj_witchcraft_ui_menu`.
///
/// @param {Struct} [variableStruct]
///   A structure which contains variables that are copied into the menu
///   before running its create event.
function wui_menu_push(obj, variableStruct = undefined) {
    if (!__wui_menu_is_supported() || !__wui_menu_exists(obj)) {
        return;
    }
    var top = wui_menu_top();
    var depth_ = top == undefined ? -9999 : (top.depth - 1);
    if (variableStruct == undefined) {
        instance_create_depth(0, 0, depth_, obj);
    } else {
        instance_create_depth(0, 0, depth_, obj, variableStruct);
    }
}

/// Pops the top menu from the menu stack if it exists.
function wui_menu_pop() {
    if (!__wui_menu_is_supported()) {
        return;
    }
    var top = wui_menu_top();
    if (top != undefined) {
        top.menuActive = false;
    }
}

/// @ignore
function __wui_menu_debug() {
    static data = { enabled : false };
    return data;
}

/// Enables or disables the debug overlay for menus on the menu stack.
///
/// @param {Bool} enable.
///   Whether to enable (`true`) or disable (`false`) the debug overlay.
function wui_menu_show_debug(enable) {
    __wui_menu_debug().enabled = is_numeric(enable) && enable;
}