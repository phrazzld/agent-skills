# /harness sync

Pull primitives from spellbook into project-local harness directories.

## How it works

Reads `.spellbook.yaml`, pulls declared skills/agents from GitHub into
project-local harness directories. When a local spellbook checkout exists,
uses symlinks instead (edits propagate instantly).

## Marker file convention

Managed primitives have a `.spellbook` marker file.
/harness sync only touches directories with this marker.
