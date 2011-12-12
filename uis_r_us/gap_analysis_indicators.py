def all_gap_indicators():
	return {
	    'health': [
	        {
	            'type': 'title',
	            'name': 'Health Section 1'
	        },
	        {
	            'type': 'other',
	            'name': 'Indicator 1',
	            'current': "current_mcgee_g",
	            'gap': 'gap_mcgee_g',
	            'target': 'target_mcgee_g'
	        }
	    ],
	    'education': [
            {
                'type': 'title',
                'name': 'Edu Section 1'
            },
            {
                'type': 'other',
                'name': 'Edu indicator 1',
                'current': 'edu_in1',
	            'gap': 'edu_in2',
	            'target': 'edu_in3'
            }
	    ]
	}