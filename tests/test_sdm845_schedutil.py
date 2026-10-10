#!/usr/bin/env python3
"""Host-side guard tests for OnePlus6/SDM845 governor policy update.

This checks the actual post_boot shell policy, including supported and legacy sysfs
paths. It never writes to real /sys or modifies device state.
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path


def main():
    if len(sys.argv) != 2:
        sys.exit('Usage: test_sdm845_schedutil.py init.qcom.post_boot.sh')
    full = Path(sys.argv[1]).read_text()
    anchor = 'case "$target" in\n    "sdm845")'
    start = full.find(anchor)
    if start < 0:
        sys.exit('Missing SDM845 vendor post-boot case')
    end = full.find('case "$target" in', start + len(anchor))
    block = full[start:end] if end >= 0 else full[start:]
    for cpu in ('cpu0', 'cpu4'):
        prefix = f'/sys/devices/system/cpu/{cpu}/cpufreq/schedutil'
        escaped = re.escape(prefix)
        pattern = (r'if \[ -w '+escaped+r'/up_rate_limit_us \] && \[ -w '+escaped+r'/down_rate_limit_us \]; then\s*'
                   r'echo 500 > '+escaped+r'/up_rate_limit_us\s*'
                   r'echo 20000 > '+escaped+r'/down_rate_limit_us\s*'
                   r'elif \[ -w '+escaped+r'/rate_limit_us \]; then\s*'
                   r'echo 500 > '+escaped+r'/rate_limit_us\s*fi')
        matches = re.findall(pattern, block)
        assert len(matches) == 1, f'{cpu}: expected one guarded policy, found {len(matches)}'
        cmd = re.search(pattern, block)[0]
        with tempfile.TemporaryDirectory() as root:
            temp = Path(root)
            for variant in ('modern', 'legacy', 'absent'):
                for file in temp.iterdir():
                    file.unlink()
                if variant == 'modern':
                    for k in ['up_rate_limit_us', 'down_rate_limit_us']:
                        (temp/k).write_text('0\n')
                elif variant == 'legacy':
                    (temp/'rate_limit_us').write_text('0\n')
                fake = cmd.replace(prefix, str(temp))
                run = subprocess.run(['sh','-c',fake],capture_output=True,text=True)
                assert run.returncode == 0, (cpu,variant,run.stderr)
                if variant == 'modern':
                    assert (temp/'up_rate_limit_us').read_text().strip() == '500'
                    assert (temp/'down_rate_limit_us').read_text().strip() == '20000'
                if variant == 'legacy':
                    assert (temp/'rate_limit_us').read_text().strip() == '500'
                if variant == 'absent':
                    assert not list(temp.iterdir()), 'Should not create an unsupported tunable'
    assert block.count('echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/rate_limit_us') == 0
    assert block.count('echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/rate_limit_us') == 0
    print('PASS: target SDM845 only, policy0/4 modern+legacy+missing sysfs guards; read-only simulated nodes.')
    print('BOUNDARY: host simulation only; no ROM boot or performance measurements.')


if __name__ == '__main__':
    main()