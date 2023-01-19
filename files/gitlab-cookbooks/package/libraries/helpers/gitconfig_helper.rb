module Gitconfig
  class Util
    class << self
      def convert_gitconfig(entries_map)
        return [] if entries_map.nil?

        entries_map.flat_map do |section_and_subsection, entries|
          entries.map do |entry|
            # Split up the `bar=value` part to obtain the key and right-hand
            # side of the assignment.
            key, value = entry.split('=', 2)

            raise "Invalid entry detected in omnibus_gitconfig['system']: '#{entry}' should be in the form key=value" if key.nil? || value.nil?

            # And then we need to potentially split the section/subsection if we
            # have `http "http://example.com"` now.
            section, subsection = section_and_subsection.split(' ', 2)
            subsection&.gsub!(/\A"|"\Z/, '')

            raise "Invalid section detected in omnibus_gitconfig['system']: '#{section_and_subsection}' should be in the form `core` or `http \"http://example.com\"`" if section.nil?

            # So that we have finally split up the section, subsection, key and
            # value. It is fine for the `subsection` to be `nil` here in case there
            # is none.
            {
              section: section.strip,
              subsection: subsection&.strip,
              key: key.strip,
              value: value.strip
            }.delete_if { |k, v| v.nil? }
          end
        end
      end
    end
  end
end
