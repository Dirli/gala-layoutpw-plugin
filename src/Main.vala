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
        private GLib.Settings input_settings;
        private Gee.HashMap<string, uint32> layout_apps;
        private Gee.HashMap<int, uint32> layout_wins;
        private int focused_window_id;
        private string focused_window_wmclass;
        private string path_to_cache;

        private enum SaveType {
            NONE = 0,
            APPLICATION = 1,
            WINDOW = 2
        }

        private SaveType save_state = SaveType.NONE;
        private ILogindManager? logind_manager;

        public override void initialize (Gala.WindowManager wm) {
			this.wm = wm;
#if HAS_MUTTER330
            display = wm.get_display ();
#else
            display = wm.get_screen ().get_display ();
#endif
            layout_wins = new Gee.HashMap<int, uint32> ();
            layout_apps = new Gee.HashMap<string, uint32> ();

            path_to_cache = GLib.Environment.get_user_cache_dir () + "/gala_plugins";

            input_settings = new GLib.Settings ("org.gnome.desktop.input-sources");
            settings = new GLib.Settings ("org.pantheon.desktop.gala.layout-per-window");
            settings.changed["save-type"].connect (on_changed_setting);

            on_changed_setting ();
		}


        private void on_changed_setting () {
            GLib.File file = GLib.File.new_for_path (path_to_cache + "/layoutpw_cache");
            var old_state = save_state;
            save_state = (SaveType) settings.get_enum ("save-type");

            focused_window_wmclass = "";
            focused_window_id = -1;
            layout_apps.clear ();
            layout_wins.clear ();
            logind_manager = null;

            if (save_state != SaveType.APPLICATION) {
                clear_cache (file);
            }

            if (save_state == SaveType.NONE) {
                warning ("layout-per-window plugin: is off");
                if (old_state != SaveType.NONE) {
                    display.window_created.disconnect (on_window_created);
                    Meta.Backend.get_backend ().keymap_changed.disconnect (on_keymap_changed);
                }

                return;
            }

            if (save_state == SaveType.APPLICATION) {
                try {
                    if (file.query_exists () && settings.get_boolean ("restore")) {
                        GLib.DataInputStream dis = new GLib.DataInputStream (file.read ());
                        string line;

                        while ((line = dis.read_line ()) != null) {
                            var entry_arr = line.split ("::");
                            if (entry_arr.length == 2) {
                                layout_apps[entry_arr[0]] = (uint32) uint64.parse (entry_arr[1]);
                            }
                        }
                    }

                    logind_manager = GLib.Bus.get_proxy_sync (BusType.SYSTEM,
                                                              "org.freedesktop.login1",
                                                              "/org/freedesktop/login1");

                    if (logind_manager != null) {
                        logind_manager.prepare_for_shutdown.connect ((start) => {
                            if (settings.get_boolean ("restore") && start) {
                                save_cache ();
                            }
                        });
                        logind_manager.prepare_for_sleep.connect ((start) => {
                            if (settings.get_boolean ("restore") && start) {
                                save_cache ();
                            }
                        });
                    }
                } catch (Error e) {
                    warning ("Error: %s\n", e.message);
                }
            }

            warning ("layout-per-window plugin: selected for %s".printf (save_state == SaveType.APPLICATION ? "application" : "window"));
            if (old_state == SaveType.NONE) {
                display.window_created.connect (on_window_created);
                Meta.Backend.get_backend ().keymap_changed.connect (on_keymap_changed);
            }
        }

        private void on_window_created (Meta.Window window) {
            if (window.window_type == Meta.WindowType.NORMAL) {
                var wmclass = window.get_wm_class ();
                var wid = (int) window.get_xwindow ();
                window.focused.connect (() => {
                    if (save_state == SaveType.APPLICATION) {
                        if (wmclass != null && focused_window_wmclass != wmclass) {
                            focused_window_wmclass = wmclass;
                            application_focused_async.begin (wmclass);
                        }
                    } else if (save_state == SaveType.WINDOW) {
                        if (focused_window_id != wid) {
                            focused_window_id = wid;
                            window_focused_async.begin (wid);
                        }
                    }
                });
                if (save_state == SaveType.WINDOW) {
                    window.unmanaged.connect (() => {
                        if (layout_wins.has_key (wid)) {
                            layout_wins.unset (wid);
                        }
                    });
                }
            }
        }

        private async void application_focused_async (string wmclass) {
            var cur_layout = get_current_layout ();
            if (layout_apps.has_key (wmclass)) {
                if (layout_apps[wmclass] != cur_layout) {
                    input_settings.set_value ("current", layout_apps[wmclass]);
                }
            } else {
                if (cur_layout != 0) {
                    var default_layout = new Variant.uint32 (0);
                    input_settings.set_value ("current", default_layout);
                }
            }
        }

        private async void window_focused_async (int wid) {
            var cur_layout = get_current_layout ();
            if (layout_wins.has_key (wid)) {
                if (layout_wins[wid] != cur_layout) {
                    input_settings.set_value ("current", layout_wins[wid]);
                }
            } else {
                if (cur_layout != 0) {
                    var default_layout = new Variant.uint32 (0);
                    input_settings.set_value ("current", default_layout);
                }
            }
        }

        private void on_keymap_changed () {
            var focused_windows = display.get_focus_window ();
            if (focused_windows != null) {
                var cur_layout = get_current_layout ();
                if (save_state == SaveType.APPLICATION) {
                    var wmclass = focused_windows.get_wm_class ();
                    if (cur_layout != 0) {
                        if (!layout_apps.has_key (wmclass) || layout_apps[wmclass] != cur_layout) {
                            layout_apps[wmclass] = cur_layout;
                        }
                    } else if (layout_apps.has_key (wmclass)) {
                        layout_apps.unset (wmclass);
                    }
                } else if (save_state == SaveType.WINDOW) {
                    var wid = (int) focused_windows.get_xwindow ();
                    if (cur_layout != 0) {
                        if (!layout_wins.has_key (wid) || layout_wins[wid] != cur_layout) {
                            layout_wins[wid] = cur_layout;
                        }
                    } else if (layout_wins.has_key (wid)) {
                        layout_wins.unset (wid);
                    }
                }

            }
        }

        private uint32 get_current_layout () {
            var current = input_settings.get_value ("current");
            return current.get_uint32 ();
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
