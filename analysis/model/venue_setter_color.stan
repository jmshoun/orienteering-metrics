data {
    int<lower=1> N;
    int<lower=1> nColors;
    int<lower=1> nVenues;
    int<lower=1> nSetters;

    real metric[N];
    int<lower=1, upper=nColors> color_id[N];
    int<lower=1, upper=nVenues> venue_id[N];
    int<lower=1, upper=nSetters> setter_id[N];
}

parameters {
    real mu;

    real color_norm[nColors];
    real venue_norm[nVenues];
    real setter_norm[nSetters];

    real<lower=0> color_sigma;
    real<lower=0> venue_sigma;
    real<lower=0> setter_sigma;
    real<lower=0> color_pred_sigma[nColors];
}

transformed parameters {
    real color_effect[nColors];
    real venue_effect[nVenues];
    real setter_effect[nSetters];

    for (n in 1:nColors) {
        color_effect[n] = color_sigma * color_norm[n];
    }

    for (n in 1:nVenues) {
        venue_effect[n] = venue_sigma * venue_norm[n];
    }

    for (n in 1:nSetters) {
        setter_effect[n] = setter_sigma * setter_norm[n];
    }
}

model {
    real pred_metric[N];
    real pred_sigma[N];

    color_norm ~ student_t(8, 0, 1);
    venue_norm ~ student_t(4, 0, 1);
    setter_norm ~ student_t(4, 0, 1);

    color_sigma ~ cauchy(0, 1);
    venue_sigma ~ cauchy(0, 0.1);
    setter_sigma ~ cauchy(0, 0.1);
    color_pred_sigma ~ cauchy(0, 0.3);

    for (n in 1:N) {
        pred_metric[n] = mu + color_effect[color_id[n]] + venue_effect[venue_id[n]]
                + setter_effect[setter_id[n]];
        pred_sigma[n] = color_pred_sigma[color_id[n]];
    }

    metric ~ normal(pred_metric, pred_sigma);
}
