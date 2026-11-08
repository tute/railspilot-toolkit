#!/usr/bin/env python3 -I
"""figma_tokens.py <nodes.json> [node-name-filter]

Walks a Figma /v1/files/<file>/nodes response and prints, in reading order:
TEXT nodes (characters, fontFamily, fontWeight, fontSize, lineHeight, fill hex) and
FRAME nodes with auto-layout (name, size, layoutMode, itemSpacing, padding, fill hex).
"""
import json
import sys


def hex_of(fills):
    for f in fills or []:
        if f.get("type") == "SOLID" and f.get("visible", True):
            c = f["color"]
            a = f.get("opacity", 1) * c.get("a", 1)
            s = "#%02X%02X%02X" % tuple(round(c[k] * 255) for k in "rgb")
            return s if a >= 0.999 else f"{s}@{a:.2f}"
    return None


def walk(node, depth, out, flt):
    t = node.get("type")
    name = node.get("name", "")
    box = node.get("absoluteBoundingBox") or {}
    if t == "TEXT":
        st = node.get("style", {})
        out.append((box.get("y", 0), box.get("x", 0), "  " * depth + f"T {node.get('characters','').strip()[:80]!r} {st.get('fontFamily')} {st.get('fontWeight')} {st.get('fontSize')}px lh={st.get('lineHeightPx')} fill={hex_of(node.get('fills'))}"))
    elif node.get("layoutMode") and (not flt or flt.lower() in name.lower()):
        pad = tuple(node.get(k, 0) for k in ("paddingTop", "paddingRight", "paddingBottom", "paddingLeft"))
        out.append((box.get("y", 0), box.get("x", 0), "  " * depth + f"F {name!r} {round(box.get('width',0))}x{round(box.get('height',0))} {node['layoutMode']} gap={node.get('itemSpacing')} pad={pad} fill={hex_of(node.get('fills'))} radius={node.get('cornerRadius')}"))
    for ch in node.get("children", []):
        walk(ch, depth + 1, out, flt)


data = json.load(open(sys.argv[1]))
flt = sys.argv[2] if len(sys.argv) > 2 else None
out = []
for n in data.get("nodes", {}).values():
    walk(n["document"], 0, out, flt)
for _, _, line in sorted(out, key=lambda r: (round(r[0] / 8), r[1])):
    print(line)
