# The Witchcraft Collection

A collection of self-contained micro-libraries which would be a pain to maintain
individually:

 - **`Witchcraft::ui`** ([source](./src/scripts/scr_witchcraft_ui/scr_witchcraft_ui.gml))

    - Batteries not included, extendible box model UI system.
    - Erases busywork of defining element positions manually, by calculating the
      layout of child elements automatically.
    - The size of parent elements can automatically scale to fit their content,
      allowing for menus to be responsive to text size.
    - Can be used both for navigable menus and HUDs.
    - Mouse and keyboard support and menu stack.

 - **`Witchcraft::camera`** ([source](./src/scripts/scr_witchcraft_camera/scr_witchcraft_camera.gml))

    - Application surface, GUI, and View utilities.

 - **`Witchcraft::chanel`** ([source](./src/scripts/scr_witchcraft_chanel/scr_witchcraft_chanel.gml))

    - Small publish-subscribe event system.

 - **`Witchcraft::task`** ([source](./src/scripts/scr_witchcraft_task/scr_witchcraft_task.gml))

    - General purpose async task management system.
    - Useful for loading screens.

 - **`Witchcraft::validation`** ([source](./src/scripts/scr_witchcraft_validation/scr_witchcraft_validation.gml))

    - General purpose library for mashaling and unmarshaling GML values from JSON.

 - **`Witchcraft::toolbox`** ([source](./src/scripts/scr_witchcraft_toolbox/scr_witchcraft_toolbox.gml))

    - A collection of mildly useful utility functions.
