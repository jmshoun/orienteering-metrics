data {
    int<lower=1> N1;
    int<lower=1> N2;
    real obs_latitude[N1];
    real obs_longitude[N1];
    int<lower=0> y[N1];
    real pred_latitude[N2];
    real pred_longitude[N2];
}

transformed data {
    real delta = 1e-9;
    int N = N1 + N2;
    real latitude[N];
    real longitude[N];

    for (n in 1:N1) {
        latitude[n] = obs_latitude[n];
        longitude[n] = obs_longitude[n];
    }
    for (n in 1:N2) {
        latitude[N1 + n] = pred_latitude[n];
        longitude[N1 + n] = pred_longitude[n];
    }
}

parameters {
    real<lower=0> rho;
    real<lower=0> alpha;
    real<lower=0> sigma;
    real bias;
    vector[N] mu;
}

transformed parameters {
    vector[N] y_hat;

    {
        matrix[N, N] K;
        matrix[N, N] L_K;

        for (i in 1:N) {
                for (j in i:N) {
                    K[i, j] = square(alpha) * exp(-0.5 / square(rho)
                                                  * (square(latitude[i] - latitude[j])
                                                     + square(longitude[i] - longitude[j])));
                    K[j, i] = K[i, j];
            }
        }

        //  Add unit diagonal
        for (i in 1:N) {
            K[i, i] += delta;
        }

        L_K = cholesky_decompose(K);
        y_hat = bias + L_K * mu;
    }
}

model {
    rho ~ inv_gamma(5, 5);
    alpha ~ normal(0, 1);
    sigma ~ normal(0, 1);
    mu ~ normal(0, 1);

    y ~ poisson(exp(y_hat[1:N1]));
}

generated quantities {
    vector[N2] y_pred;
    for (n in 1:N2) {
        y_pred[n] = poisson_rng(exp(y_hat[N1 + n]));
    }
}
