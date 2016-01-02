#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
"412.3.....7.5.............43.4.98....59....2....2..9...6.78...384......1..7......"
"4...3.......6..8..........1....5..9..8....6...7.2........1.27..5.3....4.9........"
"1234567894567891237891.345623456789156789123489123456734.678912678912345912345678"
"""

from __future__ import print_function
import copy
import subprocess

AOUT = './a.out'
VALID = '1'
NONVALID = '0'
GRID = [
    '123456789',
    '456789123',
    '7891.3456',
    '234567891',
    '567891234',
    '891234567',
    '34.678912',
    '678912345',
    '912345678',
]

#print(' '.join(GRID))


def make_cmd(grid):
    return [AOUT] + grid


def replace_char(s, char, index):
    return s[:index] + char + s[index+1:]


def parse_output(out):
    return out.split('\n')[-2].strip()


def result(e, a):
    if e == a:
        return 'success'
    else:
        return 'FAILED'


def test(expected, changes=None, verbose=False):
    if changes == None:
        changes = []

    grid = copy.copy(GRID)
    for y, x, val in changes:
        grid[y] = replace_char(grid[y], val, x)

    raw_out = subprocess.check_output(make_cmd(grid))

    if verbose:
        print('==> Grid:')
        print('\n'.join(grid))
        print('==> Prog out:')
        print(raw_out)
        print('==>', end=' ')

    out = parse_output(raw_out)
    print('%s %s %s' % (expected, out, result(expected, out)))


print('Expected Actual Conclusion')
test(VALID)
test(NONVALID, [(0, 0, '2')])
test(NONVALID, [(1, 1, '4')])
test(NONVALID, [(2, 2, '2')])

