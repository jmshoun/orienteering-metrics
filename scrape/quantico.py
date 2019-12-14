import re
import datetime
import functools
import time

import requests
import bs4

from . import attack_point

ATTACK_POINT_REGEX = re.compile(r".*attackpoint\.org")


def pull_course_info(course_tag):
    course_info = [course_tag.contents[0].strip()]
    sibling = course_tag.next_sibling
    while sibling and sibling.name == "h4":
        sibling_info = sibling.contents[0].split(":")[1].strip()
        course_info += [sibling_info]
        sibling = sibling.next_sibling
    return course_info


def pull_course_results(table_tag):
    rows = table_tag.find_all("tr")
    return [pull_result_row(row) for row in rows]


def pull_result_row(row_tag):
    elements = row_tag.find_all("td")
    return ["".join(elem.contents).strip() for elem in elements]


def pull_event_page(page):
    soup = bs4.BeautifulSoup(page, "html.parser")

    courses = soup.find_all("h3")
    course_info = [pull_course_info(course) for course in courses]

    result_tags = soup.find_all("tbody")
    course_starts = [pull_course_results(result) for result in result_tags]
    flat_course_starts = [(info[0], *start_row) for info, start in zip(course_info, course_starts)
                          for start_row in start]

    link_urls = [str(link.get("href")) for link in soup.find_all("a")]
    attack_point_urls = list(filter(ATTACK_POINT_REGEX.match, link_urls))
    attack_point_url = attack_point_urls[0] if attack_point_urls else None

    return attack_point_url, course_info, flat_course_starts


@functools.lru_cache(64)
def get_year_event_urls(year):
    year_url = f"https://www.qocweb.org/results/{year}"
    response = requests.get(year_url)
    soup = bs4.BeautifulSoup(response.text, "html.parser")
    result_table = soup.find("tbody")
    event_links = result_table.find_all("a")
    return [str(link["href"]) for link in event_links]


def get_event_url(event_date):
    year_urls = get_year_event_urls(event_date.year)
    # Using a formatted string instead of strftime because we don't want leading
    # zeroes on months or days.
    formatted_date = f"/{event_date.year}/{event_date.month}/{event_date.day}/"
    date_pattern = re.compile(f".*{formatted_date}")
    event_urls = list(filter(date_pattern.match, year_urls))
    return "https://www.qocweb.org" + event_urls[0]


def pull_event_details(event_row):
    event_date = event_row[0]
    event_location = event_row[1]
    base_url = event_row[5]
    known_attack_point_url = event_row[6]
    clean_url = get_event_url(event_date) if base_url is None else base_url

    time.sleep(1)
    response = requests.get(clean_url)
    derived_attack_point_url, course_rows, start_rows = pull_event_page(response.text)
    full_course_rows = [(event_date, event_location, *row) for row in course_rows]
    full_start_rows = [(event_date, event_location, *row) for row in start_rows]

    attack_point_url = derived_attack_point_url if known_attack_point_url is None \
            else known_attack_point_url
    event_info = (*event_row[:5], clean_url, attack_point_url)
    leg_rows, split_rows = attack_point.pull_event_details(event_info)
    return (event_info, full_course_rows, full_start_rows, leg_rows, split_rows)
