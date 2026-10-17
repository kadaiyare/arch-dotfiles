"""Read-only folder/framework symbols for Starship; never execute project code."""
import os
import sys


def folder_symbol():
    current = os.getcwd()
    home = os.path.realpath(os.path.expanduser('~'))
    if current == home:
        return ''
    categories = {
        '.config': '', 'Downloads': '', 'ダウンロード': '',
        'Music': '󰝚', 'ミュージック': '󰝚', '音楽': '󰝚',
        'Pictures': '', 'ピクチャ': '', '画像': '',
        'Documents': '󰈙', 'ドキュメント': '󰈙',
        'Videos': '', 'ビデオ': '', '動画': '',
        'Desktop': '', 'デスクトップ': '',
    }
    for name, symbol in categories.items():
        prefix = os.path.join(home, name)
        if current == prefix or current.startswith(prefix + os.sep):
            return symbol
    cursor = current
    while cursor != home:
        if os.path.exists(os.path.join(cursor, '.git')):
            return '󰲋'
        parent = os.path.dirname(cursor)
        if parent == cursor:
            break
        cursor = parent
    return ''


def framework_symbols():
    import json
    from pathlib import Path
    import tomllib

    # Prefer framework-specific config/dependencies over their base framework.
    frameworks = [
        ('next', '', ('next.config.js', 'next.config.mjs', 'next.config.ts', 'next.config.cjs')),
        ('nuxt', '󱄆', ('nuxt.config.js', 'nuxt.config.ts', 'nuxt.config.mjs')),
        ('@sveltejs/kit', '', ('svelte.config.js', 'svelte.config.ts')),
        ('astro', '', ('astro.config.mjs', 'astro.config.ts', 'astro.config.js')),
        ('@angular/core', '', ('angular.json',)),
        ('svelte', '', ()), ('vue', '', ()), ('react', '', ()),
    ]
    home = Path.home().resolve()
    cursor = Path.cwd()
    for directory in (cursor, *cursor.parents):
        if directory == home:
            break
        dependencies = set()
        has_manifest = False
        manifest = directory / 'package.json'
        if manifest.is_file():
            has_manifest = True
            try:
                with manifest.open('rb') as stream:
                    data = json.loads(stream.read(512 * 1024))
                if isinstance(data, dict):
                    for group in ('dependencies', 'devDependencies', 'peerDependencies', 'optionalDependencies'):
                        values = data.get(group, {})
                        if isinstance(values, dict):
                            dependencies.update(values)
            except (OSError, ValueError):
                pass
        symbols = []
        for package, symbol, config_files in frameworks:
            if package in dependencies or any((directory / filename).is_file() for filename in config_files):
                symbols.append(symbol)
                break
        if 'tailwindcss' in dependencies:
            symbols.append('󱏿')
        if symbols:
            return ' '.join(symbols)
        cargo = directory / 'Cargo.toml'
        if cargo.is_file():
            has_manifest = True
            try:
                with cargo.open('rb') as stream:
                    data = tomllib.loads(stream.read(512 * 1024).decode())
                deps = data.get('dependencies', {})
                for names, label in [(('egui', 'eframe'), 'egui'), (('tauri',), 'Tauri'), (('iced',), 'Iced')]:
                    if any(name in deps for name in names):
                        return ' ' + label
            except (OSError, ValueError, UnicodeError):
                pass
        # Do not inherit an unrelated parent application's framework.
        if has_manifest or (directory / '.git').exists():
            break
    return ''


if __name__ == '__main__':
    try:
        result = folder_symbol() if sys.argv[1] == 'folder' else framework_symbols()
        if result:
            print(result)
    except (OSError, IndexError):
        pass
