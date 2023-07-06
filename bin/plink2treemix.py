#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jul  6 14:42:21 2023

@author: Paolo Cozzi <paolo.cozzi@ibba.cnr.it>

Inspired by the script developed by Pickrell and Pritchard (the treemix
developers)
"""

import csv
import sys
import gzip

from collections import namedtuple, defaultdict


def read_plink_freq(infile):
    """Read frequencies from plink freq file"""

    pop2rs = defaultdict(defaultdict)
    rss = list()
    rss2 = set()

    with gzip.open(infile, "rt") as handle:
        # get header from file
        # ['CHR', 'SNP', 'CLST', 'A1', 'A2', 'MAF', 'MAC', 'NCHROBS']
        header = handle.readline().strip().split()
        Record = namedtuple('Record', header)

        for line in handle:
            line = line.strip().split()
            record = Record._make(line)

            rs = record.SNP
            pop = record.CLST
            mc = record.MAC
            total = record.NCHROBS

            if rs not in rss2:
                rss.append(rs)
                rss2.add(rs)

            # track MAC in memory
            pop2rs[pop][rs] = (int(mc), int(total))

    return pop2rs, rss


def write_treemix_input(outfile, pop2rs, rss):
    with gzip.open(outfile, "wt") as handle:
        writer = csv.writer(handle, delimiter=" ", lineterminator="\n")
        pops = list(pop2rs.keys())

        # treemix input header
        writer.writerow(pops)

        for rs in rss:
            line = []

            for pop in pops:
                mc, total = pop2rs[pop][rs]
                # this is the Major allele count
                Mc = total - mc
                line.append(f"{Mc},{mc}")

            # track counts for all pops for the same SNP
            writer.writerow(line)


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("plink2treemix.py [gzipped input file] [gzipped output file]")
        print("ERROR: improper command line")
        exit(1)

    pop2rs, rss = read_plink_freq(sys.argv[1])
    write_treemix_input(sys.argv[2], pop2rs, rss)
