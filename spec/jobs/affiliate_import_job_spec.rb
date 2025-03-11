require 'rails_helper'

RSpec.describe AffiliateImportJob, type: :job do
  let(:file_path) { Rails.root.join('spec/fixtures/valid_records.csv') }
  let(:filename) { 'valid_records.csv' }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(file_path),
      filename: filename,
      content_type: 'text/csv'
    )
  end
  let(:blob_signed_id) { blob.signed_id }
  let(:merchant_id) { create(:merchant)&.id }
  let(:delimiter) { ',' }
  subject { -> { AffiliateImportJob.perform_now(merchant_id, blob_signed_id, delimiter) } }
  let(:all_records_count) do
    CSV.open(file_path, headers: true, col_sep: delimiter)
      .map { |row| row['email'] }.count
  end
  let(:unique_valid_row_count) do
    CSV.open(file_path, headers: true, col_sep: delimiter)
    .map { |row| row['email'] if row['first_name'].present? && row['last_name'].present? }.compact.uniq.count
  end

  describe '#perform' do
    context 'with valid records' do
      it 'processes the CSV file successfully' do
        expect { subject.call }.not_to raise_error
      end

      it 'creates affiliates' do
        expect { subject.call }.to change { Affiliate.count }.by(all_records_count)
      end

      it 'creates notification' do
        expect { subject.call }.to change { Notification.count }.by(1)
        notification = Notification.last
        expect(notification.errors_file.attached?).to be_falsey
        expect(notification.title).to eq('Affiliate Import Completed')
        expect(notification.message).to eq("Affiliate import successful for #{all_records_count} rows.")
      end
    end

    context 'with valid but duplicate records' do
      let(:file_path) { Rails.root.join('spec/fixtures/duplicate_records.csv') }
      let(:filename) { 'duplicate_records.csv' }

      it 'processes the CSV file successfully' do
        expect { subject.call }.not_to raise_error
      end

      it 'creates uniq affiliates' do
        expect { subject.call }.to change { Affiliate.count }.by(unique_valid_row_count)
      end

      it 'creates notification' do
        expect { subject.call }.to change { Notification.count }.by(1)
        notification = Notification.last
        expect(notification.errors_file.attached?).to be_falsey
        expect(notification.title).to eq('Affiliate Import Completed')
        expect(notification.message).to eq("Affiliate import successful for #{unique_valid_row_count} rows.")
      end
    end

    context 'with invalid records' do
      let(:file_path) { Rails.root.join('spec/fixtures/invalid_records.csv') }
      let(:filename) { 'invalid_records.csv' }

      it 'processes the CSV file successfully' do
        expect { subject.call }.not_to raise_error
      end

      it 'creates valid affiliates' do
        expect { subject.call }.to change { Affiliate.count }.by(unique_valid_row_count)
      end

      it 'creates notification' do
        expect { subject.call }.to change { Notification.count }.by(1)
        notification = Notification.last
        expect(notification.errors_file.attached?).to be_truthy
        expect(notification.title).to eq('Affiliate Import Completed')
        expect(notification.message).to eq("Affiliate import succesful for #{unique_valid_row_count} rows, Please download file for unsuccessful rows and try again.")
      end
    end
  end
end
