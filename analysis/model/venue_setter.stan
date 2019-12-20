data {
    int<lower=1> N;
    int<lower=1> nVenues;
    int<lower=1> nSetters;

    real metric[N];
    int<lower=1, upper=nVenues> venue_id[N];
    int<lower=1, upper=nSetters> setter_id[N];
}

parameters {
    real mu;

    real venue_norm[nVenues];
    real setter_norm[nSetters];

    real<lower=0> venue_sigma;
    real<lower=0> setter_sigma;
    real<lower=0> pred_sigma;
}

transformed parameters {
    real venue_effect[nVenues];
    real setter_effect[nSetters];

    for (n in 1:nVenues) {
        venue_effect[n] = venue_sigma * venue_norm[n];
    }

    for (n in 1:nSetters) {
        setter_effect[n] = setter_sigma * setter_norm[n];
    }
}

model {
    real pred_metric[N];

    venue_norm ~ student_t(4, 0, 1);
    setter_norm ~ student_t(4, 0, 1);

    venue_sigma ~ cauchy(0, 0.1);
    setter_sigma ~ cauchy(0, 0.1);
    pred_sigma ~ cauchy(0, 0.3);

    for (n in 1:N) {
        pred_metric[n] = mu + venue_effect[venue_id[n]] + setter_effect[setter_id[n]];
    }

    metric ~ normal(pred_metric, pred_sigma);
}
