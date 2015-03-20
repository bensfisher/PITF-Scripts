from datetime import datetime
import pandas as pd
from joblib import Parallel, delayed
import multiprocessing

starttime = datetime.now()
num_cores = multiprocessing.cpu_count()

print 'Reading in data...'

filelist =  []

data = pd.DataFrame()

for file in filelist:
    yeardata = pd.read_table(file, sep='\t',header=None)
    data = data.append(yeardata)

data.columns = ['Date','ISO1','COW1','Agent1','ISO2','COW2','Agent2','CAMEO',
                'GoldsteinScale','quad']
# concatenate country and agent fields into one field
data['Actor1Code'] = data.ISO1.map(str)+data.Agent1.map(str)
data['Actor2Code'] = data.ISO2.map(str)+data.Agent2.map(str)
keep_columns = ['Date', 'Actor1Code', 'Actor2Code', 'quad', 'GoldsteinScale']
data = data[keep_columns]

data['year'] = data['Date'].map(lambda x: int(str(x)[0:4]))

shortened = data
shortened['month'] = shortened['Date'].map(lambda x: int(str(x)[5:7]))
del data

#These are counts and goldstein sums for each possible combination of the
#various actors

variables = ['gov_gov_vercp', 'gov_gov_matcp', 'gov_gov_vercf', 'gov_gov_matcf',
             'gov_gov_gold', 'gov_opp_vercp', 'gov_opp_matcp', 'gov_opp_vercf',
             'gov_opp_matcf', 'opp_gov_vercp', 'opp_gov_matcp', 'opp_gov_vercf',
             'opp_gov_matcf', 'opp_gov_gold', 'gov_reb_vercp', 'gov_reb_matcp',
             'gov_reb_vercf', 'gov_reb_matcf', 'gov_reb_gold', 'reb_gov_vercp',
             'reb_gov_matcp', 'reb_gov_vercf', 'reb_gov_matcf', 'reb_gov_gold',
             'gov_soc_vercp', 'gov_soc_matcp', 'gov_soc_vercf', 'gov_soc_matcf',
             'gov_soc_gold', 'soc_gov_vercp', 'soc_gov_matcp', 'soc_gov_vercf',
             'soc_gov_matcf', 'soc_gov_gold', 'gov_ios_vercp', 'gov_ios_matcp', 
             'gov_ios_vercf', 'gov_ios_matcf', 'gov_ios_gold', 'ios_gov_vercp',
             'ios_gov_matcp', 'ios_gov_vercf', 'ios_gov_matcf', 'ios_gov_gold',
             'gov_usa_vercp', 'gov_usa_matcp', 'gov_usa_vercf', 'gov_usa_matcf',
             'gov_usa_gold', 'usa_gov_vercp', 'usa_gov_matcp', 'usa_gov_vercf', 
             'usa_gov_matcf', 'usa_gov_gold', 'opp_reb_vercp', 'opp_reb_matcp', 
             'opp_reb_vercf', 'opp_reb_matcf', 'opp_reb_gold', 'reb_opp_vercp', 
             'reb_opp_matcp', 'reb_opp_vercf', 'reb_opp_matcf', 'reb_opp_gold', 
             'opp_opp_vercp', 'opp_opp_matcp', 'opp_opp_vercf', 'opp_opp_matcf',
             'opp_opp_gold', 'reb_reb_vercp', 'reb_reb_matcp', 'reb_reb_vercf', 
             'reb_reb_matcf', 'reb_reb_gold', 'opp_soc_vercp', 'opp_soc_matcp', 
             'opp_soc_vercf', 'opp_soc_matcf', 'opp_soc_gold', 'soc_opp_vercp', 
             'soc_opp_matcp', 'soc_opp_vercf', 'sco_opp_matcf', 'soc_opp_gold',
             'soc_reb_vercp', 'soc_reb_matcp', 'soc_reb_vercf', 'soc_reb_matcf',
             'reb_soc_vercp', 'reb_soc_matcp', 'reb_soc_vercf', 'reb_soc_matcf',
             'opp_ios_vercp', 'opp_ios_matcp', 'opp_ios_vercf', 'opp_ios_matcf',
             'opp_ios_gold', 'ios_opp_vercp', 'ios_opp_matcp', 'ios_opp_vercf', 
             'ios_opp_matcf', 'ios_opp_gold', 'opp_usa_vercp', 'opp_usa_matcp', 
             'opp_usa_vercf', 'opp_usa_matcf', 'opp_usa_gold', 'usa_opp_vercp', 
             'usa_opp_matcp', 'usa_opp_vercf', 'usa_opp_matcf', 'usa_opp_gold',
             'soc_ios_vercp', 'soc_ios_matcp', 'soc_ios_vercf', 'soc_ios_matcf',
             'soc_ios_gold', 'ios_soc_vercp', 'ios_soc_matcp', 'ios_soc_vercf', 
             'ios_soc_matcf', 'ios_soc_gold', 'soc_usa_vercp', 'soc_usa_matcp', 
             'soc_usa_vercf', 'soc_usa_matcf', 'soc_usa_gold', 'gov_gov_vercp', 
             'usa_soc_matcp', 'usa_soc_vercf', 'usa_soc_matcf', 'usa_soc_gold',
             'soc_soc_vercp', 'soc_soc_matcp', 'soc_soc_vercf', 'soc_soc_matcf',
             'soc_soc_gold', 'soc_reb_gold', 'reb_soc_gold', 'gov_opp_gold',
             'soc_opp_matcf']

# list of countries to get counts for

all_actors =['AFG', 'ALA', 'ALB', 'DZA', 'ASM', 'AND', 'AGO', 'ATG', 
            'ARG', 'ARM', 'AUS', 'AUT', 'AZE', 'BHS', 'BHR', 'BGD', 
            'BRB', 'BLR', 'BEL', 'BLZ', 'BEN', 'BTN', 'BOL', 'BIH', 
            'BWA', 'BRA', 'VGB', 'BRN', 'BGR', 'BFA', 'BDI', 'KHM', 'CMR',
            'CAN', 'CPV', 'CAF', 'TCD', 'CHL', 'CHN', 'COL', 'COM', 
            'COD', 'COG', 'CRI', 'CIV', 'HRV', 'CUB', 'CYP', 'CZE', 
            'DNK', 'DJI', 'DMA', 'DOM', 'TMP', 'ECU', 'EGY', 'SLV', 'GNQ', 
            'ERI', 'EST', 'ETH', 'FRO', 'FLK', 'FJI', 'FIN', 'FRA', 'GUF',
            'PYF', 'GAB', 'GMB', 'GEO', 'DEU', 'GHA', 'GIB', 'GRC', 'GRL',
            'GRD', 'GLP', 'GUM', 'GTM', 'GIN', 'GNB', 'GUY', 'HTI', 
            'HND', 'HUN', 'ISL', 'IND', 'IDN', 'IRN', 'IRQ', 'IRL', 
            'IMY', 'ISR', 'ITA', 'JAM', 'JPN', 'JOR', 'KAZ', 'KEN',
            'PRK', 'KOR', 'KWT', 'KGZ', 'LAO', 'LVA', 'LBN', 'LSO', 'LBR', 
            'LBY', 'LIE', 'LTU', 'LUX', 'MKD', 'MDG', 'MWI', 'MYS',
            'MDV', 'MLI', 'MLT', 'MRT', 'MUS', 'MYT', 'MEX',
            'MDA', 'MCO', 'MNG', 'MTN', 'MSR', 'MAR', 'MOZ', 'MMR',
            'NAM', 'NPL', 'NLD', 'NCL', 'NZL', 'NIC', 'NER',
            'NGA', 'NIU', 'NFK', 'NOR', 'OMN', 'PAK', 'PLW', 
            'PAN', 'PNG', 'PRY', 'PER', 'PHL', 'PCN', 'POL', 'PRT', 
            'QAT', 'REU', 'ROU', 'RUS', 'RWA', 'SHN', 'KNA', 'LCA', 'SPM', 
            'VCT', 'WSM', 'SMR', 'STP', 'SAU', 'SEN', 'SRB', 'SYC', 'SLE', 
            'SGP', 'SVK', 'SVN', 'SLB', 'SOM', 'ZAF', 'ESP', 'LKA', 'SDN',
            'SUR', 'SJM', 'SWZ', 'SWE', 'CHE', 'SYR', 'TJK', 'TZA', 'THA', 
            'TGO', 'TKL', 'TTO', 'TUN', 'TUR', 'TKM','TWN',
            'UGA', 'UKR', 'ARE', 'GBR', 'VIR', 'URY', 'UZB', 'VUT', 
            'VEN', 'VNM', 'WLF', 'YEM', 'ZMB', 'ZWE']

#Creating indicator variables for actor1 and actor2 to determine what type it is
#Each actor type has it's own set of logical conditions

shortened['actor1_type'] = 'NaN'
shortened['actor2_type'] = 'NaN'

print 'Creating actor_type variables...'

##OPP actors

# checks to see if 'OPP' is in actor fields
opp_cond1 = shortened['Actor1Code'].map(lambda x: str(x)[3:6] == 'OPP')
shortened['actor1_type'][opp_cond1] = 'OPP'

opp_cond2 = shortened['Actor2Code'].map(lambda x: str(x)[3:6] == 'OPP')
shortened['actor2_type'][opp_cond2] = 'OPP'

del opp_cond1
del opp_cond2

#Second test

##GOV actors

gov_actors = ['GOV', 'MIL', 'JUD', 'PTY']

# checks to see if any of the actors in the gov_actors list are in the actor field
gov_cond1 = shortened['Actor1Code'].map(lambda x: str(x)[3:6] in gov_actors)
shortened['actor1_type'][gov_cond1] = 'GOV'

gov_cond2 = shortened['Actor2Code'].map(lambda x: str(x)[3:6] in gov_actors)
shortened['actor2_type'][gov_cond2] = 'GOV'

del gov_cond1
del gov_cond2

##REB actors

reb_actors = ['REB', 'INS']

# checks to see if any of the actors in the reb_actors list are in the actor field
reb_cond1 = shortened['Actor1Code'].map(lambda x: str(x)[3:6] in reb_actors)
shortened['actor1_type'][reb_cond1] = 'REB'

reb_cond2 = shortened['Actor2Code'].map(lambda x: str(x)[3:6] in reb_actors)
shortened['actor2_type'][reb_cond2] = 'REB'

del reb_cond1
del reb_cond2

##USA actors

# checks to see if any of the actors in the actor field are USA
usa_cond1 = shortened['Actor1Code'].map(lambda x: str(x)[0:3] == 'USA')
shortened['actor1_type'][usa_cond1] = 'USA'

usa_cond2 = shortened['Actor2Code'].map(lambda x: str(x)[0:3] == 'USA')
shortened['actor2_type'][usa_cond2] = 'USA'

del usa_cond1
del usa_cond2

##IOS actors

ios_actors = ['NGO', 'IGO']
ios_cond1 = shortened['Actor1Code'].map(lambda x: str(x)[3:6] in ios_actors)
shortened['actor1_type'][ios_cond1] = 'IOS'

ios_cond2 = shortened['Actor2Code'].map(lambda x: str(x)[3:6] in ios_actors)
shortened['actor2_type'][ios_cond2] = 'IOS'

del ios_cond1
del ios_cond2

##SOC actors

#soc_actors = ['CVL']

# checks to see if any of the actors in the soc_actors list are in the actor field
#soc_cond1 = shortened['Actor1Code'].map(lambda x: str(x)[3:6] in soc_actors)
#shortened['actor1_type'][soc_cond1] = 'SOC'

#soc_cond2 = shortened['Actor2Code'].map(lambda x: str(x)[3:6] in soc_actors)
#shortened['actor2_type'][soc_cond2] = 'SOC'

#del soc_cond1
#del soc_cond2

#Creating empty variables from the list above

for name in variables:
    shortened[name] = 0

var_actors = ['gov', 'opp', 'ios', 'usa', 'reb']
var_types = {'vercp': 1, 'matcp': 2, 'vercf': 3, 'matcf': 4}

print 'Creating count variables...'

for name1 in var_actors:
    for name2 in var_actors:
        for var_type in var_types:
            var_name = name1 + "_" + name2 + "_" + var_type
            var_gold = name1 + "_" + name2 + "_" + "gold"
            if var_name in variables:
                print 'var_name is %s' % var_name
                check1 = shortened['actor1_type'] == name1.upper()
                check2 = shortened['actor2_type'] == name2.upper()
                check3 = shortened['quad'] == var_types[var_type]
                shortened[var_name][check1 & check2 & check3] = 1
            else:
                pass
            if var_gold in variables:
                try:
                    print 'var_gold is %s' % var_gold
                    shortened[var_gold] = shortened['GoldsteinScale']
                    reverse1 = shortened['actor1_type'] != name1.upper()
                    reverse2 = shortened['actor2_type'] != name2.upper()
                    shortened[var_gold][reverse1 | reverse2] = 0
                except:
                    pass
            else:
                pass


print 'Creating groupings...'

final = pd.DataFrame()
def processActor(actor):
    print 'Processing %s' % actor
    cond1 = shortened['Actor1Code'].str[0:3] == actor
    cond2 = shortened['Actor2Code'].str[0:3] == actor
    actor_dataset = shortened[cond1 & cond2]
    actor_dataset = actor_dataset.groupby(['year', 'month'], as_index = False)
    actor_dataset_sum = actor_dataset.sum()
    actor_dataset_sum['country'] = actor
    return actor_dataset_sum

temp = Parallel(n_jobs=num_cores)(delayed(processActor)(actor) for actor in all_actors[0:])

#for actor in all_actors[0:]:
#    print 'Processing %s' % actor
#    cond1 = shortened['Actor1Code'].str[0:3] == actor
#    cond2 = shortened['Actor2Code'].str[0:3] == actor
#    actor_dataset = shortened[cond1 & cond2]
#    actor_dataset = actor_dataset.groupby(['year', 'month'], as_index = False)
#    actor_dataset_sum = actor_dataset.sum()
#    actor_dataset_sum['country'] = actor
#    final = final.append(actor_dataset_sum)
final = final.append(temp)

del final['GoldsteinScale']
del final['quad']

#order columns because it puts country at end for whatever reason
cols = final.columns.tolist()
cols = cols[0:1] + cols[-1:] + cols[45:46] + cols[1:45] + cols[46:-1]
final = final[cols]

print 'Saving to final_output.csv'

final.to_csv('agg_output.csv', index = False)

print(datetime.now()-starttime)
