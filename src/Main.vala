/*
 * Copyright (c) 2019 Dirli <litandrej85@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

namespace Gala.Plugins.LayoutPW {
    [DBus (name = "org.freedesktop.login1.Manager")]
    interface ILogindManager : DBusProxy {
        public abstract signal void prepare_for_shutdown (bool start);
        public abstract signal void prepare_for_sleep (bool start);
    }

	public class Main : Gala.Plugin {
        private Gala.WindowManager? wm = null;
        private Meta.Display display;
        private GLib.Settings settings;
        private Gee.HashMap<string, uint32> layout_apps;
        private string focused_window_wmclass;
        private string path_to_cache;

        private ILogindManager? logind_manager;

        public override void initialize (Gala.WindowManager wm) {
			this.wm = wm;
#if HAS_MUTTER3
            display = wm.get_display ();
#endif
#if HAS_MUTTER2
            display = wm.get_screen ().get_display ();
#endif
            layout_apps = new Gee.HashMap<string, uint32> ();

            path_to_cache = GLib.Environment.get_user_cache_dir () + "/gala_plugins";

            settings = new GLib.Settings ("org.gnome.desktop.input-sources");
            settings.changed["per-window"].connect (on_changed_setting);

            on_changed_setting ();
		}


        private void on_changed_setting () {
            GLib.File file = GLib.File.new_for_path (path_to_cache + "/layoutpw_cache");
            /* if (settings.get_boolean ("per-window")) { */
                focused_window_wmclass = "";

                try {
                    if (file.query_exists ()) {
                        GLib.DataInputStream dis = new GLib.DataInputStream (file.read ());
                        string line;

                        while ((line = dis.read_line ()) != null) {
                            var entry_arr = line.split ("::");
                            if (entry_arr.length == 2) {
                                layout_apps[entry_arr[0]] = (uint32) uint64.parse (entry_arr[1]);
                            }
                        }
                    }

                } catch (Error e) {
                    warning ("Error: %s\n", e.message);
                }

                display.window_created.connect (on_window_created);
                Meta.Backend.get_backend ().keymap_changed.connect (on_keymap_changed);

                try {
                    logind_manager = GLib.Bus.get_proxy_sync (BusType.SYSTEM,
                                                              "org.freedesktop.login1",
                                                              "/org/freedesktop/login1");

                    if (logind_manager != null) {
                        logind_manager.prepare_for_shutdown.connect ((start) => {
                            if (start) {
                                save_cache ();
                            }
                        });
                        logind_manager.prepare_for_sleep.connect ((start) => {
                            if (start) {
                                save_cache ();
                            }
                        });
                    }
                } catch (Error e) {
                    warning ("Error: %s\n", e.message);
                }

            /* } else {
                display.window_created.disconnect (on_window_created);
                Meta.Backend.get_backend ().keymap_changed.disconnect (on_keymap_changed);
                layout_apps.clear ();
                clear_cache (file);
                logind_manager = null;
            } */
        }

        private void on_window_created (Meta.Window window) {
            if (window.window_type == Meta.WindowType.NORMAL) {
                window.focused.connect (() => {
                    var wmclass = window.get_wm_class ();
                    if (wmclass != null && focused_window_wmclass != wmclass) {
                        focused_window_wmclass = wmclass;
                        var current = settings.get_value ("current");
                        var cur_layout = current.get_uint32 ();
                        if (layout_apps.has_key (wmclass)) {
                            if (layout_apps[wmclass] != cur_layout) {
                                settings.set_value ("current", layout_apps[wmclass]);
                            }
                        } else {
                            if (cur_layout != 0) {
                                var default_layout = new Variant.uint32 (0);
                                settings.set_value ("current", default_layout);
                            }
                        }
                    }
                });
            }
        }

        private void on_keymap_changed () {
            var focused_windows = display.get_focus_window ();
            if (focused_windows != null) {
                var wmclass = focused_windows.get_wm_class ();
                var current = settings.get_value ("current");
                var cur_layout = current.get_uint32 ();
                if (cur_layout != 0) {
                    if (!layout_apps.has_key (wmclass) || layout_apps[wmclass] != cur_layout) {
                        layout_apps[wmclass] = cur_layout;
                    }
                } else if (layout_apps.has_key (wmclass)) {
                    layout_apps.unset (wmclass);
                }
            }
        }

        private bool clear_cache (GLib.File file) {
            try {
                var path = GLib.File.new_for_path (path_to_cache);
                if (!path.query_exists ()) {
                    path.make_directory ();
                }

                if (file.query_exists ()) {
                    file.delete ();
                }

            } catch (Error e) {
                warning (e.message);
                return false;
            }

            return true;
        }

        private void save_cache () {
            try {
                var cache_file = GLib.File.new_for_path (path_to_cache + "/layoutpw_cache");

                if (clear_cache (cache_file)) {
                    if (layout_apps.size > 0) {
                        var dos = new GLib.DataOutputStream (cache_file.create (FileCreateFlags.REPLACE_DESTINATION));

                        layout_apps.foreach ((m_entry) => {
                            try {
                                dos.put_string ("%s::%llu\n".printf (m_entry.key, m_entry.value));
                            } catch (Error e) {
                                warning (e.message);
                                return false;
                            }

                            return true;
                        });
                    }
                }

            } catch (Error e) {
                warning (e.message);
            }
        }

        public override void destroy () {
			if (wm == null) {
				return;
            }

            display.window_created.disconnect (on_window_created);
            Meta.Backend.get_backend ().keymap_changed.disconnect (on_keymap_changed);
		}
    }
}

public Gala.PluginInfo register_plugin () {
	return Gala.PluginInfo () {
		name = "LayoutPW",
		author = "dirli litandrej85@gmail.com",
		plugin_type = typeof (Gala.Plugins.LayoutPW.Main),
		provides = Gala.PluginFunction.ADDITION,
		load_priority = Gala.LoadPriority.IMMEDIATE
	};
}
