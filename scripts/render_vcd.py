import sys
import os
import re
from PIL import Image, ImageDraw, ImageFont

def parse_vcd_advanced(vcd_path):
    timescale = "1ns"
    current_time = 0
    in_definitions = True
    scope_stack = []

    # raw_vars: var_id -> {scope, name, size, type, bit_idx, base_name}
    raw_vars = {}
    time_changes = {} # time -> {var_id: val}

    with open(vcd_path, 'r', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            if in_definitions:
                if line.startswith('$timescale'):
                    parts = line.split()
                    if len(parts) >= 2 and parts[1] != '$end':
                        timescale = parts[1]
                elif line.startswith('$scope'):
                    parts = line.split()
                    if len(parts) >= 3:
                        scope_stack.append(parts[2])
                elif line.startswith('$upscope'):
                    if scope_stack:
                        scope_stack.pop()
                elif line.startswith('$var'):
                    parts = line.split()
                    if len(parts) >= 5:
                        var_type = parts[1]
                        size = int(parts[2])
                        var_id = parts[3]
                        # Exclude trailing $end if present
                        name_tokens = parts[4:-1] if parts[-1] == '$end' else parts[4:]
                        raw_name = "".join(name_tokens)

                        # Check if bit sliced e.g. name[2] or ranged e.g. name[1:0]
                        m = re.match(r'^([^\[]+)\[(\d+)(?::(\d+))?\]$', raw_name)
                        if m:
                            base_name = m.group(1)
                            if m.group(3) is not None:
                                # Range like [1:0], already multi-bit
                                bit_idx = None
                            else:
                                # Single bit slice like [2]
                                bit_idx = int(m.group(2))
                        else:
                            base_name = raw_name
                            bit_idx = None

                        # If already recorded at a shallower scope (e.g. top testbench), don't overwrite with deeper scope
                        if var_id in raw_vars and len(raw_vars[var_id]['scope']) <= len(scope_stack):
                            pass
                        else:
                            raw_vars[var_id] = {
                                'var_id': var_id,
                                'scope': list(scope_stack),
                                'name': raw_name,
                                'base_name': base_name,
                                'bit_idx': bit_idx,
                                'size': size,
                                'type': var_type
                            }
                elif line.startswith('$enddefinitions'):
                    in_definitions = False
                continue

            if line.startswith('#'):
                try:
                    current_time = int(line[1:])
                except ValueError:
                    pass
                continue

            if line.startswith('$dumpvars') or line.startswith('$end'):
                continue

            if current_time not in time_changes:
                time_changes[current_time] = {}

            if line.startswith('b') or line.startswith('B'):
                parts = line[1:].split()
                if len(parts) >= 2:
                    time_changes[current_time][parts[1]] = parts[0]
            elif line.startswith('r') or line.startswith('R'):
                parts = line[1:].split()
                if len(parts) >= 2:
                    time_changes[current_time][parts[1]] = parts[0]
            else:
                val = line[0]
                var_id = line[1:].strip()
                time_changes[current_time][var_id] = val

    # Now assemble unified signals at Top-level (scope depth 1)
    # Filter for top-level scope (e.g. testbench)
    top_scope = None
    for v in raw_vars.values():
        if len(v['scope']) == 1:
            top_scope = v['scope'][0]
            break

    # Group variables belonging to top_scope
    bus_groups = {} # base_name -> list of raw_var
    top_vars = []
    for v in raw_vars.values():
        if v['scope'] == [top_scope]:
            base = v['base_name']
            if base.lower() in ['i', 'j', 'k', 'idx', 'loop'] or v['type'] == 'integer':
                continue
            if base not in bus_groups:
                bus_groups[base] = []
            bus_groups[base].append(v)

    all_times = sorted(time_changes.keys())
    assembled_signals = []

    for base_name, vars_in_group in bus_groups.items():
        # Check if single variable with size > 1
        if len(vars_in_group) == 1 and vars_in_group[0]['bit_idx'] is None:
            v = vars_in_group[0]
            var_id = v['var_id']
            changes = []
            last_val = '0' if v['size'] == 1 else '0'*v['size']
            for t in all_times:
                if var_id in time_changes[t]:
                    last_val = time_changes[t][var_id]
                    changes.append((t, last_val))
            assembled_signals.append({
                'name': base_name if v['size'] == 1 else f"{base_name}[{v['size']-1}:0]",
                'base_name': base_name,
                'size': v['size'],
                'changes': changes
            })
        else:
            # Multi-bit bus decomposed into bits [0], [1], ...
            # Sort by bit_idx descending
            sorted_bits = sorted([v for v in vars_in_group if v['bit_idx'] is not None], key=lambda x: x['bit_idx'], reverse=True)
            if not sorted_bits:
                v = vars_in_group[0]
                var_id = v['var_id']
                changes = [(t, time_changes[t][var_id]) for t in all_times if var_id in time_changes[t]]
                assembled_signals.append({
                    'name': base_name,
                    'base_name': base_name,
                    'size': 1,
                    'changes': changes
                })
                continue

            max_idx = sorted_bits[0]['bit_idx']
            min_idx = sorted_bits[-1]['bit_idx']
            width = max_idx - min_idx + 1

            bit_state = {v['bit_idx']: '0' for v in sorted_bits}
            changes = []
            last_assembled = ""

            for t in all_times:
                changed = False
                for v in sorted_bits:
                    vid = v['var_id']
                    if vid in time_changes[t]:
                        bit_state[v['bit_idx']] = time_changes[t][vid]
                        changed = True
                if changed:
                    # Construct binary string MSB to LSB
                    assembled_val = "".join([bit_state[idx] for idx in range(max_idx, min_idx - 1, -1)])
                    if assembled_val != last_assembled:
                        changes.append((t, assembled_val))
                        last_assembled = assembled_val

            assembled_signals.append({
                'name': f"{base_name}[{max_idx}:{min_idx}]",
                'base_name': base_name,
                'size': width,
                'changes': changes
            })

    # Order signals nicely: Clock first, reset second, inputs, then outputs/buses
    def sig_order(s):
        name = s['base_name'].lower()
        if 'clk' in name:
            return 0
        if 'rst' in name or 'reset' in name:
            return 1
        if 'in' in name or 'a' in name or 'b' in name or 'start' in name:
            return 2
        return 3

    assembled_signals.sort(key=sig_order)
    return assembled_signals, timescale, current_time

def render_waveform(vcd_path, out_png, title="Simulation Waveform", max_time_ps=None):
    signals, timescale, end_time = parse_vcd_advanced(vcd_path)
    if not signals:
        print(f"No signals found in {vcd_path}")
        return

    if max_time_ps and max_time_ps > 0:
        total_time = max_time_ps
    else:
        total_time = max(end_time, 1)

    width = 1380
    header_height = 80
    row_height = 42
    footer_height = 32
    total_height = header_height + len(signals) * row_height + footer_height

    label_col_width = 250
    wave_left = label_col_width + 15
    wave_right = width - 40
    wave_width = wave_right - wave_left

    # Visual Theme - Professional Dark
    c_bg = (20, 21, 24)           # Deep sleek gray
    c_panel_bg = (28, 29, 34)     # Sidebar panel
    c_wave_bg = (14, 15, 18)      # Waveform canvas
    c_border = (44, 46, 52)       # Borders
    c_grid = (32, 34, 40)         # Timeline grid lines
    c_text_title = (255, 255, 255)
    c_text_sub = (150, 155, 165)
    c_sig_name = (225, 230, 240)
    c_sig_clock = (56, 189, 248)  # Ice Blue
    c_sig_bit = (74, 222, 128)    # Neon Green
    c_sig_bus_line = (245, 158, 11) # Amber outline
    c_bus_fill = (45, 36, 20)     # Bus fill
    c_bus_text = (254, 243, 199)
    c_time_tick = (170, 175, 185)

    img = Image.new('RGB', (width, total_height), c_bg)
    draw = ImageDraw.Draw(img)

    try:
        font_title = ImageFont.truetype(r'C:\Windows\Fonts\consola.ttf', 18)
        font_sub = ImageFont.truetype(r'C:\Windows\Fonts\consola.ttf', 12)
        font_sig = ImageFont.truetype(r'C:\Windows\Fonts\consola.ttf', 14)
        font_val = ImageFont.truetype(r'C:\Windows\Fonts\consola.ttf', 11)
        font_time = ImageFont.truetype(r'C:\Windows\Fonts\consola.ttf', 11)
    except:
        font_title = ImageFont.load_default()
        font_sub = font_title
        font_sig = font_title
        font_val = font_title
        font_time = font_title

    # Header
    draw.rectangle([(0, 0), (width, header_height)], fill=c_panel_bg)
    draw.text((25, 16), title, fill=c_text_title, font=font_title)
    draw.text((25, 45), f"ModelSim Verification | Timescale: {timescale} | Total Simulation Time: {total_time} ps", fill=c_text_sub, font=font_sub)

    # Panels
    draw.rectangle([(0, header_height), (label_col_width, total_height - footer_height)], fill=c_panel_bg)
    draw.rectangle([(label_col_width, header_height), (width, total_height - footer_height)], fill=c_wave_bg)

    # Timeline Grid
    time_bar_y = header_height - 18
    num_ticks = 10
    time_step = total_time / num_ticks

    for i in range(num_ticks + 1):
        t_val = int(i * time_step)
        x = wave_left + int(i * (wave_width / num_ticks))
        draw.line([(x, header_height), (x, total_height - footer_height)], fill=c_grid, width=1)
        draw.line([(x, header_height - 6), (x, header_height)], fill=c_border, width=1)
        
        if total_time >= 1000:
            time_str = f"{t_val/1000:g}ns"
        else:
            time_str = f"{t_val}ps"
        tx = max(wave_left, x - 12)
        draw.text((tx, time_bar_y - 2), time_str, fill=c_time_tick, font=font_time)

    # Signals
    for idx, s in enumerate(signals):
        y_top = header_height + idx * row_height
        y_bot = y_top + row_height
        y_mid = y_top + row_height // 2

        draw.line([(0, y_bot), (width, y_bot)], fill=c_border, width=1)

        name_str = s['name']
        is_bus = (s['size'] > 1)
        is_clock = ('clk' in s['base_name'].lower())

        accent = c_sig_clock if is_clock else (c_sig_bus_line if is_bus else c_sig_bit)
        draw.rectangle([(16, y_mid - 5), (22, y_mid + 5)], fill=accent)
        draw.text((32, y_mid - 7), name_str, fill=c_sig_name, font=font_sig)

        changes = s['changes']
        if not changes:
            draw.line([(wave_left, y_mid + 9), (wave_right, y_mid + 9)], fill=accent, width=2)
            continue

        extended = []
        if changes[0][0] > 0:
            extended.append((0, changes[0][1]))
        extended.extend(changes)
        extended.append((total_time, extended[-1][1]))

        def t_to_x(t):
            ratio = min(max(t / total_time, 0.0), 1.0)
            return wave_left + int(ratio * wave_width)

        if not is_bus:
            # 1-bit binary wave
            y_high = y_mid - 9
            y_low = y_mid + 9

            for i in range(len(extended) - 1):
                t1, v1 = extended[i]
                t2, _ = extended[i+1]
                x1 = t_to_x(t1)
                x2 = t_to_x(t2)

                y_curr = y_high if v1 == '1' else y_low
                draw.line([(x1, y_curr), (x2, y_curr)], fill=accent, width=2)

                if i < len(extended) - 2:
                    _, next_v = extended[i+1]
                    if next_v != v1:
                        y_next = y_high if next_v == '1' else y_low
                        draw.line([(x2, y_curr), (x2, y_next)], fill=accent, width=2)
        else:
            # Multi-bit bus wave
            y_top_bus = y_mid - 11
            y_bot_bus = y_mid + 11

            for i in range(len(extended) - 1):
                t1, v1 = extended[i]
                t2, _ = extended[i+1]
                x1 = t_to_x(t1)
                x2 = t_to_x(t2)
                seg_w = x2 - x1

                if seg_w <= 0:
                    continue

                bevel = min(6, max(1, seg_w // 4))

                poly = [
                    (x1 + bevel, y_top_bus),
                    (x2 - bevel, y_top_bus),
                    (x2, y_mid),
                    (x2 - bevel, y_bot_bus),
                    (x1 + bevel, y_bot_bus),
                    (x1, y_mid)
                ]
                draw.polygon(poly, fill=c_bus_fill, outline=c_sig_bus_line)

                # Format bus value: hex and dec
                try:
                    int_val = int(v1, 2)
                    hex_val = f"{int_val:X}h"
                except:
                    hex_val = v1

                val_box_w = len(hex_val) * 7
                if seg_w > val_box_w + 8:
                    cx = (x1 + x2) // 2
                    draw.text((cx - val_box_w // 2, y_mid - 6), hex_val, fill=c_bus_text, font=font_val)

    # Frame
    draw.rectangle([(0, 0), (width - 1, total_height - 1)], outline=c_border, width=2)
    draw.line([(label_col_width, 0), (label_col_width, total_height - footer_height)], fill=c_border, width=2)

    # Footer
    draw.rectangle([(0, total_height - footer_height), (width, total_height)], fill=c_panel_bg)
    draw.text((25, total_height - 23), "MaharaTech - Digital IC Design with Verilog | Verified RTL Simulation", fill=(120, 125, 135), font=font_sub)

    os.makedirs(os.path.dirname(out_png), exist_ok=True)
    img.save(out_png)
    print(f"Successfully generated: {out_png}")

if __name__ == '__main__':
    if len(sys.argv) >= 3:
        vcd_f = sys.argv[1]
        out_f = sys.argv[2]
        title_s = sys.argv[3] if len(sys.argv) > 3 else "Simulation Waveform"
        render_waveform(vcd_f, out_f, title_s)
    else:
        print("Usage: py render_vcd.py <vcd_file> <output_png> [title]")
