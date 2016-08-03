class Ingestor::Bea
  include HTTParty

  LOG_COLUMNS = [
    :options,
    :api_response_code,
    :api_error
  ]

  attr_accessor :dataset, :options, :api_response

  class_attribute :data_logger
  self.data_logger = DataLog.new('bea.log')

  BEA_DIR = Rails.root.join('app', 'data', 'bea')
  ALL_VALUES = {
    year: 'X'
  }

  DATASET_NAME = {
    fixed_assets: 'FixedAssets',
    nipa: 'NIPA'
  }

  FREQUENCY = {
    annual: 'A',
    quarterly: 'Q',
    monthly: 'M'
  }

  SHOW_MILLIONS = {
    no: 'N',
    yes: 'Y'
  }

  def initialize(dataset, opts={})
    @dataset = dataset
    @options = opts
  end

  def parameters
    self.class.get(url, { query: { userid: api_key, method: 'GetParameterList', datasetname: DATASET_NAME[dataset] } })
  end

  def write_to_json
    FileUtils.mkdir_p(series_dir) unless File.exists?(series_dir)
    File.open("#{ series_dir }/#{ SimpleUUID::UUID.new.to_guid }.json", 'wb+') { |f| f.write api_response.to_json }
    data_logger.log(*log_columns)
  end

  def series_dir
    "#{ BEA_DIR }/#{ dataset }/#{ options[:tableid] }/#{ options[:year] }"
  end

  def url
    @url ||= SystemConfig.instance.services.bea.url
  end

  def api_key
    @api_key ||= SystemConfig.instance.services.bea.api_key
  end

  def external_tables
    @external_tables ||= Source.where(internal_name: :bea).first.datasets.where(internal_name: dataset).first.external_tables
  end

  def log_columns
    LOG_COLUMNS.map { |c| send(c) }
  end

  def api_response_code
    api_response.code
  end

  def api_error
    api_response["BEAAPI"]["Error"]
  end
end
