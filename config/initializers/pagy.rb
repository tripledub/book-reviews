# Pagy initializer file (9.4.0)
# Uncomment the following lines to load the extras you need:
# require 'pagy/extras/bootstrap'
# require 'pagy/extras/bulma'
# require 'pagy/extras/foundation'
# require 'pagy/extras/materialize'
# require 'pagy/extras/navs'
# require 'pagy/extras/semantic'
# require 'pagy/extras/uikit'

# Backend Extras
# require 'pagy/extras/array'
# require 'pagy/extras/countless'
# require 'pagy/extras/elasticsearch_rails'
# require 'pagy/extras/searchkick'

# Feature Extras
# require 'pagy/extras/headers'
# require 'pagy/extras/items'
require "pagy/extras/overflow"
# require 'pagy/extras/metadata'
# require 'pagy/extras/trim'

# Instance variables
# See https://ddnexus.github.io/pagy/api/pagy#variables
# All the Pagy::VARS are set for all the Pagy instances but can be overridden
# per instance by just passing them to Pagy.new or the #pagy controller method

# Items per page - configurable via environment variable
Pagy::DEFAULT[:items] = ENV.fetch("PAGY_ITEMS_PER_PAGE", 20).to_i

# How many page links to show
Pagy::DEFAULT[:size] = ENV.fetch("PAGY_PAGE_LINKS", 7).to_i

# Set to :last_page to handle overflow gracefully
Pagy::DEFAULT[:overflow] = :last_page

# Maximum items per page (prevents abuse)
Pagy::DEFAULT[:max_items] = ENV.fetch("PAGY_MAX_ITEMS", 100).to_i
