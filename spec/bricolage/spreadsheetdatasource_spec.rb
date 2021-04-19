require 'bricolage/spreadsheetdatasource'
require 'json'

module Bricolage
  describe SpreadsheetDataSource do

    ROWS = [['1','a'],['2','b']]
    let(:api_response) {
      d = double
      allow(d).to receive(:values) {
        ROWS
      }
      d
    }
    let(:sheet_id) {'1'}
    let(:range) {'2'}

    shared_context "stub_api_call" do
      let(:ds) {
        ds = SpreadsheetDataSource.new
        allow(ds).to receive_message_chain(:service, :get_spreadsheet_values) {
          api_response
        }
        ds
      }
		end

    describe '#initialize' do
      it 'should respond with default values' do
        ds = SpreadsheetDataSource.new
        expect(ds.scope).to eq("#{SpreadsheetDataSource::SCOPE_BASE}#{SpreadsheetDataSource::DEFAULT_SCOPE}")
        expect(ds.application_name).to eq(SpreadsheetDataSource::DEFAULT_APPLICATION_NAME)
      end

      it 'should set parameter to instance val' do
        scope = 'hoge'
        application_name = 'huga'
        ds = SpreadsheetDataSource.new(scope: scope, application_name: application_name)
        expect(ds.scope).to eq("#{SpreadsheetDataSource::SCOPE_BASE}#{scope}")
        expect(ds.application_name).to eq(application_name)
      end
    end

    describe '#rows' do
      include_context "stub_api_call"
      it 'should return array of rows' do
        expect { |b| ds.rows(sheet_id, range, &b) }.to yield_successive_args(ROWS[0], ROWS[1])
      end
    end

    describe '#formatted_rows' do
      include_context "stub_api_call"
      it 'should return csv by default' do
        expect { |b| ds.formatted_rows(sheet_id, range, &b) }.to yield_successive_args('"1","a"', '"2","b"')
      end

      it 'should return json with format = json' do
        expect { |b| ds.formatted_rows(sheet_id, range, 'json', &b) }.to yield_successive_args('{"1":"2","a":"b"}')
      end
    end

    describe '#credential' do
      let(:dummy_credential_filepath) { './spec/support/dummy_credential.json' }
      let(:dummy_credentials_json) { '{"key":"value"}' }
      let(:dummy_credentials) { JSON.parse(dummy_credentials_json) }

      after do
        ENV['GOOGLE_APPLICATION_CREDENTIALS'] = nil
      end

      it 'returns credential when initialized with hash parameter' do
        ds = SpreadsheetDataSource.new(credentials: dummy_credentials)
        expect(ds.credential.read).to eq(dummy_credentials_json)
      end

      it 'returns credential when initialized with filepath' do
        ds = SpreadsheetDataSource.new(credentials: dummy_credential_filepath)
        expect(ds.credential.read).to eq(File.open(dummy_credential_filepath).read)
      end

      it 'returns credential when GOOGLE_APPLICATION_CREDENTIALS is set' do
        ENV['GOOGLE_APPLICATION_CREDENTIALS'] = dummy_credential_filepath
        ds = SpreadsheetDataSource.new
        expect(ds.credential.read).to eq(File.open(dummy_credential_filepath).read)
      end

      it 'raise error when initialized without parameter and GOOGLE_APPLICATION_CREDENTIALS is not set' do
        ds = SpreadsheetDataSource.new
        expect {ds.credential}.to raise_error(ParameterError)
      end
    end

  end
end
