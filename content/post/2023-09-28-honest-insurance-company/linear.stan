data {
    int<lower=0> n;
    vector[n] odometer;
    vector[n] price;
}
parameters {
    real alpha;
    real beta;
    real<lower=0> sigma;
}
model {
    log(price) ~ normal(alpha + beta * odometer, sigma);
}
