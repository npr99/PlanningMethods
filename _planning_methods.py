
import requests ## Required for the Census API
import pandas as pd # For reading, writing and wrangling data
import json # used to read in metadata for Census variables
import numpy as np # For setting missing values
import urllib.request, json  # reading in json files

class planning_methods():
  """
  Python File with Functions used in Planning Methods Course.

  version 0.0.1 2021-10-07

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
          # Set up hyperlink for Census API
          api_hyperlink = ('https://api.census.gov/data/' + vintage + '/'+dataset_name + '?get=' + get_vars +
                          '&in=state:' + state + '&in=county:' + county + '&for=' + census_geography)

          print("Census API data from: " + api_hyperlink)

          # Obtain Census API JSON Data
          apijson = requests.get(api_hyperlink)

          # Convert the requested json into pandas dataframe
          df = pd.DataFrame(columns=apijson.json()[0], data=apijson.json()[1:])

          return df


  def clean_acs_variables(df,vintage,dataset_name,get_vars):
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
      print(vintage,"Renameing",variable," = ",label_addvintage_addtype,"Changing type to",variable_metadata["predicateType"])

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
          print(observations_with_annotation,"Observations have",Annotation_value)
          print(Annotation_values[Annotation_value])
          print('Replacing values with missing.')
          df.loc[(df[variable] == Annotation_value), variable] = np.nan


      df = df.rename(columns={variable: label_addvintage_addtype}) 

    return df

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

    # Select Esimates Only
    estimate_cols = [col for col in float_col_list if col.endswith("(Estimate)")]
    table1 = df[estimate_cols].describe().T
    varformat = "{:,.2f}" # The variable format adds a comma and rounds up
    table1 = table1.style.set_caption(table_title)\
      .format(varformat)\
      .set_table_styles(styles)\
      .set_properties(**{'text-align': 'right','font-size': '20pt','border': '2px solid black','width': '100px'})
    
    return table1


  def find_zscore_outliers(df,variable_to_check):
    mean = df[variable_to_check].mean()
    standard_deviation = df[variable_to_check].std()
    df[variable_to_check+' Z-score'] = (df[variable_to_check] - mean)/standard_deviation
    # Create a new variable to identify outliers
    df['Z-score Outlier '+variable_to_check] = 0
    df.loc[abs(df[variable_to_check+' Z-score']) > 3, 
                'Z-score Outlier '+variable_to_check] = 1

    # Return Outliers
    outliers_df = df.loc[df['Z-score Outlier '+variable_to_check] == 1]

    # Sort Values
    outliers_df = outliers_df.sort_values(by = [variable_to_check],  ascending=False)
      
    return outliers_df