module Builder
  class IcalPlugin < ActionView::TemplateHandler
    include ActionView::TemplateHandlers::Compilable if defined?(ActionView::TemplateHandlers::Compilable)

    def compile(template)
      "_set_controller_content_type(Mime::ICS);" +
        "cal = ::Builder::Ical.new;" +
        "self.output_buffer = cal.to_s;" +
        template.source +
        ";cal.to_s;"
    end

  end
end

puts "HERE!"
ActionView::Template.register_template_handler(:ical, Builder::IcalPlugin)
