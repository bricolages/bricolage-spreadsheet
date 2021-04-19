# bricolage-spreadsheet

Google Spreadsheet-related job classes for Bricolage batch job framework.

## Home Page

https://github.com/bricolages/bricolage-spreadsheet

## Usage

Add following line in your Gemfile:
```
gem 'bricolage-spreadsheet'
```

Job Options

```
% bundle exec bricolage spreadsheet-import -h
Usage: bricolage spreadsheet-import [job_class_options]
        --src-ds=NAME                [optional] Main data source. [default: spreadsheet]
        --sheet-id=ID                Spreadsheet ID
        --range=RANGE_EXPR           Spreadsheet Range
        --format=VALUE               [optional] Data file format. (csv, json)
        --value-render-option=VALUE  [optional] For values with format on sheets (FORMATTED_VALUE, UNFORMATTED_VALUE, FORMULA)
        --s3-ds=NAME                 [optional] Main data source. [default: s3]
        --s3-file=PATH               Target file name.
        --dest-ds=NAME               [optional] Main data source. [default: psql]
        --dest-table=[SCHEMA.]TABLE  [optional] Target table name.
        --options=OPTIONS            [optional] Loader options.
        --table-def=PATH             Create table file.
        --no-backup                  [optional] Drop dest table with suffix "_old".
        --analyze                    [optional] ANALYZE table after SQL is executed.
        --grant=KEY:VALUE            [optional] GRANT table after SQL is executed. (required keys: privilege, to)
        --gzip                       [optional] Compress Temporary files.
    -v, --variable=NAME=VALUE        Set variable.
        --help                       Shows this message and quit.
        --version                    Shows program version and quit.
```

## License

MIT license.
See LICENSES file for details.

## Credit

Author: Shimpei Kodama

This software is written in working time in Cookpad, Inc.
