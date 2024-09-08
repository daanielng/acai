"""
Lambda function to create and return a Pandas dataframe.
(An example workload for processes needed in AI applications)
"""
# Third-party Imports
import pandas as pd

def lambda_handler(event, context):
    
    # Initialise data dictionary
    dict_data = {"col1": [1,2,3,4],
                 "col2": [5,6,7,8]}
    
    # Create Pandas dataframe from data dictionary
    df_data = pd.DataFrame(data=dict_data)
    
    return df_data