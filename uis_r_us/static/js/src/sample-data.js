var sampleData = {
    "facility_variables": {
        "overview": [],
        "sectors": [
            {
                "subgroups": [
                    {
                        "name": "All",
                        "slug": "all"
                    },
                    {
                        "name": "Subsector 2",
                        "slug": "ss2"
                    }
                ],
                "name": "Health",
                "columns": [
                    {
                        "descriptive_name": "name",
                        "description": "name",
                        "display_order": 0,
                        "name": "name",
                        "clickable": false,
                        "slug": "name",
                        "subgroups": [
                            "all"
                        ]
                    },
                    {
                        "descriptive_name": "s1v1",
                        "description": "s2v1",
                        "display_order": 1,
                        "name": "s1v1",
                        "clickable": false,
                        "slug": "s1v1",
                        "subgroups": [
                            "all",
                            "ss2"
                        ]
                    },
                    {
                        "descriptive_name": "s1v3",
                        "description": "s2v3",
                        "display_order": 2,
                        "name": "s1v3",
                        "clickable": false,
                        "slug": "s1v3",
                        "subgroups": [
                            "all",
                            "ss2"
                        ]
                    },
                    {
                        "descriptive_name": "s1v5",
                        "description": "s2v5",
                        "display_order": 3,
                        "name": "s1v5",
                        "clickable": false,
                        "slug": "s1v5",
                        "subgroups": [
                            "all",
                            "ss2"
                        ]
                    }
                ],
                "slug": "health"
            },
            {
                "subgroups": [
                    {
                        "name": "All",
                        "slug": "all"
                    },
                    {
                        "name": "Subsector 1",
                        "slug": "ss1"
                    }
                ],
                "name": "Education",
                "columns": [
                    {
                        "descriptive_name": "name",
                        "description": "name",
                        "display_order": 0,
                        "name": "name",
                        "clickable": false,
                        "slug": "name",
                        "subgroups": [
                            "all"
                        ]
                    },
                    {
                        "descriptive_name": "s1v1",
                        "description": "s1v1",
                        "display_order": 1,
                        "name": "s1v1",
                        "clickable": false,
                        "slug": "s1v1",
                        "subgroups": [
                            "all",
                            "ss1"
                        ]
                    },
                    {
                        "descriptive_name": "s1v3",
                        "description": "s1v3",
                        "display_order": 2,
                        "name": "s1v3",
                        "clickable": false,
                        "slug": "s1v3",
                        "subgroups": [
                            "all",
                            "ss1"
                        ]
                    },
                    {
                        "descriptive_name": "s1v5",
                        "description": "s1v5",
                        "display_order": 3,
                        "name": "s1v5",
                        "clickable": false,
                        "slug": "s1v5",
                        "subgroups": [
                            "all",
                            "ss1"
                        ]
                    }
                ],
                "slug": "education"
            },
            {
                "subgroups": [
                    {
                        "name": "All",
                        "slug": "all"
                    },
                    {
                        "name": "Subsector 1",
                        "slug": "ss1"
                    },
                    {
                        "name": "Subsector 2",
                        "slug": "ss2"
                    }
                ],
                "name": "Water",
                "columns": [
                    {
                        "descriptive_name": "name",
                        "description": "name",
                        "display_order": 0,
                        "name": "name",
                        "clickable": false,
                        "slug": "name",
                        "subgroups": [
                            "all"
                        ]
                    },
                    {
                        "descriptive_name": "s3v1",
                        "description": "s3v1",
                        "display_order": 1,
                        "name": "s3v1",
                        "clickable": false,
                        "slug": "s3v1",
                        "subgroups": [
                            "all",
                            "ss1"
                        ]
                    },
                    {
                        "descriptive_name": "s3v3",
                        "description": "s3v3",
                        "display_order": 2,
                        "name": "s3v3",
                        "clickable": false,
                        "slug": "s3v3",
                        "subgroups": [
                            "all",
                            "ss2"
                        ]
                    },
                    {
                        "descriptive_name": "s3v5",
                        "description": "s3v5",
                        "display_order": 3,
                        "name": "s3v5",
                        "clickable": false,
                        "slug": "s3v5",
                        "subgroups": [
                            "all",
                            "ss1"
                        ]
                    }
                ],
                "slug": "water"
            }
        ]
    },
    "data": {
        "facilities": {
            "31": {
                "sector": "Education",
                "name": "name1",
                "students": 110,
                "tsr_should_be": 0.23,
                "teachers": 25,
                "ts_ratio": 0.22727272727272727,
                "s1v6": 0.41,
                "s1v4": 0.35,
                "s1v5": 0.18,
                "s1v2": 7.65,
                "s1v3": 3.88,
                "s1v1": 8.5
            },
            "32": {
                "sector": "Education",
                "name": "name1",
                "students": 95,
                "tsr_should_be": 0.37,
                "teachers": 35,
                "ts_ratio": 0.3684210526315789,
                "s1v6": 8.33,
                "s1v4": 9.23,
                "s1v5": 3.73,
                "s1v2": 6.33,
                "s1v3": 6.33,
                "s1v1": 4.4
            },
            "33": {
                "sector": "Education",
                "name": "name1",
                "students": 60,
                "tsr_should_be": 0.58,
                "teachers": 35,
                "ts_ratio": 0.5833333333333334,
                "s1v6": 3.28,
                "s1v4": 9.26,
                "s1v5": 7.73,
                "s1v2": 6.28,
                "s1v3": 0.33,
                "s1v1": 5.83
            },
            "34": {
                "sector": "Education",
                "name": "name1",
                "students": 90,
                "tsr_should_be": 0.5,
                "teachers": 45,
                "ts_ratio": 0.5,
                "s1v6": 8.06,
                "s1v4": 2.82,
                "s1v5": 5.3,
                "s1v2": 7.98,
                "s1v3": 2.46,
                "s1v1": 3.01
            },
            "35": {
                "sector": "Education",
                "name": "name1",
                "students": 100,
                "tsr_should_be": 0.3,
                "teachers": 30,
                "ts_ratio": 0.3,
                "s1v6": 0.62,
                "s1v4": 4.18,
                "s1v5": 0.42,
                "s1v2": 9,
                "s1v3": 6.35,
                "s1v1": 1.17
            },
            "36": {
                "sector": "Education",
                "name": "name1",
                "students": 70,
                "tsr_should_be": 0.57,
                "teachers": 40,
                "ts_ratio": 0.5714285714285714,
                "s1v6": 2.54,
                "s1v4": 5.83,
                "s1v5": 6.33,
                "s1v2": 1.55,
                "s1v3": 7.14,
                "s1v1": 0.44
            },
            "37": {
                "sector": "Education",
                "name": "name1",
                "students": 70,
                "tsr_should_be": 0.64,
                "teachers": 45,
                "ts_ratio": 0.6428571428571429,
                "s1v6": 6.94,
                "s1v4": 5.67,
                "s1v5": 7.86,
                "s1v2": 5.05,
                "s1v3": 7.09,
                "s1v1": 9.28
            },
            "38": {
                "sector": "Education",
                "name": "name1",
                "students": 140,
                "tsr_should_be": 0.14,
                "teachers": 20,
                "ts_ratio": 0.14285714285714285,
                "s1v6": 1.1,
                "s1v4": 6.81,
                "s1v5": 6.73,
                "s1v2": 8.39,
                "s1v3": 9.98,
                "s1v1": 2.95
            },
            "39": {
                "sector": "Education",
                "name": "name1",
                "students": 75,
                "tsr_should_be": 0.07,
                "teachers": 5,
                "ts_ratio": 0.06666666666666667,
                "s1v6": 6.27,
                "s1v4": 0.62,
                "s1v5": 9.06,
                "s1v2": 9.66,
                "s1v3": 5.11,
                "s1v1": 4.84
            },
            "40": {
                "sector": "Education",
                "name": "name1",
                "students": 65,
                "tsr_should_be": 0.23,
                "teachers": 15,
                "ts_ratio": 0.23076923076923078,
                "s1v6": 7.55,
                "s1v4": 7.01,
                "s1v5": 8.86,
                "s1v2": 4.58,
                "s1v3": 0.87,
                "s1v1": 9.95
            },
            "41": {
                "sector": "Health",
                "name": "name1",
                "s2v1": 1.8,
                "s2v3": 9.45,
                "s2v2": 5.37,
                "s2v5": 4.97,
                "s2v4": 2.46,
                "s2v6": 2.35
            },
            "42": {
                "sector": "Health",
                "name": "name1",
                "s2v1": 5.45,
                "s2v3": 8.32,
                "s2v2": 3.58,
                "s2v5": 4.21,
                "s2v4": 0.48,
                "s2v6": 3.27
            },
            "43": {
                "sector": "Health",
                "name": "name1",
                "s2v1": 1.81,
                "s2v3": 9.21,
                "s2v2": 8.49,
                "s2v5": 5.92,
                "s2v4": 5.74,
                "s2v6": 4.15
            },
            "44": {
                "sector": "Health",
                "name": "name1",
                "s2v1": 2.18,
                "s2v3": 7.41,
                "s2v2": 0.54,
                "s2v5": 1.33,
                "s2v4": 3.42,
                "s2v6": 5.67
            },
            "45": {
                "sector": "Health",
                "name": "name1",
                "s2v1": 3.7,
                "s2v3": 4.34,
                "s2v2": 8,
                "s2v5": 2.96,
                "s2v4": 4.35,
                "s2v6": 6.39
            },
            "46": {
                "sector": "Health",
                "name": "name1",
                "s2v1": 9.32,
                "s2v3": 8.04,
                "s2v2": 9.98,
                "s2v5": 1.73,
                "s2v4": 5.19,
                "s2v6": 9.54
            },
            "47": {
                "sector": "Health",
                "name": "name1",
                "s2v1": 4.78,
                "s2v3": 6.33,
                "s2v2": 0.51,
                "s2v5": 4.41,
                "s2v4": 1.57,
                "s2v6": 7.54
            },
            "48": {
                "sector": "Health",
                "name": "name1",
                "s2v1": 0.71,
                "s2v3": 4.93,
                "s2v2": 9.18,
                "s2v5": 9.01,
                "s2v4": 5.23,
                "s2v6": 0.41
            },
            "49": {
                "sector": "Health",
                "name": "name1",
                "s2v1": 4.46,
                "s2v3": 3.26,
                "s2v2": 3.16,
                "s2v5": 5.64,
                "s2v4": 0.16,
                "s2v6": 8.08
            },
            "50": {
                "sector": "Health",
                "name": "name1",
                "s2v1": 2.48,
                "s2v3": 1.29,
                "s2v2": 3.05,
                "s2v5": 3.75,
                "s2v4": 7.55,
                "s2v6": 2.03
            },
            "51": {
                "sector": "Water",
                "name": "name1",
                "s3v4": 0.36,
                "s3v5": 6.77,
                "s3v6": 3.82,
                "s3v1": 0.1,
                "s3v2": 8.56,
                "s3v3": 1.91
            },
            "52": {
                "sector": "Water",
                "name": "name1",
                "s3v4": 3.75,
                "s3v5": 9.09,
                "s3v6": 7.29,
                "s3v1": 5.45,
                "s3v2": 9.98,
                "s3v3": 7.56
            },
            "53": {
                "sector": "Water",
                "name": "name1",
                "s3v4": 7.28,
                "s3v5": 2,
                "s3v6": 6.49,
                "s3v1": 1.4,
                "s3v2": 4.75,
                "s3v3": 9.37
            },
            "54": {
                "sector": "Water",
                "name": "name1",
                "s3v4": 1.67,
                "s3v5": 0.06,
                "s3v6": 0.76,
                "s3v1": 6.6,
                "s3v2": 5.01,
                "s3v3": 2.41
            },
            "55": {
                "sector": "Water",
                "name": "name1",
                "s3v4": 0.63,
                "s3v5": 8.06,
                "s3v6": 5.32,
                "s3v1": 5.24,
                "s3v2": 8.72,
                "s3v3": 7.8
            },
            "56": {
                "sector": "Water",
                "name": "name1",
                "s3v4": 3.37,
                "s3v5": 6.96,
                "s3v6": 3.78,
                "s3v1": 7.02,
                "s3v2": 8.02,
                "s3v3": 7.52
            },
            "57": {
                "sector": "Water",
                "name": "name1",
                "s3v4": 9.07,
                "s3v5": 7.12,
                "s3v6": 6.29,
                "s3v1": 3.01,
                "s3v2": 2.49,
                "s3v3": 7.67
            },
            "58": {
                "sector": "Water",
                "name": "name1",
                "s3v4": 5.64,
                "s3v5": 1.26,
                "s3v6": 9.34,
                "s3v1": 7.34,
                "s3v2": 9.24,
                "s3v3": 3.31
            },
            "59": {
                "sector": "Water",
                "name": "name1",
                "s3v4": 2.71,
                "s3v5": 3.54,
                "s3v6": 2.31,
                "s3v1": 6.09,
                "s3v2": 1.1,
                "s3v3": 0.33
            },
            "60": {
                "sector": "Water",
                "name": "name1",
                "s3v4": 6.31,
                "s3v5": 1.07,
                "s3v6": 2.81,
                "s3v1": 1.36,
                "s3v2": 9.49,
                "s3v3": 6.52
            }
        },
        "stateName": "State1",
        "profileData": {},
        "lgaName": "LGA2"
    }
};