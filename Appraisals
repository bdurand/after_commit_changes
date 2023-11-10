RAILS_MINOR_RELEASES = ["7.1", "7.0", "6.1", "6.0"].freeze

RAILS_MINOR_RELEASES.each do |version|
  appraise "activerecord-#{version}" do
    gem "activerecord", "~> #{version}.0"
  end
end
