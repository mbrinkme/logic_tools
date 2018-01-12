# -*- encoding: utf-8 -*-
# stub: logic_tools 0.3.9 ruby lib

Gem::Specification.new do |s|
  s.name = "logic_tools".freeze
  s.version = "0.3.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Lovic Gauthier".freeze]
  s.bindir = "exe".freeze
  s.date = "2018-01-11"
  s.description = "LogicTools is a set of command-line tools for processing logic expressions. \nThe tools include: \nsimplify_qm for simplifying a logic expression, \nsimplify_es for simplifying a logic expression much more quickly than simplify_qm, \nstd_conj for computing the conjunctive normal form of a logic expression, \nstd_dij for computing the disjunctive normal form a of logic expression, \ntruth_tbl for generating the truth table of a logic expression,\nis_tautology for checking if a logic expression is a tautology or not,\nand complement for computing the complement of a logic expression.".freeze
  s.email = ["lovic@ariake-nct.ac.jp".freeze]
  s.executables = ["complement".freeze, "is_tautology".freeze, "simplify_es".freeze, "simplify_qm".freeze, "std_conj".freeze, "std_dij".freeze, "truth_tbl".freeze]
  s.files = [".gitignore".freeze, ".travis.yml".freeze, "Gemfile".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "bin/console".freeze, "bin/setup".freeze, "exe/complement".freeze, "exe/is_tautology".freeze, "exe/simplify_es".freeze, "exe/simplify_qm".freeze, "exe/std_conj".freeze, "exe/std_dij".freeze, "exe/truth_tbl".freeze, "lib/logic_tools.rb".freeze, "lib/logic_tools/complement.rb".freeze, "lib/logic_tools/is_tautology.rb".freeze, "lib/logic_tools/logicconvert.rb".freeze, "lib/logic_tools/logiccover.rb".freeze, "lib/logic_tools/logicfunction.rb".freeze, "lib/logic_tools/logicgenerator.rb".freeze, "lib/logic_tools/logicinput.rb".freeze, "lib/logic_tools/logicparse.rb".freeze, "lib/logic_tools/logicsimplify_es.rb".freeze, "lib/logic_tools/logicsimplify_qm.rb".freeze, "lib/logic_tools/logictree.rb".freeze, "lib/logic_tools/minimal_column_covers.rb".freeze, "lib/logic_tools/simplify_bug.txt".freeze, "lib/logic_tools/simplify_es.rb".freeze, "lib/logic_tools/simplify_qm.rb".freeze, "lib/logic_tools/std_conj.rb".freeze, "lib/logic_tools/std_dij.rb".freeze, "lib/logic_tools/test_logic_tools.rb".freeze, "lib/logic_tools/traces.rb".freeze, "lib/logic_tools/truth_tbl.rb".freeze, "lib/logic_tools/version.rb".freeze, "logic_tools.gemspec".freeze]
  s.homepage = "https://github.com/civol".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.3".freeze
  s.summary = "A set of tools for processing logic expressions.".freeze

  s.installed_by_version = "2.7.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.13"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
      s.add_runtime_dependency(%q<parslet>.freeze, [">= 0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.13"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
      s.add_dependency(%q<parslet>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.13"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_dependency(%q<parslet>.freeze, [">= 0"])
  end
end
