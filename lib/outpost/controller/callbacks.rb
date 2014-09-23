module Outpost
  module Controller
    module Callbacks
      def get_record
        @record = model.find(params[:id])
      end

      def get_records
        @records = model.order(
          "#{order_attribute} #{order_direction}")
      end
    end # Callbacks
  end # Controller
end # Outpost
