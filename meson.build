project (
    'gala-layoutpw-plugin',
    'vala', 'c',
    version: '0.1.0'
)

vala_args = []

mutter328_dep = dependency('libmutter-2', version: ['>= 3.27', '< 3.29'], required: false)
if mutter328_dep.found()
    add_project_arguments ([
            '--vapidir', join_paths (meson.current_source_dir (), 'vapi'),
            '--pkg', 'libmutter',
            '--pkg', 'mutter-cogl',
            '--pkg', 'mutter-clutter'
        ],
        language: 'vala'
    )
    vala_args += ['--define', 'HAS_MUTTER2']
endif

mutter330_dep = dependency('libmutter-3', version: ['>= 3.29.2', '< 3.31'], required: false)
if mutter330_dep.found()
    add_project_arguments ([
            '--vapidir', join_paths (meson.current_source_dir (), 'vapi'),
            '--pkg', 'libmutter-3',
            '--pkg', 'mutter-cogl-3',
            '--pkg', 'mutter-clutter-3'
        ],
        language: 'vala'
    )
    vala_args += ['--define', 'HAS_MUTTER3']
endif

if mutter328_dep.found() and mutter330_dep.found()
    error ('No supported mutter library found!')
endif

deps = [
    dependency ('gala'),
    dependency ('gee-0.8'),
    dependency ('glib-2.0')
]

lib = shared_library ('gala-layoutpw',
                    'src/Main.vala',
                    dependencies: deps,
                    install: true,
                    vala_args: vala_args,
                    install_dir: join_paths (get_option ('libdir'), 'gala', 'plugins'))
