class Analytics::HomeController < Analytics::AnalyticsController
  MAX_NUMBER_OF_BIG_MOVERS_TO_SHOW = 21
  MAX_NUMBER_OF_NO_RESULTS_TO_SHOW = 21
  before_filter :establish_aws_connection, :only => [:queries]

  def index
  end

  def queries
    @page_title = 'Queries'
    @day_being_shown = request["day"].blank? ? DailyQueryStat.most_recent_populated_date : request["day"].to_date
    @num_results_dqs = (request["num_results_dqs"] || "10").to_i
    @num_results_dqgs = (request["num_results_dqgs"] || "10").to_i
    @most_recent_day_popular_terms = DailyQueryStat.most_popular_terms(@day_being_shown, 1, @num_results_dqs)
    @trailing_week_popular_terms = DailyQueryStat.most_popular_terms(@day_being_shown, 7, @num_results_dqs)
    @trailing_month_popular_terms = DailyQueryStat.most_popular_terms(@day_being_shown, 30, @num_results_dqs)
    @most_recent_day_popular_query_groups = DailyQueryStat.most_popular_query_groups(@day_being_shown, 1, @num_results_dqgs)
    @trailing_week_popular_query_groups = DailyQueryStat.most_popular_query_groups(@day_being_shown, 7, @num_results_dqgs)
    @trailing_month_popular_query_groups = DailyQueryStat.most_popular_query_groups(@day_being_shown, 30, @num_results_dqgs)
    @most_recent_day_biggest_movers = MovingQuery.biggest_movers(@day_being_shown, MAX_NUMBER_OF_BIG_MOVERS_TO_SHOW)
    @most_recent_day_no_results_queries = DailyQueryNoresultsStat.no_results_queries(@day_being_shown, MAX_NUMBER_OF_NO_RESULTS_TO_SHOW)
    @contextual_query_total = DailyContextualQueryTotal.total_for(@day_being_shown)
    @start_date = 1.month.ago.to_date
    @end_date = Date.yesterday
  end
end
