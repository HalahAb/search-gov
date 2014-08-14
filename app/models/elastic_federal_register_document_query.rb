class ElasticFederalRegisterDocumentQuery < ElasticTextFilteredQuery
  def initialize(options)
    super(options.merge({ sort: 'comments_close_on:desc' }))
    self.highlighted_fields = %i(abstract title)
    @federal_register_agency_ids = options[:federal_register_agency_ids]
  end

  def filtered_query_query(json)
    json.query do
      json.bool do
        json.set! :should do |should_json|
          should_json.child! { should_json.terms { should_json.document_number @q.split(/\s+/) } }
          should_json.child! { multi_match(should_json, highlighted_fields, @q, multi_match_options) }
        end
      end
    end if @q.present?
  end

  def multi_match_options
    { operator: :and, analyzer: @text_analyzer }
  end

  def filtered_query_filter(json)
    json.filter do
      json.bool do
        json.must do
          json.child! { json.terms { json.federal_register_agency_ids @federal_register_agency_ids } }
        end
      end
    end
  end
end