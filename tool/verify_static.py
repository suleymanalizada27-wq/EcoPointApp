#!/usr/bin/env python3
"""Offline static checks (no Dart SDK needed):
 1. syntax check of every .dart file via tree-sitter (if installed)
 2. every relative / package:ecopoint imports resolves to a file
 3. every context.tr('key') literal exists in all 4 string tables
 4. all 4 string tables have identical key sets
Run: python3 tool/verify_static.py
"""
import re, sys, pathlib
root = pathlib.Path(__file__).resolve().parent.parent
lib = root / 'lib'
files = sorted(list(lib.rglob('*.dart')) + list((root / 'test').rglob('*.dart')))
errors = []

# 1. syntax
try:
    from tree_sitter_language_pack import get_parser
    parser = get_parser('dart')
    def has_err(node):
        stack = [node]
        while stack:
            n = stack.pop()
            if n.type == 'ERROR' or n.is_missing:
                return n
            stack.extend(n.children)
        return None
    for f in files:
        tree = parser.parse(f.read_bytes())
        bad = has_err(tree.root_node)
        if bad is not None:
            errors.append(f'SYNTAX {f.relative_to(root)}:{bad.start_point[0]+1}')
    print(f'syntax: parsed {len(files)} files')
except Exception as e:
    print('syntax: SKIPPED (' + str(e) + ')')

# 2. imports
name = re.search(r'^name:\s*(\S+)', (root / 'pubspec.yaml').read_text(), re.M).group(1)
imp = re.compile(r"""^\s*(?:import|export|part)\s+['"]([^'"]+)['"]""", re.M)
for f in files:
    for m in imp.finditer(f.read_text()):
        t = m.group(1)
        if t.startswith('dart:'):
            continue
        if t.startswith('package:'):
            if t.startswith(f'package:{name}/'):
                p = lib / t[len(f'package:{name}/'):]
                if not p.exists():
                    errors.append(f'IMPORT {f.relative_to(root)} -> {t}')
            continue
        if not (f.parent / t).resolve().exists():
            errors.append(f'IMPORT {f.relative_to(root)} -> {t}')

# 3/4. l10n
def table(code):
    txt = (lib / 'app/localization' / f'strings_{code}.dart').read_text()
    return set(re.findall(r"^\s*'([a-z0-9_]+)'\s*:", txt, re.M))
tables = {c: table(c) for c in ('az', 'en', 'ru', 'tr')}
base = tables['en']
for c, t in tables.items():
    for k in sorted(base - t): errors.append(f'L10N {c} missing {k}')
    for k in sorted(t - base): errors.append(f'L10N {c} extra {k}')
used = set()
lit = re.compile(r"""\btr\(\s*'([a-z0-9_]+)'""")
for f in files:
    used |= set(lit.findall(f.read_text()))
for k in sorted(used - base):
    errors.append(f'L10N key used but undefined: {k}')
print(f'l10n: {len(base)} keys x 4 langs, {len(used)} literal keys used')

if errors:
    print('\n'.join(errors)); sys.exit(1)
print('OK')
