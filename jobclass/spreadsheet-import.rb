require 'bricolage/psqldatasource'

module Bricolage
  JobClass.define('spreadsheet-import') {
    parameters {|params|
      # S3Export
      params.add DataSourceParam.new('spreadsheet', 'src-ds')
      params.add StringParam.new('sheet-id', 'ID', 'Google Spreadsheet ID')
      params.add StringParam.new('range', 'RANGE_EXPR', 'Google Spreadsheet Range Expression')
      params.add EnumParam.new('format', %w(csv json), 'Intermediate data file format.', default: 'json')
      params.add EnumParam.new('value-render-option', %w(FORMATTED_VALUE UNFORMATTED_VALUE FORMULA), 'For values with format on sheets', default: 'FORMATTED_VALUE')
      params.add DataSourceParam.new('s3', 's3-ds')
      params.add DestFileParam.new('s3-file')

      # Load
      params.add DataSourceParam.new('psql', 'dest-ds')
      params.add DestTableParam.new
      params.add KeyValuePairsParam.new('options', 'OPTIONS', 'Loader options.',
          optional: true, default: PSQLLoadOptions.new,
          value_handler: lambda {|value, ctx, vars| PSQLLoadOptions.parse(value) })
      params.add SQLFileParam.new('table-def', 'PATH', 'Create table file.')
      params.add OptionalBoolParam.new('no-backup', 'Drop dest table with suffix "_old".', default: false)

      # Misc
      params.add OptionalBoolParam.new('analyze', 'ANALYZE table after SQL is executed.', default: true)
      params.add KeyValuePairsParam.new('grant', 'KEY:VALUE', 'GRANT table after SQL is executed. (required keys: privilege, to)')
      params.add OptionalBoolParam.new('gzip', 'Compress Temporary files.')
    }

    script {|params, script|
      # S3Export
      script.task(params['src-ds']) {|task|
        task.s3export params['sheet-id'],
                      params['range'],
                      params['format'],
                      params['value-render-option'],
                      params['s3-ds'],
                      params['s3-file'],
                      params['gzip']
      }

      # Load
      script.task(params['dest-ds']) {|task|
        prev_table = '${dest_table}_old'
        work_table = '${dest_table}_wk'

        task.transaction {
          # CREATE
          task.drop_force prev_table
          task.drop_force work_table
          task.exec params['table-def'].replace(/\$\{?dest_table\}?\b/, work_table)

          # COPY
          options = params['gzip'] ? params['options'].merge('gzip' => params['gzip']) : params['options']
          task.load params['s3-ds'], params['s3-file'], work_table,
              params['format'], nil, options

          # GRANT, ANALYZE
          task.grant_if params['grant'], work_table
          task.analyze_if params['analyze'], work_table

          # RENAME
          task.create_dummy_table '${dest_table}'
          task.rename_table params['dest-table'].to_s, "#{params['dest-table'].name}_old"
          task.rename_table work_table, params['dest-table'].name
        }
        # No Backup
        task.drop_force prev_table if params['no-backup']
      }
    }
  } #spreadsheet-import job class
end
