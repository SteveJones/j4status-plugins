To add a new plugin
===================

Directory architecture
----------------------

    configure.ac
    Makefile.am
    m4/<plugin>.m4
    <plugin>/<plugin>.mk>
    <plugin>/src/<plugin>.c
    <plugin>/man/j4status-<plugin>.conf.xml

Write a `<plugin>.m4` file
--------------------------

This file must contain one macro `J4STATUS_PLUGINS_PLUGIN_<ID>` for all the `configure.ac` code of your plugin.
This macro must be called in `configure.ac`.
This macro should call one of these three macros:

    J4SP_ADD_INPUT_PLUGIN([plugin id], [plugin name/description], [yes|no|always], [dependencies check code])
    J4SP_ADD_OUTPUT_PLUGIN([plugin id], [plugin name/description], [yes|no|always], [dependencies check code])
    J4SP_ADD_INPUT_OUTPUT_PLUGIN([plugin id], [plugin name/description], [yes|no|always], [dependencies check code])

Here is a description of each argument:

* `plugin id`: Used for the configure switch (e.g. `--disable-exec-input`)
* `plugin name/description`: Used in the configure switch description and in the configure summary
* `yes|no|always`: The (default) enabled status of your plugin
* `dependencies check code`: Your code to check dependencies

Example:

    m4/exec.m4:
        AC_DEFUN([J4STATUS_PLUGINS_PLUGIN_EXEC], [
            J4SP_ADD_INPUT_PLUGIN([exec], [Command execution], [always], [
                PKG_CHECK_MODULES([EXEC_PLUGIN], [glib-2.0 gio-2.0])
            ])
        ])



    m4/mpris.m4:
        AC_DEFUN([J4STATUS_PLUGINS_PLUGIN_MPRIS], [
            J4SP_ADD_INPUT_PLUGIN([mpris], [MPRIS D-Bus interface], [yes], [
                AC_ARG_VAR([MPRIS_GDBUS_CODEGEN], [The gdbus-codegen executable])
                PKG_CHECK_MODULES(MPRIS_PLUGIN, [glio-2.0 gobject-2.0 gio-2.0])
                AC_PATH_PROG([MPRIS_GDBUS_CODEGEN], [`$PKG_CONFIG --variable=gdbus_codegen gio-2.0`])
                if test -z "$MPRIS_GDBUS_CODEGEN"; then
                    AC_MSG_ERROR([*** gdbus-codegen is required to build the MPRIS plugin])
                fi
            ])
        ])



    configure.ac:
        #
        # Plugins
        #
        J4STATUS_PLUGINS_PLUGIN_EXEC
        J4STATUS_PLUGINS_PLUGIN_MPRIS



    ./configure --help output:
        --disable-exec-input      Disable Command execution plugin
        --disable-mpris-input      Disable MPRIS D-Bus interface plugin



    ./configure output:
        Input plugins:
            Command execution: yes
            MPRIS D-Bus interface: yes (Default, disable with --disable-mpris-input)

Write a `<plugin>.mk` file
--------------------------

This file must contain your `Makefile.am` code.
Your file must be included in the top-level `Makefile.am`.
If relevant, this include must be conditional.
The automake conditional name is `ENABLE_<ID>_<TYPE>` where
`<ID>` is the upper case version of the id passed to `J4SP_ADD_*` macros and
`<TYPE>` one of `INPUT`, `OUTPUT` or `INPUT_OUTPUT`.

You must add your plugin `.la` file to the `plugins_LTLIBRARIES` variable.
Your file must use full paths (e.g. `<plugin>/src/*.c`) as no recurvise `Makefile`s are used.
You must include the relevant `AM_*` variables if you use per-target variables.

Make sure to include `$(J4STATUS_PLUGIN_LIBS)` in your `*_LIBADD`.

You can add man pages to `man1_MANS` or `man5_MANS` if relevant.
Man pages should be in the DocBook (with a `.xml` extension ) format and
will be processed by `xsltproc` automatically.

Other availables variables:

* `BUILT_SOURCES`
* `CLEANFILES`
* `EXTRA_DIST`: Please do not use this variable in a `dist_*` variant is usable.
    Man pages XML files are added automatically to `EXTRA_DIST`

Example:

    exec/exec.mk:
        plugins_LTLIBRARIES += \
            exec/exec.la


        exec_exec_la_SOURCES = \
            exec/src/exec.c

        exec_exec_la_CFLAGS = \
            $(AM_CFLAGS) \
            $(EXEC_PLUGINS_CFLAGS)

        exec_exec_la_LDFLAGS = \
            $(AM_LDFLAGS) \
            -module -avoid-version -export-symbols-regex j4status_input

        exec_exec_la_LIBADD = \
            $(J4STATUS_PLUGIN_LIBS) \
            $(EXEC_PLUGINS_LIBS)



    mpris/mpris.mk:
        plugins_LTLIBRARIES += \
            mpris/mpris.la

        man5_MANS += \
            mpris/man/j4status-mpris.conf.5

        BUILT_SOURCES += \
            mpris/src/mpris-generated.c \
            mpris/src/mpris-generated.h

        CLEANFILES += \
            mpris/src/mpris-generated.c \
            mpris/src/mpris-generated.h

        EXTRA_DIST += \
            mpris/src/mpris-interface.xml


        mpris_mpris_la_SOURCES = \
            mpris/src/mpris-generated.c \
            mpris/src/mpris-generated.h \
            mpris/src/mpris.c

        mpris_mpris_la_CFLAGS = \
            $(AM_CFLAGS) \
            $(MPRIS_PLUGINS_CFLAGS)

        mpris_mpris_la_LDFLAGS = \
            $(AM_LDFLAGS) \
            -module -avoid-version -export-symbols-regex j4status_input

        mpris_mpris_la_LIBADD = \
            $(J4STATUS_PLUGIN_LIBS) \
            $(MPRIS_PLUGINS_LIBS)


        mpris/src/mpris-generated.h mpris/src/mpris-generated.c: mpris/src/mpris-interface.xml
            $(AM_V_GEN)cd $(builddir)/$(dir $*) && $(MPRIS_GDBUS_CODEGEN) --interface-prefix=org.mpris.MediaPlayer2 --generate-c-code=$(notdir $(basename $*)) --c-namespace=J4statusPluginsMpris $^



    Makefile.am:
        #
        # Plugins
        #
        if ENABLE_EXEC_INPUT
        include exec/exec.mk
        endif
        if ENABLE_MPRIS_INPUT
        include mpris/mpris.mk
        endif