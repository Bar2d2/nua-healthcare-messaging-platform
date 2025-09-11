# frozen_string_literal: true

# Pagy Configuration for High-Performance Message Pagination
# See: https://ddnexus.github.io/pagy/docs/api/pagy

require 'pagy/extras/overflow'    # Handle invalid pages gracefully
require 'pagy/extras/metadata'   # For JSON APIs
require 'pagy/extras/headers'    # For API pagination headers
require 'pagy/extras/bootstrap'  # Bootstrap styling integration

# Default pagination settings optimized for message performance
Pagy::DEFAULT[:items] = 10        # Messages per page (optimal for performance)
Pagy::DEFAULT[:limit] = 10        # Explicit limit override (fixes pagination issue)
Pagy::DEFAULT[:overflow] = :last_page  # Redirect to last page if page number too high
Pagy::DEFAULT[:size] = 5          # Number of page links in navigation

# Performance optimizations
Pagy::DEFAULT[:limit_param] = :per_page  # Allow dynamic items per page
Pagy::DEFAULT[:limit_max] = 100   # Maximum items per page (prevent abuse)

# JSON API configuration for our API endpoints
Pagy::DEFAULT[:jsonapi] = true

# Enable metadata for AJAX/Turbo Stream pagination
Pagy::DEFAULT[:metadata] = %i[
  scaffold_url
  first_url prev_url next_url last_url
  count page items vars pages last offset from to
  series
]
