data {
    int<lower=0> n;
    vector[n] odometer_Mm;
    vector[n] price;
}
parameters {
    real a;
    real b;
    real<lower=0> sigma;
}
model {
    log(price) ~ normal(a + b * odometer_Mm, sigma);
}    
generated quantities {
    array[n] real y_s = normal_rng(a + b * odometer_Mm, sigma);
    
    real price_pred = exp( normal_rng(a + b * 60, sigma) );
}
