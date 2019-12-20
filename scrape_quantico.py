"""
Script to scrape detailed event outcomes for QOC-sponsored events.
The input file data/quantico_events.csv controls the list of events for which results are scraped.
The output is five separate CSV files listed at the bottom of the script.
"""

import csv
import datetime
import sys

from scrape import quantico


def append_csv(filename, rows):
    with open(filename, "r", newline="") as infile:
        reader = csv.reader(infile)
        old_rows = [row for row in reader]
    with open(filename, "w", newline="") as outfile:
        writer = csv.writer(outfile)
        for row in old_rows + rows:
            writer.writerow(row)


def write_csv(filename, rows):
    with open(filename, "w", newline="") as outfile:
        writer = csv.writer(outfile)
        for row in rows:
            writer.writerow(row)


row_ids = [int(arg) for arg in sys.argv[1:]]

with open("data/quantico_events.csv", newline="") as infile:
    reader = csv.reader(infile)
    next(reader)
    rows = [(datetime.datetime.strptime(row[0], "%Y-%m-%d").date(), row[1], row[2],
             row[3], None if row[4] == "" else row[4], None if row[5] == "" else row[5])
            for row in reader]

# Filter to specific rows if specified
if row_ids:
    rows = [row for id, row in enumerate(rows) if id in row_ids]

event_rows, course_rows, start_rows, leg_rows, split_rows = [], [], [], [], []
for row in rows:
    print(row)
    try:
        ev, co, st, le, sp = quantico.pull_event_details(row)
    except Exception as e:
        print(e)
        ev, co, st, le, sp = [], [], [], [], []
    event_rows += [ev]
    course_rows += co
    start_rows += st
    leg_rows += le
    split_rows += sp

if row_ids:
    save_fn = append_csv
else:
    save_fn = write_csv

save_fn("data/events.csv", event_rows)
save_fn("data/courses.csv", course_rows)
save_fn("data/starts.csv", start_rows)
save_fn("data/legs.csv", leg_rows)
save_fn("data/splits.csv", split_rows)
