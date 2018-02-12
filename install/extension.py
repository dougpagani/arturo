import pandas as pd

from zipline.data.bundles import register
from zipline.data.bundles.csvdir import csvdir_equities

CSVDIR = '/csv_data'

start_session = pd.Timestamp('2012-7-10', tz='utc')
end_session = pd.Timestamp('2017-05-15', tz='utc')

register(
    'csv-bundle',
    csvdir_equities(['minute'], CSVDIR),
    start_session=start_session,
    end_session=end_session)