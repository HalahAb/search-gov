class FilterableSearch < Search
  TIME_FILTER_PARAMS = %i(hour day week month year)
  TIME_BASED_SEARCH_OPTIONS = Hash[TIME_FILTER_PARAMS.collect { |p| [p.to_s[0], p] }]

  class_attribute :default_sort_by
  self.default_sort_by = 'r'.freeze

  attr_reader :since,
              :sort,
              :sort_by,
              :tbs,
              :until

  def initialize(options)
    super
    initialize_date_attributes options
    @sort_by = options[:sort_by] if %w(date r).include?(options[:sort_by])
    @sort = 'published_at:desc' unless sort_by_relevance?
  end

  def sort_by_relevance?
    sort_by.nil? || 'r' == sort_by
  end

  def custom_filter_params?
    !default_sort? || tbs || since || self.until
  end

  def default_sort?
    sort_by.nil? || sort_by == default_sort_by
  end

  protected

  def initialize_date_attributes(options)
    @until = parse_until_ts options[:until_date]
    @since = parse_since_ts options[:since_date]

    if @since and @until and @since > @until
      @since, @until = @until.beginning_of_day, @since.end_of_day
    end

    extent = TIME_BASED_SEARCH_OPTIONS[options[:tbs]]
    if extent && @since.nil? && @until.nil?
      @tbs = options[:tbs]
      @since = since_when extent
    end
  end

  def parse_until_ts(until_date_str)
    return unless until_date_str.present?
    parse_date_str(until_date_str).end_of_day
  rescue
    DateTime.current.end_of_day
  end

  def parse_since_ts(since_date_str)
    return unless since_date_str.present?
    parsed_date = parse_date_str(since_date_str).beginning_of_day rescue nil
    parsed_date || (@until ? @until : DateTime.current).prev_year.beginning_of_day
  end

  def parse_date_str(date_str)
    DateTime.strptime(date_str, I18n.t(:cdr_format)).utc
  end

  def since_when(extent)
    time = 1.send(extent).ago
    time = time.beginning_of_day if extent != :hour
    time
  end
end
