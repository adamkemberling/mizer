context("Wrapper functions for trait and community models")

# Multiple gears work correctly in trait-based model ----
test_that("Multiple gears work correctly in trait-based model", {
    # Check multiple gears are working properly
    min_w_inf <- 10
    max_w_inf <- 1e5
    no_sp <- 10
    w_inf <- 10^seq(from = log10(min_w_inf), 
                    to = log10(max_w_inf), 
                    length = no_sp)
    knife_edges <- w_inf * 0.05
    params <- newTraitParams(no_sp = no_sp, 
                             min_w_inf = min_w_inf, 
                             max_w_inf = max_w_inf, 
                             knife_edge_size = knife_edges)
    expect_identical(params@species_params$knife_edge_size, 
                     knife_edges)
    # All gears fire
    sim1 <- project(params, t_max = 10, effort = 1)
    fmg <- getFMortGear(sim1)
    for (i in 1:no_sp) {
        expect_true(all(fmg[10,1,i,params@w < knife_edges[i]] == 0))
        expect_true(all(fmg[10,1,i,params@w >= knife_edges[i]] == 1))
    }
    # Only the 4th gear fires
    params <- newTraitParams(no_sp = no_sp, 
                             min_w_inf = min_w_inf, 
                             max_w_inf = max_w_inf, 
                             knife_edge_size = knife_edges, 
                             gear_names = 1:no_sp)
    effort <- c(0,0,0,1,0,0,0,0,0,0)
    names(effort) = 1:no_sp
    sim2 <- project(params, t_max = 10, effort = effort)
    fmg <- getFMortGear(sim2)
    expect_true(all(fmg[10, c(1:3,5:10),c(1:3,5:10),] == 0))
    expect_true(all(fmg[10, 4, 4, params@w < knife_edges[4]] == 0))
    expect_true(all(fmg[10, 4, 4, params@w >= knife_edges[4]] == 1))
    
})

# Scaling model is set up correctly ----
test_that("Scaling model is set up correctly", {
    p <- newTraitParams(perfect_scaling = TRUE, sigma = 1,
                        n = 2/3, q = 3/4)
    sim <- project(p, t_max = 5)
    
    # Check some dimensions
    no_sp <- length(p@species_params$species)
    expect_equal(no_sp, 11)
    
    # Check against analytic results
    sp <- 6  # check middle species
    gamma <- p@species_params$gamma[sp]
    sigma <- p@species_params$sigma[sp]
    beta <- p@species_params$beta[sp]
    alpha <- p@species_params$alpha[sp]
    h <- p@species_params$h[sp]
    ks <- p@species_params$ks[sp]
    mu0 <- (1 - p@f0) * sqrt(2 * pi) * p@kappa * gamma * sigma *
        (beta ^ (p@n - 1)) * exp(sigma ^ 2 * (p@n - 1) ^ 2 / 2)
    hbar <- alpha * h * p@f0 - ks
    # Check encounter rate
    lm2 <- p@lambda - 2
    e <- getEncounter(p, p@initial_n, p@initial_n_pp)[sp, ] * p@w^(lm2 - p@q)
    ae <- gamma * p@kappa * exp(lm2^2 * sigma^2 / 2) *
        beta^lm2 * sqrt(2 * pi) * sigma * 
        # The following factor takes into account the cutoff in the integral
        (pnorm(3 - lm2 * sigma) + pnorm(log(beta)/sigma + lm2 * sigma) - 1)
    # TODO: not precise enough yet
    expect_equivalent(e, rep(ae, length(e)), tolerance = 1e-1)
    # Check feeding level
    f <- getFeedingLevel(p, p@initial_n, p@initial_n_pp)[sp, ]
    names(f) <- NULL
    expect_equal(f, rep(f[1], length(f)), tolerance = 1e-14)
    # Death rate
    mu <- getMort(p, p@initial_n, p@initial_n_pp, effort = 0)[sp, ]
    mumu <- mu  # To set the right names
    mumu[] <- mu0 * p@w^(p@n - 1)
    expect_equal(mu, mumu, tolerance = 0.2)
    # Growth rate
    g <- getEGrowth(p, p@initial_n, p@initial_n_pp)[sp, ]
    gg <- g  # To set the right names
    gg[] <- hbar * p@w^p@n * (1 - p@psi[sp, ])
    # TODO: not precise enough yet
    # expect_equal(g, gg, tolerance = 1e-4)
    
    # Check that community is perfect power law
    expect_identical(p@sc, colSums(p@initial_n))
    total <- p@initial_n_pp
    fish_idx <- (length(p@w_full) - length(p@w) + 1):length(p@w_full)
    total[fish_idx] <- total[fish_idx] + p@sc
    total <- total * p@w_full^p@lambda
    expected <- rep(p@kappa, length(p@w_full))
    expect_equivalent(total, expected, tolerance = 1e-15, check.names = FALSE)
    
    # All erepros should be equal
    expect_equal(p@species_params$erepro, rep(p@species_params$erepro[1], no_sp))
    
    # Check that total biomass changes little (relatively)
    bm <- getBiomass(sim)
    expect_lt(max(abs(bm[1, ] - bm[6, ])), 4*10^(-5))
})

# removeSpecies ----
test_that("removeSpecies works", {
    data("NS_species_params")
    remove <- NS_species_params$species[2:11]
    reduced <- NS_species_params[!(NS_species_params$species %in% remove), ]
    params <- MizerParams(NS_species_params, no_w = 20, 
                          max_w = 39900, min_w_pp = 9e-14)
    p1 <- removeSpecies(params, species = remove)
    expect_equal(nrow(p1@species_params), nrow(params@species_params) - 10)
    p2 <- MizerParams(reduced, no_w = 20, 
                      max_w = 39900, min_w_pp = 9e-14)
    expect_equivalent(p1, p2)
    sim1 <- project(p1, t_max = 0.4, t_save = 0.4)
    sim2 <- project(p2, t_max = 0.4, t_save = 0.4)
    expect_identical(sim1@n[2, 2, ], sim2@n[2, 2, ])
})

# retuneBackground() reproduces scaling model ----
test_that("retuneBackground() reproduces scaling model", {
    # This numeric test failed on Solaris and without long doubles. So for now
    # skipping it on CRAN
    skip_on_cran()
    p <- newTraitParams(n = 2/3, q = 3/4)
    initial_n <- p@initial_n
    # We multiply one of the species by a factor of 5 and expect
    # retuneBackground() to tune it back down to the original value.
    p@initial_n[5, ] <- 5 * p@initial_n[5, ]
    pr <- p %>% 
        markBackground() %>% 
        retuneBackground()
    expect_lt(max(abs(initial_n - pr@initial_n)), 2e-11)
})

# pruneSpecies() removes low-abundance species ----
test_that("pruneSpecies() removes low-abundance species", {
    params <- newTraitParams()
    p <- params
    # We multiply one of the species by a factor of 10^-3 and expect
    # pruneSpecies() to remove it.
    p@initial_n[5, ] <- p@initial_n[5, ] * 10^-4
    p <- pruneSpecies(p, 10^-2)
    expect_is(p, "MizerParams")
    expect_equal(nrow(params@species_params) - 1, nrow(p@species_params))
    expect_equal(p@initial_n[5, ], params@initial_n[6, ])
})

# addSpecies ----
test_that("addSpecies works when adding a second identical species", {
    p <- newTraitParams()
    no_sp <- length(p@A)
    p <- markBackground(p)
    species_params <- p@species_params[5,]
    species_params$species = "new"
    # Adding species 5 again should lead two copies of the species with the
    # same combined abundance
    pa <- addSpecies(p, species_params)
    # TODO: think about what to check now
})
test_that("addSpecies does not allow duplicate species", {
    p <- NS_params
    species_params <- p@species_params[5, ]
    expect_error(addSpecies(p, species_params),
                 "You can not add species that are already there.")
})

# retuneReproductiveEfficiency ----
test_that("retuneReproductiveEfficiency works", {
    p <- newTraitParams(rfac = Inf)
    no_sp <- nrow(p@species_params)
    erepro <- p@species_params$erepro
    p@species_params$erepro[5] <- 15
    ps <- retuneReproductionEfficiency(p)
    expect_equal(ps@species_params$erepro, erepro)
    # can also select species in various ways
    ps <- retuneReproductionEfficiency(p, species = p@species_params$species[5])
    expect_equal(ps@species_params$erepro, erepro)
    p@species_params$erepro[3] <- 15
    species <- (1:no_sp) %in% c(3,5)
    ps <- retuneReproductionEfficiency(p, species = species)
    expect_equal(ps@species_params$erepro, erepro)
})

# renameSpecies ----
test_that("renameSpecies works", {
    sp <- NS_species_params
    p <- newMultispeciesParams(sp)
    sp$species <- tolower(sp$species)
    replace <- NS_species_params$species
    names(replace) <- sp$species
    p2 <- newMultispeciesParams(sp)
    p2 <- renameSpecies(p2, replace)
    expect_identical(p, p2)
})
test_that("renameSpecies warns on wrong names", {
    expect_error(renameSpecies(NS_params, c(Kod = "cod", Hadok = "haddock")),
                 "Kod, Hadok do not exist")
})

# rescaleAbundance ----
test_that("rescaleAbundance works", {
    p <- retuneReproductionEfficiency(NS_params)
    factor <- c(Cod = 2, Haddock = 3)
    p2 <- rescaleAbundance(NS_params, factor)
    expect_identical(p@initial_n["Cod"] * 2, p2@initial_n["Cod"])
    expect_equal(p, rescaleAbundance(p2, 1/factor))
})
test_that("rescaleAbundance throws correct error",{
    expect_error(rescaleAbundance(NS_params, c(2, 3)))
    expect_error(rescaleAbundance(NS_params, "a"))
})
test_that("rescaleAbundance warns on wrong names", {
    expect_error(rescaleAbundance(NS_params, c(Kod = 2, Hadok = 3)),
                 "Kod, Hadok do not exist")
})

# rescaleSystem ----
test_that("rescaleSystem does not change dynamics.", {
    factor <- 10
    sim <- project(NS_params, t_max = 1)
    params2 <- rescaleSystem(NS_params, factor)
    sim2 <- project(params2, t_max = 1)
    expect_equal(sim2@n[1, , ], sim@n[1, , ] * factor)
    expect_equal(sim2@n[2, , ], sim@n[2, , ] * factor)
})

# steady ----
test_that("steady works", {
    expect_message(params <- newTraitParams(no_sp = 4, no_w = 30, rfac = Inf,
                                            n = 2/3, q = 3/4),
                   "Increased no_w to 36")
    params@species_params$gamma[2] <- 2000
    params <- setSearchVolume(params)
    p <- steady(params, t_per = 2)
    expect_known_value(getRDI(p), "values/steady")
    # and works the same when returning sim
    sim <- steady(params, t_per = 2, return_sim = TRUE)
    expect_is(sim, "MizerSim")
    expect_known_value(getRDI(sim@params), "values/steady")
})

# newSheldonParams ----
test_that("newSheldonParams works", {
    params <- newSheldonParams()
    no_w <- length(params@w)
    expect_equal(dim(params@initial_n), c(1, no_w))
    expect_equal(params@w[1], params@species_params$w_min)
    expect_equal(params@w[no_w], params@species_params$w_inf)
    sim <- project(params, t_max = 1)
    expect_equal(sim@n[1, 1, ], sim@n[2, 1, ])
})