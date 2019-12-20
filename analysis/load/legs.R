leg.df <- read_csv("../data/legs.csv",
                   col_names=c("event_date", "venue", "course", "leg", "length")) %>%
    group_by(event_date, venue, course) %>%
    # Filter out all courses for which we don't have reliable distance measurements for one or
    # more legs. For some legs, distance is missing; for other legs, a time is given
    # instead of a distance.
    mutate(any_bad = any(is.na(length) | !grepl("m", length))) %>%
    ungroup() %>%
    filter(!any_bad) %>%
    select(-any_bad) %>%
    mutate(length = as.numeric(gsub("m", "", length))) %>%
    # The course names in the leg data.frame are guaranteed to map back to names
    # on the QOC site 100% of the time. Clean up a few inconsistencies...
    mutate(course = recode(course, BLUE="Blue", BROWN="Brown", `Classic - Green`="Green",
                           `Classic - Orange`="Orange", `Classic - White`="White",
                           `Classic - Yellow`="Yellow", GREEN="Green", ORANGE="Orange",
                           RED="Red", `Sunday - Blue`="Blue", `Sunday - Brown`="Brown",
                           `Sunday - Green`="Green", `Sunday - Orange`="Orange",
                           `Sunday - Red`="Red", `Sunday - White`="White",
                           `Sunday - Yellow`="Yellow", WHITE="White", YELLOW="Yellow"))

leg.summary.df <- leg.df %>%
    group_by(event_date, venue, course) %>%
    # Ensure that the number of legs is the same as the maximum enumerated leg ID.
    summarize(num_legs = n(),
              num_legs_alt = max(leg),
              length = sum(length)) %>%
    filter(num_legs == num_legs_alt) %>%
    select(-num_legs_alt)

classic.leg.summary.df <- classic.course.df %>%
    inner_join(leg.summary.df, by=c("event_date", "venue", "course")) %>%
    mutate(control_points = ifelse(is.na(control_points), num_legs - 1, control_points)) %>%
    # There are a few courses for which leg info is shifted and corrupted; there are also
    # a few courses for which the sum of the leg lengths is radically different from the quoted
    # rough course distance in the course description. We filter out both of these cases.
    filter(control_points + 1 - num_legs != 3,
           abs(log(length / (1000 * length_km))) < 0.2)

classic.leg.df <- classic.leg.summary.df %>%
    select(event_date, venue, course_setter,
           course, course_clean, total_length=length, climb, num_legs) %>%
    inner_join(leg.df, by=c("event_date", "venue", "course"))
