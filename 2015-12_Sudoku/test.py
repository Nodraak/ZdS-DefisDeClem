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

SOLVER_ASM = True  # set to false to use C solver
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

GRID2 = [
    '127943568',
    '369218745',
    '.........',
    '..64..8..',
    '.....7..9',
    '..485.3..',
    '...12....',
    '2.......4',
    '.53......',
]

if SOLVER_ASM:
    AOUT = './a.s.out'
else:
    AOUT = './a.c.out'

print('CMD:')
print(' '.join(GRID))
print(' '.join(GRID2))
print('')
#exit(0)


def make_cmd(grid):
    if SOLVER_ASM:
        return [AOUT] + grid
    else:
        return [AOUT] + [''.join(grid)]


def replace_char(s, char, index):
    return s[:index] + char + s[index+1:]


def parse_output(out):
    if SOLVER_ASM:
        return out.split('\n')[-2].strip()
    else:
        return out.split('\n')[-2].strip()[3]


def result(e, a):
    if e == a:
        return 'success'
    else:
        return 'FAILED ("%s" != "%s")' % (e, a)


def test(expected, changes=None, verbose=False, grid=None):
    if changes == None:
        changes = []
    grid = copy.copy(grid if grid != None else GRID)

    for y, x, val in changes:
        grid[y] = replace_char(grid[y], val, x)

    try:
        raw_out = subprocess.check_output(make_cmd(grid))
    except subprocess.CalledProcessError as e:
        print(e.output)
        exit(1)

    if verbose:
        print('===== Grid =====')
        print('\n'.join(grid))
        print('===== Prog out =====')
        print(raw_out)
        print('====>', end=' ')

    out = parse_output(raw_out)
    print('%s %s %s' % (expected, out, result(expected, out)))


print('Expected Actual Conclusion')
test(VALID)
test(VALID, [(0, 0, '.')])
test(NONVALID, [(0, 0, '2')])
test(NONVALID, [(1, 1, '4')])
test(NONVALID, [(2, 2, '2')])
test(NONVALID, grid=GRID2)
