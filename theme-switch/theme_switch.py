#!/usr/bin/env python3
"""Switch the user's desktop and supported applications between Mocha and Latte."""

import argparse
import configparser
import fcntl
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import tempfile
import time


def patch_ini(text, section, values):
    """Change named entries without rewriting fonts, comments or Qt byte arrays."""
    lines = text.splitlines(keepends=True)
    header = '[' + section + ']'
    starts = [i for i, line in enumerate(lines) if line.strip() == header]
    if not starts:
        return text.rstrip() + ('\n\n' if text.strip() else '') + header + '\n' + ''.join(f'{k}={v}\n' for k, v in values.items())
    start = starts[0]
    end = next((i for i in range(start + 1, len(lines)) if lines[i].lstrip().startswith('[')), len(lines))
    remaining = dict(values)
    for i in range(start + 1, end):
        match = re.match(r'\s*([^#;=]+?)\s*=', lines[i])
        if match and match[1].strip() in remaining:
            key = match[1].strip()
            lines[i] = f'{key}={remaining.pop(key)}\n'
    if remaining and end > 0 and not lines[end - 1].endswith('\n'): lines[end - 1] += '\n'
    lines[end:end] = [f'{key}={value}\n' for key, value in remaining.items()]
    return ''.join(lines)


def jsonc_spans(text):
    """Locate top-level values while ignoring comments and nested JSON strings."""
    decoder = json.JSONDecoder()

    def skip(i):
        while i < len(text):
            if text[i].isspace(): i += 1
            elif text.startswith('//', i):
                end = text.find('\n', i + 2); i = len(text) if end < 0 else end + 1
            elif text.startswith('/*', i):
                end = text.find('*/', i + 2)
                if end < 0: raise ValueError('Unterminated JSON comment')
                i = end + 2
            else: break
        return i

    opening = skip(0)
    if text[opening:opening + 1] != '{': raise ValueError('Expected a JSON object')
    i, spans = opening + 1, {}
    while True:
        i = skip(i)
        if text[i:i + 1] == '}': return opening, spans
        key, end = decoder.raw_decode(text, i)
        if not isinstance(key, str) or key in spans: raise ValueError('Invalid or duplicate JSON key')
        i = skip(end)
        if text[i:i + 1] != ':': raise ValueError('Missing JSON colon')
        start = i = skip(i + 1)
        if text[i:i + 1] in ('{', '['):
            depth = 0
            while i < len(text):
                i = skip(i)
                if text[i] == '"': _, i = decoder.raw_decode(text, i); continue
                if text[i] in '{[': depth += 1
                if text[i] in '}]':
                    depth -= 1
                    if depth == 0: i += 1; break
                i += 1
            if depth: raise ValueError('Unbalanced JSON value')
        else:
            _, i = decoder.raw_decode(text, i)
        spans[key] = (start, i)
        i = skip(i)
        if text[i:i + 1] == ',': i += 1
        elif text[i:i + 1] != '}': raise ValueError('Missing JSON comma')


def patch_jsonc(text, values):
    opening, spans = jsonc_spans(text)
    for start, end, value in sorted([(spans[k][0], spans[k][1], v) for k, v in values.items() if k in spans], reverse=True):
        text = text[:start] + json.dumps(value, ensure_ascii=False) + text[end:]
    missing = {k: v for k, v in values.items() if k not in spans}
    if missing:
        entries = ',\n'.join('  ' + json.dumps(k) + ': ' + json.dumps(v, ensure_ascii=False) for k, v in missing.items())
        text = text[:opening + 1] + '\n' + entries + (',' if spans else '') + '\n' + text[opening + 1:]
    return text


def material(p):
    roles = {
        'background': 'base', 'surface': 'base', 'surface_dim': 'mantle', 'surface_bright': 'surface0',
        'surface_container_lowest': 'crust', 'surface_container_low': 'mantle', 'surface_container': 'base',
        'surface_container_high': 'surface0', 'surface_container_highest': 'surface1', 'surface_variant': 'surface0',
        'on_background': 'text', 'on_surface': 'text', 'on_surface_variant': 'subtext1',
        'outline': 'overlay0', 'outline_variant': 'surface2', 'shadow': 'crust', 'scrim': 'crust',
        'primary': 'lavender', 'on_primary': 'base', 'primary_container': 'surface1', 'on_primary_container': 'text',
        'inverse_primary': 'mauve', 'surface_tint': 'lavender', 'source_color': 'lavender',
        'primary_fixed': 'lavender', 'primary_fixed_dim': 'mauve', 'on_primary_fixed': 'base', 'on_primary_fixed_variant': 'crust',
        'secondary': 'blue', 'on_secondary': 'base', 'secondary_container': 'surface0', 'on_secondary_container': 'text',
        'secondary_fixed': 'blue', 'secondary_fixed_dim': 'sapphire', 'on_secondary_fixed': 'base', 'on_secondary_fixed_variant': 'crust',
        'tertiary': 'pink', 'on_tertiary': 'base', 'tertiary_container': 'surface0', 'on_tertiary_container': 'text',
        'tertiary_fixed': 'pink', 'tertiary_fixed_dim': 'mauve', 'on_tertiary_fixed': 'base', 'on_tertiary_fixed_variant': 'crust',
        'error': 'red', 'on_error': 'base', 'error_container': 'surface0', 'on_error_container': 'red',
        'inverse_surface': 'text', 'inverse_on_surface': 'base'
    }
    return {k: p[v] for k, v in roles.items()}


def gtk4_css(palettes):
    roles = {'window-bg-color': 'base', 'window-fg-color': 'text', 'view-bg-color': 'mantle',
             'view-fg-color': 'text', 'headerbar-bg-color': 'mantle', 'headerbar-fg-color': 'text',
             'headerbar-backdrop-color': 'crust', 'sidebar-bg-color': 'mantle', 'sidebar-fg-color': 'text',
             'secondary-sidebar-bg-color': 'crust', 'secondary-sidebar-fg-color': 'text',
             'card-bg-color': 'surface0', 'card-fg-color': 'text', 'dialog-bg-color': 'base',
             'dialog-fg-color': 'text', 'popover-bg-color': 'surface0', 'popover-fg-color': 'text',
             'accent-bg-color': 'lavender', 'accent-fg-color': 'base', 'accent-color': 'lavender',
             'destructive-bg-color': 'red', 'destructive-fg-color': 'base', 'destructive-color': 'red',
             'warning-bg-color': 'yellow', 'warning-fg-color': 'base', 'success-bg-color': 'green',
             'success-fg-color': 'base', 'borders': 'surface2'}
    blocks = ['/* Catppuccin: GTK 4.20+ switches these variables live with the system preference. */']
    for mode, flavor in [('light', 'latte'), ('dark', 'mocha')]:
        p = palettes[flavor]
        blocks.append('@media (prefers-color-scheme: ' + mode + ') {\n  :root {\n' +
                      ''.join(f'    --{key}: {p[value]};\n' for key, value in roles.items()) + '  }\n}')
    return '\n'.join(blocks) + '\n'


def firefox_css(palettes):
    roles = {'lwt-accent-color': 'mantle', 'lwt-text-color': 'text', 'toolbar-bgcolor': 'base',
             'toolbar-color': 'text', 'toolbar-field-background-color': 'mantle', 'toolbar-field-color': 'text',
             'toolbar-field-focus-background-color': 'base', 'toolbar-field-focus-color': 'text',
             'tab-selected-bgcolor': 'surface0', 'tab-selected-textcolor': 'text',
             'arrowpanel-background': 'base', 'arrowpanel-color': 'text', 'arrowpanel-border-color': 'surface2',
             'sidebar-background-color': 'mantle', 'sidebar-text-color': 'text',
             'chrome-content-separator-color': 'surface1', 'focus-outline-color': 'lavender',
             'in-content-page-background': 'base', 'in-content-page-color': 'text', 'in-content-primary-button-background': 'lavender'}
    result = '/* Managed Catppuccin Mocha/Latte; follows the operating-system preference. */\n'
    for mode, flavor in [('light', 'latte'), ('dark', 'mocha')]:
        p = palettes[flavor]
        result += '@media (prefers-color-scheme: ' + mode + ') {\n  :root {\n'
        result += ''.join(f'    --{key}: {p[value]} !important;\n' for key, value in roles.items())
        result += '  }\n  #navigator-toolbox { background: ' + p['mantle'] + ' !important; color: ' + p['text'] + ' !important; }\n}\n'
    return result


class Switcher:
    def __init__(self, home=None, resources=None):
        self.home = Path.home() if home is None else Path(home)
        self.config = Path(os.environ.get('XDG_CONFIG_HOME') or self.home / '.config') if home is None else self.home / '.config'
        self.data = Path(os.environ.get('XDG_DATA_HOME') or self.home / '.local/share') if home is None else self.home / '.local/share'
        self.state = Path(os.environ.get('XDG_STATE_HOME') or self.home / '.local/state') if home is None else self.home / '.local/state'
        self.resources = Path(resources) if resources else self.data / 'catppuccin-switch'
        self.palettes = json.loads((self.resources / 'palettes.json').read_text())
        self.edits = {}

    def read(self, path): return self.edits.get(path, path.read_text() if path.exists() else '')
    def ini(self, path, section, values): self.edits[path] = patch_ini(self.read(path), section, values)

    def current(self):
        p = self.state / 'catppuccin-theme/current.json'
        if p.exists(): return json.loads(p.read_text())['mode']
        p = self.config / 'nucleus-shell/config/configuration.json'
        return json.loads(p.read_text()).get('appearance', {}).get('theme', 'dark') if p.exists() else 'dark'

    def replace_colors(self, text, flavor):
        target = self.palettes[flavor]
        mapping = {color.lower(): target[name] for palette in self.palettes.values() for name, color in palette.items()}
        text = re.sub(r'#[0-9a-fA-F]{6}\b', lambda m: mapping.get(m[0].lower(), m[0]), text)
        rgb = {tuple(bytes.fromhex(color[1:])): tuple(bytes.fromhex(target[name][1:])) for palette in self.palettes.values() for name, color in palette.items()}
        def convert(m):
            old = tuple(int(m[i]) for i in [2, 3, 4])
            return m[1] + ', '.join(map(str, rgb.get(old, old)))
        return re.sub(r'(rgba?\(\s*)(\d+)\s*,\s*(\d+)\s*,\s*(\d+)', convert, text)

    def plan(self, mode):
        if mode not in ('light', 'dark'): raise ValueError('Expected light or dark')
        self.edits = {}
        flavor = 'latte' if mode == 'light' else 'mocha'
        p = self.palettes[flavor]
        gtk_name = f'catppuccin-{flavor}-lavender-standard+default'
        gtk = next((root / gtk_name for root in [self.data / 'themes', self.home / '.themes', Path('/usr/share/themes')] if (root / gtk_name / 'gtk-3.0/gtk.css').exists()), None)
        if gtk is None: raise FileNotFoundError('GTK theme is not installed: ' + gtk_name)
        qt = self.resources / f'qt5ct/themes/catppuccin-{flavor}-lavender.conf'
        kde = self.resources / f'kde/generated/color-schemes/Catppuccin{flavor.title()}Lavender.colors'
        for path in [qt, kde]:
            if not path.is_file(): raise FileNotFoundError(path)
        icon = 'Papirus-Light' if mode == 'light' else 'Papirus-Dark'
        for version in ['3.0', '4.0']:
            self.ini(self.config / f'gtk-{version}/settings.ini', 'Settings', {
                'gtk-theme-name': gtk_name, 'gtk-application-prefer-dark-theme': str(mode == 'dark').lower(), 'gtk-icon-theme-name': icon})
        gtk3_settings = self.config / 'gtk-3.0/settings.ini'
        old_modules = re.search(r'(?m)^gtk-modules=(.*)$', self.read(gtk3_settings))
        if old_modules and 'colorreload-gtk-module' in old_modules[1]:
            modules = [m for m in re.split(r'[:;,]', old_modules[1]) if m and m != 'colorreload-gtk-module']
            self.ini(gtk3_settings, 'Settings', {'gtk-modules': ':'.join(modules)})
        self.edits[self.config / 'gtk-4.0/gtk.css'] = gtk4_css(self.palettes)
        gtk3 = self.config / 'gtk-3.0/gtk.css'
        old_css = self.read(gtk3)
        self.edits[gtk3] = re.sub(r"@import\s+['\"]colors\.css['\"]\s*;", '/* Colors follow gtk-theme-name; no fixed palette override. */', old_css)

        # This optional legacy override otherwise pins GTK 3 widgets to old KDE colors.
        colors = material(p)
        gtk_colors = {'theme_bg_color': p['base'], 'theme_fg_color': p['text'], 'theme_base_color': p['mantle'],
                      'theme_text_color': p['text'], 'theme_selected_bg_color': p['lavender'], 'theme_selected_fg_color': p['base'],
                      'theme_unfocused_bg_color': p['base'], 'theme_unfocused_fg_color': p['subtext0'],
                      'theme_unfocused_base_color': p['mantle'], 'theme_unfocused_text_color': p['subtext0'],
                      'theme_unfocused_selected_bg_color': p['surface1'], 'theme_unfocused_selected_fg_color': p['text'],
                      'insensitive_bg_color': p['surface0'], 'insensitive_fg_color': p['overlay0'], 'insensitive_base_color': p['mantle'],
                      'borders': p['surface2'], 'unfocused_borders': p['surface1'], 'warning_color': p['yellow'],
                      'error_color': p['red'], 'success_color': p['green']}
        self.edits[self.config / 'gtk-3.0/colors.css'] = ''.join(f'@define-color {k} {v};\n' for k, v in gtk_colors.items())
        old = self.home / '.gtkrc-2.0'
        text = self.read(old)
        for key, value in [('gtk-theme-name', gtk_name), ('gtk-icon-theme-name', icon)]:
            line = f'{key}="{value}"'
            text = re.sub(r'(?m)^' + re.escape(key) + r'\s*=.*$', line, text) if re.search(r'(?m)^' + key + r'\s*=', text) else text + '\n' + line + '\n'
        self.edits[old] = text
        for version in [5, 6]:
            self.ini(self.config / f'qt{version}ct/qt{version}ct.conf', 'Appearance', {
                'color_scheme_path': str(qt), 'custom_palette': 'true', 'icon_theme': icon, 'style': 'Fusion'})
        parser = configparser.ConfigParser(interpolation=None); parser.optionxform = str; parser.read(kde)
        for section in parser.sections():
            if section.startswith(('Colors:', 'ColorEffects:', 'WM')): self.ini(self.config / 'kdeglobals', section, dict(parser[section]))
        self.ini(self.config / 'kdeglobals', 'General', {'ColorScheme': f'Catppuccin{flavor.title()}Lavender', 'ColorSchemeHash': hashlib.sha1(kde.read_bytes()).hexdigest()})
        self.ini(self.config / 'kdeglobals', 'Icons', {'Theme': icon})
        # Both palettes are installed together; SIGUSR1/2 can switch new foot instances.
        foot = self.config / 'foot/foot.ini'
        self.ini(foot, 'main', {'initial-color-theme': mode})
        configured_foot = configparser.ConfigParser(interpolation=None)
        configured_foot.read_string(self.read(foot))
        for flavor_name, scheme in [('mocha', 'dark'), ('latte', 'light')]:
            fp = configparser.ConfigParser(interpolation=None); fp.read(f'/usr/share/foot/themes/catppuccin-{flavor_name}')
            section = 'colors-' + scheme
            palette = dict(fp[section])
            # Translucent palettes may also contain custom colors for readable glass windows.
            if configured_foot.getfloat(section, 'alpha', fallback=1.0) < 1.0 and configured_foot.has_option(section, 'background'):
                palette.update(dict(configured_foot[section]))
            self.ini(foot, section, palette)
        # Kitty reloads this file, including existing windows.
        kitty = self.config / 'kitty/kitty.conf'
        if kitty.exists():
            text = re.sub(r'(?m)^Catppuccin-(?:Mocha|Latte)\s*$', '# Catppuccin colors are managed by catppuccin-theme', self.read(kitty))
            if 'include current-theme.conf' not in text: text += '\ninclude current-theme.conf\n'
            self.edits[kitty] = text
            cp = configparser.ConfigParser(interpolation=None); cp.read(f'/usr/share/foot/themes/catppuccin-{flavor}')
            ansi = cp['colors-' + mode]
            entries = {'foreground': p['text'], 'background': p['base'], 'cursor': p['rosewater'],
                       'selection_background': p['lavender'], 'selection_foreground': p['base'], 'active_border_color': p['lavender'], 'inactive_border_color': p['surface1']}
            entries.update({f'color{i}': '#' + ansi[('regular' if i < 8 else 'bright') + str(i % 8)] for i in range(16)})
            self.edits[self.config / 'kitty/current-theme.conf'] = ''.join(f'{k} {v}\n' for k, v in entries.items())
        # Konsole uses its own terminal palette in addition to the Qt widget palette.
        cp = configparser.ConfigParser(interpolation=None); cp.read(f'/usr/share/foot/themes/catppuccin-{flavor}')
        ansi = cp['colors-' + mode]
        def triplet(color): return ','.join(map(str, bytes.fromhex(color.removeprefix('#'))))
        konsole = '[General]\nDescription=Catppuccin ' + flavor.title() + '\nOpacity=1\n'
        for role, value in [('Background', p['base']), ('Foreground', p['text'])]:
            for suffix in ['', 'Intense', 'Faint']:
                konsole += f'\n[{role}{suffix}]\nColor={triplet(value)}\n'
        for index in range(8):
            for suffix, key in [('', 'regular'), ('Intense', 'bright'), ('Faint', 'regular')]:
                konsole += f'\n[Color{index}{suffix}]\nColor={triplet(ansi[key + str(index)])}\n'
        self.edits[self.data / 'konsole/Catppuccin.colorscheme'] = konsole
        profiles = list((self.data / 'konsole').glob('*.profile'))
        if not profiles:
            profile = self.data / 'konsole/Catppuccin.profile'
            self.ini(profile, 'General', {'Name': 'Catppuccin', 'Parent': 'FALLBACK/'})
            profiles = [profile]
            self.ini(self.config / 'konsolerc', 'Desktop Entry', {'DefaultProfile': 'Catppuccin.profile'})
        for profile in profiles: self.ini(profile, 'Appearance', {'ColorScheme': 'Catppuccin'})
        # Use the same fixed palette in the shell and notification center.
        self.edits[self.config / 'nucleus-shell/config/colors.json'] = json.dumps(colors, indent=4) + '\n'
        for variant, name in [('light', 'latte'), ('dark', 'mocha')]:
            self.edits[self.config / f'nucleus-shell/colorschemes/catppuccin-lavender-{variant}.json'] = json.dumps(material(self.palettes[name]), indent=4) + '\n'
        nucleus = self.config / 'nucleus-shell/config/configuration.json'
        if nucleus.exists():
            state = json.loads(nucleus.read_text()); appearance = state.setdefault('appearance', {})
            appearance['theme'] = mode
            appearance.setdefault('colors', {}).update({'autogenerated': False, 'scheme': 'catppuccin-lavender'})
            state.setdefault('bar', {}).setdefault('modules', {})['paddingColor'] = p['base']
            self.edits[nucleus] = json.dumps(state, ensure_ascii=False, indent=4) + '\n'
        if (self.config / 'swaync').exists(): self.edits[self.config / 'swaync/colors.css'] = ''.join(f'@define-color {k} {v};\n' for k, v in colors.items())
        for relative in ['wofi/style.css', 'rofi/catppuccin-mocha.rasi', 'waybar/style.css']:
            path = self.config / relative
            if path.exists(): self.edits[path] = self.replace_colors(path.read_text(), flavor)
        xs = self.config / 'xsettingsd/xsettingsd.conf'
        if xs.exists():
            text = xs.read_text()
            for key, value in [('Net/ThemeName', gtk_name), ('Net/IconThemeName', icon)]:
                text = re.sub(r'(?m)^' + re.escape(key) + r'\s+.*$', key + ' "' + value + '"', text)
            self.edits[xs] = text
        code = self.config / 'Code/User/settings.json'
        if code.exists(): self.edits[code] = patch_jsonc(code.read_text(), {
            'workbench.colorTheme': 'Catppuccin ' + flavor.title(), 'workbench.preferredLightColorTheme': 'Catppuccin Latte',
            'workbench.preferredDarkColorTheme': 'Catppuccin Mocha', 'window.autoDetectColorScheme': True})
        zed = self.config / 'zed/settings.json'
        if zed.exists(): self.edits[zed] = patch_jsonc(zed.read_text(), {
            'theme': {'mode': mode, 'light': 'Catppuccin Latte', 'dark': 'Catppuccin Mocha'},
            'icon_theme': {'mode': mode, 'light': 'Catppuccin Latte', 'dark': 'Catppuccin Mocha'}})
        # Firefox reads these startup settings once; future switches use CSS media queries.
        profiles = self.home / '.mozilla/firefox/profiles.ini'
        if profiles.exists():
            parser = configparser.ConfigParser(); parser.read(profiles)
            for section in parser.sections():
                if not section.startswith('Profile') or not parser.has_option(section, 'Path'): continue
                profile = Path(parser[section]['Path'])
                if parser[section].get('IsRelative', '1') == '1': profile = profiles.parent / profile
                if not profile.is_dir(): continue
                userjs = profile / 'user.js'
                managed = '\n// BEGIN CATPPUCCIN SYSTEM THEME\n' + '\n'.join([
                    'user_pref("extensions.activeThemeID", "default-theme@mozilla.org");',
                    'user_pref("layout.css.prefers-color-scheme.content-override", 2);',
                    'user_pref("browser.theme.toolbar-theme", 2);',
                    'user_pref("browser.theme.content-theme", 2);',
                    'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);']) + '\n// END CATPPUCCIN SYSTEM THEME\n'
                text = re.sub(r'\n?// BEGIN CATPPUCCIN SYSTEM THEME.*?// END CATPPUCCIN SYSTEM THEME\n?', '', self.read(userjs), flags=re.S)
                self.edits[userjs] = text.rstrip() + managed
                self.edits[profile / 'chrome/catppuccin-system.css'] = firefox_css(self.palettes)
                for name in ['userChrome.css', 'userContent.css']:
                    file = profile / 'chrome' / name
                    text = self.read(file)
                    import_line = '@import url("catppuccin-system.css");'
                    if import_line not in text: self.edits[file] = import_line + '\n' + text
        # Compositor decorations follow the selected palette through a small Lua include.
        hypr = self.config / 'hypr/hyprland.lua'
        if hypr.exists():
            text = hypr.read_text()
            include = 'dofile(os.getenv("HOME") .. "/.config/hypr/catppuccin-theme.lua")'
            if include not in text: self.edits[hypr] = text.rstrip() + '\n\n-- Shared Mocha/Latte theme.\n' + include + '\n'
            self.edits[hypr.parent / 'catppuccin-theme.lua'] = ('hl.config({ general = { col = { active_border = { colors = { "rgb(' + p['lavender'][1:] + ')" }, angle = 0 }, inactive_border = "rgb(' + p['surface1'][1:] + ')" } } })\n')
        self.edits[self.state / 'catppuccin-theme/current.json'] = json.dumps({'mode': mode, 'flavor': flavor}) + '\n'
        return self.edits

    def write(self, backup_root):
        backup_root.mkdir(parents=True, exist_ok=True, mode=0o700)
        manifest = backup_root / 'files.json'
        saved = json.loads(manifest.read_text()) if manifest.exists() else {}
        for path, content in self.edits.items():
            # Replace the GTK4 CSS link itself; never write into /usr/share/themes.
            destination = path if path == self.config / 'gtk-4.0/gtk.css' else path.resolve()
            if destination.exists() and destination.read_text() == content: continue
            label = str(destination)
            if label not in saved:
                name = hashlib.sha256(label.encode()).hexdigest()
                if destination.is_symlink(): saved[label] = {'link': os.readlink(destination)}
                elif destination.exists():
                    shutil.copy2(destination, backup_root / name); os.chmod(backup_root / name, 0o600)
                    saved[label] = {'copy': name}
                else: saved[label] = {'absent': True}
            destination.parent.mkdir(parents=True, exist_ok=True)
            descriptor, temporary = tempfile.mkstemp(prefix='.catppuccin-', dir=destination.parent)
            with os.fdopen(descriptor, 'w') as output: output.write(content)
            os.chmod(temporary, 0o600 if destination.suffix == '.json' or destination.name == 'user.js' else 0o644)
            os.replace(temporary, destination)
        manifest.write_text(json.dumps(saved, indent=2) + '\n'); os.chmod(manifest, 0o600)

    def live(self, mode):
        warnings = []
        def run(args):
            try:
                r = subprocess.run(args, capture_output=True, text=True, timeout=8)
                if r.returncode: warnings.append(args[0] + ': ' + (r.stderr.strip() or r.stdout.strip())[:180])
            except (OSError, subprocess.TimeoutExpired) as error: warnings.append(args[0] + ': ' + str(error))
        flavor = 'latte' if mode == 'light' else 'mocha'
        for key, value in [('gtk-theme', f'catppuccin-{flavor}-lavender-standard+default'),
                           ('icon-theme', 'Papirus-Light' if mode == 'light' else 'Papirus-Dark'),
                           ('color-scheme', 'prefer-' + mode)]:
            run(['gsettings', 'set', 'org.gnome.desktop.interface', key, value])
        run(['gdbus', 'emit', '--session', '--object-path', '/KGlobalSettings', '--signal', 'org.kde.KGlobalSettings.notifyChange', '0', '0'])
        if os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'): run(['hyprctl', 'reload'])
        # The notification daemon is optional; do not wait for D-Bus activation
        # when Nucleus is the notification server for this session.
        if shutil.which('swaync-client'):
            try:
                owner = subprocess.run(['gdbus', 'call', '--session', '--dest', 'org.freedesktop.DBus',
                    '--object-path', '/org/freedesktop/DBus', '--method', 'org.freedesktop.DBus.NameHasOwner',
                    'org.erikreider.swaync.cc'], capture_output=True, text=True, timeout=1)
                if 'true' in owner.stdout:
                    subprocess.run(['swaync-client', '-rs'], capture_output=True, timeout=1)
            except (OSError, subprocess.TimeoutExpired):
                pass

        terminals = {}
        for proc in Path('/proc').iterdir():
            if not proc.name.isdigit(): continue
            try:
                if proc.stat().st_uid != os.getuid(): continue
                name = (proc / 'comm').read_text().strip()
                if name == 'kitty': os.kill(int(proc.name), signal.SIGUSR1)
                elif name == 'xsettingsd': os.kill(int(proc.name), signal.SIGHUP)
                elif name in ('foot', 'konsole'):
                    if name == 'foot': os.kill(int(proc.name), signal.SIGUSR2 if mode == 'light' else signal.SIGUSR1)
                    normal_foot = name == 'foot' and b'nucleus-dropdown-terminal' not in (proc / 'cmdline').read_bytes()
                    # Existing foot processes loaded their palettes before installation.
                    # OSC updates their own PTYs without restarting the user's shells.
                    for fd in (proc / 'fdinfo').iterdir():
                        match = re.search(r'(?m)^tty-index:\s*(\d+)\s*$', fd.read_text())
                        if match: terminals[Path('/dev/pts') / match[1]] = normal_foot
            except (OSError, ProcessLookupError, PermissionError): continue
        parser = configparser.ConfigParser(interpolation=None); parser.read(f'/usr/share/foot/themes/catppuccin-{flavor}')
        colors = parser['colors-' + mode]
        osc = ''.join(f'\033]4;{i};#{colors[("regular" if i < 8 else "bright") + str(i % 8)]}\033\\' for i in range(16))
        osc += f'\033]10;#{colors["foreground"]}\033\\\033]11;#{colors["background"]}\033\\'
        osc += f'\033]12;#{colors["cursor"].split()[-1]}\033\\'
        foot_config = configparser.ConfigParser(interpolation=None)
        foot_config.read(self.config / 'foot/foot.ini')
        section = 'colors-' + mode
        background = foot_config.get(section, 'background', fallback=colors['background'])
        alpha = round(foot_config.getfloat(section, 'alpha', fallback=1.0) * 65535)
        rgba = '/'.join(background[i:i+2] * 2 for i in (0, 2, 4)) + f'/{alpha:04x}'
        foot_colors = dict(colors)
        if foot_config.has_section(section): foot_colors.update(dict(foot_config[section]))
        foot_osc = ''.join(f'\033]4;{i};#{foot_colors[("regular" if i < 8 else "bright") + str(i % 8)]}\033\\' for i in range(16))
        foot_osc += f'\033]10;#{foot_colors["foreground"]}\033\\\033]11;rgba:{rgba}\033\\'
        foot_osc += f'\033]12;#{foot_colors["cursor"].split()[-1]}\033\\'
        for terminal, normal_foot in terminals.items():
            try:
                descriptor = os.open(terminal, os.O_WRONLY | os.O_NOCTTY | os.O_NONBLOCK)
                try: os.write(descriptor, (foot_osc if normal_foot else osc).encode())
                finally: os.close(descriptor)
            except OSError as error: warnings.append('foot: ' + str(error))
        return warnings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', nargs='?', choices=['toggle', 'light', 'dark', 'status'], default='toggle')
    parser.add_argument('--no-live', action='store_true', help='Write settings without touching the desktop session')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--shell-managed', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    switcher = Switcher()
    if args.mode == 'status': print(json.dumps({'mode': switcher.current()})); return
    state_dir = switcher.state / 'catppuccin-theme'; state_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (state_dir / 'switch.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        mode = ('light' if switcher.current() == 'dark' else 'dark') if args.mode == 'toggle' else args.mode
        edits = switcher.plan(mode)
        if args.shell_managed:
            edits.pop(switcher.config / 'nucleus-shell/config/configuration.json', None)
        if args.dry_run:
            print(json.dumps({'mode': mode, 'files': [str(p) for p in edits]}, indent=2)); return
        backup_path = state_dir / 'original-backup'
        switcher.write(backup_path)
        warnings = [] if args.no_live else switcher.live(mode)
        if not args.no_live and not args.shell_managed and shutil.which('quickshell'):
            try:
                subprocess.run(['quickshell', '-c', 'nucleus-shell', 'ipc', 'call', 'global', 'syncTheme', mode],
                               capture_output=True, timeout=2)
            except (OSError, subprocess.TimeoutExpired): pass
        print(json.dumps({'mode': mode, 'flavor': 'latte' if mode == 'light' else 'mocha', 'warnings': warnings}, ensure_ascii=False))


if __name__ == '__main__':
    main()
