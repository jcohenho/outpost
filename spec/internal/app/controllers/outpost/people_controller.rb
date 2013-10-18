module Outpost
  class PeopleController < Outpost::ResourceController
    outpost_controller model: Person

    define_list do |l|
      l.default_order_attribute   = "name"
      l.default_order_direction   = DESCENDING
      l.per_page                  = 25

      l.column :name
      l.column :email
      l.column :location
      l.column :age
    end

    private

    def form_params
      params.require(model.singular_route_key)
        .permit(:name, :email, :location, :age)
    end
  end
end
