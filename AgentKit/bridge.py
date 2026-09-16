import argparse, json, uuid, base64, sys
from pathlib import Path

def validate(d):
    assert d['format'] == 'ielts-semantic-breakdown' and d['version'] == 1, 'Unsupported format/version'
    t = d['document']['text']
    raw = t.encode('utf-16-le')
    assert len(t.encode()) <= 3_000_000
    ids = set()
    for n in d['annotations']:
        assert n['id'] not in ids, 'Duplicate ID: ' + str(n['id'])
        ids.add(n['id'])
        assert 0 <= n['start'] < n['end'] <= len(raw) // 2, 'Invalid range'
        assert raw[n['start'] * 2 : n['end'] * 2].decode('utf-16-le') == n['quote'], f"Quote mismatch: {raw[n['start']*2:n['end']*2].decode('utf-16-le')} != {n['quote']}"
        assert n['kind'] in ['comment', 'correction', 'vocabulary', 'structure', 'bold', 'italic', 'underline', 'highlight'], 'Invalid kind: ' + str(n['kind'])
        assert n['level'] in ['essay', 'paragraph', 'sentence', 'word'], 'Invalid level: ' + str(n['level'])
        assert all(isinstance(n[k], str) for k in ['label', 'body']), 'Label and body must be strings'
    images = [base64.b64decode(i['data'], validate=True) for i in d.get('images', [])]
    assert len(images) <= 12 and sum(map(len, images)) <= 48_000_000 and all(len(i) <= 8_000_000 for i in images)

def library_dir():
    p = Path.home() / "Library" / "Application Support" / "Passage" / "Library"
    p.mkdir(parents=True, exist_ok=True)
    return p

def main():
    p = argparse.ArgumentParser(description="Pass Passage By! Agent Bridge")
    sub = p.add_subparsers(dest='command', required=True)

    v = sub.add_parser('validate')
    v.add_argument('file')

    a = sub.add_parser('assemble')
    a.add_argument('essay')
    a.add_argument('notes')
    a.add_argument('output', nargs='?', default=None)
    a.add_argument('--title', default='Untitled')
    a.add_argument('--task-type', default='unknown')
    a.add_argument('--prompt')
    a.add_argument('--to-library', action='store_true', help='Export directly into Pass Passage By! local Library')

    args = p.parse_args()

    if args.command == 'validate':
        validate(json.loads(Path(args.file).read_text(encoding='utf-8')))
        print('Valid PPB document: ' + args.file)
        return

    if args.command == 'assemble':
        text = Path(args.essay).read_text(encoding='utf-8')
        notes = json.loads(Path(args.notes).read_text(encoding='utf-8'))
        result = []
        for source in notes:
            n = dict(source)
            quote = n['quote']
            assert quote, 'Empty quote'
            start = -1
            for _ in range(n.pop('occurrence', 0) + 1):
                start = text.find(quote, start + 1)
                assert start >= 0, 'Quote not found: ' + quote
            n.update(
                id=n.get('id', str(uuid.uuid4())),
                start=len(text[:start].encode('utf-16-le')) // 2,
                end=len(text[:start + len(quote)].encode('utf-16-le')) // 2
            )
            for k, value in dict(kind='comment', level='sentence', label='Note', body='', side='right', tag='blue').items():
                n.setdefault(k, value)
            result.append(n)

        doc_id = str(uuid.uuid4())
        d = dict(
            format='ielts-semantic-breakdown',
            version=1,
            document=dict(
                id=doc_id,
                title=args.title,
                text=text,
                taskType=args.task_type,
                prompt=Path(args.prompt).read_text(encoding='utf-8') if args.prompt else ''
            ),
            annotations=result
        )
        validate(d)

        out_path = args.output
        if args.to_library or not out_path:
            out_file = library_dir() / f"{doc_id}.json"
            out_file.write_text(json.dumps(d, ensure_ascii=False, indent=2), encoding='utf-8')
            print(f"SUCCESS: Saved to Pass Passage By! Library: {out_file}")
            print(f"To open: open -a \"/Applications/Pass Passage By!.app\" \"{out_file}\"")
        else:
            p_out = Path(out_path)
            p_out.parent.mkdir(parents=True, exist_ok=True)
            p_out.write_text(json.dumps(d, ensure_ascii=False, indent=2), encoding='utf-8')
            print(str(p_out))

if __name__ == '__main__':
    main()
