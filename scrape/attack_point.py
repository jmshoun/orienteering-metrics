import time

import bs4
import requests


def pull_split_page_links(event_url):
    response = requests.get(event_url)
    page_soup = bs4.BeautifulSoup(response.text, "html.parser")
    split_list = page_soup.find("ul", class_="eventsplits")
    return [(str(link.text), "http://www.attackpoint.org" + str(link["href"]))
            for link in split_list.find_all("a")]


def pull_legs(table):
    top_row = table.find("tr")
    header_text = [str(header.text) for header in top_row.find_all("th")]
    leg_distance = [dist.split(".")[1] for dist in header_text[7:-2]]
    final_distance = header_text[-2][6:]
    return leg_distance + [final_distance]


def pull_runner_splits(row):
    entries = [str(entry.text) for entry in row.find_all("td")]
    leg_times = [entry.split(" ")[0] for entry in entries[7:-1]]
    return leg_times


def pull_all_splits(table):
    return [pull_runner_splits(row) for row in table.find_all("tr")[1:-1]]


def pull_leg_rows(event_info, course_name, page_soup):
    event_date, venue, *_ = event_info
    split_table = page_soup.find("table", class_="splittable")
    legs = pull_legs(split_table)
    return [(event_date, venue, course_name, leg_number + 1, distance)
            for leg_number, distance in enumerate(legs)]


def pull_split_rows(event_info, course_name, page_soup):
    event_date, venue, *_ = event_info
    split_table = page_soup.find("table", class_="splittable")
    return [(event_date, venue, course_name, finish_order + 1, leg_number + 1, time)
            for finish_order, splits in enumerate(pull_all_splits(split_table))
            for leg_number, time in enumerate(splits)]


def pull_event_details(event_info):
    event_url = event_info[-1]
    if event_url is None:
        return [], []
    leg_rows = []
    split_rows = []

    for course_name, url in pull_split_page_links(event_url):
        time.sleep(0.5)
        response = requests.get(url)
        page_soup = bs4.BeautifulSoup(response.text, "html.parser")
        leg_rows += pull_leg_rows(event_info, course_name, page_soup)
        split_rows += pull_split_rows(event_info, course_name, page_soup)

    return leg_rows, split_rows
