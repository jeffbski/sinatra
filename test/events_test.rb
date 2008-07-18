require File.dirname(__FILE__) + '/../lib/sinatra'

require 'rubygems'
require 'test/spec'

context "Simple Events" do

  def simple_request_hash(method, path)
    Rack::Request.new({
      'REQUEST_METHOD' => method.to_s.upcase,
      'PATH_INFO' => path
    })
  end

  def invoke_simple(path, request_path, &b)
    event = Sinatra::Event.new(path, &b)
    event.invoke(simple_request_hash(:get, request_path))
  end

  def invoke_with_options(path, request_path, options, &b)
    event = Sinatra::Event.new(path, options, &b)
    event.invoke(simple_request_hash(:get, request_path))
  end

  specify "return last value" do
    block = Proc.new { 'Simple' }
    result = invoke_simple('/', '/', &block)
    result.should.not.be.nil
    result.block.should.be block
    result.params.should.equal Hash.new
  end

  specify "takes params in path" do
    result = invoke_simple('/:foo/:bar', '/a/b')
    result.should.not.be.nil
    result.params.should.equal "foo" => 'a', "bar" => 'b'

    # unscapes
    result = invoke_simple('/:foo/:bar', '/a/blake%20mizerany')
    result.should.not.be.nil
    result.params.should.equal "foo" => 'a', "bar" => 'blake mizerany'
  end

  specify "ignores to many /'s" do
    result = invoke_simple('/x/y', '/x//y')
    result.should.not.be.nil
  end

  specify "understands splat" do
    invoke_simple('/foo/*', '/foo/bar').should.not.be.nil
    invoke_simple('/foo/*', '/foo/bar/baz').should.not.be.nil
    invoke_simple('/foo/*', '/foo/baz').should.not.be.nil
  end

  specify "if param_regex is specified, override the default regex for those params" do
    event = Sinatra::Event.new('/:foo/:bar', { :param_regex => { :bar => '.+'}})
    event.pattern.to_s.should.equal '(?-mix:^\\/([^\\/?:,&#\\.]+)\\/(.+)$)'

    event = Sinatra::Event.new('/:foo/:bar', { :param_regex => { :foo => '\d{8}', :bar => '.+'}})
    event.pattern.to_s.should.equal '(?-mix:^\\/(\\d{8})\\/(.+)$)'
  end

  specify "allows options param_regex values to override regex for param" do
    result = invoke_with_options('/:foo/:bar', '/a/hello/world', { :param_regex => { :bar => '.*?'}})
    result.should.not.be.nil
    result.params.should.equal "foo" => 'a', "bar" => 'hello/world'

    result = invoke_with_options('/:foo/:bar', '/hello/world/12345678',
                                 { :param_regex => { :foo => '.+', :bar => '\d{8}'}})
    result.should.not.be.nil
    result.params.should.equal "foo" => 'hello/world', "bar" => '12345678'

    result = invoke_with_options('/:foo/:bar', '/hello/world/abc12345678',
                                 { :param_regex => { :foo => '.+', :bar => '\d{8}'}})
    result.should.be.nil
  end

end
