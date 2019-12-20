raw.course.df <- read_csv("../data/courses.csv",
                       col_names = c("event_date", "venue", "course", "length",
                                     "climb", "control_points"))

# The initial data pull is pretty dumb, by design. There are a fair number of formatting
# irregularities in the data, and it's easier/cleaner to handle them after the fact than
# try to catch every special case when scraping the data.

# On the course files, this means that every column after "course" doesn't necessarily
# correspond to its designated semantic meaning. For example, a race without climb data
# might show up as length = "4.5 km", climb = "13", control_points = NA -- i.e, the
# available fields are put into the available slots in order, without regard to semantics.
# This also means that length == NA implies climb == NA, and climb == NA implies
# control_points == NA.

# Courses with length == NA or climb == NA are generally bumbles, tumbles, and other
# nontraditional formats.
# If control_points is NA, then it usually means that climb is missing. There are a couple
# of exceptions, though.
course.df <- raw.course.df %>%
    filter(!is.na(climb),
           !grepl("Bike", course)) %>%
    # Move control points and climbs to correct columns
    mutate(missing_climb = is.na(control_points) & !grepl("m", climb),
           control_points = ifelse(missing_climb, as.numeric(as.character(climb)), control_points),
           climb = ifelse(missing_climb, NA, climb)) %>%
    # Convert columns to numeric
    mutate(length_km = as.numeric(str_split_fixed(length, " ", 2)[, 1]),
           climb = as.numeric(str_split_fixed(climb, " ", 2)[, 1])) %>%
    # Course type cleanup
    mutate(course_clean = gsub(" Classic", "", course)) %>%
    select(event_date, venue, course, course_clean, length_km, climb, control_points)


CLASSIC.COURSES <- c("White", "Yellow", "Orange", "Brown", "Green", "Red", "Blue")
classic.course.df <- classic.event.df %>%
    inner_join(course.df, by=c("event_date", "venue")) %>%
    filter(!is.na(climb),
           course_clean %in% CLASSIC.COURSES) %>%
    mutate(course_clean = factor(course_clean, CLASSIC.COURSES))
