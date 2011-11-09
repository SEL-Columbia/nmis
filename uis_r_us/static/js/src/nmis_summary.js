+function summaryDisplay(){
    function loadSummary(s){
        var params = s.params;
        var _env = {
            mode: 'summary',
            state: params.state,
            lga: params.lga
        };
        NMIS.LocalNav.iterate(function(sectionType, buttonName, a){
            // var env = {
            //     lga: lga,
            //     mode: facilitiesMode,
            //     state: state,
            //     sector: _sector
            // };
            var env = _.extend({}, _env)
            log(env.mode);
            env[sectionType] = buttonName;
            log(sectionType, buttonName, a, NMIS.urlFor(env));
            a.attr('href', NMIS.urlFor(env));
        });
    }
    dashboard = $.sammy(function(){
        this.get("/nmis~/:state/:lga/summary/?", loadSummary);
        this.get("/nmis~/:state/:lga/summary/:sector/?", loadSummary);
        this.get("/nmis~/:state/:lga/summary/:sector/:subsector/?", loadSummary);
        this.get("/nmis~/:state/:lga/summary/:sector/:subsector/:indicator/?", loadSummary);
    });
}()
