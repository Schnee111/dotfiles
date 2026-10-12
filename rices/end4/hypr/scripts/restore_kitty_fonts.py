#!/usr/bin/env python3
import subprocess, json, sys

def main():
    try:
        clients = json.loads(subprocess.check_output(['hyprctl', 'clients', '-j'], timeout=2))
    except Exception:
        return

    pid_to_client = {c.get('pid'): c for c in clients if c.get('pid')}

    try:
        pids = subprocess.check_output(['pgrep', '-x', 'kitty'], timeout=2).decode().split()
    except Exception:
        return

    for pid_str in pids:
        try:
            pid = int(pid_str)
            c = pid_to_client.get(pid)
            if not c:
                continue
            w_class = c.get('class', '')
            title = c.get('title', '')
            
            # Determine target font size
            target_font = None
            if w_class in ['kitty-btop', 'kitty-ws9'] or 'btop' in title:
                target_font = '10.0'
            elif w_class in ['kitty-fastfetch', 'kitty-main'] or any(k in title for k in ['hermes', 'agy']):
                target_font = '11.0'

            if target_font:
                subprocess.run(
                    ['kitten', '@', '--to', f'unix:@kitty-{pid}', 'set-font-size', target_font],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=0.5
                )
        except Exception:
            continue

if __name__ == '__main__':
    main()
