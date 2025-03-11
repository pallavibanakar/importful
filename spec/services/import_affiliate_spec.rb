require 'rails_helper'

RSpec.describe ImportAffiliate do
  let(:merchant) { create(:merchant) }
  let(:valid_file) { fixture_file_upload('spec/fixtures/valid_records.csv', 'text/csv') }
  let(:invalid_csv_file) { fixture_file_upload('spec/fixtures/invalid_headers.csv', 'text/csv') }
  let(:non_csv_file) do
    ActionDispatch::Http::UploadedFile.new(
      filename: "empty.txt",
      type: "text/plain",
      tempfile: StringIO.new("")
    )
  end
  subject { ImportAffiliate.new(merchant: merchant, file: valid_file, delimiter: 'comma') }
  let(:result) { subject.call }

  describe '#call' do
    context 'when the file is valid' do
      it 'upload file, enqueues a job and returns a success message' do
        expect { subject.call }.to have_enqueued_job(AffiliateImportJob)
      end

      it 'uploads file' do
        subject.call
        expect(ActiveStorage::Blob.count).to eq(1)
      end

      it 'returns a success message' do
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('CSV successfully uploaded and processing started, Results will be notified.')
      end
    end

    context 'when the file is nil' do
      subject { ImportAffiliate.new(merchant: merchant, file: nil, delimiter: 'comma') }

      it 'does not enqueue a job and returns an error message' do
        expect { subject.call }.not_to have_enqueued_job(AffiliateImportJob)

        expect(result[:success]).to be_falsey
        expect(result[:message]).to eq('Please provide a csv file')
      end
    end

    context 'when the file is invalid type' do
      subject { ImportAffiliate.new(merchant: merchant, file: non_csv_file, delimiter: 'comma') }

      it 'does not enqueue a job and returns an error message' do
        expect { subject.call }.not_to have_enqueued_job(AffiliateImportJob)

        expect(result[:success]).to be_falsey
        expect(result[:message]).to eq('Invalid file type. Please upload a CSV file.')
      end
    end

    context 'when the csv file has invalid headers' do
      subject { ImportAffiliate.new(merchant: merchant, file: invalid_csv_file, delimiter: 'comma') }

      it 'does not enqueue a job and returns an error message' do
        expect { subject.call }.not_to have_enqueued_job(AffiliateImportJob)

        expect(result[:success]).to be_falsey
        expect(result[:message]).to eq('Invalid CSV headers. Please refer to sample CSV file.')
      end
    end
  end
end
