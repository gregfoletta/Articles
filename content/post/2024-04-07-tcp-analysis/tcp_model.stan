data {
  int<lower = 0> n;
  array[n] int<lower = 0> cps;
}
parameters { 
    real<lower = 0> alpha, beta;
}
model {
    alpha ~ gamma(1,1);
    beta ~ exponential(1);
    cps ~ neg_binomial(alpha, beta);
}

