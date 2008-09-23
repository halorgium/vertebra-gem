require 'thor'
require 'pp'
require 'vertebra/actor'
require 'vertebra/extensions'

module VertebraGemtool
  class Actor < Vertebra::Actor
    # TODO: These actors need a way to return a useful response in the face of errors encountered when performing an operation.

    # The semantics of this actor are documented here:
    # https://engineyard.onconfluence.com/display/OSS/Acceptance+Criteria+for+Gem+Agent
    #
    # If there are changes or additions to this actor, document them in the comments below
    # and then just cut and paste the comments back into the wiki document so that the
    # documentation outside of the code stays current.

    provides '/gem'

    # A {{list}} request MAY specify a {{filter}} attribute.
    # The response MUST return a hash containing gem names as the key with an array of gem versions as the value.

    bind_op "/gem/list", :list
    desc "/gem/list", "Get a list of gems"
    method_options :filter => :optional

    def list(options = {})
      filter = options['filter'] || nil
      output = spawn("gem", "list") do |output|
        gemlist = output.chomp.split("\n").reject { |g| g =~ /^\*\*\* / || g.empty? }
        gemlist.inject({}) do |hsh, str|
          md = str.match(/(.*)\W\((.*)\)/)
          hsh[md[1]] = md[2].split(", ")
          hsh
        end
      end
    end

    # A {{install}} request MUST specify a {{name}} attribute which indicates the gem to install.
    # The response SHOULD be the only the normal STDOUT/STDERR generated by a spawned actor process.

    bind_op "/gem/install", :install
    desc "/gem/install", "Install a gem"
    method_options :name => :required, :version -> :optional

    def install(options = {})
      str = options['name']
      args = ["gem", "install", str]
      args = args + ['-v', options['version']] if options['version']
      args = args + ["--no-rdoc", "--no-ri"]
      spawn args
    end

    # A {{install}} request MUST specify a {{name}} attribute which indicates the gem to install.
    # The response SHOULD be the only the normal STDOUT/STDERR generated by a spawned actor process.

    bind_op "/gem/uninstall", :uninstall
    desc "/gem/uninstall", "Install a gem"
    method_options :name => :required

    def uninstall(options = {})
      str = options['name']
      str << "-#{options['version']}" if options['version']
      spawn "gem", "uninstall", str
    end

    # A {{source/add}} request MUST specify a {{source_url}} attribute which indicates the URL to add.
    # The response SHOULD be the only the normal STDOUT/STDERR generated by a spawned actor process.

    bind_op "/gem/source/add", :add_source_url
    desc "/gem/source/add", "Add a rubygems source URL"
    method_options :source_url => :required

    def add_source_url(options = {})
      spawn "gem", "source", "-a", options['source_url']
    end

    # A {{source/remove}} request MUST specify a {{source_url}} attribute which indicates the URL to remove.
    # The response SHOULD be the only the normal STDOUT/STDERR generated by a spawned actor process.

    bind_op "/gem/source/remove", :remove_source_url
    desc "/gem/source/remove", "Remove a rubygems source URL"
    method_options :source_url => :required

    def remove_source_url(options = {})
      spawn "gem", "source", "-r", options['source_url']
    end

    # The response MUST return an array of HTTP source urls.

    bind_op "/gem/source/list", :list_sources
    desc "/gem/source/list", "List rubygem sources"

    def list_sources(options = {})
      spawn "gem", "source", "-l" do |output|
        output.chomp.split("\n").reject { |s| s !~ /^http/ }
      end
    end
  end
end
