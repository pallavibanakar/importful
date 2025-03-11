require 'rails_helper'

RSpec.describe "Imports", type: :request do
  let(:merchant) { create(:merchant) }

  describe "GET /imports" do
    context 'with valid merchant' do
      it "returns http success" do
        get "/merchants/#{merchant.slug}/imports/new"
        expect(response).to have_http_status(:success)
      end
    end

    context 'with invalid merchant' do
      it "redirects to merchants page" do
        get "/merchants/invalid-slug/imports/new"
        expect(response).to redirect_to(merchants_url)
      end
    end
  end

  describe "POST /imports" do
    let(:delimiter) { 'comma' }

    context 'when file is valid' do
      let(:valid_csv_file) { fixture_file_upload('spec/fixtures/valid_records.csv', 'text/csv') }

      before do
        allow(ImportAffiliate).to receive(:call).and_return({ success: true, message: 'CSV successfully uploaded and processing started, Results will be notified.' })
      end

      it 'calls the service and redirects with success message' do
        post "/merchants/#{merchant.slug}/imports", params: { file: valid_csv_file, delimiter: delimiter }

        expect(response).to redirect_to(new_merchant_import_path(merchant.slug))
        expect(flash[:notice]).to eq('CSV successfully uploaded and processing started, Results will be notified.')
        expect(ImportAffiliate).to have_received(:call)
      end
    end

    context 'when file is not present' do
      before do
        allow(ImportAffiliate).to receive(:call).and_return({ success: false, message: 'Please provide a csv file' })
      end

      it 'calls the service and redirects with error message' do
        post "/merchants/#{merchant.slug}/imports", params: { file: nil, delimiter: delimiter }

        expect(response).to redirect_to(new_merchant_import_path(merchant.slug))
        expect(flash[:alert]).to eq('Please provide a csv file')
        expect(ImportAffiliate).to have_received(:call)
      end
    end

    context 'when file is not valid type' do
      let(:non_csv_file) do
        ActionDispatch::Http::UploadedFile.new(
          filename: "empty.txt",
          type: "text/plain",
          tempfile: StringIO.new("")
        )
      end

      before do
        allow(ImportAffiliate).to receive(:call).and_return({ success: false, message: 'Invalid file type. Please upload a CSV file.' })
      end

      it 'calls the service and redirects with error message' do
        post "/merchants/#{merchant.slug}/imports", params: { file: non_csv_file, delimiter: delimiter }

        expect(response).to redirect_to(new_merchant_import_path(merchant.slug))
        expect(flash[:alert]).to eq('Invalid file type. Please upload a CSV file.')
        expect(ImportAffiliate).to have_received(:call)
      end
    end

    context 'when csv file does not have valid headers' do
      let(:invalid_csv_file) { fixture_file_upload('spec/fixtures/invalid_headers.csv', 'text/csv') }

      before do
        allow(ImportAffiliate).to receive(:call).and_return({ success: false, message: 'Invalid CSV headers. Please refer to sample CSV file.' })
      end

      it 'calls the service and redirects with error message' do
        post "/merchants/#{merchant.slug}/imports", params: { file: invalid_csv_file, delimiter: delimiter }

        expect(response).to redirect_to(new_merchant_import_path(merchant.slug))
        expect(flash[:alert]).to eq('Invalid CSV headers. Please refer to sample CSV file.')
        expect(ImportAffiliate).to have_received(:call)
      end
    end
  end
end
