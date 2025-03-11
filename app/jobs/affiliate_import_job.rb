require "csv"

class AffiliateImportJob < ApplicationJob
  queue_as :urgent
  BATCH_SIZE = 10000

  def perform(merchant_id, blob_signed_id, delimiter)
    Rails.logger.info "---- In AffiliateImportJob ------"
    blob = ActiveStorage::Blob.find_signed(blob_signed_id)
    invalid_rows = []
    valid_rows_count = 0
    blob.open do |file|
      CSV.open(file.path, headers: true, col_sep: delimiter) do |csv|
        csv.lazy.each_slice(BATCH_SIZE) do |csv_rows|
          valid_rows, error_rows = validate_rows(merchant_id, csv_rows)
          invalid_rows.concat(error_rows)
          upserted_records = Affiliate.upsert_all(valid_rows, returning: :id, unique_by: [ :merchant_id, :email ])
          valid_rows_count += upserted_records.rows.uniq.size
        end
      end
    end
    Rails.logger.debug "Invalid_rows: #{invalid_rows}"
    create_notification(merchant_id, valid_rows_count, invalid_rows, blob.filename.to_s)
    clear_temp_file(blob)
  end

  private

  def validate_rows(merchant_id, rows)
    valid_rows, invalid_rows = [], []
    rows.each do |row|
      validation_result = affiliate_contract.call(row.to_h)
      if validation_result.errors.empty?
        valid_rows.push(validation_result.to_h.merge({ merchant_id: merchant_id }))
      else
        invalid_rows.push(validation_result)
      end
    end
    [ valid_rows, invalid_rows ]
  end

  def affiliate_contract
    @affiliate_contract ||= AffiliateContract.new
  end

  def clear_temp_file(blob)
    blob.purge
  end

  def csv_errors_data(invalid_rows)
    headers = invalid_rows.first.to_h.keys + [ :errors ]
    CSV.generate do |data|
      data << headers
      invalid_rows.each do |row|
        row_errors = row.errors.to_h.map { |field, messages| "#{field}: #{messages.join(', ')}" }.join("; ")
        data << row.to_h.values + [ row_errors ]
      end
    end
  end

  def create_notification(merchant_id, valid_rows_count, invalid_rows, original_file_name)
    notification = AffiliateImport.new(title: "Affiliate Import Completed", merchant_id: merchant_id)
    if invalid_rows.empty?
      notification.message = "Affiliate import successful for #{valid_rows_count} rows."
    else
      notification.message = "Affiliate import succesful for #{valid_rows_count} rows, Please download file for unsuccessful rows and try again."
      notification.errors_file.attach(
        io: StringIO.new(csv_errors_data(invalid_rows)),
        filename: "invalid_rows_#{original_file_name}",
        content_type: "text/csv"
      )
    end
    notification.save
  end
end
