"""Check actual packaged page registry and ABC, including a cloud-re-signed .app."""
import io
import json
import sys
from pathlib import Path
from zipfile import ZipFile

STUDIES = ('SketchLab', 'ReadingDemo', 'MicaStudy', 'ReadingEdgeStudy',
           'CloudAcceptance', 'AlbumStudy', 'FridgePreviewer', 'NativeV28QA')


def audit_hap(data, label):
    with ZipFile(io.BytesIO(data)) as hap:
        pages = json.loads(hap.read('resources/base/profile/main_pages.json'))['src']
        if pages != ['pages/Index', 'pages/WidgetBinding', 'pages/ReceiveTemplate']:
            raise ValueError(f'{label}: unexpected registered pages: {pages}')
        abc = hap.read('ets/modules.abc')
        for name in STUDIES:
            for token in (f'ets/pages/{name}', f'pages/{name}'):
                if token.encode() in abc:
                    raise ValueError(f'{label}: experimental page remains in ABC: {name}')
        packaged = json.loads(hap.read('module.json'))
        for capability in ('cloudFileSyncEnabled', 'cloudStructuredDataSyncEnabled'):
            if packaged['app'].get(capability, False):
                raise ValueError(f'{label}: unverified cloud capability remains enabled: {capability}')
        for token in ('ets/model/SystemCloudSync', 'ets/model/CloudSyncFiles', 'ets/views/CloudSyncDialog'):
            if token.encode() in abc:
                raise ValueError(f'{label}: experimental cloud coordinator remains linked: {token}')
        manifest = packaged['module']
        if [a['name'] for a in manifest['abilities']] != ['EntryAbility']:
            raise ValueError(f'{label}: unexpected ability entry')
        if {a['name'] for a in manifest['extensionAbilities']} != {'TemplateShareAbility', 'FridgeFormAbility', 'WidgetConfigAbility'}:
            raise ValueError(f'{label}: production extensions changed')
        print(f'PASS {label}: production pages/extensions retained; all study/temporary QA page modules absent')


paths = [Path(p) for p in sys.argv[1:]] or [Path('build/outputs/default/FridgeMemo-default-signed.app')]
missing = [str(path) for path in paths if not path.exists()]
if missing:
    raise SystemExit('Package not found: ' + ', '.join(missing))
if not paths:
    raise SystemExit('No .app found. Build release first or pass a .hap/.app path.')
for path in paths:
    if path.suffix == '.hap':
        audit_hap(path.read_bytes(), str(path))
    elif path.suffix == '.app':
        with ZipFile(path) as app:
            haps = [name for name in app.namelist() if name.endswith('.hap')]
            if not haps:
                raise ValueError(f'{path}: no HAP found')
            for name in haps:
                audit_hap(app.read(name), f'{path}!{name}')
    else:
        raise ValueError(f'Unsupported package: {path}')
