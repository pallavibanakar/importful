require "csv"

class ImportAffiliate < ApplicationService
  VALID_HEADERS = [ "first_name", "last_name", "email",  "website_url", "commissions_total", "merchant_slug" ]

  def initialize(merchant:, file:, delimiter: "comma")
    @merchant_id = merchant&.id
    @file = file
    @delimiter = DELIMITERS[(delimiter.presence || "comma").to_sym]
  end

  def call
    return { success: false, message: "Please provide a csv file" } unless @file
    return { success: false, message: "Invalid file type. Please upload a CSV file." } unless csv_file?
    return { success: false, message: "Invalid CSV headers. Please refer to sample CSV file." } unless valid_headers?
    stored_blob = store_file
    if stored_blob
      AffiliateImportJob.perform_later(@merchant_id, stored_blob.signed_id, @delimiter)
      { success: true, message: "CSV successfully uploaded and processing started, Results will be notified." }
    else
      { success: false, message: "Failed to upload file, Please try again" }
    end
  end

  private

  def csv_file?
    @file.content_type == "text/csv"
  end

  def valid_headers?
    headers = nil
    CSV.open(@file.path, headers: true, col_sep: @delimiter) do |csv|
      headers = csv.first&.to_h&.keys
    end
    return false unless headers
    (headers - VALID_HEADERS).empty?
  end

  def store_file
    ActiveStorage::Blob.create_and_upload!(
      io: @file,
      filename: @file.original_filename,
      content_type: @file.content_type
    )
  rescue StandardError => e
    Rails.logger.error "Failed to attach file: #{e.message}"
    nil
  end
end
