require 'rubygems'
require 'twitter'

# Linguistic gem:         http://www.deveiate.org/projects/Linguistics/ that automatically load
# WordNet Ruby Bindings:  http://raa.ruby-lang.org/project/wordnet/     and
# LinkParser:             http://www.deveiate.org/projects/Linguistics/wiki/LinkParser
require 'linguistics'   

# This file come from Ola Bini PAIPR (ch2)
# you can find it in its repository: http://github.com/olabini/paipr/tree/7334d50b3b62924bc7c02effd22be0201658945b/lib/ch02
require 'rule_based'

Linguistics::use( :en )

module WordNet               
  class Lexicon
    alias_method :lookupSynsets, :lookup_synsets 
  end
end

base = Twitter::Base.new(Twitter::HTTPAuth.new('twsapiens', <psw here>))

# -- Random Personality
phrase  =  base.friends_timeline.sort{|a,b| rand()<=>rand()}.first.text   

# -- Kind Personality
# phrase = "kind polite garden sun ecology work"

# -- Angry Personality
# phrase = "angry distruptive hate dead explosion"

# Take every word from the sentence and use WordNet to create 
# a group of words that can be, somehow, linked to the base ones.
categories = Hash.new(Array.new)
fuzzyes = phrase.split(" ").collect do |word|
  [:synsets,:meronyms,:hypernyms,:derivations,:hyponyms].collect do |method|
   !(vals = word.en.send(method)).nil? ? vals : nil rescue nil
  end.flatten.compact.collect do |synset| { synset.part_of_speech => synset.words[0..5] } end
end.flatten.each do |tupla|
  cat, vals = tupla.keys[0], tupla.values[0].collect{|v| v.gsub(/\(.*\)/,"").strip}
   (categories[cat] += vals).uniq! unless cat.nil? || vals.to_a.empty?
end

# This grammar is a small modification of the OlaBini original one
$bigger_grammar = { 
  :sentence => [[:noun_phrase, :verb_phrase]],
  :noun_phrase => [[:Article, :Adj, :Noun, :'PP*'], [:Noun], [:Pronoun]],
  :verb_phrase => [[:Verb, :noun_phrase]],
  :'PP*' => [[], [:PP, :'PP*']],
  :'Adj*' => [[], [:Adj, :'Adj*']],
  :PP => [[:Prep, :noun_phrase]],
  :Prep => %w(to in by with on),
  :Adj  => categories[:adjective],
  :Article => %w(the a),
  :Name => %w(Jason Keel Kira Anthony Pat Kim Lee Terry Robin Stephen Jack Holly),
  :Noun => categories[:noun],
  :Verb => categories[:verb],
  :Pronoun => %w(I you he she it these those that)}

$grammar = $bigger_grammar

# Push the generated message on twsapiens account
base.update(generate(:sentence).join(" ").gsub(/\s+/," ")).capitalize

