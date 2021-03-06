require 'spec_helper'
require 'ostruct'

module Piggly

=begin
describe Compiler::Trace, "with terminal root node" do
  before do
    @tree     = N.terminal('code')
    @compiler = Compiler::Trace.new('file.sql')
  end

  it "compiles to original terminal" do
    code, _ = @compiler.compile(@tree)
    code.should eql('code')
  end

  it "compiles to single block sequence" do
    code, data = @compiler.compile(@tree)
    blocks = data[:blocks].flatten

    blocks.size.should eql(1)
    blocks.first.should eql([:root, 0..code.size - 1])
  end
end

describe Compiler::Trace, "with regular root node" do
  before do
    @tree = N.node N.terminal('statement'),
                   N.terminal('statement'),
                   N.node(N.terminal('statement'),
                          N.terminal('statement')),
                   N.terminal('statement'),
                   N.terminal('statement')
    @compiler = Compiler::Trace.new('file.sql')
  end

  it "compiles" do
    code, _ = @compiler.compile(@tree)
    code.should eql('statement' * 6)
  end

  it "flattens" do
    code, data = @compiler.compile(@tree)
    blocks  = data[:blocks].flatten
    blocks.size.should eql(1)

    # compiled code has no added instrumentation
    blocks.first.should eql([:root, 0..code.size - 1])
  end
end

describe Compiler::Trace, "root node contains branches" do
  before do
    @tree = N.node N.node(N.terminal('statement-1;'),         N.space),
                   N.branch(N.node(N.terminal('if-1'),        N.space),
                            N.node(N.terminal('condition'),   N.space),
                            N.node(N.terminal('then'),        N.space),
                            N.node(N.terminal('consequence'), N.space),
                            N.node(N.terminal('end if;'),     N.space)),
                   N.node(N.terminal('statement-2;'),         N.space),
                   N.branch(N.node(N.terminal('if-2'),        N.space),
                            N.node(N.terminal('condition'),   N.space),
                            N.node(N.terminal('then'),        N.space),
                            N.node(N.terminal('consequence'), N.space),
                            N.terminal('end if;'))
    @tree.interval # force computation
    @compiler = Compiler::Trace.new('file.sql')
  end

  it "flattens" do
    code, data = @compiler.compile(@tree)
    blocks = data[:blocks].flatten

    first = blocks.select{|id, interval| id == 1 }.map{|e| e.last }
    first.size.should eql(1)
    'consequence'.size.should eql(first[0].end - first[0].begin)

    second = blocks.select{|id, interval| id == 2 }.map{|e| e.last }
    second.size.should eql(1)
    'consequence'.size.should eql(second[0].end - second[0].begin)

    roots = blocks.select{|id, interval| id == :root }.map{|e| e.last }
    roots.size.should eql(3) # root <consequence> root <consequence> root

    # compiled code size = source code size + instrumentation code size
    roots.first.begin.should eql(0)
    roots.last.end.should eql(code.size - ("raise notice 'PIGGLY-file.sql-n';\n".size * 2) - 1)
  end

  it "compiles" do
    code, _ = @compiler.compile(@tree)
    code.should eql(%w[statement-1;
                       if-1 condition then
                         raise notice 'PIGGLY-file.sql-1';\n
                         consequence
                       end if;
                       statement-2;
                       if-2 condition then
                         raise notice 'PIGGLY-file.sql-2';\n
                         consequence
                       end if;].join(' ').gsub('\n ', "\n"))
  end

  it "prepends Config.trace_prefix to raise statements" do
    Config.trace_prefix = 'PREFIX'
    
    code, _ = @compiler.compile(@tree)
    code.should eql(%w[statement-1;
                       if-1 condition then
                         raise notice 'PREFIX-file.sql-1';\n
                         consequence
                       end if;
                       statement-2;
                       if-2 condition then
                         raise notice 'PREFIX-file.sql-2';\n
                         consequence
                       end if;].join(' ').gsub('\n ', "\n"))
  end
end
=end

end
