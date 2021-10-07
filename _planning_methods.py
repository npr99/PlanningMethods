
class planningmethod():
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