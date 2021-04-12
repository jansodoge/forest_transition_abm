extensions [nw csv]

globals [
  t_0_land_amount
  empirical_agriculture_pattern
  current_explanandum_agriculture_cover
  global_abandoned_land
  global_deforested_land
  global_household_index
  gini-index-reserve
  gini-index-reserve-relative
  lorenz-points
  intercept_coeff
  log_age_coeff
  land_coeff
  network_coeff
  children_coeff
  global_simulation_run_id
]


;define patch specific variables
patches-own [
  landscape_type ; biomass variable for each patch
  forest_cover; stores information for empirical precipitation variation data
  household_ID ; territory of a patch
  agricultural_productivity
            ]


breed [households household]
; define variables of households
households-own [
  agriculture_land
  migrated_hh_members
  migrated_hh_members_t_prior
  received_remittances
  land_abandoned
  remittances_investment_probability
  hh_members
  workers
  workers_to
  commun
  hhnum
  surveyyr
  add_workers
  member_migrated_already_in_t
  relative_utility ;for inequality re-distribution procedure
  household_first_gen_children
  ]

breed [individuals individual]
individuals-own [
  member_relhead
  member_commun
  member_hhnum
  member_surveyyr
  member_age
  member_sex
  individual_utlitity_land
  member_migrated
  married
]




to setup
  clear-all

  setup_agent_on_grid
  parametrize_agents
  migration_model_parameters
  set global_abandoned_land 0
  set global_household_index 1000
  update-lorenz-and-gini
  update-lorenz-and-gini_relative_utility
  print gini-index-reserve-relative



 if change_inequality = "on" [
update_land_inequality_levels
  ]

  set global_simulation_run_id random 10000


  reset-ticks
end




;Create agriculture clusters
 to setup_agent_on_grid
  clear-all
  ;lines below somewhere from the internet
   let horizontal-spacing (world-width / sqrt(225))
   let vertical-spacing (world-height / sqrt(225))
   let min-xpos (min-pxcor - 0.5 + horizontal-spacing / 2)
   let min-ypos (min-pycor - 0.5 + vertical-spacing / 2)
  nw:generate-lattice-2d households links sqrt(225) sqrt(225) false [
  let row (floor (who / sqrt(225)))
     let col (who mod sqrt(225))
     setxy (min-xpos + col * horizontal-spacing)
           (min-ypos + row * vertical-spacing)
   ]
 end


to migration_model_parameters
  set intercept_coeff 6.73048907717479
  set log_age_coeff -2.92021521801411


  ;set log_age_coeff mig_coeff_age_input

  set land_coeff  -0.0665087568419369
  set network_coeff 0.670856145543941
  ;set network_coeff mig_coeff_sna_input
  set children_coeff -0.395899574876846
end



to parametrize_agents
  file-close-all
  file-open "../socio_economic_mmp_data/household_sample.csv"
  let data csv:from-row file-read-line
  ask households [
    ;empirical components
    set data csv:from-row file-read-line
    set agriculture_land item 0 data + 1 ;tmp fix only for non-correct imported data
    set commun item 5 data
    set hhnum item 6 data
    set surveyyr item 7 data
    ;Indirectly derived attributes

    set land_abandoned TRUE
    set member_migrated_already_in_t FALSE
  ]


set t_0_land_amount sum [agriculture_land] of households






  ask households [

  ;Design
    set shape "circle"
    set size agriculture_land
     if migrated_hh_members > 0 [
    set color red
    ]
    if migrated_hh_members = 0 [
    set color green
    ]
  ]
  ;create individuals as breed
  create-individuals 1593 [
  set color black ; place somewhere where they stay unnoticed

  ]




  file-close-all
  file-open "../socio_economic_mmp_data/household_members_sample.csv"
  set data csv:from-row file-read-line
  ask individuals [
    set data csv:from-row file-read-line
    set member_relhead item 0 data
    set member_commun item 1 data
    set member_hhnum item 2 data
    set member_surveyyr item 3 data
    set member_age item 4 data
    set member_sex item 5 data
    set married FALSE


    ifelse item 6 data = 1 [
    set member_migrated TRUE
    ][
    set member_migrated FALSE
    ]
  ]



  ;now place individuals at cells of their households
  ask individuals [



    let member_commun_spec [ member_commun ] of self
    let member_hhnum_spec [ member_hhnum] of self
    let member_surveyyr_spec [ member_surveyyr ] of self

    let household_x_cor 0
    let household_y_cor 0
    ask one-of households with [commun =  member_commun_spec  AND hhnum = member_hhnum_spec AND surveyyr = member_surveyyr_spec] [
      set household_x_cor xcor
      set household_y_cor ycor
    ]
    set xcor household_x_cor
    set ycor household_y_cor
  ]





  ask households [
    let household_commun  commun
    let household_hhnum hhnum
    let household_surveyyr surveyyr

    set migrated_hh_members count individuals with [ member_commun = household_commun AND member_hhnum = household_hhnum AND member_surveyyr = household_surveyyr  AND
  member_migrated = TRUE]


   if migrated_hh_members > 0 [
      let share_of_migrants (migrated_hh_members / ( workers + migrated_hh_members + 1)) * 100
      set color scale-color red share_of_migrants 100 0
    ;set color red
    ]
    if migrated_hh_members = 0 [
    set color green
    ]


     let household_adults_non_head count individuals with [ member_commun = household_commun AND member_hhnum = household_hhnum AND member_surveyyr = household_surveyyr  AND
 member_age > 18 AND member_relhead  > 1 ]

  let retired_hh_members  count individuals with [ member_commun = household_commun AND member_hhnum = household_hhnum AND member_surveyyr = household_surveyyr  AND
  member_migrated = FALSE AND member_age > 65]

  set workers household_adults_non_head + 1 - migrated_hh_members - retired_hh_members

    set hh_members count individuals with [ member_commun = household_commun AND member_hhnum = household_hhnum AND member_surveyyr = household_surveyyr AND member_migrated = FALSE]

   set household_first_gen_children count individuals with [ member_commun = household_commun AND member_hhnum = household_hhnum AND member_surveyyr = household_surveyyr AND member_migrated = FALSE AND
    member_relhead = 3]

    set relative_utility agriculture_land / (household_first_gen_children + 1 )

    set workers_to workers

  ]


  if homogeneity_mode = "on" [
    ask households[
    set agriculture_land mean [agriculture_land] of households

    ]

  ]



end









to go


 if time_frame = "empirical_data" [
  set empirical_agriculture_pattern (list  0.016 0.032 0.049 0.06 0.076 0.08 0.09 0.1 0.11 0.11 0.11 0.12 0.11 0.11 0.1 0.1)
  set current_explanandum_agriculture_cover item (ticks ) empirical_agriculture_pattern
  if ticks > 14 [ stop ]
  ]
  ask individuals [
  individuals_demographics_module
  migration_decision
  ]



  ask households [


   set member_migrated_already_in_t FALSE
   ;demographics
  household_demographics_module

  ;households where one member at least is migrated receive remittances and make decision about usage (consumption vs. agriculture labor force)
  receiving_remittances

  ;practice of agriculture
  agriculture_practices

  ]
  update_color_scheme
 update-lorenz-and-gini
  update-lorenz-and-gini_relative_utility
  print gini-index-reserve-relative

  export_world_procedure

  tick
end



to export_world_procedure



if export_sim_csv_files = TRUE [


  let simulation_run_number global_simulation_run_id

  export-world (word "individual_sim_runs_exports/"  simulation_run_number "run" ticks "with_tick.csv")

  ]



end






to individuals_demographics_module
  set member_age member_age + 1







  if member_sex = 1 AND member_age > 18 AND member_age < 40 AND member_migrated = FALSE AND member_relhead = 2 [


    if random-float 1 < 0.08 [
    let child_hhnum member_hhnum
    let child_surveyyr member_surveyyr
    let child_commun member_commun




 hatch 1 [
  set member_commun member_commun
  set member_hhnum member_hhnum
  set member_surveyyr member_surveyyr
  set member_relhead 3 ; this might be the crucial game breaker leaving it out for test purposes
  set member_age random 0
  set married FALSE ; needs to be set for relhead 1 or 2 in constructor of ABM too
  set member_migrated FALSE

   ifelse random-float 1 > 0.5 [
      set member_sex  2
      ][
      set member_sex 1
      ]

    ]

    ]
  ]

end



to household_demographics_module
  let household_commun  commun
  let household_hhnum hhnum
  let household_surveyyr surveyyr






  let household_adults_non_head count individuals with [ member_commun = household_commun AND member_hhnum = household_hhnum AND member_surveyyr = household_surveyyr  AND
 member_age > 18 AND member_relhead  > 1 ]


  ;update param for number of out-migrated HH-members
  set migrated_hh_members_t_prior migrated_hh_members

  set migrated_hh_members count individuals with [ member_commun = household_commun AND member_hhnum = household_hhnum AND member_surveyyr = household_surveyyr  AND
  member_migrated = TRUE]


  set hh_members count individuals with [ member_commun = household_commun AND member_hhnum = household_hhnum AND member_surveyyr = household_surveyyr AND member_migrated = FALSE]


  let retired_hh_members  count individuals with [ member_commun = household_commun AND member_hhnum = household_hhnum AND member_surveyyr = household_surveyyr  AND
  member_migrated = FALSE AND member_age > 65]


  if migrated_hh_members != migrated_hh_members_t_prior [
  set land_abandoned FALSE ] ; if someone new from HH migrates, land abandonedment becomes relevant again


  set workers count individuals with [ member_commun = household_commun AND member_hhnum = household_hhnum AND member_surveyyr = household_surveyyr  AND
  member_migrated = FALSE AND member_age > 18 AND member_age < 65]



   set household_first_gen_children count individuals with [ member_commun = household_commun AND member_hhnum = household_hhnum AND member_surveyyr = household_surveyyr AND member_migrated = FALSE AND
    member_relhead = 3]


  set relative_utility agriculture_land / (household_first_gen_children + 1 )


  if internal_validation_mode = "on" [
  print "------------------------------------"
  print who

  type "household_adults_non_head "   type household_adults_non_head print " "
  type "migrated_hh_members "   type migrated_hh_members print " "
  type "workers "   type workers print " "
  ]

end









; turtles make migration decisions
to migration_decision
  if member_age > 18 AND member_migrated = FALSE AND member_relhead = 3 [


    ;while agents have no age specified
    let network 0
    if any? link-neighbors with [migrated_hh_members > 0] [
    set network 2
    ]

    let member_commun_spec [ member_commun ] of self
    let member_hhnum_spec [ member_hhnum] of self
    let member_surveyyr_spec [ member_surveyyr ] of self

    let migration_stop_household FALSE
    ask one-of households with [commun =  member_commun_spec  AND hhnum = member_hhnum_spec AND surveyyr = member_surveyyr_spec] [
      set migration_stop_household  member_migrated_already_in_t
    ]
    if migration_stop_household = FALSE [


    ;create regression binary value for whether children are in the household already existing i.e. check for relationship to HH-head (prelim.version)
    let children_probit_var 0
    ifelse [ member_relhead ] of self = 3 [
      set children_probit_var 0
    ][
    set children_probit_var 1
    ]


let individual_utlitity_land_tmp 0
let relative_utility_factor 1



      if member_relhead = 3 [

    ;get inormation of household of agent (i.e. land and social network, relevant for regression model not stored within the agent)
    ask one-of households with [commun =  member_commun_spec  AND hhnum = member_hhnum_spec AND surveyyr = member_surveyyr_spec] [
      set individual_utlitity_land_tmp  agriculture_land ; calculate individual utility of agriculture land for each household
      ;set relative_utility_factor hh_members
      set relative_utility_factor household_first_gen_children
    ]


      ]


      if member_relhead = 1 OR member_relhead = 2 [

      ;get inormation of household of agent (i.e. land and social network, relevant for regression model not stored within the agent)
    ask one-of households with [commun =  member_commun_spec  AND hhnum = member_hhnum_spec AND surveyyr = member_surveyyr_spec] [
      set individual_utlitity_land_tmp  agriculture_land ; calculate individual utility of agriculture land for each household
      ;set relative_utility_factor hh_members
      set relative_utility_factor agriculture_land
    ]


      ]


    set individual_utlitity_land individual_utlitity_land_tmp
    ;if the turtle is a son/daughter --> divide utility by number of total children thus potentially relevant for land inheritance at a later life cycle stage
    set individual_utlitity_land individual_utlitity_land /   relative_utility_factor



let migration_probability  exp(intercept_coeff + (log_age_coeff * log member_age e ) + (children_coeff * children_probit_var) +
      (land_coeff * individual_utlitity_land ) + (network_coeff * network)) /(1 + exp(intercept_coeff + (log_age_coeff * log member_age e ) +
        (land_coeff * individual_utlitity_land) +
         (children_coeff * children_probit_var) + (network_coeff * network)))




   set migration_probability migration_probability * scaling_param_migration
    ;purely random decision making on migration
    if random-float 1 < migration_probability [
    set member_migrated TRUE
      ;check that per timestep and HH only one member can migrate
      ask households with [commun =  member_commun_spec  AND hhnum = member_hhnum_spec AND surveyyr = member_surveyyr_spec] [
      set member_migrated_already_in_t TRUE
      ]
    ]
  ]
  ]

end



to receiving_remittances


let land_wealth_coeff   0.6621922
let intercept_coeff_invest -5.077139
set remittances_investment_probability  exp(intercept_coeff_invest + (land_wealth_coeff * agriculture_land)) / ( 1 + exp(intercept_coeff_invest + (land_wealth_coeff * agriculture_land ) ))
set remittances_investment_probability   remittances_investment_probability * remittances_usage_scaling_param
 if migrated_hh_members > 0 [
    set received_remittances 0
    let tmp_list n-values migrated_hh_members [1]
    foreach tmp_list [
      if random-float 1 < 0.7 [ ; empirically derived parameter
      set received_remittances received_remittances + 1
      ]
    ]
    if remittances_investment_probability > 0 [
    set tmp_list n-values received_remittances [1]
      foreach tmp_list [
        if random-float 1 < remittances_investment_probability [
          set workers workers + 1
      ]
      ]
    ]
  ]
end



to agriculture_practices

      if migrated_hh_members > 0 AND workers > 0 [
       set agriculture_land agriculture_land - (migrated_hh_members  ) * deforestation_per_step_worker_ha
        set global_abandoned_land global_abandoned_land + migrated_hh_members * deforestation_per_step_worker_ha
      ]
    set agriculture_land agriculture_land + deforestation_per_step_worker_ha * ([ workers ] of self)
    set global_deforested_land global_deforested_land + deforestation_per_step_worker_ha * ([ workers ] of self)

end




to update_color_scheme
  ask households [
    set size agriculture_land
    if migrated_hh_members > 0 [
      let share_of_migrants (migrated_hh_members / ( workers + migrated_hh_members + 1)) * 100
      set color scale-color red share_of_migrants 100 0
    ;set color red
    ]
    if migrated_hh_members = 0 [
    set color green
    ]
  ]
end






;; this procedure is a copied from the wealth distribution example
to update-lorenz-and-gini
  let sorted-wealths sort [agriculture_land] of households
  let total-wealth sum sorted-wealths
  let wealth-sum-so-far 0
  let index 0
  set gini-index-reserve 0
  set lorenz-points []
  let num-people count households

  repeat num-people [
    set wealth-sum-so-far (wealth-sum-so-far + item index sorted-wealths)
    set lorenz-points lput ((wealth-sum-so-far / total-wealth) * 100) lorenz-points
    set index (index + 1)
    set gini-index-reserve
      gini-index-reserve +
      (index / num-people) -
      (wealth-sum-so-far / total-wealth)
  ]
end


to update-lorenz-and-gini_relative_utility
  let sorted-wealths sort [relative_utility ] of households
  let total-wealth sum sorted-wealths
  let wealth-sum-so-far 0
  let index 0
  set gini-index-reserve-relative 0
  set lorenz-points []
  let num-people count households

  repeat num-people [
    set wealth-sum-so-far (wealth-sum-so-far + item index sorted-wealths)
    set lorenz-points lput ((wealth-sum-so-far / total-wealth) * 100) lorenz-points
    set index (index + 1)
    set gini-index-reserve-relative
      gini-index-reserve-relative +
      (index / num-people) -
      (wealth-sum-so-far / total-wealth)
  ]
end






to update_land_inequality_levels
 ;implement the procedure similar to R script with re-distribution from rich to poor


  update-lorenz-and-gini


  if inequality_distribution_mode = "total" [

  while [gini-index-reserve > desired_gini_level]
  [

 ; ask household with most land

  ask one-of households with [agriculture_land = (max [agriculture_land] of households) ] [
  set agriculture_land agriculture_land - 0.1
  ]


  ask one-of households with [agriculture_land = (min [agriculture_land] of households) ] [
  set agriculture_land agriculture_land + 0.1
  ]

 update-lorenz-and-gini
  ]

  ]


  if inequality_distribution_mode = "relative" [
update-lorenz-and-gini_relative_utility
    while [gini-index-reserve-relative > desired_gini_level]
  [

      ;print gini-index-reserve-relative
 ; ask household with most land

  ask one-of households with [relative_utility = (max [relative_utility] of households) ] [
  set agriculture_land agriculture_land - 0.1
  set relative_utility agriculture_land / (household_first_gen_children + 1 )


  ]


  ask one-of households with [relative_utility = (min [relative_utility] of households) ] [
  set agriculture_land agriculture_land + 0.1
  set relative_utility agriculture_land / (household_first_gen_children + 1 )

  ]




 update-lorenz-and-gini_relative_utility
  ]





  ]







end
@#$#@#$#@
GRAPHICS-WINDOW
507
12
1115
621
-1
-1
2.99
1
10
1
1
1
0
1
1
1
-100
100
-100
100
0
0
1
ticks
30.0

BUTTON
214
306
280
339
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
15
468
382
631
Land inequality
NIL
NIL
0.0
15.0
0.0
11.0
true
false
"" ""
PENS
"default" 0.5 1 -955883 true "" "histogram [ agriculture_land ] of households"

BUTTON
84
307
202
340
NIL
\ngo
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1419
182
1696
325
Out-migration
NIL
NIL
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (count individuals with [member_migrated = TRUE]) "
"pen-1" 1.0 0 -7500403 true "" ""

BUTTON
14
306
77
339
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
13
348
285
381
probability_remittances_agriculture_invest
probability_remittances_agriculture_invest
0
1
0.05
0.05
1
NIL
HORIZONTAL

PLOT
0
10
313
300
Agricultural Land
NIL
NIL
0.0
16.0
0.0
0.3
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot   ((sum [agriculture_land] of households) - t_0_land_amount ) / t_0_land_amount "
"pen-1" 1.0 0 -1184463 true "" "plot current_explanandum_agriculture_cover"

INPUTBOX
320
175
501
235
scaling_param_migration
1.2
1
0
Number

SLIDER
7
394
287
427
remittances_usage_scaling_param
remittances_usage_scaling_param
0
1
0.8
0.05
1
NIL
HORIZONTAL

CHOOSER
320
244
500
289
time_frame
time_frame
"empirical_data" "long-term"
0

PLOT
392
633
640
783
Land Abandoned
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot global_abandoned_land"

PLOT
1131
346
1415
495
Workers per household
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ workers ] of households"

PLOT
15
633
383
783
Gini vs. time
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot gini-index-reserve-relative"

CHOOSER
321
71
502
116
change_inequality
change_inequality
"off" "on"
1

CHOOSER
321
123
502
168
internal_validation_mode
internal_validation_mode
"off" "on"
0

PLOT
648
634
897
783
Household relative Utility of Land
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" " histogram  [relative_utility] of households"

PLOT
1131
181
1411
326
Migrated members per HH
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [migrated_hh_members] of households"

PLOT
1131
21
1410
171
Rural Labor Force
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [workers] of households"

PLOT
1417
21
1696
171
Share of migrated individuals
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count individuals with [member_migrated = TRUE] / count individuals"

PLOT
1428
346
1719
496
Mean probability of using remittances for investment
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ remittances_investment_probability ] of households"

INPUTBOX
320
304
499
373
deforestation_per_step_worker_ha
0.03
1
0
Number

SLIDER
317
374
499
407
desired_gini_level
desired_gini_level
0
100
10.0
1
1
NIL
HORIZONTAL

CHOOSER
321
22
503
67
inequality_distribution_mode
inequality_distribution_mode
"total" "relative"
1

CHOOSER
334
414
499
459
homogeneity_mode
homogeneity_mode
"off" "on"
0

SWITCH
1204
557
1379
590
export_sim_csv_files
export_sim_csv_files
1
1
-1000

INPUTBOX
1555
513
1716
573
mig_coeff_sna_input
0.6
1
0
Number

INPUTBOX
1556
579
1717
639
mig_coeff_age_input
0.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="different_gini_levels_total" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>((sum [agriculture_land] of households) - t_0_land_amount ) / t_0_land_amount</metric>
    <metric>gini-index-reserve</metric>
    <metric>global_abandoned_land</metric>
    <metric>count individuals with [member_migrated = TRUE] / count individuals</metric>
    <metric>sum [workers] of households</metric>
    <metric>global_deforested_land</metric>
    <metric>global_household_index</metric>
    <enumeratedValueSet variable="change_inequality">
      <value value="&quot;on&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homogeneity_mode">
      <value value="&quot;off&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inequality_distribution_mode">
      <value value="&quot;total&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scaling_param_migration">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deforestation_per_step_worker_ha">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="internal_validation_mode">
      <value value="&quot;off&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export_sim_csv_files">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="desired_gini_level" first="5" step="10" last="45"/>
    <enumeratedValueSet variable="remittances_usage_scaling_param">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability_remittances_agriculture_invest">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time_frame">
      <value value="&quot;empirical_data&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="different_gini_levels_relativ_age_variations" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>((sum [agriculture_land] of households) - t_0_land_amount ) / t_0_land_amount</metric>
    <metric>gini-index-reserve</metric>
    <metric>global_abandoned_land</metric>
    <metric>count individuals with [member_migrated = TRUE] / count individuals</metric>
    <metric>sum [workers] of households</metric>
    <metric>global_deforested_land</metric>
    <metric>global_household_index</metric>
    <enumeratedValueSet variable="change_inequality">
      <value value="&quot;on&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homogeneity_mode">
      <value value="&quot;off&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inequality_distribution_mode">
      <value value="&quot;relative&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scaling_param_migration">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deforestation_per_step_worker_ha">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="internal_validation_mode">
      <value value="&quot;off&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export_sim_csv_files">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired_gini_level">
      <value value="5"/>
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="remittances_usage_scaling_param">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability_remittances_agriculture_invest">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time_frame">
      <value value="&quot;empirical_data&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mig_coeff_sna_input">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mig_coeff_age_input">
      <value value="-2.92"/>
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="gini_phase_diagram" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>((sum [agriculture_land] of households) - t_0_land_amount ) / t_0_land_amount</metric>
    <metric>gini-index-reserve</metric>
    <metric>gini-index-reserve-relative</metric>
    <metric>global_abandoned_land</metric>
    <metric>count individuals with [member_migrated = TRUE] / count individuals</metric>
    <metric>sum [workers] of households</metric>
    <metric>global_deforested_land</metric>
    <metric>global_household_index</metric>
    <enumeratedValueSet variable="change_inequality">
      <value value="&quot;on&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homogeneity_mode">
      <value value="&quot;off&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deforestation_per_step_worker_ha">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scaling_param_migration">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inequality_distribution_mode">
      <value value="&quot;relative&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="internal_validation_mode">
      <value value="&quot;off&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mig_coeff_sna_input">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mig_coeff_age_input">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="desired_gini_level" first="5" step="5" last="45"/>
    <enumeratedValueSet variable="export_sim_csv_files">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="remittances_usage_scaling_param">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability_remittances_agriculture_invest">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time_frame">
      <value value="&quot;empirical_data&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
