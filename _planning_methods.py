
import requests ## Required for the Census API
import pandas as pd # For reading, writing and wrangling data
import json # used to read in metadata for Census variables
import numpy as np # For setting missing values
import urllib.request, json  # reading in json files

class planning_methods():
  """
  Python File with Functions used in Planning Methods Course.

  version 0.0.2 2022-06-15T1246

  """

  def obtain_census_api(
                      state: str = "*",
                      county: str = "*",
                      census_geography: str = 'county:*',
                      vintage: str = "2010", 
                      dataset_name: str = 'dec/sf1',
                      get_vars: str = 'GEO_ID'):

          """General utility for obtaining census from Census API.

          Args:
              state (str): 2-digit FIPS code. Default * for all states
              county (str): 3-digit FIPS code. Default * all counties
              census_geography (str): example '&for=block:*' would be for all blocks
                default is for all counties
              vintage (str): Census Year. Default 2010
              dataset_name (str): Census dataset name. Default Decennial SF1
              for a list of all Census API
              get_vars (str): list of variables to get from the API.

          Returns:
              obj, dict: A dataframe for with Census data

          """
          # Check geography hierarchy
          if (
            census_geography == 'county:*' or 
            census_geography == 'tract:*' or 
            census_geography == 'block:*'
            ):
            geography_hierarchy =  '&in=state:' + state + '&in=county:' + county 
          else:
            geography_hierarchy = ''
          # Set up hyperlink for Census API
          api_hyperlink = ('https://api.census.gov/data/' + vintage + '/'+dataset_name + '?get=' + get_vars +
                          geography_hierarchy + '&for=' + census_geography)

          print("Census API data from: " + api_hyperlink)

          # Obtain Census API JSON Data
          apijson = requests.get(api_hyperlink)

          # Convert the requested json into pandas dataframe
          df = pd.DataFrame(columns=apijson.json()[0], data=apijson.json()[1:])

          return df


  def clean_acs_variables(df,vintage,dataset_name,get_vars, print_annotations = False):
    """
    Function runs loop to rename variables, set variable type, and 
    address missing values in ACS data.
    """

    for variable in get_vars.split(","):
      variable_metadata_hyperlink = (f'https://api.census.gov/data/{vintage}/{dataset_name}/variables/{variable}.json')
      # Obtain Census API JSON Data
       
      # wget fails when trying to load from github
      #!wget --no-cache --quiet --backups=1 {variable_metadata_hyperlink}

      with urllib.request.urlopen(variable_metadata_hyperlink) as url:
        variable_metadata = json.load(url)

      # Find the variable label 
      census_label_string = str(variable_metadata["label"])
      last_exclamation_point_position = census_label_string.rfind("!!")
      if last_exclamation_point_position >= 0:
        last_exclamation_point_position = last_exclamation_point_position + 2
      else:
        last_exclamation_point_position = 0
      label = census_label_string[last_exclamation_point_position:] 

      # Add vintage to label name (skip geo_id and name variables)
      if variable not in ['GEO_ID','NAME']:
        label_addvintage = label + f' {vintage}'
      else:
        label_addvintage = label

      # Add estimate or Margin of Error to label
      last_letter_of_variable = variable[-1]
      if variable not in ['GEO_ID','NAME']:
        if last_letter_of_variable == 'E':
          label_addvintage_addtype = label_addvintage + ' (Estimate)'
        if last_letter_of_variable == 'M':
          label_addvintage_addtype = label_addvintage + ' (MOE)'
      else:
        label_addvintage_addtype = label_addvintage
      if print_annotations == True:
        print(vintage,"Renaming",variable," = ",label_addvintage_addtype,"Changing type to",variable_metadata["predicateType"])

      # Change variable type
      df[variable] = df[variable].astype(variable_metadata["predicateType"])

      # Reset Estimates and MOE with Annotation Values
      Annotation_values = {-999999999 : 'Number of sample cases is too small.',
      -888888888 : 'Estimate is not applicable or not available.',
      -666666666 : 'No sample observations or too few sample observations were available to compute an estimate.',
      -555555555 : 'Estimate is controlled. A statistical test for sampling variability is not appropriate.',
      -333333333 : 'Median falls in the lowest interval or upper interval of an open-ended distribution. A statistical test is not appropriate.',
      -222222222 : 'No sample observations or too few sample observations were available to compute a standard error and thus the margin of error. A statistical test is not appropriate.'}

      for Annotation_value in Annotation_values:
        observations_with_annotation = len(df.loc[(df[variable] == Annotation_value)])
        if observations_with_annotation > 0:
          if print_annotations == True:
            print(observations_with_annotation,"Observations have",Annotation_value)
            print(Annotation_values[Annotation_value])
            print('Replacing values with missing.')
          df.loc[(df[variable] == Annotation_value), variable] = np.nan


      df = df.rename(columns={variable: label_addvintage_addtype}) 

    return df


  def percent_pop_by_age_sex(years: list = ['2019'], acs_5_year = True):
    """
    Collect Census Data by percent population by age and sex.
    """

    tableid = 'S0101'
    columns = {4 : 'Percent Male',
              6 : 'Percent Female'
              }
    # There are 18 age cohorts under 5 years to 85 years and over
    age_cohorts = 18
    # What is the variable number for thefirst age cohort
    first_age_cohort_variable = 2

    # Create an empty "container" to store multiple ACS years for the data
    acs_df = {} 

    if acs_5_year == True:
      dataset_name = 'acs/acs5/subject'
    else:
      dataset_name = 'acs/acs1/subject'
    vintages = years

    for column in columns:
      total_column = column - 1
      total_estimate_var = tableid+'_C0'+str(total_column)+"_"+'001E'
      total_moe_var = tableid+'_C0'+str(total_column)+"_"+'001M'
      get_vars = 'GEO_ID,NAME,'+total_estimate_var+ ','+total_moe_var
      for age_variable in range(0,age_cohorts):
        age_cohort_var = first_age_cohort_variable + age_variable
        age_cohort_var_str = str(age_cohort_var).zfill(3)
        get_estimate_var = tableid+'_C0'+str(column)+"_"+age_cohort_var_str+'E'
        get_moe_var = tableid+'_C0'+str(column)+"_"+age_cohort_var_str+'M'
        get_vars = get_vars + ',' + get_estimate_var + ',' + get_moe_var

      # Get dat for the list of variables
      for vintage in vintages:
        acs_df[vintage+' '+columns[column]] = planning_methods.obtain_census_api(get_vars = get_vars,
                                                            dataset_name = dataset_name, 
                                                            vintage = vintage)
        
        acs_df[vintage+' '+columns[column]] = planning_methods.clean_acs_variables(acs_df[vintage+' '+columns[column]],vintage, dataset_name, get_vars)

    return acs_df   

  def descriptive_stats_table(df,**kwargs):
    """
        Args:
            df (obj): Pandas DataFrame object.
            kwargs (kwargs): Keyword arguments for visualization title.
        Returns:
            object: Pandas DataFrame object.
    """

    who = ""
    what = ""
    when = ""
    where = ""

    if "who" in kwargs.keys():
        who = kwargs["who"]
    if "what" in kwargs.keys():
        what = kwargs["what"]
    if "when" in kwargs.keys():
        when = kwargs["when"]
    if "where" in kwargs.keys():
        where = kwargs["where"]

    table_title = "Table. " + who + " " + what + " " + where + " " + when + "."

    # Caption Title Style
    styles = [dict(selector="caption", 
        props=[("text-align", "center"),
                ("caption-side", "top"),
                ("font-size", "150%"),
                ("color", 'black')])]    # the color value can not be None

    float_col_list = list(df.select_dtypes(include=['float']).columns)

    # Select Estimates Only
    estimate_cols = [col for col in float_col_list if col.endswith("(Estimate)")]
    table1 = df[estimate_cols].describe().T
    varformat = "{:,.2f}" # The variable format adds a comma and rounds up
    table1 = table1.style.set_caption(table_title)\
      .format(varformat)\
      .set_table_styles(styles)\
      .set_properties(**{'text-align': 'right','font-size': '20pt','border': '2px solid black','width': '100px'})
    
    return table1


  def find_zscore_outliers(df,variable_to_check):
    estimate_var = variable_to_check + ' (Estimate)'
    moe_var = variable_to_check + ' (MOE)'
    
    mean = df[estimate_var].mean()
    standard_deviation = df[estimate_var].std()
    df[variable_to_check+' Z-score'] = (df[estimate_var] - mean)/standard_deviation
    
    # Create a new variable to identify outliers
    df['Z-score Outlier '+estimate_var] = 0
    df.loc[abs(df[variable_to_check+' Z-score']) > 3, 
                'Z-score Outlier '+estimate_var] = 1

    # Add Coefficients of variation
    df[estimate_var+' SE'] = \
        df[moe_var]/1.645
    df[estimate_var+' CV'] = \
        df[estimate_var+' SE']/df[estimate_var]

    # Return Outliers
    outliers_df = df.loc[df['Z-score Outlier '+estimate_var] == 1]

    # Sort Values
    outliers_df = outliers_df.sort_values(by = [estimate_var],  ascending=False)
    

    return outliers_df


  def generate_source_county_links(year,county_fips,tableid: str = 'S0101', acs_5_year = True):

      # The state code is the first 2 characters of the 5 character county FIPS Code
      state_code = str(county_fips[0:2]).zfill(2)
      county_code = str(county_fips[2:5]).zfill(3)

      # ACS Narrative Profile
      acs_narrative_profile_base_url = 'https://www.census.gov/acs/www/data/data-tables-and-tools/narrative-profiles/'
      acs_narrative_profile_url = acs_narrative_profile_base_url+year+'/report.php?geotype=county&state='+state_code+'&county='+county_code

      print('For an ACS Narrative Profile click on link:')
      print(acs_narrative_profile_url)


      # Census Reporter Link
      census_reporter_base_url = 'https://censusreporter.org/profiles/'
      census_reporter_url = census_reporter_base_url + '05000US'+county_fips

      print('\n')
      print('For a Census Reporter Profile click on link:')
      print(census_reporter_url)

      # data.census.gov link
      data_census_gov_base_url = 'https://data.census.gov/cedsci/'
      
      # set ACS Table Link
      first_letter_of_tableid = tableid[0:1]
      # If first letter is S then ACS Table is a Subject Table
      if first_letter_of_tableid == "S":
        acstable = 'ACSST'
      if first_letter_of_tableid == "B":
        acstable = 'ACSDT'
      # Check 5-year of 1-year
      if acs_5_year == True:
        acstable = acstable + '5Y'
      else:
        acstable = acstable + '1Y'
       
      geography = 'g=0500000US'+county_fips
      data_census_gov_url = data_census_gov_base_url + 'table?tid='+acstable+year+'.'+tableid+'&'+geography
      print('\n')
      print('For data.census.gov data click on link:')
      print(data_census_gov_url)
