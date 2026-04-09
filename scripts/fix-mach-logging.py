#!/usr/bin/env python3
"""Fix mach logging bug where curly braces in file paths crash str.format()"""

import sys

if len(sys.argv) != 2:
    print("Usage: fix-mach-logging.py <firefox-src-dir>")
    sys.exit(1)

src_dir = sys.argv[1]
logging_path = f"{src_dir}/python/mach/mach/logging.py"

content = open(logging_path).read()
old = '        formatted_msg = record.msg.format(**getattr(record, "params", {}))'
new = '        try:\n            formatted_msg = record.msg.format(**getattr(record, "params", {}))\n        except (KeyError, ValueError, IndexError):\n            formatted_msg = record.msg'
content = content.replace(old, new)
open(logging_path, 'w').write(content)
print("Fixed mach logging bug")
