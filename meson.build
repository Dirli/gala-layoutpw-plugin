project(
  'gala-layoutpw-plugin',
  'vala', 'c',
  version: '7.1.1'
)

add_project_arguments([
    '--vapidir=' + join_paths (meson.source_root (), 'vapi'),
  ],
  language: 'vala',
)

c_flags = [
  '-DCLUTTER_ENABLE_COMPOSITOR_API',
  '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
  '-DCOGL_ENABLE_EXPERIMENTAL_API',
  '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API'
]

mutter_dep = []
libmutter_dep = []

vala_flags = []

mutter42_dep = dependency('libmutter-10', version: ['>= 42', '< 43'], required: false)
if mutter42_dep.found()
	libmutter_dep = dependency('libmutter-10', version: '>= 42')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-10'), dependency('mutter-cogl-pango-10'),
		dependency('mutter-clutter-10')
	]
	vala_flags = []
endif

mutter43_dep = dependency('libmutter-11', version: ['>= 43', '< 44'], required: false)
if mutter43_dep.found()
	libmutter_dep = dependency('libmutter-11', version: '>= 43')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-11'), dependency('mutter-cogl-pango-11'),
		dependency('mutter-clutter-11')
	]
	vala_flags = ['--define', 'HAS_MUTTER43']
endif

mutter44_dep = dependency('libmutter-12', version: ['>= 44', '< 45'], required: false)
if mutter44_dep.found()
	libmutter_dep = dependency('libmutter-12', version: '>= 44')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-12'), dependency('mutter-cogl-pango-12'),
		dependency('mutter-clutter-12')
	]
	vala_flags = ['--define', 'HAS_MUTTER43', '--define', 'HAS_MUTTER44']
endif

if mutter_dep.length () == 0
  error('No supported mutter library found!')
endif

mutter_typelib_dir = libmutter_dep.get_pkgconfig_variable('typelibdir')

vapigen = find_program('vapigen', required: false)
if vapigen.found()
  subdir('vapi')
endif

lib = shared_library('gala-layoutpw',
  'src/Main.vala',
  dependencies: [
    dependency('gala', version: '>= 6.0.0'),
    dependency('gee-0.8'),
    dependency('glib-2.0'),
    dependency('gio-unix-2.0'),
    dependency('granite', version: '>= 5.4.0'),
    mutter_dep
  ],
  install: true,
  vala_args: vala_flags,
  c_args: c_flags,
  install_rpath: mutter_typelib_dir,
  install_dir: join_paths(get_option('libdir'), 'gala', 'plugins')
)

install_data(
  'data/gala.layout-per-window.gschema.xml',
  install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

meson.add_install_script('meson/meson_post_install.py')
