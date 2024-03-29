event.df <- read_csv("../data/events.csv",
                     col_names = c("event_date", "venue", "event_type",
                                   "course_setter", "quantico_url", "attack_point_url"))

classic.event.df <- event.df %>%
    filter(event_type == "Classic") %>%
    select(event_date, venue, course_setter)
