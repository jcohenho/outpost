module ListHelper
  ICON_DOWN = "icon-arrow-down"
  ICON_UP   = "icon-arrow-up"

  BOOLEAN_BOOTSTRAP_MAP = {
    true  => { icon: "icon-white icon-ok",     badge: "badge badge-success"},
    false => { icon: "icon-white icon-remove", badge: "badge badge-important"}
  }

  # Public: Renders the attribute for this column and record
  #
  # column  - (Outpost::Column) The column object.
  # record  - (Object) The ActiveRecord object being listed.
  #
  # Examples
  #
  #   column.attribute # => :published_at
  #   <%= render_attribute(column, @post) %>
  #   # => 2013-03-13 11:39:37 -0700
  #
  # Returns String of the rendered attribute.
  def render_attribute(column, record)
    if column.display.is_a? Proc
      # If we passed a Proc to :display, use it.
      record.instance_eval(&column.display)
    else
      if column._display_helper.present?
        # If we've already figured out which method to use for
        # this column, then use it. This is to prevent this method
        # from having to fully run hundreds of times on each page.
        display_helper = column._display_helper

      elsif column.display.is_a? Symbol
        display_helper = column.display

      elsif self.methods.include? :"display_#{column.attribute}"
        # If we have explicitly defined a helper for this attribute, use it.
        display_helper = :"display_#{column.attribute}"

      elsif record.class.respond_to?(:reflect_on_association) &&
        record.class.reflect_on_association(column.attribute.to_sym)
        # For associations, display the associated object's #to_title
        display_helper = :display_record

      elsif record.class.respond_to?(:columns_hash) &&
        (ar_column = record.class.columns_hash[column.attribute]) &&
        self.methods.include?(type_helper = :"display_#{ar_column.type}")
        # display_#{column_type} for generic display
        # Example: display_datetime
        display_helper = type_helper

      else
        # Fallback to just using attribute.to_s
        display_helper = :display_string
      end

      value = record.send(column.attribute)
      column._display_helper = display_helper

      if self.method(display_helper).arity == 2
        send(display_helper, value, record)
      else
        send(display_helper, value)
      end
    end
  end


  # Public: Format a DateTime for displaying in lists
  #
  # date - (DateTime) The date to be formatted
  #
  # Examples
  #
  #   display_date(Time.zone.now)
  #   # => March 13th, 2012
  #
  # Returns String of formatted date
  def display_date(date)
    format_date(date, format: :full_date)
  end


  # Public: Display the attribute or "[blank]" if not present
  #
  # attrib  - (String) The attribute to display
  # options - (Hash) A hash of options (default: {}).
  #           fallback - (String) The string to use as placeholder text
  #                      (default: "[blank]").
  #
  # Examples
  #
  #   display_or_fallback("Foo")
  #   # => Foo
  #
  #   display_or_fallback("", fallback: "none")
  #   # => none
  #
  # Returns String of either the attribute (if present) or "[blank]"
  def display_or_fallback(attrib, options={})
    fallback = options[:fallback] || "[blank]"
    attrib.present? ? attrib.to_s : content_tag(:em, fallback)
  end


  # Public: Display the attribute as a string.
  #
  # attrib - (String) The attribute to display.
  #
  # Examples
  #
  #   display_string("anything")
  #   # => "anything"
  #
  # Returns String of the attribute
  def display_string(attrib)
    attrib.to_s
  end


  # Public: Displays an String representation of the record using +#to_title+.
  #
  # record - (String) The associated record.
  #
  # Examples
  #
  #   user = User.last
  #   user.to_title # => "James Earl Jones"
  #   display_record(User.last)
  #   # => "James Earl Jones"
  #
  # Returns String representation of the passed-in record.
  def display_record(associated_record)
    associated_record.try(:to_title)
  end


  # Public: Display a formatted DateTime.
  #
  # datetime - (DateTime) The DateTime object to format.
  #
  # Examples
  #
  #   display_datetime(Time.zone.now)
  #   # => "March 13th, 2013,  4:12pm"
  #
  # Returns String of the formatted date and time.
  def display_datetime(datetime)
    format_date(datetime, format: :full_date, time: true)
  end


  # Public: Display a boolean attribute as a sweet icon.
  #
  # boolean - (boolean) true or false
  #
  # Examples
  #
  #   display_boolean(true)
  #   # => <span class="badge badge-important">
  #   # =>   <i class="icon-white icon-ok"></i>
  #   # => </span>
  #
  # Returns String of the appropriate icon.
  def display_boolean(boolean)
    content_tag(:span,
      content_tag(:i, "", class: BOOLEAN_BOOTSTRAP_MAP[!!boolean][:icon]),
      class: BOOLEAN_BOOTSTRAP_MAP[!!boolean][:badge])
  end


  # Public: Maps the passed-in sort mode (asc, desc) to the appropriate
  # Bootstrap Glyphicons (icon-arrow-up, icon-arrow-down respectively)
  #
  # direction - (String) "ASC", "DESC"
  #
  # Examples
  #
  #   <i class="<%= direction_icon('ASC') %>">
  #   # => <i class="icon-arrow-up">
  #
  # Returns String of the icon class.
  def direction_icon(direction)
    direction = direction.to_s.upcase

    case direction
    when Outpost::DESCENDING then ICON_DOWN
    when Outpost::ASCENDING  then ICON_UP
    end
  end


  # Public: Which sort mode to switch to. Useful for creating links to
  # switch the sort mode or change the list order.
  #
  # column            - (Outpost::Column) The column on which the sort
  #                     will be performed.
  # current_attribute - (String) The attribute that is currently being
  #                     ordered.
  # current_direction - (String) The current sort mode ("ASC", "DESC").
  #
  # Examples
  #
  #   <%= link_to column.header, request.parameters.merge({
  #      :direction => switch_direction(
  #          column, current_attribute, current_direction
  #      )
  #   }) %>
  #
  # Returns String of the sort mode, "asc" or "desc"
  def switch_direction(column, current_attribute, current_direction)
    direction = current_direction.to_s.upcase

    if column.attribute == current_attribute
      case direction
      when Outpost::ASCENDING then Outpost::DESCENDING
      when Outpost::DESCENDING then Outpost::ASCENDING
      else column.default_order_direction
      end
    else
      column.default_order_direction
    end
  end


  # Public: Generate a CSS class for the column. If the column represents
  # an association, the class will be "column-association".
  #
  # model     - (Class) The ActiveRecord model.
  # attribute - (String) The attribute for this column.
  #
  # Examples
  #
  #   <tr class="<%= column_type_class(BlogEntry, 'created_at') %>">
  #   # => <tr class="column-datetime">
  #
  # Returns String to be used as a CSS class.
  def column_type_class(model, attribute)
    if model.respond_to?(:columns_hash)
      if column = model.columns_hash[attribute]
        "column-#{column.type}"
      else
        "column-association"
      end
    else
      "column-#{attribute}"
    end
  end


  # Public: Generate a CSS class for this attribute
  #
  # attribute - (String) The attribute.
  #
  # Examples
  #
  #   <td class="<%= column_attribute_class('created_at') %>">
  #   # => <td class="column-created_at">
  #
  # Returns String to be used as a CSS class.
  def column_attribute_class(attribute)
    "column-#{attribute}".parameterize
  end


  # Public: Call the BOOLEAN_BOOTSTRAP_MAP
  def boolean_bootstrap_map
    BOOLEAN_BOOTSTRAP_MAP
  end
end
