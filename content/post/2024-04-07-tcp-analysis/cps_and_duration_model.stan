data {
  //int<lower = 0> n_cps;
  //int<lower = 0> n_duration;
  //array[n_cps] int cps;
  //vector[n_duration] duration;
  
  int<lower = 0> n_cps, n_duration;
  array[n_cps] int cps;
  vector[n_duration] duration;
}
parameters { 
    //cps neg_binomial() parameters
    real<lower = 0> nb_alpha;
    real<lower = 0> nb_beta;
    
    //duration gamma() parameteres 
    real<lower = 0> g_alpha;
    real<lower = 0> g_beta;
}
model {
    // negative binomial priors
    nb_alpha ~ exponential(.5);
    nb_beta ~ exponential(.5);
    
    //gamma priors
    g_alpha ~ exponential(.5);
    g_beta ~ exponential(.5);
    
    //model
    cps ~ neg_binomial(nb_alpha, nb_beta);
    duration ~ gamma(g_alpha, g_beta);
}

generated quantities {
    array[1000] int cps_sim;
    array[1000] real duration_sim;
    
    for (n in 1:1000) {
        cps_sim[n] = neg_binomial_rng(nb_alpha, nb_beta);
        duration_sim[n] = gamma_rng(g_alpha, g_beta);
    }
}

