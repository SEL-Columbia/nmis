
def tmp_variables_for_sector(sector_slug, lga_data, record_counts):
    def g(slug):
        value_dict = lga_data.get(slug, None)
        if value_dict:
            return value_dict.get('value', None)
        else:
            return None
    def i(slug1, slug2):
        if g(slug1) == None or g(slug2) == None:
            return None
        return "%s/%s" % (g(slug1), g(slug2))
    def h(slug1, slug2):
        try:
            indicator = LGAIndicator.objects.get(slug=slug1)
            count = 0
            records = record_counts[indicator.sector.slug][indicator.origin.slug]
            for k, v in records.items():
                count += v
        except:
            return None
        return "%s/%s" % (g(slug1), count)
    example = {
        'health': [
            ('Facilities', [
            #proof of concept that lga is accessible from here.
                ["Health Posts and Dispensaries", g("num_level_1_health_facilities"), None, g("target_level_1_health_facilities"), None],
                ["Primary Health Clinics", g("num_level_2_health_facilities"), None, g("target_level_2_health_facilities"), None],
                ["Primary Health Centres", g("num_level_3_health_facilities"), None, g("target_level_3_health_facilities"), None],
                ["Comprehensive Health Centres and Hospitals", g("num_level_4_health_facilities"), None, g("target_level_4_health_facilities"), None],
                ["Other Health Facilities", g("num_level_other_health_facilities"), None, None, None],
                ["Total number of facilities", g("num_health_facilities"), None, g("target_total_health_facilities"), None],
                ["Percentage of facilities that offer inpatient care", g("proportion_health_facilities_inpatient_care"), h("num_health_facilities_inpatient_care", "num_health_facilities"), None, None],
                ["Percentage of facilities that offer care 24 hours a day, 7 days a week", g("proportion_health_facilities_open_24_7"), h("num_health_facilities_open_24_7", "num_health_facilities"), g("target_health_facilities_open_24_7"), g("target_all_but_level_1_health_facilities")],
            ],),
            ('Staffing', [
                ["Total number of doctors in the LGA", g("num_doctors"), None, g("target_num_doctors"), None],
                ["Total number of midwives and nurse-midwives in the LGA", g("num_nursemidwives_midwives"), None, g("target_num_midwives_nursemidwives"), None],
                ["Total number of nurses in the LGA", g("num_nurses"), None, g("target_num_nurses"), None],
                ["Total number of CHEWs (Jr. and Sr.) in the LGA", g("num_chews"), None, g("target_num_chews"), None],
                ["Total number of laboratory technicians in the LGA", g("num_lab_techs"), None, g("target_num_lab_techs"), None],
                ["Number of skilled health providers per 1,000 population", g("num_skilled_health_providers_per_1000"), None, None, None],
                ["Number of CHEWs per 1,000 population", g("num_chews_per_1000"), None, None, None],
                ["Percentage of facilities where all salaried staff were paid during the last pay period", g("proportion_staff_paid"), h("num_staff_paid", "staff_paid_lastmth_yn"), g("target_total_health_facilities"), "100%"],
            ],),
            ('Child Health', [
                ["Percentage of facilities that offer routine immunization", g("proportion_health_facilities_routine_immunization"), h("num_health_facilities_routine_immunization", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Percentage of facilities that offer growth monitoring", g("proportion_growth_monitoring"), h("num_growth_monitoring", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Percentage of facilities that offer deworming", g("proportion_deworming"), h("num_deworming", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Percentage of facilities that do not charge any fees for child health services", g("proportion_no_user_fees_child_health"), h("num_no_user_fees_child_health", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
            ],),
            ('Maternal Health', [
                ["Percentage of facilities that offer delivery services 24 hours a day, 7 days a week", g("proportion_delivery_24_7"), h("num_delivery_24_7", "num_health_facilities"), g("target_health_facilities_open_24_7"), g("target_all_but_level_1_health_facilities")],
                ["Percentage of facilities with at least one skilled birth attendant", g("proportion_at_least_1_sba"), h("num_at_least_1_sba", "num_health_facilities"), g("target_health_facilities_open_24_7"), g("target_all_but_level_1_health_facilities")],
                ["Percentage of facilities that offer antenatal care", g("proportion_antenatal"), h("num_antenatal", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities that perform Caesarean sections", g("num_health_facilities_c_sections"), None, None, None],

                ["Percentage of facilities with access to emergency transport services", g("proportion_access_functional_emergency_transport"), h("num_access_functional_emergency_transport", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Percentage of facilities that offer family planning services", g("proportion_family_planning"), h("num_family_planning", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Percentage of facilities that do not charge any fees for maternal health services", g("proportion_delivery_no_user_fees"), h("num_delivery_no_user_fees", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
            ],),
            ('HIV/AIDS, Malaria and other Diseases', [
                ["HIV/AIDS"],
                ["Percentage of facilities that offer HIV testing", g("proportion_health_facilities_hiv_testing"), h("num_health_facilities_hiv_testing", "num_health_facilities"), None, None],
                ["Percentage of facilities that offer ART treatment", g("proportion_health_facilities_art_treatment"), h("num_health_facilities_art_treatment", "num_health_facilities"), None, None],
                ["Malaria"],
                ["Percentage of facilities that offer malaria testing (RDT or microscopy)", g("proportion_malaria_testing"), h("num_malaria_testing", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Percentage of facilities that offer ACT-based treatment for malaria", g("proportion_act_treatment_for_malaria"), h("num_act_treatment_for_malaria", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Percentage of facilities that offer malaria prophylaxis during pregnancy", g("proportion_malaria_prevention_pregnancy"), h("num_malaria_prevention_pregnancy", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Percentage of facilities that provide bednets", g("proportion_offer_bednets"), h("num_offer_bednets", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Percentage of facilities that do not charge and fees for malaria-related services", g("proportion_no_user_fees_malaria"), h("num_no_user_fees_malaria", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Tuberculosis"],
                ["Percentage of facilities that offer TB treatment", g("proportion_health_facilities_tb_treatment"), h("num_health_facilities_tb_treatment", "num_health_facilities"), None, None],
                ["Percentage of facilities that offer TB testing", g("proportion_health_facilities_tb_testing"), h("num_health_facilities_tb_testing", "num_health_facilities"), None, None],
            ],),
            ('Infrastructure', [
                ["Percentage of facilities with access to some form of power source", g("proportion_any_power_access"), h("num_any_power_access", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Percentage of facilities with access to an improved water source", g("proportion_improved_water_source"), h("num_improved_water_source", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Percentage of facilities with functioning improved sanitation", g("proportion_functional_sanitation"), h("num_functional_sanitation", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Percentage of facilities with mobile phone coverage somewhere on the premises", g("proportion_mobile_coverage"), h("num_mobile_coverage", "num_health_facilities"), g("target_total_health_facilities"), "100%"],
                ["Percentage of facilities that separate medical waste from other forms of waste", g("proportion_health_facilities_med_waste_separated"), h("num_health_facilities_med_waste_separated", "num_health_facilities"), None, None],
            ],),
            ('Equipment and Supplies', [
                ["Percentage of facilities that experienced a stock-out of essential medications in the past month", g("proportion_stockout_essential_meds"), h("num_stockout_essential_meds", "num_health_facilities"), 0, "0%"],
            ],),
        ],
        'education': [
            ('Facilities', [
                ["Number of primary schools (preprimary, primary, preprimary/primary, primary/js)", g("num_primary_schools"), None, g("target_num_primary_schools")],
                ["Number of junior secondary schools (js, js/ss)", g("num_junior_secondary_schools"), None, g("target_num_junior_secondary_schools")],
                ["Number of senior secondary schools (ss)", g("num_senior_secondary_schools"), None, g("target_num_senior_secondary_schools")],
                ["Total number of schools", g("num_schools"), None, g("target_num_schools")],
            ],),
            ('Access', [
                ["Primary net intake rate (NIR) for boys", "N/A", None, "N/A"],
                ["Primary net intake rate (NIR) for girls", "N/A", None, "N/A"],
                ["Junior secondary net intake rate (NIR) for boys", "N/A", None, "N/A"],
                ["Junior Secondary net intake rate (NIR) for girls", "N/A", None, "N/A"],
                ["Percentage of primary schools farther than 1km from catchement area", g("proportion_schools_1kmplus_catchment_primary"), h("num_schools_1kmplus_catchment_primary", "num_primary_schools"), "0%", "0"],
                ["Percentage of junior secondary schools farther than 1km from catchement area", g("proportion_schools_1kmplus_catchment_juniorsec"), h("num_schools_1kmplus_catchment_juniorsec", "num_junior_secondary_schools"), "0%", "0"],

                ["Percentage of primary schools farther than 1km from nearest secondary school", g("proportion_schools_1kmplus_ss"), h("num_primary_schools_1kmplus_ss", "num_primary_schools"), "0%", "0"],

                ["Percentage of primary schools with students living farther than 3km", g("proportion_students_3kmplus_primary"), h("num_students_3kmplus_primary", "students_living_3kmplus_school_primary"), "0%", "0"],
                ["Percentage of junior secondary schools with students living farther than 3km", g("proportion_students_3kmplus_juniorsec"), h("num_students_3kmplus_juniorsec", "students_living_3kmplus_school_juniorsec"), "0%", "0"],
            ],),
            ('Participation', [
                ["Primary net enrollment rate (NER) for boys", g("net_enrollment_rate_boys_primary"), None, "100%"],
                ["Primary net enrollment rate (NER) for girls", g("net_enrollment_rate_girls_primary"), None, "100%"],
                ["Junior secondary net enrollment rate (NER) for boys", g("net_enrollment_rate_boys_js"), None, "100%"],
                ["Junior secondary net enrollment rate (NER) for girls", g("net_enrollment_rate_girls_js"), None, "100%"],
                ["Gender parity index (GPI) for primary schools", g("gender_parity_index_primary"), None, "1", None],
                ["Gender parity index (GPI) for junior secondary schools", g("gender_parity_index_js"), None, "1", None],
            ],),
            ('Infrastructure', [
                ["Water & Sanitation"],
                ["Percentage of primary schools with access to potable water", g("proportion_schools_potable_water_primary"), h("num_schools_potable_water_primary", "num_primary_schools"), "100%", g("target_num_schools")],
                ["Percentage of junior secondary schools with access to potable water", g("proportion_schools_potable_water_juniorsec"), h("num_schools_potable_water_juniorsec", "num_junior_secondary_schools"), "100%", g("target_num_schools")],
                ["Percentage of primary schools with improved sanitation/toilet", g("proportion_schools_improved_sanitation_primary"), h("num_schools_improved_sanitation_primary", "num_primary_schools"), "100%", g("target_num_schools")],
                ["Percentage of junior secondary schools with improved sanitation/toilet", g("proportion_schools_improved_sanitation_juniorsec"), h("num_schools_improved_sanitation_juniorsec", "num_junior_secondary_schools"), "100%", g("target_num_schools")],
                ["Percentage of primary schools with gender-separated toilets", g("proportion_schools_gender_sep_toilet_primary"), h("num_schools_gender_sep_toilet_primary", "num_primary_schools"), "100%", g("target_num_schools")],
                ["Percentage of junior secondary schools with gender-separated toilets", g("proportion_schools_gender_sep_toilet_juniorsec"), h("num_schools_gender_sep_toilet_juniorsec", "num_juniorsec_schools"), "100%", g("target_num_schools")],
                ["Pupil to toilet ratio (primary)", g("pupil_toilet_ratio_primary"), None, "35"],
                ["Pupil to toilet ratio (junior secondary)", g("pupil_toilet_ratio_secondary"), None, "35"],
                ["Building Structure"],
                ["Percentage of primary schools with access to power", g("proportion_schools_power_access_primary"), h("num_schools_power_access_primary", "num_primary_schools"), "100%", g("target_num_schools")],
                ["Percentage of junior secondary schools with access to power", g("proportion_schools_power_access_juniorsec"), h("num_schools_power_access_juniorsec", "num_juniorsec_schools"), "100%", g("target_num_schools")],
                ["Percentage of primary school classrooms needing major repair", g("proportion_classrooms_need_major_repair_primary"), i("num_primary_classrooms_need_maj_repairs", "num_classrooms_lga_primary"), "0%", "0"],
                ["Percentage of junior secondary school classrooms needing major repair", g("proportion_classrooms_need_major_repair_juniorsec"), i("num_juniorsec_classrooms_need_maj_repairs", "num_classrooms_lga_juniorsec"), "0%", "0"],
                ["Percentage of primary school classrooms needing minor repair", g("proportion_classrooms_need_minor_repair_primary"), i("num_primary_classrooms_need_min_repairs", "num_classrooms_lga_primary"), "0%", "0"],
                ["Percentage of junior secondary school classrooms needing minor repair", g("proportion_classrooms_need_minor_repair_juniorsec"), i("num_juniorsec_classrooms_need_min_repairs", "num_classrooms_lga_juniorsec"), "0%", "0"],
                ["Percentage of primary schools with a roof in good condition", g("proportion_schools_covered_roof_good_cond_primary"), h("num_schools_covered_roof_good_cond_primary", "num_primary_schools"), "100%", g("num_primary_schools")],
                ["Percentage of junior secondary schools with a roof in good condition", g("proportion_schools_covered_roof_good_cond_juniorsec"), h("num_schools_covered_roof_good_cond_juniorsec", "num_juniorsec_schools"), "100%", g("num_juniorsec_schools")],
                ["Health & Safety"],
                ["Percentage of primary schools with a dispensary/health clinic", g("proportion_schools_with_clinic_dispensary_primary"), h("num_schools_with_clinic_dispensary_primary", "num_primary_schools"), "100%", g("target_num_schools")],
                ["Percentage of junior secondary schools with a dispensary/health clinic", g("proportion_schools_with_clinic_dispensary_juniorsec"), h("num_schools_with_clinic_dispensary_juniorsec", "num_juniorsec_schools"), "100%", g("target_num_schools")],
                ["Percentage of primary schools with a first aid kit only (not a health clinic)", g("proportion_schools_with_first_aid_kit_primary"), h("num_schools_with_first_aid_kit_primary", "num_primary_schools"), "100%", g("target_num_schools")],
                ["Percentage of junior secondary schools with a first aid kit only (not a health clinic)", g("proportion_schools_with_first_aid_kit_juniorsec"), h("num_schools_with_first_aid_kit_juniorsec", "num_juniorsec_schools"), "100%", g("target_num_schools")],
                ["Percentage of primary schools with a wall/fence in good condition", g("proportion_schools_fence_good_cond_primary"), h("num_schools_fence_good_cond_primary", "num_primary_schools"), "100%", g("target_num_schools")],
                ["Percentage of junior secondary schools with a wall/fence in good condition", g("proportion_schools_fence_good_cond_juniorsec"), h("num_schools_fence_good_cond_juniorsec", "num_juniorsec_schools"), "100%", g("target_num_schools")],
                ["Learning Environment"],
                ["Pupil to classroom ratio (primary)", g("student_classroom_ratio_lga_primary"), None, "35"],
                ["Pupil to classroom ratio (junior secondary)", g("student_classroom_ratio_lga_juniorsec"), None, "35"],
                ["Percentage of primary schools that teach outside because there are not enough classrooms", g("proportion_schools_hold_classes_outside_primary"), h("num_schools_hold_classes_outside_primary", "num_primary_schools"), "0%", "0"],
                ["Percentage of junior secondary schools that teach outside because there are not enough classrooms", g("proportion_schools_hold_classes_outside_juniorsec"), h("num_schools_hold_classes_outside_juniorsec", "num_juniorsec_schools"), "0%", "0"],
                ["Percentage of primary schools with double shifts", g("proportion_schools_two_shifts_primary"), h("num_schools_two_shifts_primary", "num_primary_schools"), "0%", "0"],
                ["Percentage of junior secondary schools with double shifts", g("proportion_schools_two_shifts_juniorsec"), h("num_schools_two_shifts_juniorsec", "num_juniorsec_schools"), "0%", "0"],
                ["Percentage of primary schools with multi-grade classrooms", g("proportion_schools_multigrade_classrooms_primary"), h("num_schools_multigrade_classrooms_primary", "num_primary_schools"), "0%", "0"],
                ["Percentage of junior secondary schools with multi-grade classrooms", g("proportion_schools_multigrade_classrooms_juniorsec"), h("num_schools_multigrade_classrooms_juniorsec", "num_juniorsec_schools"), "0%", "0"],
            ],),
            ('Furniture', [
                ["Percentage of primary schools with a chalkboard in every classroom", g("proportion_schools_chalkboard_all_rooms_primary"), h("num_schools_chalkboard_all_rooms_primary", "num_primary_schools"), "100%", g("target_num_schools")],
                ["Percentage of junior secondary schools with a chalkboard in every classroom", g("proportion_schools_chalkboard_all_rooms_juniorsec"), h("num_schools_chalkboard_all_rooms_juniorsec", "num_juniorsec_schools"), "100%", g("target_num_schools")],
                ["Pupil to bench ratio (primary)", g("pupil_bench_ratio_lga_primary"), None, "&#8804; 3"],
                ["Pupil to bench ratio (junior secondary)", g("pupil_bench_ratio_lga_juniorsec"), None, "&#8804; 3"],
                ["Pupil to desk ratio (primary)", g("pupil_desk_ratio_lga_primary"), None, "&#8804; 1"],
                ["Pupil to desk ratio (junior secondary)", g("pupil_desk_ratio_lga_juniorsec"), None, "&#8804; 1"],
            ],),
            ('Adequacy of Staffing', [
                ["Primary school pupil to teacher ratio", g("primary_school_pupil_teachers_ratio_lga"), None, "&#8804; 35"],
                ["Junior secondary school pupil to teacher ratio", g("junior_secondary_school_pupil_teachers_ratio_lga"), None, "&#8804; 35"],
                ["Primary school teaching to non-teaching staff ratio", g("teacher_nonteachingstaff_ratio_lga_primary"), None, "N/A"],
                ["Junior secondary teaching to non-teaching staff ratio", g("teacher_nonteachingstaff_ratio_lga_juniorsec"), None, "N/A"],
                ["Percentage of primary school qualified teachers (with NCE)", g("proportion_teachers_nce_primary"), i("num_primary_school_teachers_nce", "num_primary_school_teachers"), "100%", g("target_num_teachers")],
                ["Percentage of junior secondary qualified teachers (with NCE)", g("proportion_teachers_nce_juniorsec"), i("num_junior_secondary_school_teachers_nce", "num_junior_secondary_school_teachers"), "100%", g("target_num_teachers")],
                ["Percentage of primary school teachers who participated in training in the past 12 months", g("proportion_teachers_training_last_year_primary"), i("num_teachers_with_training_primary", "num_primary_school_teachers"), "100%", g("target_num_teachers")],
                ["Percentage of junior secondary school teachers who participated in training in the past 12 months", g("proportion_teachers_training_last_year_juniorsec"), i("num_teachers_with_training_juniorsec", "num_junior_secondary_school_teachers"), "100%", g("target_num_teachers")],
	    ],),
	    ('Institutional Development',[
                ["Percentage of primary schools that have delayed teacher payments in the past 12 months", g("proportion_schools_delay_pay_primary"), h("num_schools_delay_pay_primary", "num_primary_schools_primary"), "0%", "0"],
                ["Percentage of junior secondary schools that have delayed teacher payments in the past 12 months", g("proportion_schools_delay_pay_juniorsec"), h("num_schools_delay_pay_juniorsec", "num_junior_secondary_schools"), "0%", "0"],
                ["Percentage of primary schools that have missed teacher payments in the past 12 months", g("proportion_schools_missed_pay_primary"), h("num_schools_missed_pay_primary", "num_primary_schools)"), "0%", "0"],
                ["Percentage of junior secondary schools that have missed teacher payments in the past 12 months", g("proportion_schools_missed_pay_juniorsec"), h("num_schools_missed_pay_juniorsec", "num_junior_secondary_schools)"), "0%", "0"],
            ],),
            ('Curriculum Issues', [
                ["Textbook to pupil ratio (primary)", g("num_textbooks_per_pupil_primary"), None, "4"],
                ["Textbook to pupil ratio (junior secondary)", g("num_textbooks_per_pupil_juniorsec"), None, "4"],
                ["Percentage of primary schools where exercise books are provided to students", g("proportion_provide_exercise_books_primary"), h("num_provide_exercise_books_primary", "num_primary_schools"), "100%", g("target_num_schools")],
                ["Percentage of junior secondary schools where exercise books are provided to students", g("proportion_provide_exercise_books_juniorsec"), h("num_provide_exercise_books_juniorsec", "num_juniorsec_schools"), "100%", g("target_num_schools")],
                ["Percentage of primary schools where pens/pencils are provided to students", g("proportion_provide_pens_pencils_primary"), h("num_provide_pens_pencils_primary", "num_primary_schools"), "100%", g("target_num_schools")],
                ["Percentage of junior secondary schools where pens/pencils are provided to students", g("proportion_provide_pens_pencils_juniorsec"), h("num_provide_pens_pencils_juniorsec", "num_juniorsec_schools"), "100%", g("target_num_schools")],
                ["Percentage of primary schools that follow the National UBE Curriculum", g("proportion_natl_curriculum_primary"), h("num_natl_curriculum_primary", "num_primary_schools"), "100%", g("target_num_schools")],
                ["Percentage of junior secondary schools that follow the National UBE Curriculum", g("proportion_natl_curriculum_juniorsec"), h("num_natl_curriculum_juniorsec", "num_juniorsec_schools"), "100%", g("target_num_schools")],
                ["Percentage of primary schools where each teacher has a teaching guidebook for every subject", g("proportion_teachers_with_teacher_guide_primary"), h("num_teachers_with_teacher_guide_primary", "num_primary_schools"), "100%", g("target_num_schools")],
                ["Percentage of junior secondary schools where each teacher has a teaching guidebook for every subject", g("proportion_teachers_with_teacher_guide_juniorsec"), h("num_teachers_with_teacher_guide_juniorsec", "num_juniorsec_schools"), "100%", g("target_num_schools")],
                ["Percentage of primary schools with a functioning library", g("proportion_schools_functioning_library_primary"), h("num_schools_functioning_library_primary", "num_primary_schools"), "100%", g("target_num_schools")],
                ["Percentage of junior secondary schools with a functioning library", g("proportion_schools_functioning_library_juniorsec"), h("num_schools_functioning_library_juniorsec", "num_juniorsec_schools"), "100%", g("target_num_schools")],
            ],),
            ('Efficiency (flow rates)', [
                ["Drop out rate", "N/A", None, "0%"],
                ["Transition rate (primary to junior secondary) for boys", g("transition_rate_primary_to_js1_male"), None, "100%"],
                ["Transition rate (primary to junior secondary) for girls", g("transition_rate_primary_to_js1_female"), None, "100%"],
                ["Repetition rate (primary) for boys", g("repetition_rate_primary_male"), None, "0%"],
                ["Repetition rate (primary) for girls", g("repetition_rate_primary_female"), None, "0%"],
	    ],),
            ('Learning Outcomes', [
                ["Literacy rate of 15-24 year olds (men and women)", g("literacy_rate"), None, "100%"],
            ],),
        ],
        'water': [
            ('Type', [
                ["Number of boreholes and tube wells", g("num_boreholes_and_tubewells"), None, ""],
                ["Number of developed and treated spring and surface water", g("num_developed_and_treated_or_protected_surface_or_spring_water"), None, ""],
                ["Number of protected dug wells", g("num_protected_dug_wells"), None, ""],
                ["Number of other types of protected water sources", g("num_other_protected_sources"), None, ""],
                ["Number of assessed unprotected water sources", g("num_mapped_unprotected_sources"), None, ""],
                ["Total number of water sources", g("num_water_points"), None, ""],
            ],),
            ('Maintenance', [
                ["Percentage of boreholes, protected or treated sources that are poorly maintained", g("proportion_protected_water_points_non_functional"), i("num_protected_water_sources_non_functional", "num_protected_water_sources"), ""],
            ]),
            ('Population Served', [
                ["Population served per well-maintained borehole, protected or treated water source", g("population_served_per_protected_and_functional_water_source"), None, ""],
                ["Population served per borehole, protected or treated water source (whether or not it is well-maintained)", g("population_served_per_all_water_sources"), None, ""],
            ]),
            ('Lift Mechanisms for Boreholes and Tube Wells', [
                ["Percentage of boreholes and tube wells with a non-motorized lift (human or animal-powered)", g("proportion_boreholes_tubewells_manual"), i("num_boreholes_tubewells_manual", "num_boreholes_and_tubewells"), ""],
                ["Percentage of boreholes and tube wells with a motorized lift", g("proportion_boreholes_tubewells_non_manual"), i("num_boreholes_tubewells_non_manual", "num_boreholes_and_tubewells"), ""],
                ["Percentage of boreholes and tube wells with a diesel lift", g("proportion_boreholes_tubewells_diesel"), i("num_boreholes_tubewells_diesel", "num_boreholes_and_tubewells"), ""],
                ["Percentage of boreholes and tube wells with an electric motor lift", g("proportion_boreholes_tubewells_electric"), i("num_boreholes_tubewells_electric", "num_boreholes_and_tubewells"), ""],
                ["Percentage of boreholes and tube wells with a solar lift", g("proportion_boreholes_tubewells_solar"), i("num_boreholes_tubewells_solar", "num_boreholes_and_tubewells"), ""],
            ],),
            ('Poorly Maintained Lift Mechanisms for Boreholes and Tube Wells', [
                ["Percentage of non-motorized (human or animal-powered) lifts that are poorly maintained", g("proportion_boreholes_tubewells_manual_non_functional"), i("num_boreholes_tubewells_manual_non_functional", "num_boreholes_tubewells_manual"), ""],
                ["Percentage of all motorized lifts that are poorly maintained", g("proportion_boreholes_tubewells_non_manual_non_functional"), i("num_boreholes_tubewells_non_manual_non_functional", "num_boreholes_tubewells_non_manual"), ""],
                ["Percentage of diesel-powered lifts that are poorly maintained", g("proportion_boreholes_tubewells_diesel_non_functional"), i("num_boreholes_tubewells_diesel_non_functional", "num_boreholes_tubewells_diesel"), ""],
                ["Percentage of electrically-powered lifts that are poorly maintained", g("proportion_boreholes_tubewells_electric_non_functional"), i("num_boreholes_tubewells_electric_non_functional", "num_boreholes_tubewells_electric"), ""],
                ["Percentage of solar-powered lifts that are poorly maintained", g("proportion_boreholes_tubewells_solar_non_functional"), i("num_boreholes_tubewells_solar_non_functional", "num_boreholes_tubewells_solar"), ""],
            ]),
        ],
    }
    return example.pop(sector_slug, [])
