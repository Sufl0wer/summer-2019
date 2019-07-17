class Parser
  FIELDS_FROM_HTML = {
    'used_by' => 'used_by_count',
    'watched_by' => 'watched_by_count',
    'contributors' => 'contributors_count'
  }.freeze

  FIELDS_FROM_API = {
    'name' => 'name',
    'stars' => 'watchers_count',
    'forks' => 'forks_count',
    'issues' => 'open_issues_count'
  }.freeze

  URI = 'https://api.github.com/search/repositories'.freeze

  attr_reader :info

  def initialize(gem_name)
    @info_from_api = collect_repository_info_for gem_name
    @html = Util::Parse::HTML.parse @info_from_api['html_url']
    @info = collect_info
  end

  private

  def collect_info
    info = {}
    info = info.merge fields_from_api
    info.merge fields_from_html
  end

  def fields_from_html
    fields = {}
    FIELDS_FROM_HTML.each do |field, to_method|
      fields[field] = send(to_method)
    end
    fields
  end

  def fields_from_api
    fields = {}
    FIELDS_FROM_API.each do |field, field_key|
      fields[field] = @info_from_api[field_key]
    end
    fields
  end

  def collect_repository_info_for(gem_name)
    api_response = HTTParty.get(URI, query: { q: gem_name })

    api_response.to_hash['items'].first
  end

  def contributors_count
    contributors = @html.css("a span[class='num text-emphasized']").last.text
    parse_int(contributors)
  end

  def watched_by_count
    watched_by_count = @html.xpath('/html/body/div[4]/div/main/div[1]/div/ul/li').select do |el|
      el.text.include? 'Watch'
    end.first.text
    parse_int(watched_by_count)
  end

  def used_by_count
    html = Util::Parse::HTML.parse "#{@info_from_api['html_url']}/network/dependents"
    used_by = html.css('a.btn-link:nth-child(1)').text
    parse_int(used_by)
  end

  def parse_int(num_string)
    num_string.gsub(/[^0-9]/, '').to_i
  end
end
