data {
    int<lower=0> n;
    vector[n] odometer;
    vector[n] price;
}
parameters {
    real a;
    real b;
    real<lower=0> sigma;
}
model {
    log(price) ~ normal(a + b * odometer, sigma);
}
