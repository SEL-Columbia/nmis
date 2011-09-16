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
    context.modules = ['modes', 'tabulations']
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
        #proof of concept that lga is accessible from here.
#            ["lga", lga.name, 0],
            ["hi1", "Proportion L3 Health Facilities", g("proportion_level_3_health_facilities")],
            ["hi2", "Health Indicator 2", 223],
            ["hi3", "Health Indicator 3", 323],
            ["hi4", "Health Indicator 4", 423],
            ["hi5", "Health Indicator 5", 523],
            ["hi6", "Health Indicator 6", 623],
        ]
    ilist.append(("health", "Health Facilities", health_indicators, ))

    education_indicators = [
            ["ed1", "Education Indicator 1", 123],
            ["ed2", "Education Indicator 2", 223],
            ["ed3", "Education Indicator 3", 323],
            ["ed4", "Education Indicator 4", 423],
            ["ed5", "Education Indicator 5", 523],
        ]
    ilist.append(("education", "Schools", education_indicators,))

    water_indicators = [
            ["wa1", "Water Indicator 1", 123],
            ["wa2", "Water Indicator 2", 223],
            ["wa3", "Water Indicator 3", 323],
            ["wa4", "Water Indicator 4", 423],
            ["wa5", "Water Indicator 5", 523],
        ]
    ilist.append(("water", "Community Water Points", water_indicators,))
    return ilist

def new_dashboard(request, lga_id):
    context = RequestContext(request)
    try:
        lga = LGA.objects.get(unique_slug=lga_id)
    except:
        return HttpResponseRedirect("/")
    context.facility_indicators = temp_facility_buildr(lga)
    context.mdg_indicators = [
        ("Goal 2", [
            [None, "Students/teacher ratio for primary school [LGA]", 31.170243204578],
            [None, "Net enrollment ratio for primary education[LGA]", .389],
            [None, "Number of children secondary school going age", 19821.3211650392],
            [None, "Gross enrollment ratio in primary education[LGA]", 0.5684],
            [None, "Teacher to Classroom Ratio for primary schools(TCR)[LGA]", 3.13452914798206],
            [None, "% teachers with formal teaching qualification for secondary school[LGA]", 0.709],
        ])
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
                ["Health Posts / Dispensaries", g("num_level_1_health_facilities"), ""],
                ["Primary Care Clinics", g("num_level_2_health_facilities"), ""],
                ["Comprehensive Primary Care Centres", g("num_level_3_health_facilities"), ""],
                ["Hospitals", g("num_level_4_health_facilities"), ""],
                ["Facilities that offer care 24 hours a day, 7 days a week", g("num_health_facilities_open_24_7"), ""],
                ["Total number of facilities", g("num_health_facilities"), ""],
            ],),
            ('Staffing', [
                ["Total number of doctors in the LGA", g("num_doctors"), ""],
                ["Total number of midwives and nurse-midwives in the LGA", g("num_nursemidwives_midwives"), ""],
                ["Total number of nurses in the LGA", g("num_nurses"), ""],
                ["Total number of CHEWs (Jr. and Sr.) in the LGA", g("num_chews"), ""],
                ["Total number of laboratory technicians in the LGA", g("num_lab_techs"), ""],
                ["Total number of non-medical staff in the LGA", g("num_non_medical_staff"), ""],
                ["Number of facilities where all salaried staff were paid during the last pay period", g("num_staff_paid"), ""],
            ],),
            ('Child Health', [
                ["Number of facilities that offer routine immunization", g("num_health_facilities_routine_immunization"), ""],
                ["Number of facilities that offer growth monitoring", g("num_growth_monitoring"), ""],
                ["Number of facilities that offer malaria treatment", g("num_malaria_treatment"), ""],
                ["Number of facilities that offer deworming", g("num_deworming"), ""],
                ["Number of facilities that do not charge any fees for child health services", g("num_no_user_fees_child_health"), ""],
            ],),
            ('Maternal Health', [
                ["Number of facilities that offer antenatal care", g("num_antenatal"), ""],
                ["Number of facilities with at least one skilled birth attendant", g("num_at_least_1_sba"), ""],
                ["Number of facilities that offer services 24 hours a day, 7 days a week", g("num_delivery_24_7"), ""],
                ["Number of facilities with access to emergency transport services", g("num_access_functional_emergency_transport"), ""],
                ["Number of facilities that offer family planning services", g("num_family_planning"), ""],
                ["Number of facilities that do not charge any fees for maternal health services", g("num_delivery_no_user_fees"), ""],
            ],),
            ('Malaria', [
                ["Number of facilities that perform malaria testing (RDT or microscopy)", g("num_malaria_testing"), ""],
                ["Number of facilities that offer ACT-based treatment for malaria", g("num_act_treatment_for_malaria"), ""],
                ["Number of facilities that offer malaria prophylaxis during pregnancy", g("num_malaria_prevention_pregnancy"), ""],
                ["Number of facilities that provide bednets", g("num_offer_bednets"), ""],
                ["Number of facilities that do not charge and fees for malaria-related services", g("num_no_user_fees_malaria"), ""],
            ],),
            ('Infrastructure', [
                ["Number of facilities with access to an improved water source", g("num_water_access"), ""],
                ["Number of facilities with functioning improved sanitation", g("num_functional_sanitation"), ""],
                ["Number of facilities with access to some form of power source", g("num_any_power_source"), ""],
                ["Number of facilities with mobile phone coverage somewhere on the premises", g("num_mobile_coverage"), ""],
            ],),
            ('Equipment and Supplies', [
                ["Number of facilities that experienced NO essential medication stock-outs in the past 3 months", g("num_no_stockout_essential_meds"), ""],
            ],),
        ],
        'education': [
            ('Facilities', [
                ["Number of primary schools", g("num_primary_schools"), ""],
                ["Number of junior secondary schools", g("num_junior_secondary_schools"), ""],
                ["Number of senior secondary schools", g("num_senior_secondary_schools"), ""],
                ["Total number of schools", g("num_schools"), ""],
            ],),
            ('Access and Participation', [
                ["Primary net intake rate (NIR) for boys", "", ""],
                ["Primary net intake rate (NIR) for girls", "", ""],
                ["Junior secondary net intake rate (NIR) for boys", "", ""],
                ["Junior Secondary net intake rate (NIR) for girls", "", ""],
                ["Number of schools > 1km from catchement area", "", ""],
                ["Number of primary schools > 1km from secondary schools", "", ""],
                ["Number of schools with students living farther than 3km", "", ""],
                ["Primary net enrollment rate (NER) for boys", "", ""],
                ["Primary net enrollment rate (NER) for girls", "", ""],
                ["Junior secondary net enrollment rate (NER) for boys", "", ""],
                ["Junior secondary net enrollment rate (NER) for girls", "", ""],
            ],),
            ('Infrastructure', [
                ["Number of schools with access to power", "", ""],
                ["Number of schools with access to potable water", "", ""],
                ["Number of schools with improved sanitation", "", ""],
                ["Number of schools with separate toilets for boys and girls", "", ""],
                ["Pupil:toilet ratio", g("pupil_toilet_ratio"), ""],
                ["Pupil:classroom ratio", g("student_classroom_ratio_lga"), ""],
                ["Number of classrooms needing major repair", "", ""],
                ["Number of classrooms needing minor repair", "", ""],
                ["Number of schools that teach outside", "", ""],
                ["Number of schools with double shifts", "", ""],
                ["Number of schools with multi-grade classrooms", "", ""],
                ["Number of schools with a dispensary/health clinic", "", ""],
                ["Number of schools with a first aid kit", "", ""],
                ["Number of schools with a fence", "", ""],
            ],),
            ('Furniture', [
                ["Number of schools with a chalkboard in every classroom", "", ""],
                ["Pupil:bench ratio", "", ""],
                ["Pupil:desk ratio", "", ""],
            ],),
            ('Staffing and Institutional Development', [
                ["Primary school pupil:teacher ratio", "", ""],
                ["Junior secondary school pupil:teacher ratio", "", ""],
                ["Teaching:non-teaching staff ratio", g("teacher_nonteachingstaff_ratio_lga"), ""],
                ["Number of qualified teachers (with NCE)", g("num_teachers_nce"), ""],
                ["Number of teachers who participated in training in the past year", "", ""],
                ["Number of schools that have delayed teacher payments", "", ""],
                ["Number of schools that have missed teacher payments", "", ""],
            ],),
            ('Curriculum', [
                ["Textbooks per pupil", g("num_textbooks_per_pupil"), ""],
                ["Number of schools where exercise books are provided", "", ""],
                ["Number of schools where pens/pencils are provided", "", ""],
                ["Number of schools that follow the National UBE Curriculum", "", ""],
                ["Number of schools with teaching guidebooks", "", ""],
                ["Number of schools with a functioning library", "", ""],
            ],),
            ('Efficiency', [
                ["Drop out rate", "", ""],
                ["Transition rate (primary to junior secondary) for boys", "", ""],
                ["Transition rate (primary to junior secondary) for girls", "", ""],
                ["Repetition rate (primary) for boys", g("repetition_rate_primary_male"), ""],
                ["Repetition rate (primary) for girls", g("repetition_rate_primary_female"), ""],
                ["Literacy rate", g("literacy_rate"), ""],
            ],),
        ],
        'water': [],
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
    context.table_data = tmp_variables_for_sector(sector_slug, lga)
    context.sector = sector_slug
    return render_to_response("new_sector_overview.html", context_instance=context)
