# This script INGESTS the csv's in the directory "minute" 
# ... found at /csv_data , bound to the docker-image
import pandas as pd

from zipline.data.bundles import register
from zipline.data.bundles.csvdir import csvdir_equities

CSVDIR = '/csv_data'

# Will ingest with this range
# TODO: make a main() which accepts args to digest as desired
# TODO: will have to move the csv's, or parameterize convert_csv.py, to match
start_session = pd.Timestamp('2018-01-02', tz='utc')
end_session = pd.Timestamp('2017-02-01', tz='utc')

register(
    'csv-bundle',
    csvdir_equities(['minute'], CSVDIR),
    start_session=start_session,
    end_session=end_session)
