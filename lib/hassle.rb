require 'rack'
require 'sass'
require 'sass/plugin'

class Hassle
  def initialize(app)
    @app = app
    @compiler = Hassle::Compiler.new
    @compiler.compile
  end

  def call(env)
    path = env['PATH_INFO']

    if @compiler.stylesheets.include?(path)
      stylesheet = path.split('/').last
      stylesheet_path = File.join(@compiler.compile_location, path)

      # Read the contents of the stylesheet
      content = File.read(stylesheet_path)
      length = "".respond_to?(:bytesize) ? content.bytesize.to_s : content.size.to_s
      [200, {'Content-Type' => 'text/css', 'Content-Length' => length}, [content]]
    else
      # Not a request Hassle cares about
      @app.call(env)
    end
  end
end

class Hassle::Compiler
  def options
    Sass::Plugin.options
  end

  def css_location(path)
    expanded = File.expand_path(path)
    public_dir = File.join(File.expand_path(Dir.pwd), "public")

    File.expand_path(compile_location(expanded.gsub(public_dir, '')))
  end

  def compile_location(*subdirs)
    File.join(Dir.pwd, "tmp", "hassle", subdirs)
  end

  def normalize
    template_location = options[:template_location]

    if template_location.is_a?(Hash) || template_location.is_a?(Array)
      options[:template_location] = template_location.to_a.map do |input, output|
        [input, css_location(output)]
      end
    else
      default_location = File.join(options[:css_location], "sass")
      options[:template_location] = {default_location => File.expand_path(css_location(default_location), '..')}
    end
  end

  def prepare
    options.merge!(:cache        => false,
                   :never_update => false)

    options[:template_location].to_a.each do |location|
      FileUtils.mkdir_p(location.last)
    end
  end

  def stylesheets
    options[:template_location].to_a.map do |location|
      Dir[File.join(location.last, "**", "*.css")].map { |css| css.gsub(compile_location, "/") }
    end.flatten.sort
  end

  def compile
    normalize
    prepare
    Sass::Plugin.update_stylesheets
  end
end
