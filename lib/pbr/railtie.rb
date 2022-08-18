require 'tgw-pbr'
require 'rails'

module ProductBoard
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/generate.rake'
    end
  end
end
