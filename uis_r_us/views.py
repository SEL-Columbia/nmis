from django.shortcuts import render_to_response
from django.template import RequestContext
from django.http import HttpResponseRedirect
from django.http import HttpResponse
from django.contrib.auth.decorators import login_required
from django.forms.models import model_to_dict
from display_defs.models import FacilityTable, MapLayerDescription
from nga_districts.models import LGA, Zone, State
from django.db.models import Count
import json

@login_required
def dashboard(request, reqpath):
    if request.method == "POST":
        lgaid = request.POST['lga']
        if LGA.objects.filter(unique_slug=lgaid).count() > 0:
            return HttpResponseRedirect("/~%s" % lgaid)
        else:
            return HttpResponseRedirect("/~")
    context = RequestContext(request)
    context.data_loading_count = LGA.objects.filter(data_load_in_progress=True).count()
    context.site_title = "NMIS Nigeria"
    lga = None
    context.active_districts = active_districts()
    context.nav_zones = get_nav_zones(filter_active=True)
    mls = []
    for map_layer in MapLayerDescription.objects.all():
        mls.append(model_to_dict(map_layer))
    context.layer_details = json.dumps(mls)
    if not reqpath == "":
        req_lga_id = reqpath.split("/")[0]
        try:
            lga = LGA.objects.get(unique_slug=req_lga_id)
        except:
            lga = None
        if lga == None:
            return HttpResponseRedirect("/~")
    if lga == None:
        return country_view(context)
    else:
        context.lga = lga
        return lga_view(context)

def get_nav_zones(filter_active=False):
    zone_list = Zone.objects.all().values('id', 'name')
    zones = {}
    for zone in zone_list:
        zid = zone.pop('id')
        zone['states'] = []
        zones[zid] = zone

    state_list = State.objects.all().values('id', 'zone_id', 'name')
    if filter_active:
        lga_list = LGA.objects.annotate(facility_count=Count('facilities')). \
                        filter(facility_count__gt=0). \
                        values('unique_slug', 'name', 'state_id')
    else:
        lga_list = LGA.objects.all().values('unique_slug', 'name', 'state_id')
    states = {}
    for state in state_list:
        sid = state.pop('id')
        zid = state.pop('zone_id')
        state['lgas'] = []
        states[sid] = state
        zones[zid]['states'].append(state)
    for lga in lga_list:
        sid = lga.pop('state_id')
        states[sid]['lgas'].append(lga)
    for state in state_list:
        state['lga_count'] = len(state['lgas'])
    return zone_list

def get_nav_zones_inefficient():
    zones = Zone.objects.all()
    nav_list = []
    for zone in zones:
        nav_list.append({
            'name': zone.name,
            'states': state_data(zone)
        })
    return nav_list

def state_data(zone):
    state_l = []
    for state in zone.states.all():
        state_lgas = state.lgas.all().values('name', 'unique_slug')
        state_l.append({
            'name': state.name,
            'lgas': state_lgas
        })
    return state_l

def country_view(context):
    context.site_title = "Nigeria"
    return render_to_response("ui.html", context_instance=context)

def lga_view(context):
    context.site_title = "LGA View"
    context.lga_id = "'%s'" % context.lga.unique_slug
    return render_to_response("ui.html", context_instance=context)


from utils.csv_reader import CsvReader
import os
from django.conf import settings

def variable_data(request):
    sectors = []
    for sector_table in FacilityTable.objects.all():
        sectors.append(sector_table.display_dict)
    overview_csv = CsvReader(os.path.join(settings.PROJECT_ROOT, "data","table_definitions", "overview.csv"))
    overview_data = []
    for z in overview_csv.iter_dicts():
        overview_data.append(z)
    return HttpResponse(json.dumps({
        'sectors': sectors,
        'overview': overview_data
    }))

def active_districts():
    lgas = LGA.objects.filter(data_loaded=True)
#    lgas = LGA.objects.annotate(facility_count=Count('facilities')).filter(facility_count__gt=0)
    from collections import defaultdict
    states = defaultdict(list)
    for lga in lgas:
        states[lga.state].append(lga)
        
    output = []
    for state, lgas in states.items():
        statelgas = []
        for lga in lgas:
            statelgas.append(
                (lga.name, lga.unique_slug)
                )
        output.append((state.name, statelgas))
    return output

def all_mustache_templates(request):
    import os, glob
    cur_file = os.path.abspath(__file__)
    cur_dir = os.path.dirname(cur_file)
    all_templates = glob.glob(os.path.join(cur_dir, 'mustache', '*.html'))
    templates = []
    for template_path in all_templates:
        with open(template_path, 'r') as f:
            templates.append(f.read())
    return HttpResponse('\n'.join(templates))

def mustache_template(request, template_name):
    import os
    cur_file = os.path.abspath(__file__)
    cur_dir = os.path.dirname(cur_file)
    template_path = os.path.join(cur_dir, 'mustache', '%s.html' % template_name)
    if not os.path.exists(template_path):
        return HttpResponse('{"ERROR":"No such template: %s"}' % template_name)
    else:
        with open(template_path, 'r') as f:
            return HttpResponse(f.read())

def modes(request, mode_data):
    return render_to_response("modes.html")

def google_help_doc(request):
    google_doc_zip_url = "https://docs.google.com/document/d/1Dze4IZGr0IoIFuFAI_ohKR5mYUt4IAn5Y-uCJmnv1FQ/export?format=zip&id=1Dze4IZGr0IoIFuFAI_ohKR5mYUt4IAn5Y-uCJmnv1FQ&token=AC4w5VhqxjgX9xFvekZGlLQILEIfrl1wSg%3A1312574701000&tfe=yh_186"
    cached_doc_path = os.path.join("docs", "cached_doc.html")
    if not os.path.exists(cached_doc_path):
        import urllib, zipfile
        f = urllib.urlopen(google_doc_zip_url)
        zf_path = "%s.zip" % cached_doc_path
        with open(zf_path, 'w') as foutput:
            foutput.write(f.read())
        z = zipfile.ZipFile(zf_path)
        for name in z.namelist():
            with open(cached_doc_path, 'w') as html_file:
                html_file.write(z.read(name))
    with open(cached_doc_path) as f:
        return HttpResponse(f.read())


def test_module(request, module_id):
    context = RequestContext(request)
    context.module = module_id
    context.modules = ['modes', 'tabulations', 'facility_tables', 'display']
    if module_id in context.modules:
        return render_to_response("test_module.html", context_instance=context)
    else:
        return HttpResponseRedirect("/test/modes")

def test_map(request):
    return render_to_response("test_map.html")

def temp_facility_buildr(lga):
    lga_data = lga.get_latest_data(for_display=True)
    def g(slug):
        return lga_data.get(slug, None)
    ilist = []
    health_indicators = [
            ["Health posts and dispensaries", g("num_level_1_health_facilities")],
            ["Primary health clinics", g("num_level_2_health_facilities")],
            ["Primary health centres", g("num_level_3_health_facilities")],
            ["Comprehensive health centres & hospitals", g("num_level_4_health_facilities")],
            ["Other health facillities", g("num_level_other_health_facilities")],
            ["Skilled health provider per 1,000 population ", g("num_skilled_health_providers_per_1000")],
            ["CHEWs per 1,000 population", g("num_chews_per_1000")],
        ]
    ilist.append(("health", "Health Facilities", health_indicators, g("num_health_facilities")))

    education_indicators = [
            ["Preprimary and primary", g("num_preprimary_primary_level")],
            ["Primary", g("num_primary_level")],
            ["Primary and junior secondary", g("num_primary_js_level")],
            ["Junior secondary", g("num_js_level")],
            ["Junior and senior secondary", g("num_js_ss_level")],
            ["Senior secondary", g("num_ss_level")],
            ["Primary, junior and senior secondary", g("num_primary_js_ss_level")],
            ["Pupil to teacher ratio", g("student_teacher_ratio_lga")],
            ["Teachers with NCE qualification", g("proportion_teachers_nce")],
            ["Classrooms in need of major repairs", g("proportion_classrooms_need_major_repair")],
        ]
    ilist.append(("education", "Schools", education_indicators, g("num_schools")))

    water_indicators = [
    	    ["Total number of water sources", g("num_water_points")],
            ["Developed/treated spring and surface water", g("proportion_developed_and_treated_or_protected_surface_or_spring_water")],
            ["Protected dug wells", g("proportion_protected_dug_wells")],
            ["Bore holes and tube wells", g("proportion_boreholes_and_tubewells")],
            ["Bore holes and tube wells with non-motorized lift mechanisms", g("proportion_boreholes_tubewells_manual")],
            ["Bore holes and tube wells with motorized lift mechanisms", g("proportion_boreholes_tubewells_non_manual")],
            ["Bore holes, protected and treated sources that are well-maintained", g("proportion_protected_water_points_functional")],
            ["Population served per well-maintained bore hole, protected or treated source", g("population_served_per_protected_and_functional_water_source")],
        ]
    ilist.append(("water", "Water Points", water_indicators, g("num_water_points")))
    return ilist

def new_dashboard(request, lga_id):
    context = RequestContext(request)
    try:
        lga = LGA.objects.get(unique_slug=lga_id)
    except:
        return HttpResponseRedirect("/")
    lga_data = lga.get_latest_data(for_display=True)
    def g(slug):
        return lga_data.get(slug, None)
    context.facility_indicators = temp_facility_buildr(lga)
    context.mdg_indicators = [
        ("Goal 1: Eradicate extreme poverty and hunger", [
            [None, "Proportion of children under five who are underweight (weight-for-age)", g("prevalence_of_underweight_children_u5")],
            [None, "Proportion of children under five with stunting (height-for-age)", g("prevalence_of_stunting_children_u5")],
            [None, "Proportion of children under five with wasting", g("prevalence_of_wasting_children_u5")],
        ]),
        ("Goal 2: Achieve universal primary education", [
            [None, "Net enrollment ratio for primary education", g("net_enrollment_ratio_primary_education")],
            [None, "Gross enrollment ratio in primary education", g("gross_enrollment_rate_primary")],
            [None, "Net enrollment ratio for secondary education", g("net_enrollment_ratio_secondary_education")],
            [None, "Gross enrollment ratio in secondary education", g("gross_enrollment_ratio_secondary_education")],
            [None, "Literacy rate of 15-24 year olds (men and women)", g("literacy_rate")],
        ]),
        ("Goal 3: Promote gender equality and empower women", [
            [None, "Ratio of boys to girls in primary schools", g("boy_girl_ratio_primary")],
            [None, "Ratio of boys to girls in junior secondary schools", g("boy_girl_ratio_js")],
            [None, "Ratio of boys to girls in senior secondary schools ", g("boy_girl_ratio_secondary_school")],
        ]),
        ("Goal 4: Reduce child mortality", [
            [None, "DPT 3 immunization rate", g("immunization_rate_dpt3")],
            [None, "Under five mortality rate per 1000 live births", g("mortality_rate_children_u5")],
            [None, "Proportion of children under five years of age with diarrhea who received oral rehydration therapy", g("proportion_of_children_u5_diarrhea_treated_with_ors_med")],
        ]),
        ("Goal 5: Improve maternal health", [
            [None, "Proportion of births attended by a skilled health provider", g("proportion_of_births_by_skilled_health_personnel")],
            [None, "Proportion of pregnant women tested for HIV", g("percentage_pregnant_women_tested_for_hiv_during_pregnancy")],
            [None, "Proportion of women who attended at least four antenatal visits", g("percent_antenatal_care_four")],
        ]),
        ("Goal 6: Combat HIV/AIDS, malaria and other diseases", [
            [None, "Proportion of children under five sleeping under insecticide-treated bednets", g("proportion_children_u5_sleeping_under_itns")],
            [None, "Proportion of men and women ever tested for HIV", g("percentage_of_individuals_tested_for_hiv_ever")],
        ]),
        ("Goal 7: Ensure environmental sustainability", [
            [None, "Proportion of households with access to an improved water source", g("percentage_households_with_access_to_improved_water_sources")],
            [None, "Proportion of households with access to improved sanitation", g("percentage_households_with_access_to_improved_sanitation")],
        ]),
    ]
    context.navs = [{ 'url': '/', 'name': 'Home' },
                    { 'url': '/new_dashboard/%s' % lga.unique_slug,
                        'name': lga.name,
                        'active': True}]
    #tmp deactivating breadcrumb
    context.navs = False
    context.lga = lga
    context.state = lga.state
    context.profile_variables = [
        ["LGA Chairman", g("chairman_name")],
        ["LGA Secretary", g("secretary_name")],
        ["Population (2006)", g("pop_population")],
        ["Area (square km)", g("area_sq_km")],
        ["Distance from capital (km)", g("state_capital_distance")],
    ]
    return render_to_response("new_dashboard.html", context_instance=context)

def tmp_variables_for_sector(sector_slug, lga):
    lga_data = lga.get_latest_data(for_display=True)
    def g(slug):
        return lga_data.get(slug, None)
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
                ["Facilities that offer care 24 hours a day, 7 days a week", g("num_health_facilities_open_24_7"), g("proportion_health_facilities_open_24_7"), g("target_health_facilities_open_24_7"), g("target_all_but_level_1_health_facilities")],
            ],),
            ('Staffing', [
                ["Total number of doctors in the LGA", g("num_doctors"), None, g("target_num_doctors"), None],
                ["Total number of midwives and nurse-midwives in the LGA", g("num_nursemidwives_midwives"), None, g("target_num_midwives_nursemidwives"), None],
                ["Total number of nurses in the LGA", g("num_nurses"), None, g("target_num_nurses"), None],
                ["Total number of CHEWs (Jr. and Sr.) in the LGA", g("num_chews"), None, g("target_num_chews"), None],
                ["Total number of laboratory technicians in the LGA", g("num_lab_techs"), None, g("target_num_lab_techs"), None],
                ["Number of facilities where all salaried staff were paid during the last pay period", g("num_staff_paid"), g("proportion_staff_paid"), g("target_total_health_facilities"), "100%"],
            ],),
            ('Child Health', [
                ["Number of facilities that offer routine immunization", g("num_health_facilities_routine_immunization"), g("proportion_health_facilities_routine_immunization"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities that offer growth monitoring", g("num_growth_monitoring"), g("proportion_growth_monitoring"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities that offer malaria treatment", g("num_malaria_treatment"), g("proportion_malaria_treatment"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities that offer deworming", g("num_deworming"), g("proportion_deworming"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities that do not charge any fees for child health services", g("num_no_user_fees_child_health"), g("proportion_no_user_fees_child_health"), g("target_total_health_facilities"), "100%"],
            ],),
            ('Maternal Health', [
                ["Number of facilities that offer antenatal care", g("num_antenatal"), g("proportion_antenatal"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities with at least one skilled birth attendant", g("num_at_least_1_sba"), g("proportion_at_least_1_sba"), g("target_health_facilities_open_24_7"), g("target_all_but_level_1_health_facilities")],
                ["Number of facilities that offer delivery services 24 hours a day, 7 days a week", g("num_delivery_24_7"), g("proportion_delivery_24_7"), g("target_health_facilities_open_24_7"), g("target_all_but_level_1_health_facilities")],
                ["Number of facilities with access to emergency transport services", g("num_access_functional_emergency_transport"), g("proportion_access_functional_emergency_transport"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities that offer family planning services", g("num_family_planning"), g("proportion_family_planning"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities that do not charge any fees for maternal health services", g("num_delivery_no_user_fees"), g("proportion_delivery_no_user_fees"), g("target_total_health_facilities"), "100%"],
            ],),
            ('Malaria', [
                ["Number of facilities that perform malaria testing (RDT or microscopy)", g("num_malaria_testing"), g("proportion_malaria_testing"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities that offer ACT-based treatment for malaria", g("num_act_treatment_for_malaria"), g("proportion_act_treatment_for_malaria"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities that offer malaria prophylaxis during pregnancy", g("num_malaria_prevention_pregnancy"), g("proportion_malaria_prevention_pregnancy"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities that provide bednets", g("num_offer_bednets"), g("proportion_offer_bednets"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities that do not charge and fees for malaria-related services", g("num_no_user_fees_malaria"), g("proportion_no_user_fees_malaria"), g("target_total_health_facilities"), "100%"],
            ],),
            ('Infrastructure', [
                ["Number of facilities with access to an improved water source", g("num_water_access"), g("proportion_water_access"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities with functioning improved sanitation", g("num_functional_sanitation"), g("proportion_functional_sanitation"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities with access to some form of power source", g("num_any_power_access"), g("proportion_any_power_access"), g("target_total_health_facilities"), "100%"],
                ["Number of facilities with mobile phone coverage somewhere on the premises", g("num_mobile_coverage"), g("proportion_mobile_coverage"), g("target_total_health_facilities"), "100%"],
            ],),
            ('Equipment and Supplies', [
                ["Number of facilities that experienced NO essential medication stock-outs in the past 3 months", g("num_no_stockout_essential_meds"), g("proportion_no_stockout_essential_meds"), g("target_total_health_facilities"), "100%"],
            ],),
        ],
        'education': [
            ('Facilities', [
                ["Number of primary schools", g("num_primary_schools"), None, g("target_num_primary_schools")],
                ["Number of junior secondary schools", g("num_junior_secondary_schools"), None, g("target_num_junior_secondary_schools")],
                ["Number of senior secondary schools", g("num_senior_secondary_schools"), None, g("target_num_senior_secondary_schools")],
                ["Total number of schools", g("num_schools"), None, g("target_num_schools")],
            ],),
            ('Access', [
                ["Primary net intake rate (NIR) for boys", "N/A", None, "N/A"],
                ["Primary net intake rate (NIR) for girls", "N/A", None, "N/A"],
                ["Junior secondary net intake rate (NIR) for boys", "N/A", None, "N/A"],
                ["Junior Secondary net intake rate (NIR) for girls", "N/A", None, "N/A"],
                ["Percentage of schools > 1km from catchement area", g("proportion_schools_1kmplus_catchment"), g("num_schools_1kmplus_catchment") + "/" + g("num_schools"), "0%", "0"],
                ["Percentage of primary schools > 1km from secondary schools", g("proportion_primary_schools_1kmplus_ss"), g("num_primary_schools_1kmplus_ss") + "/" + g("num_primary_schools"), "0%", "0"],
                ["Percentage of schools with students living farther than 3km", g("proportion_students_3kmplus"), g("num_students_3kmplus") + "/" + g("num_schools"), "0%", "0"],
            ],),
            ('Participation', [
                ["Primary net enrollment rate (NER) for boys", g("net_enrollment_rate_boys_primary"), None, "100%"],
                ["Primary net enrollment rate (NER) for girls", g("net_enrollment_rate_girls_primary"), None, "100%"],
                ["Junior secondary net enrollment rate (NER) for boys", g("net_enrollment_rate_boys_js"), None, "100%"],
                ["Junior secondary net enrollment rate (NER) for girls", g("net_enrollment_rate_girls_js"), None, "100%"],
            ],),
            ('Infrastructure', [
                ["Water & Santation"],
                ["Percentage of schools with access to potable water", g("proportion_schools_potable_water"), g("num_schools_potable_water") + "/" + g("num_schools"), "100%", g("target_num_schools")],
                ["Percentage of schools with improved sanitation", g("proportion_schools_improved_sanitation"), g("num_schools_improved_sanitation") + "/" + g("num_schools"), "100%", g("target_num_schools")],
                ["Percentage of schools with separate toilets for boys and girls", g("proportion_schools_gender_sep_toilet"), g("num_schools_gender_sep_toilet") + "/" + g("num_schools"), "100%", g("target_num_schools")],
                ["Pupil to toilet ratio", g("pupil_toilet_ratio"), None, "35"],
                ["Building Structure"],
                ["Percentage of schools with access to power", g("proportion_schools_power_access"), g("num_schools_power_access") + "/" + g("num_schools"), "100%", g("target_num_schools")],
                ["Percentage of classrooms needing major repair", g("proportion_classrooms_need_major_repair"), g("number_classrooms_need_major_repair") + "/" + g("num_classrooms_lga"), "0%", "0"],
                ["Percentage of classrooms needing minor repair", g("proportion_classrooms_need_minor_repair"), g("number_classrooms_need_minor_repair") + "/" + g("num_classrooms_lga"), "0%", "0"],
                ["Health & Safety"],
                ["Percentage of schools with a dispensary/health clinic", g("proportion_schools_with_clinic_dispensary"), g("num_schools_with_clinic_dispensary") + "/" + g("num_schools"), "100%", g("target_num_schools")],
                ["Percentage of schools with a first aid kit", g("proportion_schools_with_first_aid"), g("num_schools_with_first_aid") + "/" + g("num_schools"), "100%", g("target_num_schools")],
                ["Percentage of schools with a fence in good condition", g("proportion_schools_fence_good_cond"), g("num_schools_fence_good_cond") + "/" + g("num_schools"), "100%", g("target_num_schools")],
                ["Learning Environment"],
                ["Pupil to classroom ratio", g("student_classroom_ratio_lga"), None, "35"],
                ["Percentage of schools that teach outside because there are not enough classrooms", g("proportion_schools_hold_classes_outside"), g("num_schools_hold_classes_outside") + "/" + g("num_schools"), "0%", "0"],
                ["Percentage of schools with double shifts", g("proportion_schools_two_shifts"), g("num_schools_two_shifts") + "/" + g("num_schools"), "0%", "0"],
                ["Percentage of schools with multi-grade classrooms", g("proportion_schools_multigrade_classrooms"), g("num_schools_multigrade_classrooms") + "/" + g("num_schools"), "0%", "0"],
            ],),
            ('Furniture', [
                ["Percentage of schools with a chalkboard in every classroom", g("proportion_schools_chalkboard_all_rooms"), g("num_schools_chalkboard_all_rooms") + "/" + g("num_schools"), "100%", g("target_num_schools")],
                ["Pupil to bench ratio", g("pupil_bench_ratio_lga"), None, "&#8804; 3"],
                ["Pupil to desk ratio", g("pupil_desk_ratio_lga"), None, "&#8804; 1"],
            ],),
            ('Staffing and Institutional Development', [
                ["Primary school pupil to teacher ratio", g("primary_school_pupil_teachers_ratio_lga"), None, "&#8804; 35"],
                ["Junior secondary school pupil to teacher ratio", g("junior_secondary_school_pupil_teachers_ratio_lga"), None, "&#8804; 35"],
                ["Teaching to non-teaching staff ratio", g("teacher_nonteachingstaff_ratio_lga"), None, "N/A"],
                ["Percentage of qualified teachers (with NCE)", g("proportion_teachers_nce"), g("num_teachers_nce"), "100%", g("target_num_teachers")],
                ["Percentage of teachers who participated in training in the past year", g("proportion_teachers_training_last_year"), g("num_teachers_training_last_year") + "/" + g("num_teachers"), "100%", g("target_num_teachers")],
                ["Percentage of schools that have delayed teacher payments", g("proportion_schools_delay_pay"), g("num_schools_delay_pay") + "/" + g("num_schools"), "0%", "0"],
                ["Percentage of schools that have missed teacher payments", g("proportion_schools_missed_pay"), g("num_schools_missed_pay") + "/" + g("num_schools"), "0%", "0"],
            ],),
            ('Curriculum', [
                ["Textbook to pupil ratio", g("num_textbooks_per_pupil"), None, "4"],
                ["Percentage of schools where exercise books are provided", g("proportion_provide_exercise_books"), g("num_provide_exercise_books") + "/" + g("num_schools"), "100%", g("target_num_schools")],
                ["Percentage of schools where pens/pencils are provided", g("proportion_provide_pens_pencils"), g("num_provide_pens_pencils") + "/" + g("num_schools"), "100%", g("target_num_schools")],
                ["Percentage of schools that follow the National UBE Curriculum", g("proportion_natl_curriculum"), g("num_natl_curriculum") + "/" + g("num_schools"), "100%", g("target_num_schools")],
                ["Percentage of schools where each teacher has a teaching guidebook", g("proportion_teachers_with_teacher_guide"), g("num_teachers_with_teacher_guide") + "/" + g("num_schools"), "100%", g("target_num_schools")],
                ["Percentage of schools with a functioning library", g("proportion_schools_functioning_library"), g("num_schools_functioning_library") + "/" + g("num_schools"), "100%", g("target_num_schools")],
            ],),
            ('Efficiency', [
                ["Drop out rate", "N/A", None, "0%"],
                ["Transition rate (primary to junior secondary) for boys", g("transition_rate_primary_to_js1_male"), None, "100%"],
                ["Transition rate (primary to junior secondary) for girls", g("transition_rate_primary_to_js1_female"), None, "100%"],
                ["Repetition rate (primary) for boys", g("repetition_rate_primary_male"), None, "0%"],
                ["Repetition rate (primary) for girls", g("repetition_rate_primary_female"), None, "0%"],
                ["Literacy rate of 15-24 year olds (men and women)", g("literacy_rate"), None, "100%"],
            ],),
        ],
        'water': [
            ('Type', [
                ["Number of bore holes and tube wells", g("num_boreholes_and_tubewells"), None, ""],
                ["Number of developed and treated spring and surface water", g("num_developed_and_treated_or_protected_surface_or_spring_water"), None, ""],
                ["Number of protected dug wells", g("num_protected_dug_wells"), None, ""],
                ["Number of other types of protected water sources", g("num_other_protected_sources"), None, ""],
                ["Number of mapped unprotected sources", g("num_mapped_unprotected_sources"), None, ""],
                ["Total number of water sources", g("num_water_points"), None, ""],
            ],),
            ('Maintenance', [
                ["Percentage of bore holes, protected or treated sources that are poorly maintained", g("num_protected_water_sources_non_functional"), g("proportion_protected_water_points_non_functional"), ""],
            ]),
            ('Population Served', [
                ["Population served per well-maintained borehole, protected or treated source", g("population_served_per_protected_and_functional_water_source"), None, ""],
                ["Population severed per borehole, protected or treated source (whether or not it is well-maintained)", g("population_served_per_all_water_sources"), None, ""],
            ]),
            ('Lift Mechanisms for Bore Holes and Tube Wells', [
                ["Percentage that are non-motorized (human or animal-powered)", g("num_boreholes_tubewells_manual"), g("proportion_boreholes_tubewells_manual"), ""],
                ["Percentage with a diesel lift", g("num_boreholes_tubewells_diesel"), g("proportion_boreholes_tubewells_diesel"), ""],
                ["Percentage with an electric motor lift", g("num_boreholes_tubewells_electric"), g("proportion_boreholes_tubewells_electric"), ""],
                ["Percentage with a solar lift", g("num_boreholes_tubewells_solar"), g("proportion_boreholes_tubewells_solar"), ""],
                ["Percentage with a motorized lift", g("num_boreholes_tubewells_non_manual"), g("proportion_boreholes_tubewells_non_manual"), ""],
            ],),
            ('Poorly Maintained Lift Mechanisms for Bore Holes and Tube Wells', [
                ["Percentage of non-motorized (human or animal-powered) lifts that are poorly maintained", g("num_boreholes_tubewells_manual_non_functional"), g("proportion_boreholes_tubewells_manual_non_functional"), ""],
                ["Percentage of diesel-powered lifts that are poorly maintained", g("num_boreholes_tubewells_diesel_non_functional"), g("proportion_boreholes_tubewells_diesel_non_functional"), ""],
                ["Percentage of electrically-powered lifts that are poorly maintained", g("num_boreholes_tubewells_electric_non_functional"), g("proportion_boreholes_tubewells_electric_non_functional"), ""],
                ["Percentage of solar-powered lifts that are poorly maintained", g("num_boreholes_tubewells_solar_non_functional"), g("proportion_boreholes_tubewells_solar_non_functional"), ""],
                ["Percentage of all motorized lifts that are poorly maintained",g("num_boreholes_tubewells_non_manual_non_functional"), g("proportion_boreholes_tubewells_non_manual_non_functional"), ""],
            ]),
        ],
    }
    return example.pop(sector_slug, [])

def new_sector_overview(request, lga_id, sector_slug):
    try:
        lga = LGA.objects.get(unique_slug=lga_id)
    except:
        return HttpResponseRedirect("/new_dashboard/")
    if sector_slug not in ["education", "health", "water"]:
        return HttpResponseRedirect("/new_dashboard/")
    context = RequestContext(request)
    context.lga = lga
    context.navs = [{ 'url': '/', 'name': 'Home' },
                    { 'url': '/new_dashboard/%s' % lga.unique_slug, 'name': lga.name },
                    { 'url': '/new_dashboard/%s/%s' % (lga.unique_slug, sector_slug),
                        'name': sector_slug.capitalize(),
                        'active': True }]
    #tmp deactivating breadcrumb
    context.navs = False
    context.table_data = tmp_variables_for_sector(sector_slug, lga)
    context.sector = sector_slug
    return render_to_response("new_sector_overview.html", context_instance=context)
