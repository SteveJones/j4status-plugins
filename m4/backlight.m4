AC_DEFUN([J4STATUS_PLUGINS_PLUGIN_BACKLIGHT], [
    J4SP_ADD_INPUT_PLUGIN(backlight, [Backlight info], [yes], [
        PKG_CHECK_MODULES([BACKLIGHT_PLUGIN], [gobject-2.0 glib-2.0])
        AC_CHECK_HEADERS([sys/inotify.h pthread.h], [], [AC_MSG_ERROR([sys/inotify.h and pthread.h required for plugin backlight])])
    ])
])
