project (
    'gala-layoutpw-plugin',
    'vala', 'c',
    version: '0.3.4'
)

add_project_arguments ([
        '--vapidir=' + join_paths (meson.source_root (), 'vapi'),
    ],
    language: 'vala',
)

mutter_dep = []
libmutter_dep = []

vala_flags = []
c_flags = [
    '-DCLUTTER_ENABLE_COMPOSITOR_API',
    '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
	'-DCOGL_ENABLE_EXPERIMENTAL_API',
    '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API'
]

mutter336_dep = dependency ('libmutter-6', version: ['>= 3.35.1', '< 3.38'], required: false)
if mutter336_dep.found ()
    libmutter_dep = dependency ('libmutter-6', version: '>= 3.35.1')
    mutter_dep = [
        dependency ('mutter-cogl-6'),
        dependency ('mutter-cogl-pango-6'),
        dependency ('mutter-cogl-path-6'),
        dependency ('mutter-clutter-6')
    ]
endif

mutter338_dep = dependency ('libmutter-7', version: ['>= 3.37', '< 3.39'], required: false)
if mutter338_dep.found ()
	libmutter_dep = dependency ('libmutter-7', version: '>= 3.37')
	mutter_dep = [
		dependency ('mutter-cogl-7'),
        dependency ('mutter-cogl-pango-7'),
		dependency ('mutter-clutter-7')
	]
	vala_flags = ['--define', 'HAS_MUTTER338']
endif

if mutter_dep.length () == 0
    error ('No supported mutter library found!')
endif

mutter_typelib_dir = libmutter_dep.get_pkgconfig_variable ('typelibdir')

vapigen = find_program ('vapigen', required: false)
if vapigen.found ()
    subdir ('vapi')
endif

lib = shared_library ('gala-layoutpw',
    'src/Main.vala',
    dependencies: [
        dependency ('gala'),
        dependency ('gee-0.8'),
        dependency ('glib-2.0'),
        dependency ('gio-unix-2.0'),
        mutter_dep
    ],
    install: true,
    vala_args: vala_flags,
    c_args: c_flags,
    install_rpath: mutter_typelib_dir,
    install_dir: join_paths (get_option ('libdir'), 'gala', 'plugins')
)

install_data (
    'data/gala.layout-per-window.gschema.xml',
    install_dir: join_paths (get_option ('datadir'), 'glib-2.0', 'schemas')
)

meson.add_install_script ('meson/meson_post_install.py')
