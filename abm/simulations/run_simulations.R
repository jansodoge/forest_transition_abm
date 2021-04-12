#Script to run simulations of the Netlogo model using nlrx package
# Salecker J, Sciaini M, Meyer KM, Wiegand K. The nlrx r package: A next-generation framework for
#reproducible NetLogo model analyses. Methods Ecol Evol. 2019;2041–210X. doi:10.1111/2041-210X.13286
library(nlrx)
library(unixtools)


#need to adapt path when replicating the simulations
unixtools::set.tempdir("/home/jan/NetLogo 6.2.0")
netlogopath <- file.path("/home/jan/NetLogo 6.2.0")
modelpath <- file.path("/home/jan/Dropbox/CSS/master_thesis/models/abm_household_individual_levels.nlogo")
outpath <- file.path('/home/jan/Dropbox/CSS/master_thesis/models')


nl <- nl(nlversion = "6.2.0",
         nlpath = netlogopath,
         modelpath = modelpath,
         jvmmem = 1024)

nl@experiment <- experiment(expname="test_forest_transition",
                            outpath=outpath,
                            repetition=1,
                            tickmetrics="true",
                            idsetup="setup",
                            idgo="go",
                            runtime=10,
                            evalticks=seq(1,10),
                            metrics=c("count turtles"),
                            variables = list(#variables yet not updated with current model design
                                             'probability_receiving_remittances' = list(min=0.1, max=0.1,  qfun="qunif"),
                                             'land_clearing_param' =  list(min=0.1, max=0.1, qfun="qunif")),
                            constants = list("inital_hh_translocal" = 100,
                                             "household_number" = 225,
                                             "scaling_param_migration" = 1.05,
                                             "probability_remittances_agriculture_invest" = 0.05,
                                             "time_frame" = "\"empirical_data\""
                                             ))

nl@simdesign <- simdesign_lhs(nl=nl,
                              samples=5,
                              nseeds=3,
                              precision=3)


eval_variables_constants(nl)
print(nl)

results <- run_nl_all(nl)



