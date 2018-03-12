import pandas as pd
import sys
import os
from datetime import time

# TODO: convert to an arg-ready python-script (with flag -d|--directory <CSV-DIR>)
# From quandl (organized by DATE)
ORIGINAL_CSV_PATH = '/root/arturo/DOWNLOADS/csv_data/quandl-csvs/'
# For zipline INGEST -b csv-bundle (organized by TICKER)
OUTPUT_PATH = '/root/arturo/DOWNLOADS/csv_data/minute/'
# time for 2008 --> 2017
# 41Gi used
# 18Gi avail
# ...
# 31,000 seconds ~ 9 hours, for 9 years
# : 1-hr / yr
# 37G used
# 22G avail


def open_csv(data_file):
    # Opens csv file 
    # Combines 'Date' and 'Timestamp' column into one

    df = pd.read_csv(ORIGINAL_CSV_PATH + data_file, delimiter=',', parse_dates=[['Date', 'Timestamp']])
    return df

def timestamp_handling(df):
    # Converts tz from EST to UTC

    df['Date_Timestamp'] = pd.to_datetime(df['Date_Timestamp'], exact=True) \
                             .values.astype('datetime64[s]')   
    
    market_open = time(9,30,0)
    market_close = time(16,0,0)
    

    df = df[df.Date_Timestamp.dt.time >= market_open]
    df = df[df.Date_Timestamp.dt.time <= market_close]

    df['Date_Timestamp'] = pd.to_datetime(df['Date_Timestamp'], exact=True) \
                             .dt.tz_localize('America/New_York') \
                             .dt.tz_convert('UTC') \
                             .values.astype('datetime64[s]')   

    return df

def reformat_data(df):
    # Renames columns: ['timestamp', 'open', 'high', 'low', 'close', 'volume']
    # Drops 'TotalQuantity' and 'TotalTradeCount' columns
    
    df.rename(columns={'Date_Timestamp': 'timestamp',
                        'Ticker': 'ticker',
                        'OpenPrice': 'open',
                        'HighPrice': 'high',
                        'LowPrice': 'low',
                        'ClosePrice': 'close',
                        'TotalVolume': 'volume'}, inplace=True)

    df.drop(['TotalQuantity','TotalTradeCount'], axis=1, inplace=True)
    return df

def csv_output(df):
    # Converts '/' found in some tickers to '_'
    # Iterates over a list of unique tickers on a given day to create or append csv files with minute data
 
    df['ticker'] = df['ticker'].str.replace('/', '_') # replaces slashes. 'NWS/A.csv' -> 'NWS_A.csv'

    ticker_list = df.ticker.unique() # returns ndarray of tickers in sp500 on given date
     
    for ticker in ticker_list:
        
        if os.path.isfile(OUTPUT_PATH + ticker + '.csv') == True:
            # If ticker.csv already exists: append the current day's data to the end of that csv
            df[df['ticker'] == ticker].to_csv(OUTPUT_PATH + ticker + '.csv', header=False, mode = 'a', index=False)        
    
        elif os.path.isfile(OUTPUT_PATH + ticker + '.csv') == False:
            # If ticker.csv does not exist: create ticker.csv with current day's data
            df[df['ticker'] == ticker].to_csv(OUTPUT_PATH + ticker + '.csv', sep=',', index=False)
            print('{}.csv has been created!'.format(ticker))
     

def main():
    for data_file in sorted(os.listdir(ORIGINAL_CSV_PATH)): # iterates over each orig csv file, 1 per day
        df = open_csv(data_file)
        df = timestamp_handling(df)
        df = reformat_data(df)
        csv_output(df)   
        # OPTIONAL: remove original csv to save space #
        print('Removing: {}'.format(data_file))   
        os.remove(ORIGINAL_CSV_PATH + data_file)  
         

if __name__ == '__main__':
    main()
