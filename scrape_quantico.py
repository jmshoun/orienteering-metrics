"""
Script to scrape detailed event outcomes for QOC-sponsored events.
The input file data/quantico_events.csv controls the list of events for which results are scraped.
The output is five separate CSV files listed at the bottom of the script.
"""


import csv
import datetime

from scrape import quantico


def dump_csv(filename, rows):
    with open(filename, "w", newline="") as outfile:
        writer = csv.writer(outfile)
        for row in rows:
            writer.writerow(row)


with open("data/quantico_events.csv", newline="") as infile:
    reader = csv.reader(infile)
    next(reader)
    rows = [(datetime.datetime.strptime(row[0], "%Y-%m-%d").date(), row[1], row[2],
             row[3], row[4], None if row[5] == "" else row[5], None if row[6] == "" else row[6])
            for row in reader]

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

dump_csv("data/events.csv", event_rows)
dump_csv("data/courses.csv", course_rows)
dump_csv("data/starts.csv", start_rows)
dump_csv("data/legs.csv", leg_rows)
dump_csv("data/splits.csv", split_rows)
