require 'bricolage/datasource'
require 'bricolage/jobresult'
require 'google/apis/sheets_v4'
require 'googleauth'
require 'csv'
require 'json'
require 'uri'
require 'tempfile'
require 'zlib'
require 'pathname'

module Bricolage

  class SpreadsheetDataSource < DataSource
    declare_type 'spreadsheet'

    SCOPE_BASE = "Google::Apis::SheetsV4::"
    DEFAULT_SCOPE = 'AUTH_SPREADSHEETS_READONLY'
    DEFAULT_APPLICATION_NAME = 'Bricolage'

    def initialize(credentials: nil, scope: nil, application_name: nil)
      @credentials = credentials
      @scope = "#{SCOPE_BASE}#{(scope || DEFAULT_SCOPE)}"
      @application_name = application_name || DEFAULT_APPLICATION_NAME
    end

    attr_reader :scope, :application_name

    def new_task
      SpreadsheetTask.new(self)
    end

    def rows(sheet_id, range, **get_options)
      return enum_for(:rows, sheet_id, range, **get_options) unless block_given?
      response = service.get_spreadsheet_values(sheet_id, range, **get_options)
      response.values.each do |row|
        next if row.all?(&:empty?) # skip empty row
        yield row
      end
    end

    def formatted_rows(sheet_id, range, format = 'csv', **get_options)
      return enum_for(:formatted_rows, sheet_id, range, format, **get_options) unless block_given?
      row_formatter = RowFormatterFactory.new_formatter(format)
      fields = []
      rows(sheet_id, range, **get_options).each_with_index do |row, idx|
        if idx == 0
          fields = row
          next if row_formatter.skip_header?
        end
        yield row_formatter.format(row, fields)
      end
    end

    def credential
      if @credentials
        case
        when @credentials.is_a?(Hash) then StringIO.new(@credentials.to_json)
        when Pathname.new(@credentials).exist? then File.open(@credentials)
        else raise ParameterError, "credentials must be a JSON or PATH. credentials=#{@credentials}"
        end
      elsif ENV['GOOGLE_APPLICATION_CREDENTIALS']
        File.open(ENV['GOOGLE_APPLICATION_CREDENTIALS'])
      else
        raise ParameterError, "credentials or GOOGLE_APPLICATION_CREDENTIALS is required."
      end
    end

    class SpreadsheetTask < DataSourceTask

      def s3export(sheet_id, range, format, value_render_option, dest_ds, dest_file, gzip)
        add S3ExportAction.new(sheet_id, range, format, value_render_option, dest_ds, dest_file, gzip)
      end

      class S3ExportAction < Action
        def initialize(sheet_id, range, format, value_render_option, dest_ds, dest_file, gzip)
          @sheet_id = sheet_id
          @range = range
          @format = format
          @value_render_option = value_render_option
          @dest_ds = dest_ds
          @dest_file = dest_file
          @gzip = gzip
        end

        attr_reader :sheet_id, :range, :dest_ds, :dest_file, :gzip

        def url_encoded_range
          @url_encoded_range ||= URI.encode(range)
        end

        def value_render_option
          @value_render_option&.upcase
        end

        def format
          @format.downcase
        end

        def source
          <<~SOURCE
            "GET https://sheets.googleapis.com/v4/spreadsheets/#{sheet_id}/values/#{url_encoded_range}"
            "PUT s3://#{dest_ds.bucket_name}/#{dest_ds.prefix}/#{dest_file}"
          SOURCE
        end

        def run
          ds.logger.info source
          rows = ds.formatted_rows(sheet_id, range, format, value_render_option: value_render_option)
          Tempfile.open do |f|
            f = Zlib::GzipWriter.wrap(f) if gzip
            f.write rows.to_a.join("\n")
            f.close # flush
            dest_ds.object(dest_file).upload_file(f.path)
          end
          nil
        end

      end #S3ExportAction
    end #SpreadsheetTask

    private

    def service
      return @service if @service
      @service = Google::Apis::SheetsV4::SheetsService.new
      @service.client_options.application_name = application_name
      @service.authorization = authorizer
      @service
    end

    def authorizer
      return @authorizer if @authorizer
      @authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: credential,
        scope: scope,
      )
      # token lifetime is 3600 sec
      # May need to implement refresh logic for long running app???
      @authorizer.fetch_access_token!
      @authorizer
    end

    class RowFormatterFactory
      def self.new_formatter(format)
        const_get(format.upcase! + "Formatter").new
      end

      class CSVFormatter
        def format(values, fields)
          # remove  '\n' with row_sep: nil
          escaped_values = values.map {|v| v.gsub(/\n/,'\\n') }
          CSV.generate_line(escaped_values, row_sep: nil, quote_char: '"', force_quotes: true)
        end

        def skip_header?
          false
        end
      end

      class JSONFormatter
        def format(values, fields)
          # https://stackoverflow.com/questions/1509915/converting-camel-case-to-underscore-case-in-ruby
          normalized_fields = fields.map {|f|
            f.gsub(/::/, '/').
            gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
            gsub(/([a-z\d])([A-Z])/,'\1_\2').
            tr("-", "_").
            tr(" ", "_").
            downcase
          }
          normalized_fields.zip(values).to_h.to_json
        end

        def skip_header?
          true
        end
      end
    end # RowFormatterFactory
  end
end